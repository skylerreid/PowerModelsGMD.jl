
"default SOC constructor"
SOCWRPowerModel(data::Dict{String,Any}; kwargs...) = GenericGMDPowerModel(data, SOCWRForm; kwargs...)

"default QC constructor"
function QCWRPowerModel(data::Dict{String,Any}; kwargs...)
    return GenericGMDPowerModel(data, QCWRForm; kwargs...)
end

"default QC trilinear model constructor"
function QCWRTriPowerModel(data::Dict{String,Any}; kwargs...)
    return GenericGMDPowerModel(data, QCWRTriForm; kwargs...)
end


""
function variable_ac_current{T <: PowerModels.AbstractWRForm}(pm::GenericPowerModel{T},n::Int=pm.cnw; bounded = true)
   variable_ac_current_mag(pm,n)
    
   parallel_branch = filter((i, branch) -> pm.ref[:nw][n][:buspairs][(branch["f_bus"], branch["t_bus"])]["branch"] != i, pm.ref[:nw][n][:branch])     
   cm_min = Dict([(l, 0) for l in keys(parallel_branch)]    )
   cm_max = Dict([(l, (branch["rate_a"]*branch["tap"]/pm.ref[:nw][n][:bus][branch["f_bus"]]["vmin"])^2) for (l, branch) in parallel_branch])
   pm.var[:nw][n][:cm_p] = @variable(pm.model,
        [l in keys(parallel_branch)], basename="$(n)_cm_p",
        lowerbound = cm_min[l],
        upperbound = cm_max[l],
        start = PowerModels.getstart(pm.ref[:nw][n][:branch], l, "cm_start")
    )   
end

""
function variable_dc_current{T <: PowerModels.AbstractWRForm}(pm::GenericPowerModel{T},n::Int=pm.cnw; bounded = true)
   variable_dc_current_mag(pm,n)
   variable_dc_current_mag_sqr(pm,n)
end

""
function variable_reactive_loss{T <: PowerModels.AbstractWRForm}(pm::GenericPowerModel{T},n::Int=pm.cnw; bounded = true)
   variable_qloss(pm,n)
   variable_iv(pm,n)
end

"""
```
sum(p[a] for a in bus_arcs) + sum(p_dc[a_dc] for a_dc in bus_arcs_dc) == sum(pg[g] for g in bus_gens) - pd - gs*w[i] + pd_ls
sum(q[a] for a in bus_arcs) + sum(q_dc[a_dc] for a_dc in bus_arcs_dc) == sum(qg[g] for g in bus_gens) - qd + bs*w[i] + qd_ls - qloss
```
"""
function constraint_kcl_shunt_gmd_ls{T <: PowerModels.AbstractWRForm}(pm::GenericPowerModel{T}, n::Int, i, bus_arcs, bus_arcs_dc, bus_gens, pd, qd, gs, bs)
    w = pm.var[:nw][n][:w][i]
    pg = pm.var[:nw][n][:pg]
    qg = pm.var[:nw][n][:qg]
    p = pm.var[:nw][n][:p]
    q = pm.var[:nw][n][:q]
    
    qloss = pm.var[:nw][n][:qloss]  
    pd_ls = pm.var[:nw][n][:pd]
    qd_ls = pm.var[:nw][n][:qd]     

    @constraint(pm.model, sum(p[a] for a in bus_arcs) == sum(pg[g] for g in bus_gens) - pd - gs*w + pd_ls[i])
    @constraint(pm.model, sum(q[a] + qloss[a] for a in bus_arcs)  == sum(qg[g] for g in bus_gens) - qd + bs*w + qd_ls[i])
end

"Constraint for relating current to power flow"
function constraint_current{T <: PowerModels.AbstractWRForm}(pm::GenericPowerModel{T}, n::Int, i)
    branch = ref(pm, n, :branch, i)
    f_bus = branch["f_bus"]
    t_bus = branch["t_bus"]
    pair = (f_bus, t_bus)
    buspair = ref(pm, n, :buspairs, pair)
    arc_from = (i, f_bus, t_bus)  
    
    i_ac_mag = pm.var[:nw][n][:i_ac_mag][i] 
    
    if buspair["branch"] == i       
        # p_fr^2 + q_fr^2 <= l * w comes for free with constraint_power_magnitude_sqr of PowerModels.jl
        l = pm.var[:nw][n][:cm][(f_bus, t_bus)]        
        PowerModels.relaxation_sqr(pm.model, i_ac_mag, l)
    else
        l = pm.var[:nw][n][:cm_p][i]        
        w = pm.var[:nw][n][:w][f_bus]
        p_fr = pm.var[:nw][n][:p][arc_from]
        q_fr = pm.var[:nw][n][:q][arc_from]  

        @constraint(pm.model, p_fr^2 + q_fr^2 <= l * w)  
        PowerModels.relaxation_sqr(pm.model, i_ac_mag, l) 
    end
end

"Constraint for computing thermal protection of transformers"
function constraint_thermal_protection{T <: PowerModels.AbstractWRForm}(pm::GenericPowerModel{T}, n::Int, i)
    branch = ref(pm, n, :branch, i)
    if branch["type"] != "xf"
        return  
    end  

    coeff = calc_branch_thermal_coeff(pm,i,n)
    ibase = calc_branch_ibase(pm, i, n)

    i_ac_mag = pm.var[:nw][n][:i_ac_mag][i] 
    ieff = pm.var[:nw][n][:i_dc_mag][i] 
    ieff_sqr = pm.var[:nw][n][:i_dc_mag_sqr][i] 

    @constraint(pm.model, i_ac_mag <= coeff[1] + coeff[2]*ieff/ibase + coeff[3]*ieff_sqr/(ibase^2))      
    PowerModels.relaxation_sqr(pm.model, ieff, ieff_sqr) 
    
end

""
function constraint_qloss{T <: PowerModels.AbstractWRForm}(pm::GenericPowerModel{T}, n::Int, k)
    branch = ref(pm, n, :branch, k)        

    i = branch["hi_bus"]
    j = branch["lo_bus"]

    bus = pm.ref[:nw][n][:bus][i]

    i_dc_mag = pm.var[:nw][n][:i_dc_mag][k]
    qloss = pm.var[:nw][n][:qloss]
    iv = pm.var[:nw][n][:iv][(k,i,j)]    
    vm = pm.var[:nw][n][:vm][i]
        
    if "gmd_k" in keys(branch)
        ibase = branch["baseMVA"]*1000.0*sqrt(2.0)/(bus["base_kv"]*sqrt(3.0))
        K = branch["gmd_k"]*pm.data["baseMVA"]/ibase

        # K is per phase
        @constraint(pm.model, qloss[(k,i,j)] == K*iv/(3.0*branch["baseMVA"]))
        @constraint(pm.model, qloss[(k,j,i)] == 0.0)
    else
        @constraint(pm.model, qloss[(k,i,j)] == 0.0)
        @constraint(pm.model, qloss[(k,j,i)] == 0.0)
    end

    PowerModels.relaxation_product(pm.model, i_dc_mag, vm, iv) 
end
