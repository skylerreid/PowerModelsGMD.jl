# Tests for data conversion from PSS(R)E to PowerModels data structure
# TODO: add tests to compare extended MatPower & RAW/GIC results

TESTLOG = Memento.getlogger(PowerModels)

# TODO: Rename this to PSSE? Or leave psse.jl unit tests for comparison against MatPower cases?
# Compare coupled voltages for both csv & coupling code
# Compare GMD solve results against PW - put this in PSSE.jl?

function create_bus_voltage_map(net, result)
    component_map = Dict()
    gmd_bus_solution = result["solution"]["gmd_bus"]

    for (key, component) in net["gmd_bus"]
        source_id = component["source_id"]
        component_map[source_id] = gmd_bus_solution[key]["gmd_vdc"]
    end

    return component_map
end


function create_branch_voltage_map(net)
    branch_map = Dict()

    for (key, branch) in net["gmd_branch"]
        source_id = branch["source_id"]

        if source_id[1] != "branch"
            continue
        end

        if length(source_id[4]) == 1
            source_id[4] = source_id[4] * " "
        end

        branch_map[source_id[2:end]] = branch["br_v"]
    end

    return branch_map
end

const voltage_err = 0.01
const voltage_err_hi = 1.0


@testset "Test RAW/GIC Format" begin
    @testset "Bus4 file" begin
        gic_file = "../test/data/gic/bus4.gic"
        raw_file = "../test/data/pti/bus4.raw"
        csv_file = "../test/data/pw_csv/lines/bus4_1v_km.csv"

        @testset "Solve GIC Flow" begin
            result = PowerModelsGMD.solve_gmd(raw_file, gic_file, csv_file)
            @test isapprox(result["solution"]["gmd_bus"]["1"]["gmd_vdc"], -21.338785; atol = voltage_err)
            @test isapprox(result["solution"]["gmd_bus"]["2"]["gmd_vdc"],  21.338785; atol = voltage_err)
            @test isapprox(result["solution"]["gmd_bus"]["3"]["gmd_vdc"], -32.008137; atol = voltage_err)
            @test isapprox(result["solution"]["gmd_bus"]["4"]["gmd_vdc"],  32.008137; atol = voltage_err)
            @test isapprox(result["solution"]["gmd_bus"]["5"]["gmd_vdc"], -21.338785; atol = voltage_err)
            @test isapprox(result["solution"]["gmd_bus"]["6"]["gmd_vdc"],  21.338785; atol = voltage_err)
        end
    end

    @testset "EPRI20 file" begin
        gic_file = "../test/data/gic/epri.gic"
        raw_file = "../test/data/pti/epri.raw"
        csv_file = "../test/data/pw_csv/lines/epri_1v_km.csv"

        @testset "Load coupled voltages from CSV" begin
            # TODO: Do I need to specify package name here?
            data = PowerModelsGMD.generate_dc_data(gic_file, raw_file, csv_file)
            result = PowerModelsGMD.solve_gmd(data)
            bus_voltage_map = create_bus_voltage_map(data, result)
            # Pick some different cases: 
            # first/last branch, highest/lowest voltage, middle branch
            # branch with zero voltage, 2 parallel transmission lines
            @test isapprox(bus_voltage_map[["bus", 1]], -41.817505; atol = voltage_err_hi)
            @test isapprox(bus_voltage_map[["bus", 21]], -12.543691; atol = voltage_err_hi)
            @test isapprox(bus_voltage_map[["bus", 12]], 21.668301; atol = voltage_err_hi)
            @test isapprox(bus_voltage_map[["bus", 4]], -107.737228; atol = voltage_err_hi)
            @test isapprox(bus_voltage_map[["bus", 6]], 52.523746; atol = voltage_err_hi)

            @test length(keys(result["solution"]["gmd_bus"])) == 27
            f = k -> result["solution"]["gmd_bus"][k]["gmd_vdc"]
            v = [f(k) for (k,x) in data["gmd_bus"] if x["parent_type"] == "bus"]
            @test length(v) == 19

            @test isapprox(calc_mean(v), -12.666903; atol = 0.5)
            @test isapprox(calc_std(v), 43.423599; atol = 0.5)

            @test isapprox(calc_mean(abs.(v)), 33.805089; atol = 0.5)
            @test isapprox(calc_std(abs.(v)), 29.132478; atol = 0.5)

            v = [f(k) for (k,x) in data["gmd_bus"] if x["parent_type"] == "sub"]
            @test length(v) == 8

            @test isapprox(calc_mean(v), -16.844325; atol = 0.5)
            @test isapprox(calc_std(v), 44.028149; atol = 0.5)
        end

