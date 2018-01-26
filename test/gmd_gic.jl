@testset "test gic gmd" begin
    @testset "4-bus case solution" begin
        result = run_gmd_gic("../test/data/b4gic.json", ipopt_solver)

        @test result["status"] == :LocalOptimal
    end

    @testset "4-bus case" begin
        casename = "../test/data/b4gic.json"        
        f = open(casename)
        case = JSON.parse(f)
        close(f)

        result = run_gmd_gic("../test/data/b4gic.json", ipopt_solver; setting=setting)

        @test result["status"] == :LocalOptimal

        solution = result["solution"]
        make_gmd_mixed_units(solution, 100.0)
        adjust_gmd_qloss(case, solution)

        @test isapprox(solution["gmd_bus"]["3"]["gmd_vdc"], -32, atol=0.1)       
    end

    @testset "6-bus case" begin
        casename = "../test/data/b6gic_nerc.json"
        result = run_gmd_gic(casename, ipopt_solver; setting=setting)

        f = open(casename)
        case = JSON.parse(f)
        close(f)

        @test result["status"] == :LocalOptimal
          
        solution = result["solution"]
        make_gmd_mixed_units(solution, 100.0)
        adjust_gmd_qloss(case, solution)

        @test isapprox(solution["gmd_bus"]["5"]["gmd_vdc"], -23.022192, atol=1e-1)
    end

    @testset "19-bus case" begin
        casename = "../test/data/epri21.json"
        result = run_gmd_gic(casename, ipopt_solver)

        f = open(casename)
        case = JSON.parse(f)
        close(f)

        @test result["status"] == :LocalOptimal
         
        solution = result["solution"]
        make_gmd_mixed_units(solution, 100.0)
        # adjust_gmd_qloss(case, solution)
        @test isapprox(solution["gmd_bus"]["14"]["gmd_vdc"], 44.31, atol=1e-1) # PowerModels: gmd_vdc = 44.26301987818914
        @test isapprox(solution["gmd_bus"]["23"]["gmd_vdc"],  -41.01, atol=1e-1) # PowerModels: gmd_vdc = -40.95101258160489
    end

    @testset "150-bus case" begin
        casename = "../test/data/uiuc150.json"
        result = run_gmd_gic(casename, ipopt_solver)

        f = open(casename)
        case = JSON.parse(f)
        close(f)

        @test result["status"] == :LocalOptimal
        
        solution = result["solution"]
        make_gmd_mixed_units(solution, 100.0)

        @test isapprox(solution["gmd_bus"]["190"]["gmd_vdc"], 7.00, atol=1e-1) # PowerModels: gmd_vdc = 44.26301987818914
        @test isapprox(solution["gmd_bus"]["197"]["gmd_vdc"], -32.74, atol=1e-1) # PowerModels: gmd_vdc = 44.26301987818914
    end
end






