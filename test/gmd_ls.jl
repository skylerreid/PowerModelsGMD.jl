@testset "Test AC GMD Minimum-Load-Shed" begin

    # -- Case-24 IEEE RTS-0 -- #
    # CASE24 IEEE RTS-0 - 57-bus case

    @testset "CASE24-IEEE-RTS-0 case" begin

        casename = "../test/data/case24_ieee_rts_0.m"
        case = PowerModels.parse_file(casename)
        result = run_ac_gmd_ls(casename, ipopt_optimizer)

        @test result["termination_status"] == PowerModels.LOCALLY_SOLVED || result["termination_status"] == PowerModels.OPTIMAL
        println("Testing objective $(result["objective"]) within tolerance for $casename")
        @test isapprox(result["objective"], 167153.8; atol = 1e+6)
    
    end


    # -- OTS-TEST case -- #
    # OTS case - EPRI21 21-bus case

    @testset "OTS-TEST case" begin

        casename = "../test/data/ots_test.m"
        case = PowerModels.parse_file(casename)
        result = run_ac_gmd_ls(casename, ipopt_optimizer)

        @test result["termination_status"] == PowerModels.LOCALLY_SOLVED || result["termination_status"] == PowerModels.OPTIMAL
        println("Testing objective $(result["objective"]) within tolerance for $casename")
        @test isapprox(result["objective"], 2.2694747340471516e6; atol = 1e7)

    end

end





@testset "Test QC GMD Minimum-Load-Shed" begin

    # -- Case-24 IEEE RTS-0 -- #
    # CASE24 IEEE RTS-0 - 57-bus case

    @testset "CASE24-IEEE-RTS-0 case" begin

        casename = "../test/data/case24_ieee_rts_0.m"
        case = PowerModels.parse_file(casename)
        result = run_qc_gmd_ls(casename, ipopt_optimizer)

        @test result["termination_status"] == PowerModels.LOCALLY_SOLVED || result["termination_status"] == PowerModels.OPTIMAL
        println("Testing objective $(result["objective"]) within tolerance for $casename")
        @test isapprox(result["objective"], 159820.9; atol = 1e+6)

    end


    # -- OTS-TEST case -- #
    # OTS Test case - EPRI21 21-bus case

    @testset "OTS-TEST case" begin

        casename = "../test/data/ots_test.m"
        case = PowerModels.parse_file(casename)
        result = run_qc_gmd_ls(casename, ipopt_optimizer)
    
        @test result["termination_status"] == PowerModels.LOCALLY_SOLVED || result["termination_status"] == PowerModels.OPTIMAL
        println("Testing objective $(result["objective"]) within tolerance for $casename")
        @test isapprox(result["objective"], 2.0648604728100917e6; atol = 1e7)

    end

end


