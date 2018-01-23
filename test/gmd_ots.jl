@testset "test ac gmd ots" begin
    @testset "IEEE 24 0" begin
        result = run_ac_gmd_ots("../test/data/case24_ieee_rts_0.json", bonmin_solver)        
        println(result["status"])
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
 #       @test isapprox(result["objective"], 206067.1; atol = 1e-1)
          
    end
end


@testset "test qc gmd ls" begin
    @testset "IEEE 24 0" begin
        result = run_qc_gmd_ots("../test/data/case24_ieee_rts_0.json", gurobi_solver)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
#        @test isapprox(result["objective"], 195605.43; atol = 1e-1)      
    end
end










