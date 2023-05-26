@testset "TEST GMD MLD" begin


    @testset "EPRI21 case" begin

        case_epri21 = _PM.parse_file(data_epri21)
        case_epri21_verification_data = CSV.File(data_epri21_verification)

        baseMVA = case_epri21["baseMVA"]

        result = _PMGMD.solve_gmd_pf(case_epri21,  _PM.ACPPowerModel, ipopt_solver; setting=setting)
        @test result["termination_status"] == _PM.LOCALLY_SOLVED

        for row in case_epri21_verification_data
            i = row[:BusNum3W]
            j = row[Symbol("BusNum3W:1")]
            k = row[:LineCircuit]
            i_eff = row[:GICXFIEffective1]
            qloss = row[:GICQLosses]

            found = false
            # Line circuit number doesn't get tracked in PowerModels... so, a bit of a hack here
            # There are a lot of equivelent solutions in the voltage magnitude space, which impact the qloss term.  So, we have a looser tolerance there

            k_prime = 1
            for (b, branch) in case_epri21["branch"]
                if (branch["f_bus"] == i && branch["t_bus"] == j) || (branch["f_bus"] == j && branch["t_bus"] == i)

                    if k == k_prime
                        @test isapprox(result["solution"]["branch"][b]["gmd_idc_mag"], i_eff*3.0, atol=0.5)
                        @test isapprox(result["solution"]["branch"][b]["gmd_qloss"] * baseMVA, qloss, atol=1e-1)
                        found = true
                        println(i, " ", j, " ", k, " ", result["solution"]["branch"][b]["gmd_idc_mag"], " ", i_eff*3.0)
                    end
                    k_prime = k_prime+1
                end
            end
            @test found == true
        end
    end

    @testset "B4GIC case" begin

        case_b4gic                   = _PM.parse_file(data_b4gic)
        case_b4gic_verification_data = CSV.File(data_b4gic_verification)

        baseMVA = case_b4gic["baseMVA"]

        result = _PMGMD.solve_gmd_pf(case_b4gic, _PM.ACPPowerModel, ipopt_solver; setting=setting)
        @test result["termination_status"] == _PM.LOCALLY_SOLVED


        for row in case_b4gic_verification_data
            i = row[:BusNum3W]
            j = row[Symbol("BusNum3W:1")]
            k = row[:LineCircuit]
            i_eff = row[:GICXFIEffective1]
            qloss = row[:GICQLosses]

            found = false
            # Line circuit number doesn't get tracked in PowerModels... so, a bit of a hack here
            # There are a lot of equivelent solutions in the voltage magnitude space, which impact the qloss term.  So, we have a looser tolerance there
            k_prime = 1
            for (b, branch) in case_b4gic["branch"]
                if branch["f_bus"] == i && branch["t_bus"] == j

                    if k == k_prime
                        @test isapprox(result["solution"]["branch"][b]["gmd_idc_mag"], i_eff*3.0, atol=0.5)
                        @test isapprox(result["solution"]["branch"][b]["gmd_qloss"] * baseMVA, qloss, atol=1e-1)
                        found = true
                        continue
                    else
                        k_prime = k_prime+1
                    end

                end
            end
            @test found == true
        end
    end


end
