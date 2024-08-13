using CSV, DataFrames, ExcelFiles, Query, DelimitedFiles, Statistics
using Plots, VegaLite, FileIO, VegaDatasets, FilePaths


# Reading residuals at country level
gravity_17 = CSV.File(joinpath(@__DIR__,"../results/gravity/gravity_17.csv")) |> DataFrame
country_iso3c = CSV.File("../input_data/country_iso3c.csv") |> DataFrame
iso3c_fundregion = CSV.File("../input_data/iso3c_fundregion.csv") |> DataFrame
regions = ["USA", "CAN", "WEU", "JPK", "ANZ", "EEU", "FSU", "MDE", "CAM", "LAM", "SAS", "SEA", "CHI", "MAF", "SSA", "SIS"]
regionsdf = DataFrame(originregion = repeat(regions, inner = length(regions)), indexo = repeat(1:16, inner = length(regions)), destinationregion = repeat(regions, outer = length(regions)), indexd = repeat(1:16, outer = length(regions)))


############################## Calculating residuals from remshare estimation at FUND region level ######################################
############################## Weight exp(residuals) by weights #################################################
data_resweight = gravity_17[:,union(1:6,13)]
data_resweight[!,:gdp_orig] = data_resweight[:,:ypc_orig] .* data_resweight[:,:pop_orig]
data_resweight[!,:gdp_dest] = data_resweight[:,:ypc_dest] .* data_resweight[:,:pop_dest]

data_resweight = innerjoin(data_resweight, migstock[:,3:5], on = [:orig,:dest])

data_resweight = innerjoin(data_resweight, rename(iso3c_fundregion, :iso3c=>:orig,:fundregion=>:originregion),on=:orig)
data_resweight = innerjoin(data_resweight, rename(iso3c_fundregion, :iso3c=>:dest,:fundregion=>:destinationregion),on=:dest)

# Calculate appropriate weights for exp(residuals)
data_resweight_calc = by(data_resweight, [:originregion,:destinationregion], d -> (pop_orig_reg = sum(d.pop_orig),gdp_orig_reg=sum(d.gdp_orig),pop_dest_reg = sum(d.pop_dest),gdp_dest_reg=sum(d.gdp_dest),migstock_reg=sum(d.migrantstocks)))
data_resweight = join(data_resweight, data_resweight_calc, on=[:originregion,:destinationregion])
data_resweight[!,:ypc_mig] = [max((data_resweight[i,:ypc_orig] + data_resweight[i,:ypc_dest])/2,data_resweight[i,:ypc_orig]) for i in 1:size(data_resweight,1)]
data_resweight[!,:ypc_mig_reg] = [max((data_resweight[i,:gdp_orig_reg]/data_resweight[i,:pop_orig_reg] + data_resweight[i,:gdp_dest_reg]/data_resweight[i,:pop_dest_reg])/2,data_resweight[i,:gdp_orig_reg]/data_resweight[i,:pop_orig_reg]) for i in 1:size(data_resweight,1)]
data_resweight[!,:res_weight] = data_resweight[:,:migrantstocks] ./ data_resweight[:,:migstock_reg] .* data_resweight[:,:ypc_mig] ./ data_resweight[:,:ypc_mig_reg]
for i in 1:size(data_resweight,1)
    if data_resweight[i,:migstock_reg] == 0.0
        data_resweight[i,:res_weight] = 0.0
    end
end
# Weight exp(residuals), instead of taking exp of weighted residuals 
data_resweight[!,:exp_res_weighted] = map(x -> exp(x),data_resweight[:,:residual_ratio]) .* data_resweight[:,:res_weight]

# Prepare remshare estimation at FUND region level
data_resweight_fund = by(data_resweight, [:originregion,:destinationregion], d -> sum(d.exp_res_weighted))
rename!(data_resweight_fund, :x1 => :remres)

# Sorting the data
data_resweight_fund = join(data_resweight_fund, regionsdf, on = [:originregion, :destinationregion])
sort!(data_resweight_fund, (:indexo, :indexd))
delete!(data_resweight_fund, [:indexo, :indexd])
CSV.write("../data_mig/remres.csv", data_resweight_fund; writeheader=false)
