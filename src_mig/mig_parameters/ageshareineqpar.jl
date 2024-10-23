using CSV, DataFrames, Query, DelimitedFiles


ssp = CSV.File("C:/Users/hmrb/Stanford_Benveniste Dropbox/Hélène Benveniste/migration-exposure-immobility/results_large/ssp_update.csv") |> DataFrame

regions = ["USA", "CAN", "WEU", "JPK", "ANZ", "EEU", "FSU", "MDE", "CAM", "LAM", "SAS", "SEA", "CHI", "MAF", "SSA", "SIS"]
iso3c_isonum = CSV.File(joinpath(@__DIR__,"../../input_data/iso3c_isonum.csv")) |> DataFrame
iso3c_fundregion = CSV.File(joinpath(@__DIR__,"../../input_data/iso3c_fundregion.csv")) |> DataFrame


#################################################### Compute age of migrants at time of migration per income quintile, region, scenario ################################
sspageedu = combine(d->(pop=sum(d.pop),outmig=sum(d.outmig),inmig=sum(d.inmig)), groupby(ssp, [:age,:edu,:region,:period,:scen]))
ageall = combine(d -> (pop_all=sum(d.:pop),outmig_all=sum(d.outmig),inmig_all=sum(d.inmig)), groupby(sspageedu, [:region,:age,:period,:scen]))
sspageedu = innerjoin(sspageedu, ageall, on = [:region,:age,:period,:scen])
sspageedu[!,:pop_share] = sspageedu[:,:pop] ./ sspageedu[:,:pop_all]
sspageedu[!,:outmig_share] = sspageedu[:,:outmig] ./ sspageedu[:,:outmig_all]
sspageedu[!,:inmig_share] = sspageedu[:,:inmig] ./ sspageedu[:,:inmig_all]
for name in [:pop,:inmig,:outmig] 
    for i in eachindex(sspageedu[:,1]) 
        if sspageedu[i,name] == 0.0 && sspageedu[i,Symbol(name,Symbol("_all"))] == 0.0 
            sspageedu[i,Symbol(name,Symbol("_share"))] = 0.0
        end
    end
end

rename!(sspageedu, :region => :countrynum)
sspageedu = innerjoin(sspageedu, rename(iso3c_isonum, :iso3c=>:country, :isonum=>:countrynum), on = :countrynum)
sort!(sspageedu, [:scen,:period,:country, :age, :edu])
countries=unique(sspageedu[:,:country])

# Calculate income level of migrants
# We assume that education level is perfectly correlated with income level. We attribute each education level to the corresponding income quintile.
for name in [:q1,:q2,:q3,:q4,:q5]
    sspageedu[!,name] = zeros(size(sspageedu,1))
