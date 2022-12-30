# ===   WR   === #


"VARIABLE: bus voltage on/off"
function variable_bus_voltage_on_off(pm::_PM.AbstractWRModel; kwargs...)
    variable_bus_voltage_magnitude_sqr_on_off(pm; kwargs...)
    variable_bus_voltage_product_on_off(pm; kwargs...)
end


"VARIABLE: bus voltage product on/off"
function variable_bus_voltage_product_on_off(pm::_PM.AbstractWRModel; nw::Int=nw_id_default)

    wr_min, wr_max, wi_min, wi_max = _PM.ref_calc_voltage_product_bounds(_PM.ref(pm, nw, :buspairs))

    _PM.var(pm, nw)[:wr] = JuMP.@variable(pm.model,
        [bp in _PM.ids(pm, nw, :buspairs)], base_name="$(nw)_wr",
        lower_bound = min(0,wr_min[bp]),
        upper_bound = max(0,wr_max[bp]),
        start = _PM.comp_start_value(_PM.ref(pm, nw, :buspairs, bp), "wr_start", 1.0)
    )
    _PM.var(pm, nw)[:wi] = JuMP.@variable(pm.model,
        [bp in _PM.ids(pm, nw, :buspairs)], base_name="$(nw)_wi",
        lower_bound = min(0,wi_min[bp]),
        upper_bound = max(0,wi_max[bp]),
        start = _PM.comp_start_value(_PM.ref(pm, nw, :buspairs, bp), "wi_start")
    )

end


"FUNCTION: ac current on/off"
function variable_ac_current_on_off(pm::_PM.AbstractWRModel; kwargs...)
   variable_ac_current_mag(pm; bounded=false, kwargs...)
end


"FUNCTION: ac current"
function variable_ac_current(pm::_PM.AbstractWRModel; kwargs...)

    nw = nw_id_default

    variable_ac_current_mag(pm; kwargs...)

    parallel_branch = Dict(x for x in _PM.ref(pm, nw, :branch) if _PM.ref(pm, nw, :buspairs)[(x.second["f_bus"], x.second["t_bus"])]["branch"] != x.first)
    cm_min = Dict((l, 0) for l in keys(parallel_branch))
    cm_max = Dict((l, (branch["rate_a"]*branch["tap"]/_PM.ref(pm, nw, :bus)[branch["f_bus"]]["vmin"])^2) for (l, branch) in parallel_branch)

    _PM.var(pm, nw)[:cm_p] = JuMP.@variable(pm.model,
        [l in keys(parallel_branch)], base_name="$(nw)_cm_p",
        lower_bound = cm_min[l],
        upper_bound = cm_max[l],
        start = _PM.comp_start_value(_PM.ref(pm, nw, :branch, l), "cm_p_start")
    )

end


"FUNCTION: dc current"
function variable_dc_current(pm::_PM.AbstractWRModel; kwargs...)
    variable_dc_current_mag(pm; kwargs...)
    variable_dc_current_mag_sqr(pm; kwargs...)
end


"FUNCTION: reactive loss"
function variable_reactive_loss(pm::_PM.AbstractWRModel; kwargs...)
    variable_qloss(pm; kwargs...)
    variable_iv(pm; kwargs...)
end


