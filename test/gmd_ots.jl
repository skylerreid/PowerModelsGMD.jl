@testset "TEST GMD MLS OTS" begin


    @testset "EPRI21 case" begin


        # ===   COUPLED AC-MLS-OTS   === #


        case_epri21 = _PM.parse_file(data_epri21)

        result = _PMGMD.solve_soc_gmd_ots(case_epri21, juniper_solver; setting=setting)
        @test result["termination_status"] == _PM.LOCALLY_SOLVED
        @test isapprox(result["objective"], 0.0000; atol=1e-2)


        case_epri21 = _PM.parse_file(data_epri21)

        result = _PMGMD.solve_qc_gmd_ots(case_epri21, juniper_solver; setting=setting)
        @test result["termination_status"] == _PM.LOCALLY_SOLVED
        @test isapprox(result["objective"], 0.0000; atol=1e-2)


        case_epri21 = _PM.parse_file(data_epri21)

        result = _PMGMD.solve_ac_gmd_ots(case_epri21, juniper_solver; setting=setting)
        @test result["termination_status"] == _PM.LOCALLY_SOLVED
        @test isapprox(result["objective"], 0.0000; atol=1e-2)

        # FIXME: add actual fully automated testing for "Solve_ac_gmd_mls_ots"


        # ===   COUPLED AC-MLS-OTS-TS   === #


        # FIXME: add actual fully automated testing for "Solve_soc_gmd_mls_ots_ts"

        # FIXME: add actual fully automated testing for "Solve_ac_gmd_mls_ots_ts"


    end


    @testset "OTS-TEST case" begin


        # ===   COUPLED AC-MLS-OTS   === #


        case_otstest = _PM.parse_file(data_otstest)

        result = _PMGMD.solve_soc_gmd_ots(case_otstest, juniper_solver; setting=setting)
        @test result["termination_status"] == _PM.LOCALLY_SOLVED
        @test isapprox(result["objective"], 0.0000; atol=1e-2)


        case_otstest = _PM.parse_file(data_otstest)

        result = _PMGMD.solve_qc_gmd_ots(case_otstest, juniper_solver; setting=setting)
        @test result["termination_status"] == _PM.LOCALLY_SOLVED
        @test isapprox(result["objective"], 0.0000; atol=1e-2)


        case_otstest = _PM.parse_file(data_otstest)

        result = _PMGMD.solve_ac_gmd_ots(case_otstest, juniper_solver; setting=setting)
        @test result["termination_status"] == _PM.LOCALLY_SOLVED
        @test isapprox(result["objective"], 0.0000; atol=1e-2)

        # FIXME: add actual fully automated testing for "Solve_ac_gmd_mls_ots"


        # ===   COUPLED AC-MLS-OTS-TS   === #


        # FIXME: add actual fully automated testing for "Solve_soc_gmd_mls_ots_ts"

        # FIXME: add actual fully automated testing for "Solve_ac_gmd_mls_ots_ts"


    end


end
