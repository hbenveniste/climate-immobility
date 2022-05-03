using CSV, DataFrames, DelimitedFiles, ExcelFiles
using Plots, VegaLite, FileIO, VegaDatasets, FilePaths, ImageIO, ImageMagick
using Statistics, Query, Distributions, StatsPlots


regions = ["USA", "CAN", "WEU", "JPK", "ANZ", "EEU", "FSU", "MDE", "CAM", "LAM", "SAS", "SEA", "CHI", "MAF", "SSA", "SIS"]
ssps = ["SSP1","SSP2","SSP3","SSP4","SSP5"]

ssp_edu = CSV.File(joinpath(@__DIR__, "../input_data/ssp_edu.csv")) |> DataFrame
isonum_fundregion = CSV.File("../input_data/isonum_fundregion.csv") |> DataFrame

edu_level_all = sort(ssp_edu, [:period,:region,:edu])
edu_level_all[!,:countrynum] = map(x->parse(Int,SubString(x,3)), edu_level_all[:,:region])
edu_level_all = join(edu_level_all, rename(isonum_fundregion, :isonum=>:countrynum), on = :countrynum)

edu_level_f = by(edu_level_all, [:period, :scen, :edu, :fundregion], d -> (pop = sum(d.pop), outmig = sum(d.outmig), inmig = sum(d.inmig), pop_all = sum(d.pop_all), outmig_all = sum(d.outmig_all), inmig_all = sum(d.inmig_all)))
edu_level_f[!,:pop_share] = edu_level_f[:,:pop] ./ edu_level_f[:,:pop_all]
edu_level_f[!,:outmig_share] = edu_level_f[:,:outmig] ./ edu_level_f[:,:outmig_all]
edu_level_f[!,:inmig_share] = edu_level_f[:,:inmig] ./ edu_level_f[:,:inmig_all]
for i in 1:size(edu_level_f,1)
    if edu_level_f[i,:pop] == 0 && edu_level_f[i,:pop_all] == 0 ; edu_level_f[i,:pop_share] = 0 end
    if edu_level_f[i,:outmig] == 0 && edu_level_f[i,:outmig_all] == 0 ; edu_level_f[i,:outmig_share] = 0 end
    if edu_level_f[i,:inmig] == 0 && edu_level_f[i,:inmig_all] == 0 ; edu_level_f[i,:inmig_share] = 0 end
end
sort!(edu_level_f, [:scen,:period,:fundregion, :edu])


################################################### Calculate income level of migrants #################################################
# We assume that education level is perfectly correlated with income level. We attribute each education level to the corresponding income quintile.
for name in [:q1,:q2,:q3,:q4,:q5]
    edu_level_f[!,name] = zeros(size(edu_level_f,1))