#        @testset "Run coupling" begin
#            data = PowerModelsGMD.generate_dc_data(gic_file, raw_file)
#            branch_voltage_map = create_branch_voltage_map(data)
#            @test isapprox(branch_voltage_map[[2, 3, "1 "]], 120.603544; atol = voltage_err)
#            @test isapprox(branch_voltage_map[[17, 20, "1 "]], 158.178009; atol = voltage_err)
#            @test isapprox(branch_voltage_map[[5, 6, "1 "]], 190.986511; atol = voltage_err)
#            @test isapprox(branch_voltage_map[[16, 17, "1 "]], -155.555679; atol = voltage_err)
#            @test isapprox(branch_voltage_map[[4, 6, "1 "]], 321.261292; atol = voltage_err)
#            @test isapprox(branch_voltage_map[[5, 21, "1 "]], 0.0; atol = voltage_err)
#            @test isapprox(branch_voltage_map[[15, 6, "1 "]], 191.110397; atol = voltage_err)
#            @test isapprox(branch_voltage_map[[15, 6, "2 "]], 191.110397; atol = voltage_err)      
#        end        
    end    
end

#         @testset "AC Model (parse_psse)" begin
#             data_pti = PowerModels.parse_psse("../test/data/pti/frankenstein_00.raw")
#             data_mp = PowerModels.parse_file("../test/data/matpower/frankenstein_00.m")

#             set_costs!(data_mp)

#             result_pti = PowerModels.solve_opf(data_pti, PowerModels.ACPPowerModel, nlp_solver)
#             result_mp  = PowerModels.solve_opf(data_mp, PowerModels.ACPPowerModel, nlp_solver)

#             @test result_pti["termination_status"] == LOCALLY_SOLVED
#             @test result_mp["termination_status"] == LOCALLY_SOLVED
#             @test isapprox(result_mp["objective"], result_pti["objective"]; atol = 1e-5)
#         end

#         @testset "AC Model (parse_psse; iostream)" begin
#             filename = "../test/data/pti/frankenstein_00.raw"
#             open(filename) do f
#                 data_pti = PowerModels.parse_psse(f)
#                 data_mp = PowerModels.parse_file("../test/data/matpower/frankenstein_00.m")

#                 set_costs!(data_mp)

#                 result_pti = PowerModels.solve_opf(data_pti, PowerModels.ACPPowerModel, nlp_solver)
#                 result_mp  = PowerModels.solve_opf(data_mp, PowerModels.ACPPowerModel, nlp_solver)

#                 @test result_pti["termination_status"] == LOCALLY_SOLVED
#                 @test result_mp["termination_status"] == LOCALLY_SOLVED
#                 @test isapprox(result_mp["objective"], result_pti["objective"]; atol = 1e-5)
#             end
#         end

#         @testset "with two-winding transformer unit conversions" begin
#             data_pti = PowerModels.parse_file("../test/data/pti/frankenstein_00_2.raw")

#             for (k, v) in data_pti["branch"]
#                 if v["transformer"]
#                     @test isapprox(v["br_r"], 0.; atol=1e-2)
#                     @test isapprox(v["br_x"], 0.179; atol=1e-2)
#                     @test isapprox(v["tap"], 1.019; atol=1e-2)
#                     @test isapprox(v["shift"], 0.; atol=1e-2)
#                     @test isapprox(v["rate_a"], 0.84; atol=1e-2)
#                     @test isapprox(v["rate_b"], 0.84; atol=1e-2)
#                     @test isapprox(v["rate_c"], 0.84; atol=1e-2)
#                 end
#             end

#             result_opf = PowerModels.solve_opf(data_pti, PowerModels.ACPPowerModel, nlp_solver)

#             @test result_opf["termination_status"] == LOCALLY_SOLVED
#             @test isapprox(result_opf["objective"], 29.4043; atol=1e-4)

#             result_pf = PowerModels.solve_pf(data_pti, PowerModels.ACPPowerModel, nlp_solver)