end
for i in eachindex(sspageedu[:,1])
    if sspageedu[i,:edu] == "e1"
        sspageedu[i,:q1] = min(0.2,sspageedu[i,:pop_share])
        sspageedu[i,:q2] = min(0.2,max(sspageedu[i,:pop_share]-0.2,0.0))
        sspageedu[i,:q3] = min(0.2,max(sspageedu[i,:pop_share]-0.4,0.0))
        sspageedu[i,:q4] = min(0.2,max(sspageedu[i,:pop_share]-0.6,0.0))
        sspageedu[i,:q5] = min(0.2,max(sspageedu[i,:pop_share]-0.8,0.0))
    elseif sspageedu[i,:edu] == "e2"
        sspageedu[i,:q1] = min(max(0.0, 0.2 - sspageedu[i-1,:q1]), sspageedu[i,:pop_share])
        sspageedu[i,:q2] = min(0.2 - sspageedu[i-1,:q2], sspageedu[i,:pop_share] - sspageedu[i,:q1])
        sspageedu[i,:q3] = min(0.2 - sspageedu[i-1,:q3], sspageedu[i,:pop_share] - sspageedu[i,:q1] - sspageedu[i,:q2])
        sspageedu[i,:q4] = min(0.2 - sspageedu[i-1,:q4], sspageedu[i,:pop_share] - sspageedu[i,:q1] - sspageedu[i,:q2] - sspageedu[i,:q3])
        sspageedu[i,:q5] = min(0.2 - sspageedu[i-1,:q5], sspageedu[i,:pop_share] - sspageedu[i,:q1] - sspageedu[i,:q2] - sspageedu[i,:q3] - sspageedu[i,:q4])
    elseif sspageedu[i,:edu] == "e3"
        sspageedu[i,:q1] = min(max(0.0, min(0.2 - sspageedu[i-1,:q1] - sspageedu[i-2,:q1], sspageedu[i,:pop_share])), sspageedu[i,:pop_share])
        sspageedu[i,:q2] = min(max(0.0, min(0.2 - sspageedu[i-1,:q2] - sspageedu[i-2,:q2], sspageedu[i,:pop_share] - sspageedu[i,:q1])), sspageedu[i,:pop_share])
        sspageedu[i,:q3] = min(0.2 - sspageedu[i-1,:q3] - sspageedu[i-2,:q3], sspageedu[i,:pop_share] - sspageedu[i,:q1] - sspageedu[i,:q2])
        sspageedu[i,:q4] = min(0.2 - sspageedu[i-1,:q4] - sspageedu[i-2,:q4], sspageedu[i,:pop_share] - sspageedu[i,:q1] - sspageedu[i,:q2] - sspageedu[i,:q3])
        sspageedu[i,:q5] = min(0.2 - sspageedu[i-1,:q5] - sspageedu[i-2,:q5], sspageedu[i,:pop_share] - sspageedu[i,:q1] - sspageedu[i,:q2] - sspageedu[i,:q3] - sspageedu[i,:q4])
    elseif sspageedu[i,:edu] == "e4"
        sspageedu[i,:q1] = min(max(0.0, min(0.2 - sspageedu[i-1,:q1] - sspageedu[i-2,:q1] - sspageedu[i-3,:q1], sspageedu[i,:pop_share])), sspageedu[i,:pop_share])
        sspageedu[i,:q2] = min(max(0.0, min(0.2 - sspageedu[i-1,:q2] - sspageedu[i-2,:q2] - sspageedu[i-3,:q2], sspageedu[i,:pop_share] - sspageedu[i,:q1])), sspageedu[i,:pop_share])
        sspageedu[i,:q3] = min(max(0.0, min(0.2 - sspageedu[i-1,:q3] - sspageedu[i-2,:q3] - sspageedu[i-3,:q3], sspageedu[i,:pop_share] - sspageedu[i,:q1] - sspageedu[i,:q2])), sspageedu[i,:pop_share])
        sspageedu[i,:q4] = min(max(0.0, 0.2 - sspageedu[i-1,:q4] - sspageedu[i-2,:q4] - sspageedu[i-3,:q4]), max(0.0, sspageedu[i,:pop_share] - sspageedu[i,:q1] - sspageedu[i,:q2] - sspageedu[i,:q3]))
        sspageedu[i,:q5] = min(0.2 - sspageedu[i-1,:q5] - sspageedu[i-2,:q5] - sspageedu[i-3,:q5], sspageedu[i,:pop_share] - sspageedu[i,:q1] - sspageedu[i,:q2] - sspageedu[i,:q3] - sspageedu[i,:q4])
    elseif sspageedu[i,:edu] == "e5"
        sspageedu[i,:q1] = min(max(0.0, 0.2 - sspageedu[i-1,:q1] - sspageedu[i-2,:q1] - sspageedu[i-3,:q1] - sspageedu[i-4,:q1]), sspageedu[i,:pop_share])
        sspageedu[i,:q2] = min(max(0.0, min(0.2 - sspageedu[i-1,:q2] - sspageedu[i-2,:q2] - sspageedu[i-3,:q2] - sspageedu[i-4,:q2], sspageedu[i,:pop_share] - sspageedu[i,:q1])), sspageedu[i,:pop_share])
        sspageedu[i,:q3] = min(max(0.0, min(0.2 - sspageedu[i-1,:q3] - sspageedu[i-2,:q3] - sspageedu[i-3,:q3] - sspageedu[i-4,:q3], sspageedu[i,:pop_share] - sspageedu[i,:q1] - sspageedu[i,:q2])), sspageedu[i,:pop_share])
        sspageedu[i,:q4] = min(max(0.0, min(0.2 - sspageedu[i-1,:q4] - sspageedu[i-2,:q4] - sspageedu[i-3,:q4] - sspageedu[i-4,:q4], sspageedu[i,:pop_share] - sspageedu[i,:q1] - sspageedu[i,:q2] - sspageedu[i,:q3])), sspageedu[i,:pop_share])
        sspageedu[i,:q5] = min(0.2 - sspageedu[i-1,:q5] - sspageedu[i-2,:q5] - sspageedu[i-3,:q5] - sspageedu[i-4,:q5], max(0.0, sspageedu[i,:pop_share] - sspageedu[i,:q1] - sspageedu[i,:q2] - sspageedu[i,:q3] - sspageedu[i,:q4]))
    else
        sspageedu[i,:q1] = min(max(0.0, 0.2 - sspageedu[i-1,:q1] - sspageedu[i-2,:q1] - sspageedu[i-3,:q1] - sspageedu[i-4,:q1] - sspageedu[i-5,:q1]), sspageedu[i,:pop_share])
        sspageedu[i,:q2] = min(max(0.0, min(0.2 - sspageedu[i-1,:q2] - sspageedu[i-2,:q2] - sspageedu[i-3,:q2] - sspageedu[i-4,:q2] - sspageedu[i-5,:q2], sspageedu[i,:pop_share] - sspageedu[i,:q1])), sspageedu[i,:pop_share])
        sspageedu[i,:q3] = min(max(0.0, min(0.2 - sspageedu[i-1,:q3] - sspageedu[i-2,:q3] - sspageedu[i-3,:q3] - sspageedu[i-4,:q3] - sspageedu[i-5,:q3], sspageedu[i,:pop_share] - sspageedu[i,:q1] - sspageedu[i,:q2])), sspageedu[i,:pop_share])
        sspageedu[i,:q4] = min(max(0.0, min(0.2 - sspageedu[i-1,:q4] - sspageedu[i-2,:q4] - sspageedu[i-3,:q4] - sspageedu[i-4,:q4] - sspageedu[i-5,:q4], sspageedu[i,:pop_share] - sspageedu[i,:q1] - sspageedu[i,:q2] - sspageedu[i,:q3])), sspageedu[i,:pop_share])
        sspageedu[i,:q5] = min(max(0.0, min(0.2 - sspageedu[i-1,:q5] - sspageedu[i-2,:q5] - sspageedu[i-3,:q5] - sspageedu[i-4,:q5] - sspageedu[i-5,:q5], sspageedu[i,:pop_share] - sspageedu[i,:q1] - sspageedu[i,:q2] - sspageedu[i,:q3] - sspageedu[i,:q4])), sspageedu[i,:pop_share])
    end