end
for i in 1:size(edu_level_f,1)
    if edu_level_f[i,:edu] == "e1"
        edu_level_f[i,:q1] = min(0.2,edu_level_f[i,:pop_share])
        edu_level_f[i,:q2] = min(0.2,max(edu_level_f[i,:pop_share]-0.2,0.0))
        edu_level_f[i,:q3] = min(0.2,max(edu_level_f[i,:pop_share]-0.4,0.0))
        edu_level_f[i,:q4] = min(0.2,max(edu_level_f[i,:pop_share]-0.6,0.0))
        edu_level_f[i,:q5] = min(0.2,max(edu_level_f[i,:pop_share]-0.8,0.0))
    elseif edu_level_f[i,:edu] == "e2"
        edu_level_f[i,:q1] = min(max(0.0, 0.2 - edu_level_f[i-1,:q1]), edu_level_f[i,:pop_share])
        edu_level_f[i,:q2] = min(0.2 - edu_level_f[i-1,:q2], edu_level_f[i,:pop_share] - edu_level_f[i,:q1])
        edu_level_f[i,:q3] = min(0.2 - edu_level_f[i-1,:q3], edu_level_f[i,:pop_share] - edu_level_f[i,:q1] - edu_level_f[i,:q2])
        edu_level_f[i,:q4] = min(0.2 - edu_level_f[i-1,:q4], edu_level_f[i,:pop_share] - edu_level_f[i,:q1] - edu_level_f[i,:q2] - edu_level_f[i,:q3])
        edu_level_f[i,:q5] = min(0.2 - edu_level_f[i-1,:q5], edu_level_f[i,:pop_share] - edu_level_f[i,:q1] - edu_level_f[i,:q2] - edu_level_f[i,:q3] - edu_level_f[i,:q4])
    elseif edu_level_f[i,:edu] == "e3"
        edu_level_f[i,:q1] = min(max(0.0, 0.2 - edu_level_f[i-1,:q1] - edu_level_f[i-2,:q1]), edu_level_f[i,:pop_share])
        edu_level_f[i,:q2] = min(max(0.0, min(0.2 - edu_level_f[i-1,:q2] - edu_level_f[i-2,:q2], edu_level_f[i,:pop_share] - edu_level_f[i,:q1])), edu_level_f[i,:pop_share])
        edu_level_f[i,:q3] = min(0.2 - edu_level_f[i-1,:q3] - edu_level_f[i-2,:q3], edu_level_f[i,:pop_share] - edu_level_f[i,:q1] - edu_level_f[i,:q2])
        edu_level_f[i,:q4] = min(0.2 - edu_level_f[i-1,:q4] - edu_level_f[i-2,:q4], edu_level_f[i,:pop_share] - edu_level_f[i,:q1] - edu_level_f[i,:q2] - edu_level_f[i,:q3])
        edu_level_f[i,:q5] = min(0.2 - edu_level_f[i-1,:q5] - edu_level_f[i-2,:q5], edu_level_f[i,:pop_share] - edu_level_f[i,:q1] - edu_level_f[i,:q2] - edu_level_f[i,:q3] - edu_level_f[i,:q4])
    elseif edu_level_f[i,:edu] == "e4"
        edu_level_f[i,:q1] = min(max(0.0, 0.2 - edu_level_f[i-1,:q1] - edu_level_f[i-2,:q1] - edu_level_f[i-3,:q1]), edu_level_f[i,:pop_share])
        edu_level_f[i,:q2] = min(max(0.0, min(0.2 - edu_level_f[i-1,:q2] - edu_level_f[i-2,:q2] - edu_level_f[i-3,:q2], edu_level_f[i,:pop_share] - edu_level_f[i,:q1])), edu_level_f[i,:pop_share])
        edu_level_f[i,:q3] = min(max(0.0, min(0.2 - edu_level_f[i-1,:q3] - edu_level_f[i-2,:q3] - edu_level_f[i-3,:q3], edu_level_f[i,:pop_share] - edu_level_f[i,:q1] - edu_level_f[i,:q2])), edu_level_f[i,:pop_share])
        edu_level_f[i,:q4] = min(0.2 - edu_level_f[i-1,:q4] - edu_level_f[i-2,:q4] - edu_level_f[i-3,:q4], edu_level_f[i,:pop_share] - edu_level_f[i,:q1] - edu_level_f[i,:q2] - edu_level_f[i,:q3])
        edu_level_f[i,:q5] = min(0.2 - edu_level_f[i-1,:q5] - edu_level_f[i-2,:q5] - edu_level_f[i-3,:q5], edu_level_f[i,:pop_share] - edu_level_f[i,:q1] - edu_level_f[i,:q2] - edu_level_f[i,:q3] - edu_level_f[i,:q4])
    elseif edu_level_f[i,:edu] == "e5"
        edu_level_f[i,:q1] = min(max(0.0, 0.2 - edu_level_f[i-1,:q1] - edu_level_f[i-2,:q1] - edu_level_f[i-3,:q1] - edu_level_f[i-4,:q1]), edu_level_f[i,:pop_share])
        edu_level_f[i,:q2] = min(max(0.0, min(0.2 - edu_level_f[i-1,:q2] - edu_level_f[i-2,:q2] - edu_level_f[i-3,:q2] - edu_level_f[i-4,:q2], edu_level_f[i,:pop_share] - edu_level_f[i,:q1])), edu_level_f[i,:pop_share])
        edu_level_f[i,:q3] = min(max(0.0, min(0.2 - edu_level_f[i-1,:q3] - edu_level_f[i-2,:q3] - edu_level_f[i-3,:q3] - edu_level_f[i-4,:q3], edu_level_f[i,:pop_share] - edu_level_f[i,:q1] - edu_level_f[i,:q2])), edu_level_f[i,:pop_share])
        edu_level_f[i,:q4] = min(max(0.0, min(0.2 - edu_level_f[i-1,:q4] - edu_level_f[i-2,:q4] - edu_level_f[i-3,:q4] - edu_level_f[i-4,:q4], edu_level_f[i,:pop_share] - edu_level_f[i,:q1] - edu_level_f[i,:q2] - edu_level_f[i,:q3])), edu_level_f[i,:pop_share])
        edu_level_f[i,:q5] = min(0.2 - edu_level_f[i-1,:q5] - edu_level_f[i-2,:q5] - edu_level_f[i-3,:q5] - edu_level_f[i-4,:q5], edu_level_f[i,:pop_share] - edu_level_f[i,:q1] - edu_level_f[i,:q2] - edu_level_f[i,:q3] - edu_level_f[i,:q4])
    else
        edu_level_f[i,:q1] = min(max(0.0, 0.2 - edu_level_f[i-1,:q1] - edu_level_f[i-2,:q1] - edu_level_f[i-3,:q1] - edu_level_f[i-4,:q1] - edu_level_f[i-5,:q1]), edu_level_f[i,:pop_share])
        edu_level_f[i,:q2] = min(max(0.0, min(0.2 - edu_level_f[i-1,:q2] - edu_level_f[i-2,:q2] - edu_level_f[i-3,:q2] - edu_level_f[i-4,:q2] - edu_level_f[i-5,:q2], edu_level_f[i,:pop_share] - edu_level_f[i,:q1])), edu_level_f[i,:pop_share])
        edu_level_f[i,:q3] = min(max(0.0, min(0.2 - edu_level_f[i-1,:q3] - edu_level_f[i-2,:q3] - edu_level_f[i-3,:q3] - edu_level_f[i-4,:q3] - edu_level_f[i-5,:q3], edu_level_f[i,:pop_share] - edu_level_f[i,:q1] - edu_level_f[i,:q2])), edu_level_f[i,:pop_share])
        edu_level_f[i,:q4] = min(max(0.0, min(0.2 - edu_level_f[i-1,:q4] - edu_level_f[i-2,:q4] - edu_level_f[i-3,:q4] - edu_level_f[i-4,:q4] - edu_level_f[i-5,:q4], edu_level_f[i,:pop_share] - edu_level_f[i,:q1] - edu_level_f[i,:q2] - edu_level_f[i,:q3])), edu_level_f[i,:pop_share])
        edu_level_f[i,:q5] = min(max(0.0, min(0.2 - edu_level_f[i-1,:q5] - edu_level_f[i-2,:q5] - edu_level_f[i-3,:q5] - edu_level_f[i-4,:q5] - edu_level_f[i-5,:q5], edu_level_f[i,:pop_share] - edu_level_f[i,:q1] - edu_level_f[i,:q2] - edu_level_f[i,:q3] - edu_level_f[i,:q4])), edu_level_f[i,:pop_share])
    end
