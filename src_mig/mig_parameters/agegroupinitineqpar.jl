using CSV, DataFrames, Query, DelimitedFiles, FileIO


regions = ["USA", "CAN", "WEU", "JPK", "ANZ", "EEU", "FSU", "MDE", "CAM", "LAM", "SAS", "SEA", "CHI", "MAF", "SSA", "SIS"]
iso3c_fundregion = CSV.File("../input_data/iso3c_fundregion.csv") |> DataFrame

# Computing the initial stock of migrants, and how it declines over time
# We use bilateral migration stocks from 2017 from the World Bank
# In order to get its age distribution, we assume that it is the average of two age distributions in the destination country: 
# the one of migrants at time of migration in the period 2015-2020 (computed from the SSP2 as "share")
# and the one of the overall destination population in the period 2015-2020 (based on SSP2)

# Reading bilateral migrant stocks from 2017
migstock_matrix = load(joinpath(@__DIR__, "../input_data/WB_Bilateral_Estimates_Migrant_Stocks_2017.xlsx"), "Bilateral_Migration_2017!A2:HJ219") |> DataFrame
countriesm = migstock_matrix[1:214,1]
migstock = stack(migstock_matrix, 2:215)
select!(migstock, Not([Symbol("Other North"), Symbol("Other South"), :World]))
rename!(migstock, :x1 => :origin, :variable => :destination, :value => :stock)
permutecols!(migstock, [3,1,2])
sort!(migstock, :origin)
indregion = vcat(findall(migstock[!,:origin] .== "Other North"), findall(migstock[!,:origin] .== "Other South"), findall(migstock[!,:origin] .== "World"))
delete!(migstock, indregion)
indmissing = findall([typeof(migstock[!,:stock][i]) != Float64 for i in 1:size(migstock, 1)])
for i in indmissing ; migstock[!,:stock][i] = 0.0 end
migstock[!,:stock] = map(x -> float(x), migstock[!,:stock])
migstock[!,:destination] = map(x -> string(x), migstock[!,:destination])

# Converting into country codes
ccode = load(joinpath(@__DIR__,"../input_data/GDPpercap2017.xlsx"), "Data!A1:E218") |> DataFrame
select!(ccode, Not([Symbol("Series Code"), Symbol("Series Name"), Symbol("2017 [YR2017]")]))
rename!(ccode, Symbol("Country Name") => :country, Symbol("Country Code") => :country_code)
rename!(ccode, :country => :destination)
indnkorea = findfirst(x -> x == "Korea, Dem. People’s Rep.", ccode[!,:destination])
ccode[!,:destination][indnkorea] = "Korea, Dem. Rep."
migstock = innerjoin(migstock, ccode, on = :destination)
rename!(migstock, :country_code => :dest_code)
rename!(ccode, :destination => :origin)
migstock = innerjoin(migstock, ccode, on = :origin)
rename!(migstock, :country_code => :orig_code)
select!(migstock, Not([:origin, :destination]))

rename!(iso3c_fundregion, :iso3c => :orig_code)
migstock = leftjoin(migstock, iso3c_fundregion, on = :orig_code)
rename!(migstock, :fundregion => :origin)
mis3c = Dict("SXM" => "SIS", "MAF" => "SIS", "CHI" => "WEU", "XKX" => "EEU")
for c in ["SXM", "MAF", "CHI", "XKX"] 
    indmissing = findall(migstock[!,:orig_code] .== c)
    for i in indmissing
        migstock[!,:origin][i] = mis3c[c]
    end
end
rename!(iso3c_fundregion, :orig_code => :dest_code)
migstock = leftjoin(migstock, iso3c_fundregion, on = :dest_code)
rename!(migstock, :fundregion => :destination)
for c in ["SXM", "MAF", "CHI", "XKX"] 
    indmissing = findall(migstock[!,:dest_code] .== c)
    for i in indmissing
        migstock[!,:destination][i] = mis3c[c]
    end
end

# Add data on education and income profiles of migrants.
# We use the profiles of 2015-2020 migrants in SSP for the migrant stocks (already there) at that time
edu_quint = CSV.File(joinpath(@__DIR__,"../input_data/edu_quint.csv")) |> DataFrame

