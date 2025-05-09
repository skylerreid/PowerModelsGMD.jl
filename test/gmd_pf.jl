@testset "TEST GMD Power Flow" begin


    @testset "EPRI21 case" begin

        case_epri21                   = _PM.parse_file(data_epri21)
        case_epri21_verification_data = CSV.File(data_epri21_verification, header=2)
        epri21_vm                     = CSV.File(data_epri21_vm, header=2)

        # Lock in voltage magnitudes to be what the powerworld verification data suggests
        # for row in epri21_vm
        #     i = row.Number
        #     vm = row.Vpu

        #     case_epri21["bus"]["$i"]["vm"]   = vm

        #     if i == 2 
        #         case_epri21["bus"]["$i"]["vmin"] = vm - 0.03
        #         case_epri21["bus"]["$i"]["vmax"] = vm + 0.03
        #     end
        # end

        local_setting = Dict{String,Any}("bound_voltage" => true)
        merge!(local_setting, setting)
        result = _PMGMD.solve_gmd_pf(case_epri21,  _PM.ACPPowerModel, ipopt_solver; setting=local_setting)
        @test result["termination_status"] == _PM.LOCALLY_SOLVED

        baseMVA = case_epri21["baseMVA"]

        for (b, bus) in case_epri21["bus"]
            println(b, " ", result["solution"]["bus"][b]["vm"])
        end

        for row in case_epri21_verification_data
            i = row[:BusNum3W]
            j = row[Symbol("BusNum3W:1")]
            k = row[:LineCircuit]
            i_eff = row[:GICXFIEffective1]
            qloss = row[:GICQLosses]

            found = false
            # Line circuit number doesn't get tracked in PowerModels... so, a bit of a hack here
            # There are a lot of equivelent solutions in the voltage magnitude space, which impact the qloss term.  So, we have a looser tolerance there
            for (b, branch) in case_epri21["branch"]
                if branch["fbus"] == i && branch["tbus"] == j && k == parse(Int64,branch["branch_sid"])
                    # there are discpreancies here
                    @test isapprox(result["solution"]["branch"][b]["gmd_idc_mag"], i_eff*3.0, atol=0.5)
                    @test isapprox(_PMGMD.calc_dc_current_mag(branch, case_epri21,result["solution"]), i_eff*3.0, atol=0.5) # test if ieffecitive calculations are same as the constraint
                    @test isapprox(result["solution"]["branch"][b]["gmd_qloss"] * baseMVA, qloss, atol=0.3)
                    found = true
                    break
                end
            end

            @test found == true
        end
    end

    @testset "B4GIC case" begin

        case_b4gic                   = _PM.parse_file(data_b4gic)
        case_b4gic_verification_data = CSV.File(data_b4gic_verification, header=2)
        b4gic_vm                     = CSV.File(data_b4gic_vm, header=2)

        # Lock in voltage magnitudes to be what the powerworld verification data suggests
        # for row in b4gic_vm
        #     i = row[:Number]
        #     vm = row[:Vpu]

        #     if (i == 1 || i == 2)
        #         case_b4gic["bus"]["$i"]["vmin"] = vm - 0.0001
        #         case_b4gic["bus"]["$i"]["vmax"] = vm + 0.0001
        #         case_b4gic["bus"]["$i"]["vm"]   = vm
        #     end
        # end

        local_setting = Dict{String,Any}("bound_voltage" => true)
        merge!(local_setting, setting)
        result = _PMGMD.solve_gmd_pf(case_b4gic, _PM.ACPPowerModel, ipopt_solver; setting=local_setting)
        @test result["termination_status"] == _PM.LOCALLY_SOLVED

        baseMVA = case_b4gic["baseMVA"]
        for row in case_b4gic_verification_data
            i = row[:BusNum3W]
            j = row[Symbol("BusNum3W:1")]
            k = row[:LineCircuit]
            i_eff = row[:GICXFIEffective1]
            qloss = row[:GICQLosses]

            found = false
            # Line circuit number doesn't get tracked in PowerModels... so, a bit of a hack here
            # There are a lot of equivelent solutions in the voltage magnitude space, which impact the qloss term.  So, we have a looser tolerance there
            for (b, branch) in case_b4gic["branch"]
                if branch["fbus"] == i && branch["tbus"] == j && k == parse(Int64,branch["branch_sid"])
                    @test isapprox(result["solution"]["branch"][b]["gmd_idc_mag"], i_eff*3.0, atol=0.5)
                    @test isapprox(_PMGMD.calc_dc_current_mag(branch, case_b4gic,result["solution"]), i_eff*3.0, atol=0.5) # test if ieffecitive calculations are same as the constraint
                    @test isapprox(result["solution"]["branch"][b]["gmd_qloss"] * baseMVA, qloss, atol=0.3)
                    found = true
                    break
                end
            end
            @test found == true
        end
    end


    @testset "B4GIC case decoupled" begin

        case_b4gic                   = _PM.parse_file(data_b4gic)
        case_b4gic_verification_data = CSV.File(data_b4gic_verification, header=2)
        b4gic_vm                     = CSV.File(data_b4gic_vm, header=2)

        # Lock in voltage magnitudes to be what the powerworld verification data suggests
        # for row in b4gic_vm
        #     i = row[:Number]
        #     vm = row[:Vpu]
        #     if (i == 1 || i == 2)
        #         case_b4gic["bus"]["$i"]["vmin"] = vm - 0.0001
        #         case_b4gic["bus"]["$i"]["vmax"] = vm + 0.0001
        #         case_b4gic["bus"]["$i"]["vm"]   = vm
        #     end
        # end



        local_setting = Dict{String,Any}("bound_voltage" => true)
        merge!(local_setting, setting)
        result = _PMGMD.solve_ac_gmd_pf_decoupled(case_b4gic, ipopt_solver; setting=local_setting)

        @test result["termination_status"] == _PM.LOCALLY_SOLVED

        baseMVA                      =  case_b4gic["baseMVA"]
        for row in case_b4gic_verification_data
            i = row[:BusNum3W]
            j = row[Symbol("BusNum3W:1")]
            k = row[:LineCircuit]
            i_eff = row[:GICXFIEffective1]
            qloss = row[:GICQLosses]

            found = false
            # Line circuit number doesn't get tracked in PowerModels... so, a bit of a hack here
            # There are a lot of equivelent solutions in the voltage magnitude space, which impact the qloss term.  So, we have a looser tolerance there
            for (b, branch) in case_b4gic["branch"]
                if branch["fbus"] == i && branch["tbus"] == j && k == parse(Int64,branch["branch_sid"])
                    @test isapprox(result["solution"]["branch"][b]["gmd_idc_mag"], i_eff*3.0, atol=0.5)
                    @test isapprox(result["solution"]["branch"][b]["gmd_qloss"] * baseMVA, qloss, atol=0.3)
                    found = true
                    break
                end
            end
            @test found == true
        end
    end


    @testset "EPRI 21 case decoupled" begin

        case_epri21                   = _PM.parse_file(data_epri21)
        case_epri21_verification_data = CSV.File(data_epri21_verification, header=2)
        epri21_vm                     = CSV.File(data_epri21_vm, header=2)

        # Lock in voltage magnitudes to be what the powerworld verification data suggests
        # for row in epri21_vm
        #     i = row[:Number]
        #     vm = row[:Vpu]

        #     case_epri21["bus"]["$i"]["vm"]   = vm

        #     if (i == 2)
        #         case_epri21["bus"]["$i"]["vmin"] = vm - 0.03
        #         case_epri21["bus"]["$i"]["vmax"] = vm + 0.03
        #     end
        # end

        local_setting = Dict{String,Any}("bound_voltage" => true)
        merge!(local_setting, setting)

        result = _PMGMD.solve_ac_gmd_pf_decoupled(case_epri21, ipopt_solver; setting=setting)
        @test result["termination_status"] == _PM.LOCALLY_SOLVED

        baseMVA = case_epri21["baseMVA"]
        for row in case_epri21_verification_data
            i = row[:BusNum3W]
            j = row[Symbol("BusNum3W:1")]
            k = row[:LineCircuit]
            i_eff = row[:GICXFIEffective1]
            qloss = row[:GICQLosses]

            found = false
            # Line circuit number doesn't get tracked in PowerModels... so, a bit of a hack here
            # There are a lot of equivelent solutions in the voltage magnitude space, which impact the qloss term.  So, we have a looser tolerance there
            for (b, branch) in case_epri21["branch"]
                if branch["fbus"] == i && branch["tbus"] == j && k == parse(Int64,branch["branch_sid"])
                    @test isapprox(result["solution"]["branch"][b]["gmd_idc_mag"], i_eff*3.0, atol=0.5)
                    @test isapprox(result["solution"]["branch"][b]["gmd_qloss"] * baseMVA, qloss, atol=0.3)
                    found = true
                    break
                end
            end
            @test found == true
        end
    end



end
