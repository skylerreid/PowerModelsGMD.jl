##########
# GIC DC #
##########


# ===   WITH OPTIMIZER   === #


"FUNCTION: solve GIC current model"
function solve_gmd(file, optimizer; kwargs...)
    return _PM.solve_model(
        file,
        _PM.ACPPowerModel,
        optimizer,
        build_gmd;
        ref_extensions = [
            ref_add_gmd!,
        ],
        solution_processors = [
            solution_gmd!
        ],
        kwargs...,
    )
end


"FUNCTION: build the quasi-dc-pf problem
as a linear constraint satisfaction problem"
function build_gmd(pm::_PM.AbstractPowerModel; kwargs...)

    variable_dc_voltage(pm)
    variable_gic_current(pm)
    variable_dc_line_flow(pm)
    variable_qloss(pm)

    for i in _PM.ids(pm, :gmd_bus)
        constraint_dc_kcl(pm, i) # constraint_gic_current_balance(
        
    end

    for i in _PM.ids(pm, :branch)
        constraint_qloss_gmd(pm, i)
        constraint_dc_current_mag(pm, i)
    end

    for i in _PM.ids(pm, :gmd_branch)
        constraint_dc_ohms(pm, i)
    end
end


# ===   WITH MATRIX SOLVE   === #


"FUNCTION: solve GIC matrix solve"
function solve_gmd(raw_file::String, gic_file::String, voltage_file::String; kwargs...)
    data = parse_files(gic_file, raw_file)
    case = generate_dc_data(data["nw"]["1"], data["nw"]["2"], voltage_file) 
    return solve_gmd(case; kwargs)
end

function solve_gmd(file::String; kwargs...)
    data = parse_file(file)
    return solve_gmd(data; kwargs...)
end

function solve_gmd(case::Dict{String,Any}; kwargs...)
    g, i_inj = generate_g_i_matrix(case)

    v = g\i_inj
    
    return solution_gmd(v, case)
end