migstock_edu = innerjoin(
    migstock, 
    rename(edu_quint[:,union(1:2,4)],:country=>:orig_code,:quintile=>:quint_orig),
    on=:orig_code
)
migstock_edu = innerjoin(
    migstock_edu, 
    rename(edu_quint[:,union(1:2,5)],:country=>:dest_code,:quintile=>:quint_dest),
    on=:dest_code
)

# We assume that the distribution of emigrants/immigrants among quintile levels is the same for all destinations/origins
migstock_edu[!,:stock_quint] = migstock_edu[:,:stock] .* migstock_edu[:,:outmig_quint] .* migstock_edu[:,:inmig_quint]

# Summing for FUND regions
migstock_quint_reg = combine(d -> sum(d.stock_quint), groupby(migstock_edu, [:origin, :destination, :quint_orig, :quint_dest]))
rename!(migstock_quint_reg, :x1 => :stock_quint)

# Sorting the data
regionsdf = DataFrame(origin = repeat(regions, inner = length(regions)), indexo = repeat(1:16, inner = length(regions)), destination = repeat(regions, outer = length(regions)), indexd = repeat(1:16, outer = length(regions)))
migstock_quint_reg = outerjoin(migstock_quint_reg, regionsdf, on = [:origin, :destination])
sort!(migstock_quint_reg, (:indexo, :indexd))
quintiles = DataFrame(name=unique(migstock_quint_reg[:,:quint_orig]),number=1:5)
migstock_quint_reg = innerjoin(migstock_quint_reg, rename(quintiles, :name => :quint_orig, :number=>:quint_or), on=:quint_orig)
migstock_quint_reg = innerjoin(migstock_quint_reg, rename(quintiles, :name => :quint_dest, :number=>:quint_de), on=:quint_dest)

CSV.write("../data_mig_3d/migstockinit_ineq.csv", migstock_quint_reg[:,[:origin, :destination, :quint_or, :quint_de, :stock_quint]]; writeheader=false)


##################################################### Getting age distributions #################################################
ssp = CSV.File(joinpath(@__DIR__, "../../../results/ssp.csv")) |> DataFrame

sspageedu = combine(d->(pop=sum(d.pop),outmig=sum(d.outmig),inmig=sum(d.inmig)), groupby(ssp, [:age,:edu,:region,:period,:scen]))
agedist = @from i in sspageedu begin
    @where i.period == 2015 && i.scen == "SSP2"
    @select {i.region, i.age, i.edu, i.pop, i.outmig, i.inmig}
    @collect DataFrame
end
ageall = combine(d -> (pop_all=sum(d.:pop),outmig_all=sum(d.outmig),inmig_all=sum(d.inmig)), groupby(agedist, [:region,:age]))
agedist = innerjoin(agedist, ageall, on = [:region,:age])
agedist[!,:pop_share] = agedist[:,:pop] ./ agedist[:,:pop_all]
agedist[!,:outmig_share] = agedist[:,:outmig] ./ agedist[:,:outmig_all]
agedist[!,:inmig_share] = agedist[:,:inmig] ./ agedist[:,:inmig_all]
for name in [:pop,:inmig,:outmig] 
    for i in 1:size(agedist,1) 
        if agedist[i,name] == 0.0 && agedist[i,Symbol(name,Symbol("_all"))] == 0.0 
            agedist[i,Symbol(name,Symbol("_share"))] = 0.0
        end
    end
end

agedist[!,:countrynum] = map(x->parse(Int,SubString(x,3)), agedist[:,:region])
iso3c_isonum = CSV.File(joinpath(@__DIR__,"../input_data/iso3c_isonum.csv")) |> DataFrame
agedist = innerjoin(agedist, rename(iso3c_isonum, :iso3c=>:country, :isonum=>:countrynum), on = :countrynum)
sort!(agedist, [:country, :age, :edu])
countries=unique(agedist[:,:country])

# Calculate income level of migrants
# We assume that education level is perfectly correlated with income level. We attribute each education level to the corresponding income quintile.
for name in [:q1,:q2,:q3,:q4,:q5]
    agedist[!,name] = zeros(size(agedist,1))
