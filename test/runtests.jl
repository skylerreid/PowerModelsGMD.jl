using PowerModelsLANL
using PowerModels
using Logging
# suppress warnings during testing
Logging.configure(level=ERROR)

using Ipopt
using Pajarito
using GLPKMathProgInterface
using SCS

# needed for Non-convex OTS tests
if (Pkg.installed("AmplNLWriter") != nothing && Pkg.installed("CoinOptServices") != nothing)
    using AmplNLWriter
    using CoinOptServices
end

if VERSION >= v"0.5.0-dev+7720"
    using Base.Test
else
    using BaseTestNext
    const Test = BaseTestNext
end

# default setup for solvers
ipopt_solver = IpoptSolver(tol=1e-6, print_level=0)
pajarito_solver = PajaritoSolver(mip_solver=GLPKSolverMIP(), cont_solver=ipopt_solver, log_level=0)


result = run_ml("../test/data/case3_ml.m", ACPPowerModel, ipopt_solver)
display(result)
display(result["solution"]["bus"])

#scs_solver = SCSSolver(max_iters=1000000, verbose=0)
#pajarito_sdp_solver = PajaritoSolver(mip_solver=GLPKSolverMIP(), cont_solver=scs_solver, log_level=0)

#include("ml.jl")
#include("mluc.jl")
