

"FUNCTION: ac current"
#function variable_ac_current(pm::_PM.AbstractWRModel; kwargs...)
#    nw = nw_id_default

#    variable_ac_current_mag(pm; kwargs...)

#    parallel_branch = Dict(x for x in _PM.ref(pm, nw, :branch) if _PM.ref(pm, nw, :buspairs)[(x.second["f_bus"], x.second["t_bus"])]["branch"] != x.first)
#    cm_min = Dict((l, 0) for l in keys(parallel_branch))
#    cm_max = Dict((l, (branch["rate_a"]*branch["tap"]/_PM.ref(pm, nw, :bus)[branch["f_bus"]]["vmin"])^2) for (l, branch) in parallel_branch)

#    _PM.var(pm, nw)[:cm_p] = JuMP.@variable(pm.model,
#        [l in keys(parallel_branch)], base_name="$(nw)_cm_p",
#        lower_bound = cm_min[l],
#        upper_bound = cm_max[l],
#        start = _PM.comp_start_value(_PM.ref(pm, nw, :branch, l), "cm_p_start")
#    )
#end


"CONSTRAINT: relating current to power flow on_off"
function constraint_current_on_off(pm::_PM.AbstractWRModel, n::Int, i::Int, ac_max)
    i_ac_mag = _PM.var(pm, n, :i_ac_mag)[i]
    z = _PM.var(pm, n, :z_branch)[i]

    JuMP.@constraint(pm.model, i_ac_mag <= z*ac_max)
    JuMP.@constraint(pm.model, i_ac_mag >= 0.0)
end


# ===   POWER BALANCE CONSTRAINTS   === #


"CONSTRAINT: nodal power balance with gmd"
function constraint_power_balance_gmd(pm::_PM.AbstractWRModel, n::Int, i::Int, bus_arcs, bus_arcs_dc, bus_arcs_sw, bus_gens, bus_storage, bus_pd, bus_qd)
    p = get(_PM.var(pm, n), :p, Dict()); _PM._check_var_keys(p, bus_arcs, "active power", "branch")
    q = get(_PM.var(pm, n), :q, Dict()); _PM._check_var_keys(q, bus_arcs, "reactive power", "branch")
    qloss = get(_PM.var(pm, n), :qloss, Dict()); _PM._check_var_keys(qloss, bus_arcs, "reactive power", "branch")
    pg = get(_PM.var(pm, n), :pg, Dict()); _PM._check_var_keys(pg, bus_gens, "active power", "generator")
    qg = get(_PM.var(pm, n), :qg, Dict()); _PM._check_var_keys(qg, bus_gens, "reactive power", "generator")
    ps = get(_PM.var(pm, n), :ps, Dict()); _PM._check_var_keys(ps, bus_storage, "active power", "storage")
    qs = get(_PM.var(pm, n), :qs, Dict()); _PM._check_var_keys(qs, bus_storage, "reactive power", "storage")
    psw = get(_PM.var(pm, n), :psw, Dict()); _PM._check_var_keys(psw, bus_arcs_sw, "active power", "switch")
    qsw = get(_PM.var(pm, n), :qsw, Dict()); _PM._check_var_keys(qsw, bus_arcs_sw, "reactive power", "switch")
    p_dc = get(_PM.var(pm, n), :p_dc, Dict()); _PM._check_var_keys(p_dc, bus_arcs_dc, "active power", "dcline")
    q_dc = get(_PM.var(pm, n), :q_dc, Dict()); _PM._check_var_keys(q_dc, bus_arcs_dc, "reactive power", "dcline")

    # the check "typeof(p[arc]) <: JuMP.NonlinearExpression" is required for the
    # case when p/q are nonlinear expressions instead of decision variables
    # once NLExpressions are first order in JuMP it should be possible to
    # remove this.
    nl_form = length(bus_arcs) > 0 && (typeof(p[iterate(bus_arcs)[1]]) <: JuMP.NonlinearExpression)

    if !nl_form
        cstr_p = JuMP.@constraint(pm.model,
            sum(p[a] for a in bus_arcs)
            + sum(p_dc[a_dc] for a_dc in bus_arcs_dc)
            + sum(psw[a_sw] for a_sw in bus_arcs_sw)
            ==
            sum(pg[g] for g in bus_gens)
            - sum(ps[s] for s in bus_storage)
            - sum(pd for (i,pd) in bus_pd)
        )
    else
        cstr_p = JuMP.@NLconstraint(pm.model,
            sum(p[a] for a in bus_arcs)
            + sum(p_dc[a_dc] for a_dc in bus_arcs_dc)
            + sum(psw[a_sw] for a_sw in bus_arcs_sw)
            ==
            sum(pg[g] for g in bus_gens)
            - sum(ps[s] for s in bus_storage)
            - sum(pd for (i,pd) in bus_pd)
        )
    end

    if !nl_form
        cstr_q = JuMP.@constraint(pm.model,
            sum(q[a] + qloss[a] for a in bus_arcs)
            + sum(q_dc[a_dc] for a_dc in bus_arcs_dc)
            + sum(qsw[a_sw] for a_sw in bus_arcs_sw)
            ==
            sum(qg[g] for g in bus_gens)
            - sum(qs[s] for s in bus_storage)
            - sum(qd for (i,qd) in bus_qd)
        )
    else
        cstr_q = JuMP.@NLconstraint(pm.model,
            sum(q[a] + qloss[a] for a in bus_arcs)
            + sum(q_dc[a_dc] for a_dc in bus_arcs_dc)
            + sum(qsw[a_sw] for a_sw in bus_arcs_sw)
            ==
            sum(qg[g] for g in bus_gens)
            - sum(qs[s] for s in bus_storage)
            - sum(qd for (i,qd) in bus_qd)
        )
    end

    if _IM.report_duals(pm)
        _PM.sol(pm, n, :bus, i)[:lam_kcl_r] = cstr_p
        _PM.sol(pm, n, :bus, i)[:lam_kcl_i] = cstr_q
    end