"CONSTRAINT: bus voltage product on/off"
function constraint_bus_voltage_product_on_off(pm::_PM.AbstractWRModels; nw::Int=nw_id_default)

    wr_min, wr_max, wi_min, wi_max = _PM.ref_calc_voltage_product_bounds(_PM.ref(pm, nw, :buspairs))

    wr = _PM.var(pm, nw, :wr)
    wi = _PM.var(pm, nw, :wi)
    z_voltage = _PM.var(pm, nw, :z_voltage)

    for bp in _PM.ids(pm, nw, :buspairs)
        (i,j) = bp
        z_fr = z_voltage[i]
        z_to = z_voltage[j]

        JuMP.@constraint(pm.model,
            wr[bp]
            <=
            z_fr * wr_max[bp]
        )
        JuMP.@constraint(pm.model,
            wr[bp]
            >=
            z_fr * wr_min[bp]
        )
        JuMP.@constraint(pm.model,
            wi[bp]
            <=
            z_fr * wi_max[bp]
        )
        JuMP.@constraint(pm.model,
            wi[bp]
            >=
            z_fr * wi_min[bp]
        )

        JuMP.@constraint(pm.model,
            wr[bp]
            <=
            z_to*wr_max[bp]
        )
        JuMP.@constraint(pm.model,
            wr[bp]
            >=
            z_to*wr_min[bp]
        )
        JuMP.@constraint(pm.model,
            wi[bp]
            <=
            z_to*wi_max[bp]
        )
        JuMP.@constraint(pm.model,
            wi[bp]
            >=
            z_to*wi_min[bp]
        )

    end
end


"CONSTRAINT: bus voltage on/off"
function constraint_bus_voltage_on_off(pm::_PM.AbstractWRModels, n::Int; kwargs...)

    for (i,bus) in _PM.ref(pm, n, :bus)
        constraint_voltage_magnitude_sqr_on_off(pm, i; nw=n)
    end

    constraint_bus_voltage_product_on_off(pm; nw=n)

    w = _PM.var(pm, n, :w)
    wr = _PM.var(pm, n, :wr)
    wi = _PM.var(pm, n, :wi)

    for (i,j) in _PM.ids(pm, n, :buspairs)
        _IM.relaxation_complex_product(pm.model, w[i], w[j], wr[(i,j)], wi[(i,j)])
    end

end






# ===   BUS - POWER BALANCE CONSTRAINTS   === #


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


"CONSTRAINT: nodal power balance with gmd, shunts, and constant power factor load shedding"
function constraint_power_balance_gmd_shunt_ls(pm::_PM.AbstractWRModel, n::Int, i::Int, bus_arcs, bus_arcs_dc, bus_arcs_sw, bus_gens, bus_storage, bus_pd, bus_qd, bus_gs, bus_bs)

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

    z_demand = get(_PM.var(pm, n), :z_demand, Dict()); _PM._check_var_keys(z_demand, keys(bus_pd), "power factor", "load")
    z_shunt = get(_PM.var(pm, n), :z_shunt, Dict()); _PM._check_var_keys(z_shunt, keys(bus_gs), "power factor", "shunt")

    # this is required for improved performance in NLP models
    if length(z_shunt) <= 0
        cstr_p = JuMP.@constraint(pm.model,
            sum(p[a] for a in bus_arcs)
            + sum(p_dc[a_dc] for a_dc in bus_arcs_dc)
            + sum(psw[a_sw] for a_sw in bus_arcs_sw)
            ==
            sum(pg[g] for g in bus_gens)
            - sum(ps[s] for s in bus_storage)
            - sum(pd * z_demand[i] for (i,pd) in bus_pd)
            - sum(gs * z_shunt[i] for (i,gs) in bus_gs) * w
        )
        cstr_q = JuMP.@constraint(pm.model,
            sum(q[a] + qloss[a] for a in bus_arcs)
            + sum(q_dc[a_dc] for a_dc in bus_arcs_dc)
            + sum(qsw[a_sw] for a_sw in bus_arcs_sw)
            ==
            sum(qg[g] for g in bus_gens)
            - sum(qs[s] for s in bus_storage)
            - sum(qd * z_demand[i] for (i,qd) in bus_qd)
            + sum(bs * z_shunt[i] for (i,bs) in bus_bs) * w
        )
    else
        cstr_p = JuMP.@NLconstraint(pm.model,
            sum(p[a] for a in bus_arcs)
            + sum(p_dc[a_dc] for a_dc in bus_arcs_dc)
            + sum(psw[a_sw] for a_sw in bus_arcs_sw)
            ==
            sum(pg[g] for g in bus_gens)
            - sum(ps[s] for s in bus_storage)
            - sum(pd * z_demand[i] for (i,pd) in bus_pd)
            - sum(gs * z_shunt[i] for (i,gs) in bus_gs) * w
        )
        cstr_q = JuMP.@NLconstraint(pm.model,
            sum(q[a] + qloss[a] for a in bus_arcs)
            + sum(q_dc[a_dc] for a_dc in bus_arcs_dc)
            + sum(qsw[a_sw] for a_sw in bus_arcs_sw)
            ==
            sum(qg[g] for g in bus_gens)
            - sum(qs[s] for s in bus_storage)
            - sum(qd * z_demand[i] for (i,qd) in bus_qd)
            + sum(bs * z_shunt[i] for (i,bs) in bus_bs) * w
        )
    end

    if _IM.report_duals(pm)
        _PM.sol(pm, n, :bus, i)[:lam_kcl_r] = cstr_p
        _PM.sol(pm, n, :bus, i)[:lam_kcl_i] = cstr_q
    end