#             for (bus, vm, va) in zip(["1002", "1005", "1008", "1009"],
#                                      [1.0032721, 1.0199983, 1.0203627, 1.03],
#                                      [2.946182, 0.129922, -0.002062, 0.])
#                 @test isapprox(result_pf["solution"]["bus"][bus]["vm"], vm; atol=1e-1)
#                 @test isapprox(result_pf["solution"]["bus"][bus]["va"], deg2rad(va); atol=1e-2)
#             end
#         end
#     end

#     @testset "3-bus case file" begin
#         @testset "AC Model" begin
#             data_pti = PowerModels.parse_file("../test/data/pti/case3.raw")
#             data_mp = PowerModels.parse_file("../test/data/matpower/case3.m")

#             set_costs!(data_mp)

#             result_pti = PowerModels.solve_opf(data_pti, PowerModels.ACPPowerModel, nlp_solver)
#             result_mp  = PowerModels.solve_opf(data_mp, PowerModels.ACPPowerModel, nlp_solver)

#             @test result_pti["termination_status"] == LOCALLY_SOLVED
#             @test result_mp["termination_status"] == LOCALLY_SOLVED

#             # TODO: Needs approximation of DCLINES
#             @test isapprox(result_pti["objective"], result_mp["objective"]; atol=10)
#         end
#     end

#     @testset "5-bus case file" begin
#         @testset "AC Model" begin
#             data_pti = PowerModels.parse_file("../test/data/pti/case5.raw")
#             data_mp = PowerModels.parse_file("../test/data/matpower/case5.m")

#             set_costs!(data_mp)

#             result_pti = PowerModels.solve_opf(data_pti, PowerModels.ACPPowerModel, nlp_solver)
#             result_mp  = PowerModels.solve_opf(data_mp, PowerModels.ACPPowerModel, nlp_solver)

#             @test result_pti["termination_status"] == LOCALLY_SOLVED
#             @test result_mp["termination_status"] == LOCALLY_SOLVED

#             @test isapprox(result_pti["objective"], result_mp["objective"]; atol=1e-5)
#         end
#     end

#     @testset "7-bus topology case file" begin
#         @testset "AC Model" begin
#             data_pti = PowerModels.parse_file("../test/data/pti/case7_tplgy.raw")
#             data_mp  = PowerModels.parse_file("../test/data/matpower/case7_tplgy.m")

#             PowerModels.simplify_network!(data_pti)
#             PowerModels.simplify_network!(data_mp)

#             set_costs!(data_mp)

#             result_pti = PowerModels.solve_opf(data_pti, PowerModels.ACPPowerModel, nlp_solver)
#             result_mp  = PowerModels.solve_opf(data_mp, PowerModels.ACPPowerModel, nlp_solver)

#             @test result_pti["termination_status"] == LOCALLY_SOLVED
#             @test result_mp["termination_status"] == LOCALLY_SOLVED

#             # TODO: Needs approximation of DCLINES
#             @test isapprox(result_mp["objective"], result_pti["objective"]; atol=20)
#         end
#     end

#     @testset "14-bus case file" begin
#         @testset "AC Model" begin
#             data_pti = PowerModels.parse_file("../test/data/pti/case14.raw")
#             data_mp = PowerModels.parse_file("../test/data/matpower/case14.m")

#             set_costs!(data_mp)

#             result_pti = PowerModels.solve_opf(data_pti, PowerModels.ACPPowerModel, nlp_solver)
#             result_mp  = PowerModels.solve_opf(data_mp, PowerModels.ACPPowerModel, nlp_solver)

#             @test result_pti["termination_status"] == LOCALLY_SOLVED
#             @test result_mp["termination_status"] == LOCALLY_SOLVED

#             @test isapprox(result_pti["objective"], result_mp["objective"]; atol=1e-2)
#         end
#     end

#     @testset "24-bus case file" begin
#         @testset "AC Model" begin
#             data_pti = PowerModels.parse_file("../test/data/pti/case24.raw")
#             data_mp = PowerModels.parse_file("../test/data/matpower/case24.m")

#             set_costs!(data_mp)

#             result_pti = PowerModels.solve_opf(data_pti, PowerModels.ACPPowerModel, nlp_solver)
#             result_mp  = PowerModels.solve_opf(data_mp, PowerModels.ACPPowerModel, nlp_solver)

#             @test result_pti["termination_status"] == LOCALLY_SOLVED
#             @test result_mp["termination_status"] == LOCALLY_SOLVED