end


"CONSTRAINT: nodal power balance with gmd and shunts"
function constraint_power_balance_gmd_shunt(pm::_PM.AbstractWRModel, n::Int, i::Int, bus_arcs, bus_arcs_dc, bus_arcs_sw, bus_gens, bus_storage, bus_pd, bus_qd, bus_gs, bus_bs)
    w = _PM.var(pm, n, :w, i)
    p = get(_PM.var(pm, n), :p, Dict()); _PM._check_var_keys(p, bus_arcs, "active power", "branch")
    q = get(_PM.var(pm, n), :q, Dict()); _PM._check_var_keys(q, bus_arcs, "reactive power", "branch")
    qloss = get(_PM.var(pm, n), :qloss, Dict()); _PM._check_var_keys(qloss, bus_arcs, "reactive power", "branch")
    pg = get(_PM.var(pm, n), :pg, Dict()); _PM._check_var_keys(pg, bus_gens, "active power", "generator")
    qg = get(_PM.var(pm, n), :qg, Dict()); _PM._check_var_keys(qg, bus_gens, "reactive power", "generator")
    ps = get(_PM.var(pm, n), :ps, Dict()); _PM._check_var_keys(ps, bus_storage, "active power", "storage")
    qs = get(_PM.var(pm, n), :qs, Dict()); _PM._check_var_keys(qs, bus_storage, "reactive power", "storage")
    psw = get(_PM.var(pm, n), :psw, Dict()); _PM._check_var_keys(psw, bus_arcs_sw, "active power", "switch")
    qsw = get(_PM.var(pm, n), :qsw, Dict()); _PM._check_var_keys(qsw, bus_arcs_sw, "reactive power", "switch")
    p_dc = get(_PM.var(pm, n), :p_dc, Dict()); _PM._check_var_keys(p_dc, bus_arcs_dc, "active power", "dcline")
    q_dc = get(_PM.var(pm, n), :q_dc, Dict()); _PM._check_var_keys(q_dc, bus_arcs_dc, "reactive power", "dcline")

    # the check "typeof(p[arc]) <: JuMP.NonlinearExpression" is required for the
    # case when p/q are nonlinear expressions instead of decision variables
    # once NLExpressions are first order in JuMP it should be possible to
    # remove this.
    nl_form = length(bus_arcs) > 0 && (typeof(p[iterate(bus_arcs)[1]]) <: JuMP.NonlinearExpression)

    if !nl_form
        cstr_p = JuMP.@constraint(pm.model,
            sum(p[a] for a in bus_arcs)
            + sum(p_dc[a_dc] for a_dc in bus_arcs_dc)
            + sum(psw[a_sw] for a_sw in bus_arcs_sw)
            ==
            sum(pg[g] for g in bus_gens)
            - sum(ps[s] for s in bus_storage)
            - sum(pd for (i,pd) in bus_pd)
            - sum(gs for (i,gs) in bus_gs) * w
        )
    else
        cstr_p = JuMP.@NLconstraint(pm.model,
            sum(p[a] for a in bus_arcs)
            + sum(p_dc[a_dc] for a_dc in bus_arcs_dc)
            + sum(psw[a_sw] for a_sw in bus_arcs_sw)
            ==
            sum(pg[g] for g in bus_gens)
            - sum(ps[s] for s in bus_storage)
            - sum(pd for (i,pd) in bus_pd)
            - sum(gs for (i,gs) in bus_gs) * w
        )
    end

    if !nl_form
        cstr_q = JuMP.@constraint(pm.model,
            sum(q[a] + qloss[a] for a in bus_arcs)
            + sum(q_dc[a_dc] for a_dc in bus_arcs_dc)
            + sum(qsw[a_sw] for a_sw in bus_arcs_sw)
            ==
            sum(qg[g] for g in bus_gens)
            - sum(qs[s] for s in bus_storage)
            - sum(qd for (i,qd) in bus_qd)
            + sum(bs for (i,bs) in bus_bs) * w
        )
    else
        cstr_q = JuMP.@NLconstraint(pm.model,
            sum(q[a] + qloss[a] for a in bus_arcs)
            + sum(q_dc[a_dc] for a_dc in bus_arcs_dc)
            + sum(qsw[a_sw] for a_sw in bus_arcs_sw)
            ==
            sum(qg[g] for g in bus_gens)
            - sum(qs[s] for s in bus_storage)
            - sum(qd for (i,qd) in bus_qd)
            + sum(bs for (i,bs) in bus_bs) * w
        )
    end

    if _IM.report_duals(pm)
        _PM.sol(pm, n, :bus, i)[:lam_kcl_r] = cstr_p
        _PM.sol(pm, n, :bus, i)[:lam_kcl_i] = cstr_q
    end