end

# We then assume that migrants' income profile per education level is the same as the general population
edu_cross_all = stack(edu_level_f,14:18)
rename!(edu_cross_all, :variable=>:quintile, :value=>:pop_quintile)
sort!(edu_cross_all, [:scen,:period,:fundregion,:edu,:quintile])
edu_cross_all[!,:outmig_quintile] = edu_cross_all[:,:pop_quintile] ./ edu_cross_all[:,:pop_share] .* edu_cross_all[:,:outmig_share]
edu_cross_all[!,:inmig_quintile] = edu_cross_all[:,:pop_quintile] ./ edu_cross_all[:,:pop_share] .* edu_cross_all[:,:inmig_share]

edu_quint_all = by(edu_cross_all,[:scen,:period,:fundregion,:quintile],d->(pop_quint=sum(d.pop_quintile),outmig_quint=sum(d.outmig_quintile),inmig_quint=sum(d.inmig_quintile)))


####################################### Attribute income levels to bilateral migrant flows ########################################
eduquint_ssp = join(
    DataFrame(orig = repeat(regions, inner = length(regions)), dest = repeat(regions, outer = length(regions))), 
    rename(edu_quint_all[:,union(1:4,6)],:fundregion=>:orig,:quintile=>:quint_orig),
    on=:orig
)
eduquint_ssp = join(
    eduquint_ssp, 
    rename(edu_quint_all[:,union(1:4,7)],:fundregion=>:dest,:quintile=>:quint_dest),
    on=[:scen,:period,:dest]
)

# We assume that the distribution of emigrants/immigrants among quintile levels is the same for all destinations/origins
eduquint_ssp[!,:flow_quint_share] = eduquint_ssp[:,:outmig_quint] .* eduquint_ssp[:,:inmig_quint]


################################### Extend SSP eduquint scenarios to before 2015 and after 2100 ######################################
# Linearizing repartition coefficients from 5-year periods to yearly values. Note: a value for year x actually represents the value at the beginning of the five year period                                                
eduquint_allyr = DataFrame(
    period = repeat(2015:2100, outer = length(ssps)*length(regions)*length(regions), inner = 5*5),
    scen = repeat(ssps, inner = length(2015:2100)*length(regions)*length(regions)*5*5),
    orig = repeat(regions, inner = length(2015:2100)*length(regions)*5*5, outer = length(ssps)),
    dest = repeat(regions, inner = length(2015:2100)*5*5, outer = length(ssps)*length(regions)),
    quint_orig = repeat([:q1,:q2,:q3,:q4,:q5], inner = 5, outer = length(ssps)*length(regions)*length(regions)*length(2015:2100)),
    quint_dest = repeat([:q1,:q2,:q3,:q4,:q5], outer = length(ssps)*length(regions)*length(regions)*length(2015:2100)*5)
)
eduquint_ssp = join(eduquint_ssp, eduquint_allyr, on = [:period, :scen, :orig, :dest, :quint_orig, :quint_dest], kind = :outer)
sort!(eduquint_ssp, [:scen, :orig, :dest, :quint_orig, :quint_dest, :period])
for i in 1:size(eduquint_ssp,1)
    if mod(eduquint_ssp[i,:period], 5) != 0
        ind = i - mod(eduquint_ssp[i,:period], 5)
        floor = eduquint_ssp[ind,:flow_quint_share] ; ceiling = eduquint_ssp[ind+5,:flow_quint_share]
        a = floor + (ceiling - floor) / 5 * mod(eduquint_ssp[i,:period], 5)
        eduquint_ssp[i, :flow_quint_share] = a
    end