#             # NOTE: ANGMIN and ANGMAX do not exist in PSS(R)E Spec, accounting for the objective differences
#             @test isapprox(result_pti["objective"], result_mp["objective"]; atol=0.6914)
#         end
#     end

#     @testset "30-bus case file" begin
#         @testset "AC Model" begin
#             data_pti = PowerModels.parse_file("../test/data/pti/case30.raw")
#             data_mp = PowerModels.parse_file("../test/data/matpower/case30.m")

#             set_costs!(data_mp)

#             result_pti = PowerModels.solve_opf(data_pti, PowerModels.ACPPowerModel, nlp_solver)
#             result_mp  = PowerModels.solve_opf(data_mp, PowerModels.ACPPowerModel, nlp_solver)

#             @test result_pti["termination_status"] == LOCALLY_SOLVED
#             @test result_mp["termination_status"] == LOCALLY_SOLVED

#             @test isapprox(result_pti["objective"], result_mp["objective"]; atol=1e-5)
#         end
#     end

#     @testset "exception handling" begin
#         dummy_data = PowerModels.parse_file("../test/data/pti/frankenstein_70.raw")

#         @test dummy_data["gen"]["1"]["source_id"] == ["generator", 1001, "1 "]

#         Memento.setlevel!(TESTLOG, "warn")

#         @test_warn(TESTLOG, "Could not find bus 1, returning 0 for field vm",
#                    PowerModels._get_bus_value(1, "vm", dummy_data))

#         @test_warn(TESTLOG, "The following fields in BUS are missing: NVHI, NVLO, EVHI, EVLO",
#                    PowerModels.parse_file("../test/data/pti/parser_test_i.raw"))

#         Memento.setlevel!(TESTLOG, "error")
#     end

#     @testset "three-winding transformer" begin
#         @testset "without unit conversion" begin
#             data_pti = PowerModels.parse_file("../test/data/pti/three_winding_test.raw")

#             branch_data = zip(
#                 ["4", "5", "6"],
#                 [0.00225, 0.00225, -0.00155],
#                 [0.05, 0.15, 0.15],
#                 [1.1, 1.0, 1.0],
#                 [0.0, 0.0, 0.0],
#                 [2.0, 1.0, 1.0],
#                 [2.0, 1.0, 1.0],
#                 [4.0, 1.0, 1.0]
#             )

#             for (branch, br_r, br_x, tap, shift, rate_a, rate_b, rate_c) in branch_data
#                 @test isapprox(data_pti["branch"][branch]["br_r"], br_r; atol=1e-4)
#                 @test isapprox(data_pti["branch"][branch]["br_x"], br_x; atol=1e-4)
#                 @test isapprox(data_pti["branch"][branch]["tap"], tap; atol=1e-4)
#                 @test isapprox(data_pti["branch"][branch]["shift"], shift; atol=1e-4)
#                 @test isapprox(data_pti["branch"][branch]["rate_a"], rate_a; atol=1e-4)
#                 @test isapprox(data_pti["branch"][branch]["rate_b"], rate_b; atol=1e-4)
#                 @test isapprox(data_pti["branch"][branch]["rate_c"], rate_c; atol=1e-4)
#             end

#             bus_data = zip(
#                 ["10001", "10002", "10003", "10004", "10005"],
#                 [4, 1, 1, 1, 1]
#             )

#             for (bus, bus_type) in bus_data
#                 @test isapprox(data_pti["bus"][bus]["bus_type"], bus_type; atol=1e-8)
#             end

#             @test length(data_pti["bus"]) == 8
#             @test length(data_pti["branch"]) == 15

#             result_opf = PowerModels.solve_opf(data_pti, PowerModels.ACPPowerModel, nlp_solver)

#             @test result_opf["termination_status"] == LOCALLY_SOLVED
#             @test isapprox(result_opf["objective"], 10.00027; atol=1e-5)

#             result_pf = PowerModels.solve_pf(data_pti, PowerModels.ACPPowerModel, nlp_solver)

#             bus_data = zip(
#                 ["1001", "1002", "1003", "10002", "10003", "10004"],
#                 [1.0980, 1.000, 1.0000, 0.9990, 0.9990, 0.999],
#                 [0.0135, 0.000, 0.0382, 0.0157, 0.0197, 0.018]
#             )