end


# ===   QLOSS CONSTRAINTS   === #


"CONSTRAINT: zero qloss"
function constraint_zero_qloss(pm::_PM.AbstractWRModel, n::Int, k, i, j)
    qloss = _PM.var(pm, n, :qloss)

    JuMP.@constraint(pm.model, qloss[(k,i,j)] == 0.0)
    JuMP.@constraint(pm.model, qloss[(k,j,i)] == 0.0)
end


"CONSTRAINT: thermal protection of transformers"
function constraint_thermal_protection(pm::_PM.AbstractWRModel, n::Int, i::Int, coeff, ibase)
    i_ac_mag = _PM.var(pm, n, :i_ac_mag)[i]
    ieff = _PM.var(pm, n, :i_dc_mag)[i]
    ieff_sqr = _PM.var(pm, n, :i_dc_mag_sqr)[i]

    JuMP.@constraint(pm.model, i_ac_mag <= coeff[1] + coeff[2]*ieff/ibase + coeff[3]*ieff_sqr/(ibase^2))
    _IM.relaxation_sqr(pm.model, ieff, ieff_sqr)
end


"FUNCTION: ac current on/off"
function variable_ac_current_on_off(pm::_PM.AbstractWRModel; kwargs...)
   variable_ac_current_mag(pm; bounded=false, kwargs...)
end

"FUNCTION: dc current"
function variable_dc_current(pm::_PM.AbstractWRModel; kwargs...)
    variable_dc_current_mag(pm; kwargs...)
    variable_dc_current_mag_sqr(pm; kwargs...)
end