end

# We then assume that migrants' income profile per education level is the same as the general population
age_cross = stack(sspageedu,[:q1,:q2,:q3,:q4,:q5])
rename!(age_cross, :variable=>:quintile, :value=>:pop_quintile)
age_cross[!,:outmig_quintile] = age_cross[:,:pop_quintile] ./ age_cross[:,:pop_share] .* age_cross[:,:outmig_share]
age_cross[!,:inmig_quintile] = age_cross[:,:pop_quintile] ./ age_cross[:,:pop_share] .* age_cross[:,:inmig_share]
for i in eachindex(age_cross[:,1]) ; if age_cross[i,:pop_share] == 0.0 ; age_cross[i,:outmig_quintile] = 0.0 ; age_cross[i,:inmig_quintile] = 0.0 end end

# Go from share of migrants of a given age who are in quintile q to share of migrants of a given quintile who are of age a 
age_quint = combine(d->(pop_quint=sum(d.pop_quintile),outmig_quint=sum(d.outmig_quintile),inmig_quint=sum(d.inmig_quintile)), groupby(age_cross,[:scen,:period,:country,:quintile,:age]))
rename!(ageall, :region => :countrynum)
ageall = innerjoin(ageall, rename(iso3c_isonum, :iso3c=>:country, :isonum=>:countrynum), on = :countrynum)
age_quint = innerjoin(age_quint, ageall[:,[:age,:period,:scen,:country,:inmig_all]], on=[:scen,:period,:country,:age])
age_quint[!,:inmig_agequint] = age_quint[:,:inmig_quint] .* age_quint[:,:inmig_all]
quintall = combine(d->sum(d.inmig_agequint), groupby(age_quint,[:scen,:period,:country,:quintile]))
age_quint = innerjoin(age_quint, rename(quintall, :x1=>:inmig_allage), on=[:scen,:period,:country,:quintile])
age_quint[!,:inmig_ageshare] = age_quint[:,:inmig_agequint] ./ age_quint[:,:inmig_allage]
for i in eachindex(age_quint[:,1]) ; if age_quint[i,:inmig_allage] == 0.0 ; age_quint[i,:inmig_ageshare] = 0.0 end end