end
for i in 1:size(agedist,1)
    if agedist[i,:edu] == "e1"
        agedist[i,:q1] = min(0.2,agedist[i,:pop_share])
        agedist[i,:q2] = min(0.2,max(agedist[i,:pop_share]-0.2,0.0))
        agedist[i,:q3] = min(0.2,max(agedist[i,:pop_share]-0.4,0.0))
        agedist[i,:q4] = min(0.2,max(agedist[i,:pop_share]-0.6,0.0))
        agedist[i,:q5] = min(0.2,max(agedist[i,:pop_share]-0.8,0.0))
    elseif agedist[i,:edu] == "e2"
        agedist[i,:q1] = min(max(0.0, 0.2 - agedist[i-1,:q1]), agedist[i,:pop_share])
        agedist[i,:q2] = min(0.2 - agedist[i-1,:q2], agedist[i,:pop_share] - agedist[i,:q1])
        agedist[i,:q3] = min(0.2 - agedist[i-1,:q3], agedist[i,:pop_share] - agedist[i,:q1] - agedist[i,:q2])
        agedist[i,:q4] = min(0.2 - agedist[i-1,:q4], agedist[i,:pop_share] - agedist[i,:q1] - agedist[i,:q2] - agedist[i,:q3])
        agedist[i,:q5] = min(0.2 - agedist[i-1,:q5], agedist[i,:pop_share] - agedist[i,:q1] - agedist[i,:q2] - agedist[i,:q3] - agedist[i,:q4])
    elseif agedist[i,:edu] == "e3"
        agedist[i,:q1] = min(max(0.0, min(0.2 - agedist[i-1,:q1] - agedist[i-2,:q1], agedist[i,:pop_share])), agedist[i,:pop_share])
        agedist[i,:q2] = min(max(0.0, min(0.2 - agedist[i-1,:q2] - agedist[i-2,:q2], agedist[i,:pop_share] - agedist[i,:q1])), agedist[i,:pop_share])
        agedist[i,:q3] = min(0.2 - agedist[i-1,:q3] - agedist[i-2,:q3], agedist[i,:pop_share] - agedist[i,:q1] - agedist[i,:q2])
        agedist[i,:q4] = min(0.2 - agedist[i-1,:q4] - agedist[i-2,:q4], agedist[i,:pop_share] - agedist[i,:q1] - agedist[i,:q2] - agedist[i,:q3])
        agedist[i,:q5] = min(0.2 - agedist[i-1,:q5] - agedist[i-2,:q5], agedist[i,:pop_share] - agedist[i,:q1] - agedist[i,:q2] - agedist[i,:q3] - agedist[i,:q4])
    elseif agedist[i,:edu] == "e4"
        agedist[i,:q1] = min(max(0.0, min(0.2 - agedist[i-1,:q1] - agedist[i-2,:q1] - agedist[i-3,:q1], agedist[i,:pop_share])), agedist[i,:pop_share])
        agedist[i,:q2] = min(max(0.0, min(0.2 - agedist[i-1,:q2] - agedist[i-2,:q2] - agedist[i-3,:q2], agedist[i,:pop_share] - agedist[i,:q1])), agedist[i,:pop_share])
        agedist[i,:q3] = min(max(0.0, min(0.2 - agedist[i-1,:q3] - agedist[i-2,:q3] - agedist[i-3,:q3], agedist[i,:pop_share] - agedist[i,:q1] - agedist[i,:q2])), agedist[i,:pop_share])
        agedist[i,:q4] = min(max(0.0, 0.2 - agedist[i-1,:q4] - agedist[i-2,:q4] - agedist[i-3,:q4]), max(0.0, agedist[i,:pop_share] - agedist[i,:q1] - agedist[i,:q2] - agedist[i,:q3]))
        agedist[i,:q5] = min(0.2 - agedist[i-1,:q5] - agedist[i-2,:q5] - agedist[i-3,:q5], agedist[i,:pop_share] - agedist[i,:q1] - agedist[i,:q2] - agedist[i,:q3] - agedist[i,:q4])
    elseif agedist[i,:edu] == "e5"
        agedist[i,:q1] = min(max(0.0, 0.2 - agedist[i-1,:q1] - agedist[i-2,:q1] - agedist[i-3,:q1] - agedist[i-4,:q1]), agedist[i,:pop_share])
        agedist[i,:q2] = min(max(0.0, min(0.2 - agedist[i-1,:q2] - agedist[i-2,:q2] - agedist[i-3,:q2] - agedist[i-4,:q2], agedist[i,:pop_share] - agedist[i,:q1])), agedist[i,:pop_share])
        agedist[i,:q3] = min(max(0.0, min(0.2 - agedist[i-1,:q3] - agedist[i-2,:q3] - agedist[i-3,:q3] - agedist[i-4,:q3], agedist[i,:pop_share] - agedist[i,:q1] - agedist[i,:q2])), agedist[i,:pop_share])
        agedist[i,:q4] = min(max(0.0, min(0.2 - agedist[i-1,:q4] - agedist[i-2,:q4] - agedist[i-3,:q4] - agedist[i-4,:q4], agedist[i,:pop_share] - agedist[i,:q1] - agedist[i,:q2] - agedist[i,:q3])), agedist[i,:pop_share])
        agedist[i,:q5] = min(0.2 - agedist[i-1,:q5] - agedist[i-2,:q5] - agedist[i-3,:q5] - agedist[i-4,:q5], max(0.0, agedist[i,:pop_share] - agedist[i,:q1] - agedist[i,:q2] - agedist[i,:q3] - agedist[i,:q4]))
    else
        agedist[i,:q1] = min(max(0.0, 0.2 - agedist[i-1,:q1] - agedist[i-2,:q1] - agedist[i-3,:q1] - agedist[i-4,:q1] - agedist[i-5,:q1]), agedist[i,:pop_share])
        agedist[i,:q2] = min(max(0.0, min(0.2 - agedist[i-1,:q2] - agedist[i-2,:q2] - agedist[i-3,:q2] - agedist[i-4,:q2] - agedist[i-5,:q2], agedist[i,:pop_share] - agedist[i,:q1])), agedist[i,:pop_share])
        agedist[i,:q3] = min(max(0.0, min(0.2 - agedist[i-1,:q3] - agedist[i-2,:q3] - agedist[i-3,:q3] - agedist[i-4,:q3] - agedist[i-5,:q3], agedist[i,:pop_share] - agedist[i,:q1] - agedist[i,:q2])), agedist[i,:pop_share])
        agedist[i,:q4] = min(max(0.0, min(0.2 - agedist[i-1,:q4] - agedist[i-2,:q4] - agedist[i-3,:q4] - agedist[i-4,:q4] - agedist[i-5,:q4], agedist[i,:pop_share] - agedist[i,:q1] - agedist[i,:q2] - agedist[i,:q3])), agedist[i,:pop_share])
        agedist[i,:q5] = min(max(0.0, min(0.2 - agedist[i-1,:q5] - agedist[i-2,:q5] - agedist[i-3,:q5] - agedist[i-4,:q5] - agedist[i-5,:q5], agedist[i,:pop_share] - agedist[i,:q1] - agedist[i,:q2] - agedist[i,:q3] - agedist[i,:q4])), agedist[i,:pop_share])
    end