#             for (bus, vm, va) in bus_data
#                 @test isapprox(result_pf["solution"]["bus"][bus]["vm"], vm; atol=1e-1)
#                 @test isapprox(result_pf["solution"]["bus"][bus]["va"], va; atol=1e-2)
#             end
#         end

#         @testset "with unit conversion" begin
#             data_pti = PowerModels.parse_file("../test/data/pti/three_winding_test_2.raw")

#             branch_data = zip(
#                 ["1", "2", "3"],
#                 [0.0, 0.0, 0.0],
#                 [0.05, 0.15, 0.15],
#                 [1.1, 1.0, 1.0],
#                 [0.0, 0.0, 0.0],
#                 [2.0, 1.0, 1.0],
#                 [2.0, 1.0, 1.0],
#                 [4.0, 1.0, 1.0]
#             )

#             for (branch, br_r, br_x, tap, shift, rate_a, rate_b, rate_c) in branch_data
#                 @test isapprox(data_pti["branch"][branch]["br_r"], br_r; atol=1e-4)
#                 @test isapprox(data_pti["branch"][branch]["br_x"], br_x; atol=1e-4)
#                 @test isapprox(data_pti["branch"][branch]["tap"], tap; atol=1e-4)
#                 @test isapprox(data_pti["branch"][branch]["shift"], shift; atol=1e-4)
#                 @test isapprox(data_pti["branch"][branch]["rate_a"], rate_a; atol=1e-4)
#                 @test isapprox(data_pti["branch"][branch]["rate_b"], rate_b; atol=1e-4)
#                 @test isapprox(data_pti["branch"][branch]["rate_c"], rate_c; atol=1e-4)
#             end


#             result_opf = PowerModels.solve_opf(data_pti, PowerModels.ACPPowerModel, nlp_solver)

#             @test result_opf["termination_status"] == LOCALLY_SOLVED
#             @test isapprox(result_opf["objective"], 10.0; atol=1e-5)

#             result_pf = PowerModels.solve_pf(data_pti, PowerModels.ACPPowerModel, nlp_solver)

#             for (bus, vm, va) in zip(["1001", "1002", "1003", "10001"], [1.09, 1.0, 1.0, 0.997], [2.304, 0., 6.042244, 2.5901])
#                 @test isapprox(result_pf["solution"]["bus"][bus]["vm"], vm; atol=1e-1)
#                 @test isapprox(result_pf["solution"]["bus"][bus]["va"], deg2rad(va); atol=1e-2)
#             end

#         end


#         @testset "with nomV=0 cw=2" begin
#             data = PowerModels.parse_file("../test/data/pti/case4_3wtf_vnom0_cw2.raw")
    
#             opf = PowerModels.solve_opf(data, PowerModels.ACPPowerModel, nlp_solver)
#             @test opf["termination_status"] == LOCALLY_SOLVED
#             @test isapprox(opf["objective"], 5.00079; atol=1e-3)
#         end

#         @testset "with nomV=0 cw=3" begin
#             data = PowerModels.parse_file("../test/data/pti/case4_3wtf_vnom0_cw3.raw")
    
#             opf = PowerModels.solve_opf(data, PowerModels.ACPPowerModel, nlp_solver)
#             @test opf["termination_status"] == LOCALLY_SOLVED
#             @test isapprox(opf["objective"], 5.00079; atol=1e-3)
#         end

#         @testset "2-windning transformer with nomV=0 cw=3" begin
#             data = PowerModels.parse_file("../test/data/pti/case3_2wtf_vmon0.raw")
    
#             opf = PowerModels.solve_opf(data, PowerModels.ACPPowerModel, nlp_solver)
#             @test opf["termination_status"] == LOCALLY_SOLVED
#             @test isapprox(opf["objective"], 17.5101; atol=1e-3)
#         end
        
#     end

#     @testset "transformer magnetizing admittance" begin
#         @testset "two-winding transformer" begin
#             data_pti = PowerModels.parse_file("../test/data/pti/two_winding_mag_test.raw")

#             @test length(data_pti["branch"]) == 1

#             @test isapprox(data_pti["branch"]["1"]["g_fr"], 5e-3; atol=1e-4)
#             @test isapprox(data_pti["branch"]["1"]["b_fr"], 6.74e-3; atol=1e-4)

#             result_opf = PowerModels.solve_opf(data_pti, PowerModels.ACPPowerModel, nlp_solver)

