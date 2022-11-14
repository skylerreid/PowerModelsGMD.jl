using PowerModelsGMD
const _PMGMD = PowerModelsGMD

import InfrastructureModels
const _IM = InfrastructureModels
import PowerModels
const _PM = PowerModels

import JSON
import JuMP
import Memento

# Suppressing warning messages:
Memento.setlevel!(Memento.getlogger(_PMGMD), "error")
Memento.setlevel!(Memento.getlogger(_IM), "error")
Memento.setlevel!(Memento.getlogger(_PM), "error")

_PMGMD.logger_config!("error")
const TESTLOG = Memento.getlogger(_PMGMD)
Memento.setlevel!(TESTLOG, "error")


import Ipopt
import Juniper

# Setup default optimizers:
ipopt_solver = JuMP.optimizer_with_attributes(Ipopt.Optimizer, "tol" => 1e-3, "print_level" => 0, "sb" => "yes")
juniper_solver = JuMP.optimizer_with_attributes(Juniper.Optimizer, "nl_solver" => _PM.optimizer_with_attributes(Ipopt.Optimizer, "tol" => 1e-3, "print_level" => 0, "sb" => "yes"), "log_levels" => [])
setting = Dict{String,Any}("output" => Dict{String,Any}("branch_flows" => true))


import LinearAlgebra
import SparseArrays
using Test

# Parse test cases:
case_b4gic = "../test/data/b4gic.m"
case_b4gic3w = "../test/data/b4gic3w.raw"
case_b6gic_nerc = "../test/data/b6gic_nerc.m"
case24_ieee_rts_0 = "../test/data/case24_ieee_rts_0.m"
case_epri21 = "../test/data/epri21.m"
case_uiuc150 = "../test/data/uiuc150_95pct_loading.m"
case_rtsgmlcgic = "../test/data/rtsgmlcgic/rts_gmlc_gic_pnw.m"
case_otstest = "../test/data/ots_test.m"

# mods_b4gic3w = "../test/data/b4gic3w_mods.json"
# f = open(mods_b4gic3w)
# mods = JSON.parse(f)
# close(f)
# b4gic3w_data = _PM.parse_file(case_b4gic3w)
# _PMGMD.apply_mods!(b4gic3w_data, mods) # function not defined!
# _PMGMD.fix_gmd_indices!(b4gic3w_data) # function not defined!

# Perform automated testing of PMsGMD problem specifications:
@testset "PowerModelsGMD" begin
    include("data_ac.jl")
    include("gmd_matrix.jl")
    include("gmd_mld_decoupled.jl")
    include("gmd_mld.jl")
    include("gmd_opf_decoupled.jl")
    include("gmd_opf_ts_decoupled.jl")
    include("gmd_opf.jl")
    # include("gmd_ots.jl")
    include("gmd.jl")
end