end

# We then assume that migrants' income profile per education level is the same as the general population
age_cross = stack(agedist,15:19)
rename!(age_cross, :variable=>:quintile, :value=>:pop_quintile)
sort!(age_cross, [:country,:edu,:quintile,:age])
age_cross[!,:outmig_quintile] = age_cross[:,:pop_quintile] ./ age_cross[:,:pop_share] .* age_cross[:,:outmig_share]
age_cross[!,:inmig_quintile] = age_cross[:,:pop_quintile] ./ age_cross[:,:pop_share] .* age_cross[:,:inmig_share]

age_quint = combine(d->(pop_quint=sum(d.pop_quintile),outmig_quint=sum(d.outmig_quintile),inmig_quint=sum(d.inmig_quintile)), groupby(age_cross,[:country,:quintile,:age]))

# In order to get its age distribution, we assume that it is the average of two age distributions in the destination country: 
# the one of migrants at time of migration and the one of the overall destination population, both in the period 2015-2020 (based on SSP2)
age_quint[!,:mean_quint] = (age_quint[:,:pop_quint] .+ age_quint[:,:inmig_quint]) ./ 2
age_quint[!,:quintile] = map(x->String(x), age_quint[:,:quintile])

# Join data
migstock_age_quint = innerjoin(migstock_edu, rename(age_quint, :country => :dest_code, :quintile => :quint_dest)[:,union(1:3,7)], on = [:dest_code, :quint_dest])
migstock_age_quint = innerjoin(migstock_age_quint, unique(rename(age_quint, :country => :orig_code, :quintile => :quint_orig)[:,1:2]), on = [:orig_code, :quint_orig])

