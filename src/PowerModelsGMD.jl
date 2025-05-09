module PowerModelsGMD
const _PMGMD = PowerModelsGMD

    import InfrastructureModels
    const _IM = InfrastructureModels
    import PowerModels
    const _PM = PowerModels
    # import PowerModelsRestoration
    # const _PMR = PowerModelsRestoration


    import PowerModels: pm_it_name, pm_it_sym, nw_ids, nws, ismultinetwork
    import InfrastructureModels: optimize_model!, @im_fields, nw_id_default

    import JSON
    import JuMP
    import Memento
    import Ipopt
    

    # Suppressing information and warning messages:
    const _LOGGER = Memento.getlogger(@__MODULE__)
    __init__() = Memento.register(_LOGGER)

    function silence()
        Memento.info(_LOGGER, "Suppressing information and warning messages for the rest of this session.
        Use the Memento package for more fine-grained control of logging.")
        Memento.setlevel!(Memento.getlogger(_IM), "error")
        Memento.setlevel!(Memento.getlogger(_PM), "error")
        Memento.setlevel!(Memento.getlogger(_PMGMD), "error")
    end

    function logger_config!(level)
        Memento.config!(Memento.getlogger("PowerModelsGMD"), level)
    end


    import LinearAlgebra
    import SparseArrays

    import CSV
    using DataFrames

    import Graphs
    const _Gph = Graphs

    # Add core functions:
    include("core/base.jl")
    include("core/base_staged.jl")
    include("core/constraint_template.jl")
    include("core/constraint_template_staged.jl")
    include("core/constraint.jl")
    include("core/constraint_staged.jl")
    include("core/data.jl")
    include("core/data_staged.jl")
    include("core/dc_network.jl")
    include("core/objective.jl")
    include("core/objective_staged.jl")
    include("core/ref.jl")
    include("core/solution.jl")
    include("core/solution_staged.jl")
    include("core/utilities.jl")
    include("core/variable.jl")
    include("core/variable_staged.jl")

    # Add IO functions
    include("io/common.jl")
    include("io/gic.jl")

    # Add network formulations:
    include("form/acp.jl")
    include("form/acp_staged.jl")
    include("form/dcp.jl")
    include("form/dcp_staged.jl")
    include("form/wr.jl")
    include("form/wr_staged.jl")
    include("form/wrm.jl")

    # Add problem specifications:
    include("prob/gmd.jl")
    include("prob/gmd_pf.jl")
    include("prob/gmd_opf.jl")
    include("prob/gmd_opf_ts_staged.jl")
    include("prob/gmd_mld.jl")
    include("prob/gmd_ots.jl")
    include("prob/gmd_ots_staged.jl")
    include("prob/gmd_bounds.jl")

    include("prob/gmd_opf_staged.jl")
    include("prob/gmd_mld_staged.jl")

    include("algo/decoupled.jl")

    # include("prob/gmd_msse.jl")
    # include("prob/gmd_blocker_placement.jl")
    include("prob/gmd_blocker_placement.jl")

end