end

# For 1950-2015: we assume no explicit migration, so repartition coefficients can be zeros
eduquint_past = DataFrame(
    orig = repeat(regions, inner = length(1950:2014)*length(regions)*5*5, outer = length(ssps)),
    dest = repeat(regions, inner = length(1950:2014)*5*5, outer = length(ssps)*length(regions)),
    scen = repeat(ssps, inner = length(1950:2014)*length(regions)*length(regions)*5*5),
    period = repeat(1950:2014, outer = length(ssps)*length(regions)*length(regions), inner = 5*5),
    quint_orig = repeat([:q1,:q2,:q3,:q4,:q5], inner = 5, outer = length(ssps)*length(regions)*length(regions)*length(1950:2014)),
    outmig_quint = zeros(length(ssps)*length(regions)*length(regions)*length(1950:2014)*5*5),
    quint_dest = repeat([:q1,:q2,:q3,:q4,:q5], outer = length(ssps)*length(regions)*length(regions)*length(1950:2014)*5),
    inmig_quint = zeros(length(ssps)*length(regions)*length(regions)*length(1950:2014)*5*5),
    flow_quint_share = zeros(length(ssps)*length(regions)*length(regions)*length(1950:2014)*5*5)
)
eduquint_ssp = vcat(eduquint_past, eduquint_ssp)

# For 2100-3000: we assume repartition coefficients constant, in line with constant life expectancy for that period
eduquint_2100 = eduquint_ssp[(eduquint_ssp[:,:period].==2100),Not(:period)]
eduquint_3000 = DataFrame(
    period=repeat(2101:3000,outer=size(eduquint_2100,1)),
    orig=repeat(eduquint_2100[:,:orig],inner=length(2101:3000)),
    dest=repeat(eduquint_2100[:,:dest],inner=length(2101:3000)),
    scen=repeat(eduquint_2100[:,:scen],inner=length(2101:3000)),
    quint_orig=repeat(eduquint_2100[:,:quint_orig],inner=length(2101:3000)),
    outmig_quint=repeat(eduquint_2100[:,:outmig_quint],inner=length(2101:3000)),
    quint_dest=repeat(eduquint_2100[:,:quint_dest],inner=length(2101:3000)),
    inmig_quint=repeat(eduquint_2100[:,:inmig_quint],inner=length(2101:3000)),
    flow_quint_share=repeat(eduquint_2100[:,:flow_quint_share],inner=length(2101:3000))
)
eduquint_ssp = vcat(eduquint_ssp,eduquint_3000)

# Sorting the data
regionsdf = DataFrame(fundregion = regions, index = 1:16)
eduquint_ssp = join(eduquint_ssp, rename(regionsdf, :fundregion => :orig, :index => :index_orig), on = :orig)
eduquint_ssp = join(eduquint_ssp, rename(regionsdf, :fundregion => :dest, :index => :index_dest), on = :dest)

quintiles = DataFrame(name=unique(eduquint_ssp[:,:quint_orig]),number=1:5)
eduquint_ssp = join(eduquint_ssp, rename(quintiles, :name => :quint_orig, :number=>:quint_or), on=:quint_orig)
eduquint_ssp = join(eduquint_ssp, rename(quintiles, :name => :quint_dest, :number=>:quint_de), on=:quint_dest)

sort!(eduquint_ssp, [:scen, :period, :index_orig, :index_dest, :quint_or, :quint_de])

# Write for each SSP separately
for s in ssps
    CSV.write(joinpath(@__DIR__, string("../../../results/scen_ineq_3d/eduquint_", s, ".csv")), eduquint_ssp[(eduquint_ssp[:,:scen].==s),[:period, :orig, :dest, :quint_or, :quint_de, :flow_quint_share]]; writeheader=false)
end
CSV.write(joinpath(@__DIR__, "../../../results/eduquint_ssp.csv"), eduquint_ssp)