migstock_age_quint[!,:stock_by_age] = migstock_age_quint[!,:stock_quint] .* migstock_age_quint[!,:mean_quint]

# Convert to FUND region level
migstock_age_quint_reg = combine(d->sum(d.stock_by_age), groupby(migstock_age_quint, [:origin,:destination,:quint_orig,:quint_dest,:age]))
rename!(migstock_age_quint_reg, :x1 => :stock_age_reg)
migstock_age_quint_reg = innerjoin(migstock_age_quint_reg, rename(quintiles, :name => :quint_orig, :number=>:quint_or), on=:quint_orig)
migstock_age_quint_reg = innerjoin(migstock_age_quint_reg, rename(quintiles, :name => :quint_dest, :number=>:quint_de), on=:quint_dest)

# Linearizing age groups from 5-age to agely values. Note: a value for age x actually represents the average over age group [x; x+5].                                                
migstock_quint_all = DataFrame(
    origin = repeat(regions, inner = length(regions)*length(0:120)*5*5),
    destination = repeat(regions, inner = length(0:120)*5*5, outer = length(regions)),
    quint_or = repeat(1:5, inner = length(0:120)*5, outer = length(regions)*length(regions)),
    quint_de = repeat(1:5, inner = length(0:120), outer = length(regions)*length(regions)*5),
    age = repeat(vcat(repeat(0:5:115, inner=5),[120]), outer = length(regions)*length(regions)*5*5), 
    ageall = repeat(0:120, outer = length(regions)*length(regions)*5*5)
)
migstock_quint_all = outerjoin(migstock_quint_all, migstock_age_quint_reg[:,[:origin, :destination, :quint_or, :quint_de, :age, :stock_age_reg]], on = [:origin, :destination, :quint_or, :quint_de, :age])
migstock_quint_all[:,:stock_age_reg] ./= 5

for o in 0:length(regions)-1
    for d in 0:length(regions)-1
        for p in 0:4
            for q in 0:4
                ind0 = o*length(regions)*length(0:120)*25+d*length(0:120)*25 + p*5*length(0:120) + q*length(0:120)
                for i in ind0+3:ind0+length(0:120)-3
                    if mod(migstock_quint_all[i,:ageall], 5) != 2 
                        floor = migstock_quint_all[i,:stock_age_reg] ; ceiling = migstock_quint_all[min(i+5,121),:stock_age_reg]
                        a = floor + (ceiling - floor) / 5 * (mod(migstock_quint_all[i,:ageall], 5) - 2)
                        migstock_quint_all[i, :stock_age_reg] = a
                    end
                end
                val1 = migstock_quint_all[ind0+3,:stock_age_reg] * 5
                a1 = (val1 - sum(migstock_quint_all[ind0+3:ind0+5,:stock_age_reg])) / 2
                for i in ind0+1:ind0+2 
                    migstock_quint_all[i, :stock_age_reg] = a1 
                end
                val2 = migstock_quint_all[ind0+length(0:120)-3,:stock_age_reg] * 5
                a2 = (val2 - sum(migstock_quint_all[ind0+length(0:120)-3:ind0+length(0:120),:stock_age_reg])) / 2
                for i in ind0+length(0:120)-2:ind0+length(0:120) 
                    migstock_quint_all[i, :stock_age_reg] = a2 
                end
            end
        end
    end
end

CSV.write("../data_mig_3d/agegroupinit_ineq.csv", migstock_quint_all[:,[:origin, :destination, :quint_or, :quint_de, :ageall,:stock_age_reg]]; writeheader=false)
