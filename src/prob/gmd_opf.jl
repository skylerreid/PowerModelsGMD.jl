##############
# GIC AC-OPF #
##############


# ===   DECOUPLED AC-OPF   === #


"FUNCTION: solve basic GMD model with nonlinear ac polar relaxation"
function solve_ac_opf_qloss(file, optimizer; kwargs...)
    return solve_opf_qloss( file, _PM.ACPPowerModel, optimizer; kwargs...)
end

function solve_ac_opf_qloss_vnom(file, optimizer; kwargs...)
    return solve_opf_qloss_vnom( file, _PM.ACPPowerModel, optimizer; kwargs...)
end


function solve_opf_qloss(file, model_type::Type, optimizer; kwargs...)
    return _PM.solve_model(
        file,
        model_type,
        optimizer,
        build_opf_qloss;
        solution_processors = [
            solution_PM!,
            solution_gmd_qloss!
        ],
        kwargs...,
    )
end

function solve_opf_qloss_vnom(file, model_type::Type, optimizer; kwargs...)
    return _PM.solve_model(
        file,
        model_type,
        optimizer,
        build_opf_qloss_vnom;
        solution_processors = [
            solution_PM!,
            solution_gmd_qloss!
        ],
        kwargs...,
    )
end


"FUNCTION: build the sequential quasi-dc power flow and ac optimal power flow problem
as a generator dispatch minimization problem with calculated ieff"
function build_opf_qloss(pm::_PM.AbstractPowerModel; kwargs...)
    use_vnom = false
    build_opf_qloss(pm::_PM.AbstractACPModel, use_vnom; kwargs...)
end

function build_opf_qloss_vnom(pm::_PM.AbstractPowerModel; kwargs...)
    use_vnom = true
    build_opf_qloss(pm::_PM.AbstractACPModel, use_vnom; kwargs...)
end

function build_opf_qloss(pm::_PM.AbstractACPModel, vnom; kwargs...)

    _PM.variable_bus_voltage(pm)
    _PM.variable_gen_power(pm)
    _PM.variable_branch_power(pm)
    _PM.variable_dcline_power(pm)

    variable_qloss(pm)

    _PM.constraint_model_voltage(pm)

    for i in _PM.ids(pm, :ref_buses)
        _PM.constraint_theta_ref(pm, i)
    end

    for i in _PM.ids(pm, :bus)
        constraint_power_balance_gmd(pm, i)
    end

    for i in _PM.ids(pm, :branch)

        _PM.constraint_ohms_yt_from(pm, i)
        _PM.constraint_ohms_yt_to(pm, i)

        _PM.constraint_voltage_angle_difference(pm, i)

        _PM.constraint_thermal_limit_from(pm, i)
        _PM.constraint_thermal_limit_to(pm, i)

        if vnom
            constraint_qloss_decoupled_vnom(pm, i)
        else
            constraint_qloss_decoupled(pm, i)
        end

    end

    for i in _PM.ids(pm, :dcline)
        _PM.constraint_dcline_power_losses(pm, i)
    end

    _PM.objective_min_fuel_and_flow_cost(pm)

end


"FUNCTION: solve the quasi-dc power flow problem followed by the ac-opf problem with qloss constraints"
function solve_ac_gmd_opf_decoupled(file::String, optimizer; setting=Dict(), kwargs...)
    data = _PM.parse_file(file)
    return solve_ac_gmd_opf_decoupled(data, optimizer; kwargs...)
end

function solve_ac_gmd_opf_decoupled(case::Dict{String,Any}, optimizer; setting=Dict(), kwargs...)
    return solve_gmd_opf_decoupled(case, _PM.ACPPowerModel, optimizer; kwargs...)
end

function solve_gmd_opf_decoupled(file::String, model_type, optimizer; setting=Dict(), kwargs...)
    data = _PM.parse_file(file)
    return solve_gmd_opf_decoupled(data, model_type, optimizer; kwargs...)
end

function solve_gmd_opf_decoupled(dc_case::Dict{String,Any}, model_type, optimizer; setting=Dict{String,Any}(), kwargs...)

    branch_setting = Dict{String,Any}("output" => Dict{String,Any}("branch_flows" => true))
    merge!(setting, branch_setting)

    dc_result = solve_gmd(dc_case, optimizer)
    dc_solution = dc_result["solution"]

    ac_case = deepcopy(dc_case)
    for (k, branch) in ac_case["branch"]
        dc_current_mag(branch, ac_case, dc_solution)
    end

    qloss_decoupled_vnom(ac_case)
    # ac_result = solve_opf_qloss_vnom(ac_case, model_type, optimizer, setting=setting)
    ac_result = _PM.solve_opf(ac_case, model_type, optimizer, setting=setting)
    ac_solution = ac_result["solution"]
    adjust_gmd_qloss(ac_case, ac_solution)

    data = Dict()
    data["ac"] = Dict("case"=>ac_case, "result"=>ac_result)
    data["dc"] = Dict("case"=>dc_case, "result"=>dc_result)
    return data

end


# ===   COUPLED AC-OPF   === #


"FUNCTION: solve basic GMD model with nonlinear ac polar relaxation"
function solve_ac_gmd_opf(file, optimizer; kwargs...)
    return solve_gmd_opf( file, _PM.ACPPowerModel, optimizer; kwargs...)
end


function solve_gmd_opf(file, model_type::Type, optimizer; kwargs...)
    return _PM.solve_model(
        file,
        model_type,
        optimizer,
        build_gmd_opf;
        ref_extensions = [
            ref_add_gmd!
        ],
        solution_processors = [
            solution_PM!,
            solution_gmd_qloss!,
            solution_gmd!,
            solution_gmd_mls!
        ],
        kwargs...,
    )
end


"FUNCTION: build the ac optimal power flow coupled with quasi-dc power flow problem
as a generator dispatch minimization problem"
function build_gmd_opf(pm::_PM.AbstractPowerModel; kwargs...)

    _PM.variable_bus_voltage(pm)
    _PM.variable_gen_power(pm)
    _PM.variable_branch_power(pm)
    _PM.variable_dcline_power(pm)

    variable_dc_voltage(pm)
    variable_dc_current_mag(pm)
    variable_dc_line_flow(pm)
    variable_qloss(pm)

    _PM.constraint_model_voltage(pm)

    for i in _PM.ids(pm, :ref_buses)
        _PM.constraint_theta_ref(pm, i)
    end

    for i in _PM.ids(pm, :bus)
        constraint_power_balance_gmd(pm, i)
    end

    for i in _PM.ids(pm, :branch)

        _PM.constraint_ohms_yt_from(pm, i)
        _PM.constraint_ohms_yt_to(pm, i)

        _PM.constraint_voltage_angle_difference(pm, i)

        _PM.constraint_thermal_limit_from(pm, i)
        _PM.constraint_thermal_limit_to(pm, i)

        constraint_qloss_vnom(pm, i)
        constraint_dc_current_mag(pm, i)

    end

    for i in _PM.ids(pm, :gmd_bus)
        constraint_dc_power_balance(pm, i)
    end

    for i in _PM.ids(pm, :gmd_branch)
        constraint_dc_ohms(pm, i)
    end

    objective_gmd_min_fuel(pm)

end

