# Tests for data conversion from PSS(R)E to PowerModels data structure
# TODO: add tests to compare extended MatPower & RAW/GIC results

TESTLOG = Memento.getlogger(PowerModels)

# TODO: Rename this to PSSE? Or leave psse.jl unit tests for comparison against MatPower cases?
# Compare coupled voltages for both csv & coupling code
# Compare GMD solve results against PW - put this in PSSE.jl?

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

get_branch_voltages = data -> collect(map(x -> x["br_v"], values(data["gmd_branch"])))
calc_mean = x -> sum(x)/length(x)

function calc_std(x)
    n = length(x)
    mu = calc_mean(x)
    return sqrt(sum((x .- mu).^2)/(n - 1))
end

calc_mag_sum = x -> calc_mean(abs.(x))
calc_mag_mean = x -> calc_mag_sum(x)/length(x)
calc_v_mag_std = x -> calc_std(abs.(x))

const voltage_err = 0.01

@testset "Test Coupling" begin
    @testset "Bus4 file" begin
        gic_file = "../test/data/gic/bus4.gic"
        raw_file = "../test/data/pti/bus4.raw"
        csv_file = "../test/data/lines/bus4_1v_km.csv"

        @testset "Load coupled voltages from CSV" begin

            data = PowerModelsGMD.generate_dc_data(gic_file, raw_file, csv_file)
            @test isapprox(data["gmd_branch"]["1"]["br_v"], 170.788589; atol = voltage_err)
        end

        @testset "Run Coupling" begin
            data = PowerModelsGMD.generate_dc_data(gic_file, raw_file)
            @test isapprox(data["gmd_branch"]["1"]["br_v"], 170.788589; atol = voltage_err)
        end        
    end

    @testset "EPRI20 file" begin
        gic_file = "../test/data/gic/epri.gic"
        raw_file = "../test/data/pti/epri.raw"
        csv_file = "../test/data/lines/epri_1v_km.csv"

        @testset "Load coupled voltages from CSV" begin
            data = PowerModelsGMD.generate_dc_data(gic_file, raw_file, csv_file)
            branch_voltage_map = create_branch_voltage_map(data)
            # Pick some different cases: 
            # first/last branch, highest/lowest voltage, middle branch
            # branch with zero voltage, 2 parallel transmission lines
            @test isapprox(branch_voltage_map[[2, 3, "1 "]], 120.603544; atol = voltage_err) # first line
            @test isapprox(branch_voltage_map[[17, 20, "1 "]], 158.178009; atol = voltage_err) # last line
            @test isapprox(branch_voltage_map[[5, 6, "1 "]], 190.986511; atol = voltage_err) # random line
            @test isapprox(branch_voltage_map[[16, 17, "1 "]], -155.555679; atol = voltage_err) # min voltage
            @test isapprox(branch_voltage_map[[4, 6, "1 "]], 321.261292; atol = voltage_err) # max voltage
            @test isapprox(branch_voltage_map[[5, 21, "1 "]], 0.0; atol = voltage_err) # line with zero voltage 
            @test isapprox(branch_voltage_map[[16, 20, "1 "]], 1.489666; atol = voltage_err) # line with smallest absolute nonzero voltage
            @test isapprox(branch_voltage_map[[15, 6, "1 "]], 191.110397; atol = voltage_err) # parallel line
            @test isapprox(branch_voltage_map[[15, 6, "2 "]], 191.110397; atol = voltage_err) # parallel line 

            # we don't have an objective, so check the moments of the coupled voltage (along with the min/max)
            # TODO: use Julia stats package for this
            # TODO: export coupled voltages to more than 2 decimal places
            # TODO: calculate median or other statistics?
            v = [x["br_v"] for x in values(data["gmd_branch"]) if x["source_id"][1] == "branch"]

            # Summary Stats:
            # Length:         16
            # Missing Count:  0
            # Mean:           85.624962
            # Std. Deviation: 135.194889
            # Minimum:        -155.555679
            # 1st Quartile:   -5.034325
            # Median:         131.693298
            # 3rd Quartile:   175.112583
            # Maximum:        321.261292

            @test length(v) ==  16
            mu, std = StatsBase.mean_and_std(v, corrected=true)
            @test isapprox(mu, 85.624962; atol = voltage_err) 
            @test isapprox(std, 135.194889; atol = voltage_err)  
            q = StatsBase.nquantile(v, 4)
            # @test isapprox(q[1], -155.555679; atol = voltage_err) # min, redundant
            @test isapprox(q[2], -5.034325; atol = voltage_err) # 1st quartile 
            @test isapprox(q[3], 131.693298; atol = voltage_err) # median
            @test isapprox(q[4], 175.112583; atol = voltage_err) # 3rd quartile
            # @test isapprox(q[5], 321.261292; atol = voltage_err) # max, redundant

            # Length:         16
            # Missing Count:  0
            # Mean:           135.389907
            # Std. Deviation: 80.904958
            # Minimum:        0.000000
            # 1st Quartile:   113.742239
            # Median:         143.624488
            # 3rd Quartile:   175.112583
            # Maximum:        321.261292

            vm = abs.(v)
            mu_m, std_m = StatsBase.mean_and_std(vm, corrected=true)
            @test isapprox(mu_m, 135.389907; atol = voltage_err) 
            @test isapprox(std_m, 80.904958; atol = voltage_err)  
            qm = StatsBase.nquantile(vm, 4)
            # @test isapprox(qm[1], 0.0; atol = voltage_err) # min
            @test isapprox(qm[2], 113.742239; atol = voltage_err) # 1st quartile 
            @test isapprox(qm[3], 143.624488; atol = voltage_err) # median
            @test isapprox(qm[4], 175.112583; atol = voltage_err) # 3rd quartile
            # @test isapprox(qm[5], 321.261292; atol = voltage_err) # max

            @test length(data["gmd_branch"]) == 58

            v_other = [x["br_v"] for x in values(data["gmd_branch"]) if x["source_id"][1] != "branch"]
            @test isapprox(sum(abs.(v_other)), 0.0; atol = voltage_err)  
        end

        @testset "Run coupling" begin
            data = PowerModelsGMD.generate_dc_data(gic_file, raw_file)
            branch_voltage_map = create_branch_voltage_map(data)
            @test isapprox(branch_voltage_map[[2, 3, "1 "]], 120.603544; atol = voltage_err)
            @test isapprox(branch_voltage_map[[17, 20, "1 "]], 158.178009; atol = voltage_err)
            @test isapprox(branch_voltage_map[[5, 6, "1 "]], 190.986511; atol = voltage_err)
            @test isapprox(branch_voltage_map[[16, 17, "1 "]], -155.555679; atol = voltage_err)
            @test isapprox(branch_voltage_map[[4, 6, "1 "]], 321.261292; atol = voltage_err)
            @test isapprox(branch_voltage_map[[5, 21, "1 "]], 0.0; atol = voltage_err)
            @test isapprox(branch_voltage_map[[15, 6, "1 "]], 191.110397; atol = voltage_err)
            @test isapprox(branch_voltage_map[[15, 6, "2 "]], 191.110397; atol = voltage_err)      
        end        
    end    
end