# Convert to FUND region level: weight by migrant flows
age_quint = leftjoin(age_quint, rename(iso3c_fundregion,:iso3c=>:country), on = :country)

age_quint_regshareall = combine(d->sum(d.inmig_agequint), groupby(age_quint, [:scen,:period,:fundregion,:quintile]))
age_quint = innerjoin(age_quint, rename(age_quint_regshareall,:x1=>:inmig_reg_allage), on=[:scen,:period,:fundregion,:quintile])
age_quint[!,:inmig_allage_regshare] = age_quint[:,:inmig_allage] ./ age_quint[:,:inmig_reg_allage]
for i in eachindex(age_quint[:,1]) ; if age_quint[i,:inmig_reg_allage] == 0.0 ; age_quint[i,:inmig_allage_regshare] = 0.0 end end

age_quint_reg = combine(d->sum(d.inmig_ageshare.*d.inmig_allage_regshare), groupby(age_quint, [:scen,:period,:fundregion,:quintile,:age]))
rename!(age_quint_reg,:x1=>:agemig_reg)

quintiles = DataFrame(name=unique(age_quint_reg[:,:quintile]),number=1:5)
age_quint_reg = innerjoin(age_quint_reg, rename(quintiles, :name => :quintile, :number=>:quint), on=:quintile)

# There is little difference in age distribution both over time and across SSP, so we choose, for each region and quintile, values for 2020 and SSP2.
# Linearizing age groups from 5-age to agely values. Note: a value for age x actually represents the average over age group [x; x+5].        
age_quint_all = DataFrame(
    region = repeat(regions, inner = length(0:120)*5),
    quint = repeat(1:5, inner = length(0:120), outer = length(regions)),
    age = repeat(vcat(repeat(0:5:115, inner=5),[120]), outer = length(regions)*5), 
    ageall = repeat(0:120, outer = length(regions)*5)
)
age_quint_all = outerjoin(age_quint_all, rename(age_quint_reg[.&(age_quint_reg[:,:scen].=="SSP2",age_quint_reg[:,:period].==2020),[:fundregion, :quint, :age, :agemig_reg]],:fundregion=>:region), on = [:region, :quint, :age])
age_quint_all[:,:agemig_reg] ./= 5

for r in 0:length(regions)-1
    for q in 0:4
        ind0 = r*length(0:120)*5+q*length(0:120)
        for i in ind0+3:ind0+length(0:120)-3
            if mod(age_quint_all[i,:ageall], 5) != 2 
                floor = age_quint_all[i,:agemig_reg] ; ceiling = age_quint_all[min(i+5,121),:agemig_reg]
                a = floor + (ceiling - floor) / 5 * (mod(age_quint_all[i,:ageall], 5) - 2)
                age_quint_all[i, :agemig_reg] = a
            end
        end
        val1 = age_quint_all[ind0+3,:agemig_reg] * 5
        a1 = (val1 - sum(age_quint_all[ind0+3:ind0+5,:agemig_reg])) / 2
        for i in ind0+1:ind0+2 
            age_quint_all[i, :agemig_reg] = a1 
        end
        val2 = age_quint_all[ind0+length(0:120)-3,:agemig_reg] * 5
        a2 = (val2 - sum(age_quint_all[ind0+length(0:120)-3:ind0+length(0:120),:agemig_reg])) / 2
        for i in ind0+length(0:120)-2:ind0+length(0:120) 
            age_quint_all[i, :agemig_reg] = a2 
        end
    end
end

# Sorting the data
regionsdf = DataFrame(region = regions, index = 1:16)
age_quint_all = innerjoin(age_quint_all, regionsdf, on = :region)
sort!(age_quint_all, [:index, :quint, :ageall])

CSV.write(joinpath(@__DIR__, "../../data_mig_3d/ageshare_ineq_update.csv"), age_quint_all[:,[:region,:quint,:ageall,:agemig_reg]]; writeheader=false)
CSV.write(joinpath(@__DIR__, "../../input_data/age_quint_all_update.csv"), age_quint_all)