#             @test result_opf["termination_status"] == LOCALLY_SOLVED
#             @test isapprox(result_opf["objective"], 701.637157; atol=1e-5)

#             result_pf = PowerModels.solve_pf(data_pti, PowerModels.ACPPowerModel, nlp_solver)

#             @test result_pf["termination_status"] == LOCALLY_SOLVED
#             @test result_pf["objective"] == 0.0

#             for (bus, vm, va) in zip(["1", "2"], [1.0932940, 1.06414], [0.928781, 0.])
#                 @test isapprox(result_pf["solution"]["bus"][bus]["vm"], vm; atol=1e-1)
#                 @test isapprox(result_pf["solution"]["bus"][bus]["va"], deg2rad(va); atol=1e-2)
#             end
#         end

#         @testset "three-winding transformer" begin
#             data_pti = PowerModels.parse_file("../test/data/pti/three_winding_mag_test.raw")

#             @test length(data_pti["branch"]) == 3

#             @test isapprox(data_pti["branch"]["1"]["g_fr"], 5e-3; atol=1e-4)
#             @test isapprox(data_pti["branch"]["1"]["b_fr"], 6.74e-3; atol=1e-4)

#             result_opf = PowerModels.solve_opf(data_pti, PowerModels.ACPPowerModel, nlp_solver)

#             @test result_opf["termination_status"] == LOCALLY_SOLVED
#             @test isapprox(result_opf["objective"], 10.4001; atol=1e-2)

#             result_pf = PowerModels.solve_pf(data_pti, PowerModels.ACPPowerModel, nlp_solver)

#             @test result_pf["termination_status"] == LOCALLY_SOLVED
#             @test result_pf["objective"] == 0.0

#             for (bus, vm, va) in zip(["1001", "1002", "1003", "10001"], [1.0965262, 1.0, 0.9999540, 0.9978417], [2.234718, 0., 5.985760, 2.538179])
#                 @test isapprox(result_pf["solution"]["bus"][bus]["vm"], vm; atol=1e-1)
#                 @test isapprox(result_pf["solution"]["bus"][bus]["va"], deg2rad(va); atol=1e-2)
#             end
#         end
#     end


#     @testset "transformer status" begin
#         @testset "two-winding transformers" begin
#             data_pti = PowerModels.parse_file("../test/data/pti/case5.raw")

#             br_off = Set(["8", "9"])
#             for (i,branch) in data_pti["branch"]
#                 if i in br_off
#                     @test branch["br_status"] == 0
#                 else
#                     @test branch["br_status"] == 1
#                 end
#             end
#         end

#         @testset "three-winding transformers" begin
#             data_pti = PowerModels.parse_file("../test/data/pti/three_winding_test.raw")

#             br_off = Set(["1", "2", "3", "8", "12", "13"])
#             for (i,branch) in data_pti["branch"]
#                 if i in br_off
#                     @test branch["br_status"] == 0
#                 else
#                     @test branch["br_status"] == 1
#                 end
#             end
#         end
#     end


#     @testset "import all" begin
#         @testset "30-bus case" begin
#             data = PowerModels.parse_file("../test/data/pti/case30.raw"; import_all=true)

#             for (key, n) in zip(["bus", "load", "shunt", "gen", "branch"], [15, 15, 28, 34, 29])
#                 for item in values(data[key])
#                     if key == "branch" && item["transformer"]
#                         @test length(item) == 47
#                     else
#                         @test length(item) == n
#                     end
#                 end
#             end

#             result = PowerModels.solve_opf(data, PowerModels.ACPPowerModel, nlp_solver)

#             @test result["termination_status"] == LOCALLY_SOLVED
#             @test isapprox(result["objective"], 297.878089; atol=1e-4)
#         end

#         @testset "frankenstein 70" begin
#             data = PowerModels.parse_file("../test/data/pti/frankenstein_70.raw"; import_all=true)

#             extras = ["zone", "facts control device", "owner", "area interchange", "impedance correction", "multi-terminal dc"]
#             for k in extras
#                 @test k in keys(data)
#             end
#         end

#         @testset "impedance correction keys" begin
#             data = PowerModels.parse_file("../test/data/pti/frankenstein_70.raw"; import_all=true)