end


# ===   BRANCH - QLOSS CONSTRAINTS   === #


"CONSTRAINT: zero qloss"
function constraint_zero_qloss(pm::_PM.AbstractWRModel, n::Int, k, i, j)

    qloss = _PM.var(pm, n, :qloss)
    i_dc_mag = _PM.var(pm, n, :i_dc_mag)[k]

    vm = _PM.var(pm, n, :vm)[i]
    iv = _PM.var(pm, n, :iv)[(k,i,j)]

    JuMP.@constraint(pm.model,
        qloss[(k,i,j)]
        ==
        0.0
    )
    JuMP.@constraint(pm.model,
        qloss[(k,j,i)]
        ==
        0.0
    )

    _IM.relaxation_product(pm.model, i_dc_mag, vm, iv)

end


"CONSTRAINT: qloss assuming constant ac primary voltage"
function constraint_qloss(pm::_PM.AbstractWRModel, n::Int, k, i, j, branchMVA, K, V)

    qloss = _PM.var(pm, n, :qloss)
    i_dc_mag = _PM.var(pm, n, :i_dc_mag)[k]

    vm = _PM.var(pm, n, :vm)[i]
    iv = _PM.var(pm, n, :iv)[(k,i,j)]

    if JuMP.lower_bound(i_dc_mag) > 0.0 || JuMP.upper_bound(i_dc_mag) < 0.0
        Memento.warn(_LOGGER, "DC voltage magnitude cannot take a 0 value. In OTS applications, this may result in incorrect results.")
    end

    JuMP.@constraint(pm.model,
        qloss[(k,i,j)]
        ==
        ((K * iv) / (3.0 * branchMVA))
            # K is per phase
    )
    JuMP.@constraint(pm.model,
        qloss[(k,j,i)]
        ==
        0.0
    )

    _IM.relaxation_product(pm.model, i_dc_mag, vm, iv)

end


# ===   BRANCH - THERMAL CONSTRAINTS   === #

##########






"CONSTRAINT: relating current to power flow on_off"
function constraint_current_on_off(pm::_PM.AbstractWRModel, n::Int, i::Int, ac_max)

    i_ac_mag = _PM.var(pm, n, :i_ac_mag)[i]
    z = _PM.var(pm, n, :z_branch)[i]

    JuMP.@constraint(pm.model,
        i_ac_mag
        <=
        z * ac_max
    )
    JuMP.@constraint(pm.model,
        i_ac_mag
        >=
        0
    )

end


"CONSTRAINT: computing thermal protection of transformers"
function constraint_thermal_protection(pm::_PM.AbstractWRModel, n::Int, i::Int, coeff, ibase)

    i_ac_mag = _PM.var(pm, n, :i_ac_mag)[i]
    ieff = _PM.var(pm, n, :i_dc_mag)[i]
    ieff_sqr = _PM.var(pm, n, :i_dc_mag_sqr)[i]

    JuMP.@constraint(pm.model,
        i_ac_mag
        <=
        coeff[1] + coeff[2]*ieff/ibase + coeff[3]*ieff_sqr/(ibase^2)
    )

    _IM.relaxation_sqr(pm.model, ieff, ieff_sqr)

end