#             for (i,icd) in data["impedance correction"]
#                 for i in 1:11
#                     t_key = "t$(i)"
#                     f_key = "f$(i)"
#                     if haskey(icd, t_key) || haskey(icd, f_key)
#                         @test haskey(icd, t_key) && haskey(icd, f_key)
#                     end
#                 end
#             end
#         end

#         @testset "arrays in VSC-HVDC" begin
#             data = PowerModels.parse_file("../test/data/pti/vsc-hvdc_test.raw"; import_all=true)

#             @test length(data["dcline"]["1"]) == 36
#             for item in data["dcline"]["1"]["converter buses"]
#                 for k in keys(item)
#                     @test k == lowercase(k)
#                 end
#             end
#         end

#         @testset "three-winding case" begin
#             data = PowerModels.parse_file("../test/data/pti/three_winding_test.raw"; import_all=true)

#             for (key, n) in zip(["bus", "load", "shunt", "gen", "branch"], [15, 15, 28, 34, 29])
#                 for item in values(data[key])
#                     if key == "branch" && item["transformer"]
#                         # 47 = 2 winding, 69 = 3 winding - first winding, 22 = 3 winding - other windings
#                         @test length(item) == 47 || length(item) == 69 || length(item) == 22
#                     elseif key == "bus" && item["source_id"][1] == "transformer"
#                         # star bus info
#                         @test length(item) == 12
#                     else
#                         @test length(item) == n
#                     end
#                 end
#             end

#         end
#     end

#     @testset "dclines" begin
#         @testset "two-terminal" begin
#             data = PowerModels.parse_file("../test/data/pti/two-terminal-hvdc_test.raw")

#             @test length(data["dcline"]) == 1
#             @test length(data["dcline"]["1"]) == 26

#             opf = PowerModels.solve_opf(data, PowerModels.ACPPowerModel, nlp_solver)
#             @test opf["termination_status"] == LOCALLY_SOLVED
#             @test isapprox(opf["objective"], 10.5; atol=1e-3)

#             pf = PowerModels.solve_pf(data, PowerModels.ACPPowerModel, nlp_solver)
#             @test pf["termination_status"] == LOCALLY_SOLVED
#         end

#         @testset "voltage source converter" begin
#             data = PowerModels.parse_file("../test/data/pti/vsc-hvdc_test.raw")

#             @test length(data["dcline"]) == 1
#             @test length(data["dcline"]["1"]) == 26

#             opf = PowerModels.solve_opf(data, PowerModels.ACPPowerModel, nlp_solver)
#             @test opf["termination_status"] == LOCALLY_SOLVED
#             @test isapprox(opf["objective"], 21.8842; atol=1e-3)

#             pf = PowerModels.solve_pf(data, PowerModels.ACPPowerModel, nlp_solver)
#             @test pf["termination_status"] == LOCALLY_SOLVED
#         end
#     end

#     @testset "source_id" begin
#         data = PowerModels.parse_file("../test/data/pti/frankenstein_70.raw")

#         for key in ["bus", "load", "shunt", "gen", "branch"]
#             for v in values(data[key])
#                 @test "source_id" in keys(v)
#                 @test isa(v["source_id"], Array)
#                 @test v["source_id"][1] in ["bus", "load", "fixed shunt", "switched shunt", "branch", "generator", "transformer", "two-terminal dc", "vsc dc"]
#             end
#         end
#     end

#      @testset "Impedance and Current Load Conversions" begin
#         data = PowerModels.parse_file("../test/data/pti//parser_test_k.raw")
#         Vm_load = data["bus"]["103"]["vm"]
#         # Test current load only
#         @test isapprox(data["load"]["2"]["pd"], 250*Vm_load/data["baseMVA"], atol = 1e-6)
#         @test isapprox(data["load"]["2"]["qd"], 30*Vm_load/data["baseMVA"], atol = 1e-6)
#         # Test current impedance load only
#         @test isapprox(data["load"]["3"]["pd"], 250*Vm_load^2/data["baseMVA"], atol = 1e-6)
#         @test isapprox(data["load"]["3"]["qd"], 30*Vm_load^2/data["baseMVA"], atol = 1e-6)
#         # Test mixed load types
#         @test isapprox(data["load"]["4"]["pd"], (250 + 250*Vm_load)/data["baseMVA"], atol = 1e-6)
#         @test isapprox(data["load"]["4"]["qd"], (30 + 30*Vm_load^2)/data["baseMVA"], atol = 1e-6)
#     end
