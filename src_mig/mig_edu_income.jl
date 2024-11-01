using CSV, DataFrames, DelimitedFiles, ExcelFiles, XLSX
using Plots, VegaLite, FileIO, VegaDatasets, FilePaths, ImageIO, ImageMagick
using Statistics, Query, Distributions, StatsPlots


# Calculate income levels of migrants, using bilateral flows
# Education levels of migrants: use SSP projections. 

gini = CSV.File(joinpath(@__DIR__, "../input_data/ssp_ginis.csv")) |> DataFrame
edu = ["e1","e2","e3","e4","e5","e6"]
iso3c_isonum = CSV.File(joinpath(@__DIR__,"../input_data/iso3c_isonum.csv")) |> DataFrame
iso3c_fundregion = CSV.File(joinpath(@__DIR__, "../input_data/iso3c_fundregion.csv")) |> DataFrame
regions_fullname = DataFrame(
    fundregion=["USA", "CAN", "WEU", "JPK", "ANZ", "EEU", "FSU", "MDE", "CAM", "LAM", "SAS", "SEA", "CHI", "MAF", "SSA", "SIS"],
    regionname = ["United States","Canada","Western Europe", "Japan & South Korea","Australia & New Zealand","Central & Eastern Europe","Former Soviet Union", "Middle East", "Central America", "South America","South Asia","Southeast Asia","China plus", "North Africa","Sub-Saharan Africa","Small Island States"]
)


################## Prepare population data: original SSP ####################
ssp1 = CSV.File("C:/Users/hmrb/Stanford_Benveniste Dropbox/Hélène Benveniste/YSSP-IIASA/Samir_data/SSP1.csv") |> DataFrame
ssp2 = CSV.File("C:/Users/hmrb/Stanford_Benveniste Dropbox/Hélène Benveniste/YSSP-IIASA/Samir_data/SSP2.csv") |> DataFrame
ssp3 = CSV.File("C:/Users/hmrb/Stanford_Benveniste Dropbox/Hélène Benveniste/YSSP-IIASA/Samir_data/SSP3.csv") |> DataFrame
ssp4 = CSV.File("C:/Users/hmrb/Stanford_Benveniste Dropbox/Hélène Benveniste/YSSP-IIASA/Samir_data/SSP4.csv") |> DataFrame
ssp5 = CSV.File("C:/Users/hmrb/Stanford_Benveniste Dropbox/Hélène Benveniste/YSSP-IIASA/Samir_data/SSP5.csv") |> DataFrame

select!(ssp1, Not(:Column1))
select!(ssp2, Not(:Column1))
select!(ssp3, Not(:Column1))
select!(ssp4, Not([:Column1, :pattern, :nSx, :pop1, :deaths, :pop2, :pop3, :asfr, Symbol("pop3.shift"), :births, Symbol("deaths.nb"), :pop4, :area]))
select!(ssp5, Not([:Column1, :pattern, :nSx, :pop1, :deaths, :pop2, :pop3, :asfr, Symbol("pop3.shift"), :births, Symbol("deaths.nb"), :pop4, :area]))

ssp4[!,:scen] = repeat(["SSP4"], size(ssp4,1))
ssp5[!,:scen] = repeat(["SSP5"], size(ssp5,1))

select!(ssp4, [2,1,3,4,5,6,7,8,9])
select!(ssp5, [2,1,3,4,5,6,7,8,9])

# Join ssp datasets
ssp = vcat(ssp1, ssp2, ssp3, ssp4, ssp5)

# Replace missing values by zeros
for name in [:inmig, :outmig]
    for i in 1:length(ssp[!,name])
        if ssp[!,name][i] == "NA" 
            ssp[!,name][i] = "0"
        end
    end
    ssp[!,name] = map(x -> parse(Float64, x), ssp[!,name])
end


####################### Update SSP population scenarios #################################################
# Source:  K.C., S., Lutz, W. , Potančoková, M. , Abel, G. , Barakat, B., Eder, J., Goujon, A. , Jurasszovich, S., et al. (2020). 
# Global population and human capital projections for Shared Socioeconomic Pathways – 2015 to 2100, Revision-2018. 
# https://pure.iiasa.ac.at/id/eprint/17550/
ssp1_update = CSV.read("C:/Users/hmrb/Stanford_Benveniste Dropbox/Hélène Benveniste/YSSP-IIASA/Samir_data/SSP1_2018update.csv", DataFrame)
ssp2_update = CSV.read("C:/Users/hmrb/Stanford_Benveniste Dropbox/Hélène Benveniste/YSSP-IIASA/Samir_data/SSP2_2018update.csv", DataFrame)
ssp3_update = CSV.read("C:/Users/hmrb/Stanford_Benveniste Dropbox/Hélène Benveniste/YSSP-IIASA/Samir_data/SSP3_2018update.csv", DataFrame)
ssp4_update = CSV.read("C:/Users/hmrb/Stanford_Benveniste Dropbox/Hélène Benveniste/YSSP-IIASA/Samir_data/SSP4_2018update.csv", DataFrame)
ssp5_update = CSV.read("C:/Users/hmrb/Stanford_Benveniste Dropbox/Hélène Benveniste/YSSP-IIASA/Samir_data/SSP5_2018update.csv", DataFrame)

ssp1_update.scen = repeat(["SSP1"], size(ssp1_update,1))
ssp2_update.scen = repeat(["SSP2"], size(ssp2_update,1))
ssp3_update.scen = repeat(["SSP3"], size(ssp3_update,1))
ssp4_update.scen = repeat(["SSP4"], size(ssp4_update,1))
ssp5_update.scen = repeat(["SSP5"], size(ssp5_update,1))

ssp_update = vcat(ssp1_update, ssp2_update, ssp3_update, ssp4_update, ssp5_update)

# Full update: use population sizes and demographic distribution of updated scenarios
# Convert 21 age groups to 25 age groups: assume no population over 105 yers old
ssp_update.ageno_22 = zeros(size(ssp_update,1))
ssp_update.ageno_23 = zeros(size(ssp_update,1))
ssp_update.ageno_24 = zeros(size(ssp_update,1))
ssp_update.ageno_25 = zeros(size(ssp_update,1))

ssp_update = stack(
    ssp_update[!,Not([:ageno_0])],
    [:ageno_1,:ageno_2,:ageno_3,:ageno_4,:ageno_5,:ageno_6,:ageno_7,:ageno_8,:ageno_9,:ageno_10,:ageno_11,:ageno_12,:ageno_13,:ageno_14,:ageno_15,:ageno_16,:ageno_17,:ageno_18,:ageno_19,:ageno_20,:ageno_21,:ageno_22,:ageno_23,:ageno_24,:ageno_25]
)
ssp_update.age = (map(x->parse(Int,SubString(x,7)), ssp_update.variable) .- 1 ) .* 5
rename!(ssp_update, :value => :pop_update)

# Keep only population numbers for each age group, each sex and disaggregated education levels, and distinct countries (isono < 900)
filter!(
    row -> (row.sexno != 0 && row.eduno !=0 && row.isono < 900),
    ssp_update
)
ssp_update.sex = [(ssp_update[i,:sexno] == 1 ? "male" : "female") for i in eachindex(ssp_update[:,1])]
select!(ssp_update, [:scen,:year,:isono,:eduno,:age,:sex,:pop_update])

# Convert 10 education levels (Under 15, No Education, Incomplete Primary, Primary, Lower Secondary, Upper Secondary, Post Secondary, Short Post Secondary, Bachelor, Master and higher)
# to 6 education levels (no education, some primary, primary completed, lower secondary completed, upper secondary completed, post secondary completed)
ssp_update[!,:edu_6] = [(ssp_update[i,:eduno] == 1 || ssp_update[i,:eduno] == 2) ? "e1" : (ssp_update[i,:eduno] == 3 ? "e2" : (ssp_update[i,:eduno] == 4 ? "e3" : (ssp_update[i,:eduno] == 5 ? "e4" : (ssp_update[i,:eduno] == 6 ? "e5" : "e6")))) for i in eachindex(ssp_update[:,1])]

ssp.region = map(x -> parse(Int, SubString(x, 3)), ssp.region)

ssp = leftjoin(
    ssp,
    rename(
        combine(
            groupby(
                ssp_update, 
                [:year,:isono,:scen,:edu_6,:age,:sex]
            ), 
            :pop_update => sum
        ),
        :year => :period, :isono => :region, :edu_6 => :edu, :pop_update_sum => :pop_update
    ),
    on = [:scen, :period, :region, :edu, :age, :sex]
)


# We assume that for each country, SSP scenario, and demographic group, the ratios inmig/pop and outmig/pop remain the same for the update
ssp.inmig_update = ssp.inmig .* ssp.pop_update ./ ssp.pop
ssp.outmig_update = ssp.outmig .* ssp.pop_update ./ ssp.pop
replace!(ssp.inmig_update, NaN => 0.0)
replace!(ssp.outmig_update, NaN => 0.0)

# We then rescale inmig_update to make sure that for each SSP scenario, time period, and demographic group, the sum over countries of inmig_update = the sum over countries of outmig_update
ssp = innerjoin(
    ssp,
    combine(
        groupby(
            ssp,
            [:scen, :period, :sex, :age, :edu]
        ),
        :inmig_update => sum, :outmig_update => sum
    ),
    on = [:scen, :period, :sex, :age, :edu]
)
ssp.inmig_update = ssp.inmig_update .* ssp.outmig_update_sum ./ ssp.inmig_update_sum
replace!(ssp.inmig_update, NaN => 0.0)

# Keep only updated versions and rename them 
select!(ssp, Not([:pop,:outmig,:inmig,:inmig_update_sum,:outmig_update_sum]))
rename!(ssp, :pop_update => :pop, :inmig_update => :inmig, :outmig_update => :outmig)

CSV.write("C:/Users/hmrb/Stanford_Benveniste Dropbox/Hélène Benveniste/migration-exposure-immobility/results_large/ssp_update.csv", ssp)


################################################### Calculate education levels of migrants #########################################
# Sum projections for all sexes and ages: population + net migration per country and time period
ssp_edu = combine(d -> (pop=sum(d.pop), outmig=sum(d.outmig), inmig=sum(d.inmig)), groupby(ssp, [:region, :period, :scen, :edu]))
ssp_all = combine(d->(pop_all=sum(d.pop), outmig_all=sum(d.outmig),inmig_all=sum(d.inmig)), groupby(ssp_edu, [:region, :period, :scen]))
ssp_edu = innerjoin(ssp_edu, ssp_all, on=[:region,:period,:scen])
ssp_edu[!,:pop_share] = ssp_edu[:,:pop] ./ ssp_edu[:,:pop_all]
ssp_edu[!,:outmig_share] = ssp_edu[:,:outmig] ./ ssp_edu[:,:outmig_all]
ssp_edu[!,:inmig_share] = ssp_edu[:,:inmig] ./ ssp_edu[:,:inmig_all]
for name in [:pop,:inmig,:outmig] 
    for i in eachindex(ssp_edu[:,1]) 
        if ssp_edu[i,name] == 0.0 && ssp_edu[i,Symbol(name,Symbol("_all"))] == 0.0 
            ssp_edu[i,Symbol(name,Symbol("_share"))] = 0.0
        end
    end
end
sort(ssp_edu,[:scen,:period,:region,:edu])

# Plot evolution of outmig and inmig per education level for all SSP
ssp_edu |> @filter(_.period <2100) |> @vlplot(
    mark={:errorband, extent=:ci}, y={"outmig_share:q", title = "Shares, emigrants", axis={labelFontSize=20,titleFontSize=20}}, x={"period:o",title=nothing,labelFontSize=16}, row = {"scen:o", axis={labelFontSize=20}, title=nothing},
    color={"edu:o", scale={scheme=:dark2}, legend={title = "Education level", titleFontSize=20, symbolSize=80, labelFontSize=20, titleLimit=260}}
) |> save(joinpath(@__DIR__, "../results/education/", "FigA1a_update.png"))

ssp_edu |> @filter(_.period <2100) |> @vlplot(
    :line, y={"median(inmig_share)", title = "Shares, immigrants", axis={labelFontSize=20,titleFontSize=20}}, x={"period:o",labelFontSize=16, title=nothing}, row = {"scen:o", axis={labelFontSize=16}, title=nothing},
    color={"edu:o", scale={scheme=:dark2}, legend={title = "Education level", titleFontSize=20, symbolSize=80, labelFontSize=20, titleLimit=260}}
) |> save(joinpath(@__DIR__, "../results/education/", "FigA1b_update.png"))

# Calculate changes in outmig/inmig compared to changes in pop
ssp_edu[!,:outmigpop_ratio] = ssp_edu[:,:outmig_share] ./ ssp_edu[:,:pop_share]
ssp_edu[!,:inmigpop_ratio] = ssp_edu[:,:inmig_share] ./ ssp_edu[:,:pop_share]
ssp_edu[!,:outmigpop_diff] = ssp_edu[:,:outmig_share] .- ssp_edu[:,:pop_share]
ssp_edu[!,:inmigpop_diff] = ssp_edu[:,:inmig_share] .- ssp_edu[:,:pop_share]


CSV.write(joinpath(@__DIR__, "../input_data/ssp_edu_update.csv"), ssp_edu)


# Education distribution among migrants vary a lot over time. We cannot assume that they would have been constant for all of 1990-2015.
# Thus we just calibrate on the 2010-2015 period, assuming that migrants' education level is the same as the mean of SSP scenarios for 2015-2020
edu_level = sort(
    combine(
        d->(pop=mean(d.pop),outmig=mean(d.outmig),inmig=mean(d.inmig),pop_share=mean(d.pop_share),outmig_share=mean(d.outmig_share),inmig_share=mean(d.inmig_share)),
        groupby(
            ssp_edu[(ssp_edu[:,:period].==2015),:],
            [:region,:period,:edu]
        )
    ),[:period,:region,:edu]
)
rename!(edu_level, :region => :countrynum)
edu_level = innerjoin(edu_level, rename(iso3c_isonum, :iso3c=>:country, :isonum=>:countrynum), on = :countrynum)
sort!(edu_level, [:country, :edu])


################################################### Calculate income level of migrants #################################################
# We assume that education level is perfectly correlated with income level. We attribute each education level to the corresponding income quintile.
for name in [:q1,:q2,:q3,:q4,:q5]
    edu_level[!,name] = zeros(size(edu_level,1))
end
for i in eachindex(edu_level[:,1])
    if edu_level[i,:edu] == "e1"
        edu_level[i,:q1] = min(0.2,edu_level[i,:pop_share])
        edu_level[i,:q2] = min(0.2,max(edu_level[i,:pop_share]-0.2,0.0))
        edu_level[i,:q3] = min(0.2,max(edu_level[i,:pop_share]-0.4,0.0))
        edu_level[i,:q4] = min(0.2,max(edu_level[i,:pop_share]-0.6,0.0))
        edu_level[i,:q5] = min(0.2,max(edu_level[i,:pop_share]-0.8,0.0))
    elseif edu_level[i,:edu] == "e2"
        edu_level[i,:q1] = min(max(0.0, 0.2 - edu_level[i-1,:q1]), edu_level[i,:pop_share])
        edu_level[i,:q2] = min(0.2 - edu_level[i-1,:q2], edu_level[i,:pop_share] - edu_level[i,:q1])
        edu_level[i,:q3] = min(0.2 - edu_level[i-1,:q3], edu_level[i,:pop_share] - edu_level[i,:q1] - edu_level[i,:q2])
        edu_level[i,:q4] = min(0.2 - edu_level[i-1,:q4], edu_level[i,:pop_share] - edu_level[i,:q1] - edu_level[i,:q2] - edu_level[i,:q3])
        edu_level[i,:q5] = min(0.2 - edu_level[i-1,:q5], edu_level[i,:pop_share] - edu_level[i,:q1] - edu_level[i,:q2] - edu_level[i,:q3] - edu_level[i,:q4])
    elseif edu_level[i,:edu] == "e3"
        edu_level[i,:q1] = min(max(0.0, 0.2 - edu_level[i-1,:q1] - edu_level[i-2,:q1]), edu_level[i,:pop_share])
        edu_level[i,:q2] = min(max(0.0, 0.2 - edu_level[i-1,:q2] - edu_level[i-2,:q2] - edu_level[i,:q1]), edu_level[i,:pop_share])
        edu_level[i,:q3] = min(0.2 - edu_level[i-1,:q3] - edu_level[i-2,:q3], edu_level[i,:pop_share] - edu_level[i,:q1] - edu_level[i,:q2])
        edu_level[i,:q4] = min(0.2 - edu_level[i-1,:q4] - edu_level[i-2,:q4], edu_level[i,:pop_share] - edu_level[i,:q1] - edu_level[i,:q2] - edu_level[i,:q3])
        edu_level[i,:q5] = min(0.2 - edu_level[i-1,:q5] - edu_level[i-2,:q5], edu_level[i,:pop_share] - edu_level[i,:q1] - edu_level[i,:q2] - edu_level[i,:q3] - edu_level[i,:q4])
    elseif edu_level[i,:edu] == "e4"
        edu_level[i,:q1] = min(max(0.0, 0.2 - edu_level[i-1,:q1] - edu_level[i-2,:q1] - edu_level[i-3,:q1]), edu_level[i,:pop_share])
        edu_level[i,:q2] = min(max(0.0, 0.2 - edu_level[i-1,:q2] - edu_level[i-2,:q2] - edu_level[i-3,:q2] - edu_level[i,:q1]), edu_level[i,:pop_share])
        edu_level[i,:q3] = min(max(0.0, min(0.2 - edu_level[i-1,:q3] - edu_level[i-2,:q3] - edu_level[i-3,:q3], edu_level[i,:pop_share] - edu_level[i,:q1] - edu_level[i,:q2])), edu_level[i,:pop_share])
        edu_level[i,:q4] = min(0.2 - edu_level[i-1,:q4] - edu_level[i-2,:q4] - edu_level[i-3,:q4], edu_level[i,:pop_share] - edu_level[i,:q1] - edu_level[i,:q2] - edu_level[i,:q3])
        edu_level[i,:q5] = min(0.2 - edu_level[i-1,:q5] - edu_level[i-2,:q5] - edu_level[i-3,:q5], edu_level[i,:pop_share] - edu_level[i,:q1] - edu_level[i,:q2] - edu_level[i,:q3] - edu_level[i,:q4])
    elseif edu_level[i,:edu] == "e5"
        edu_level[i,:q1] = min(max(0.0, 0.2 - edu_level[i-1,:q1] - edu_level[i-2,:q1] - edu_level[i-3,:q1] - edu_level[i-4,:q1]), edu_level[i,:pop_share])
        edu_level[i,:q2] = min(max(0.0, 0.2 - edu_level[i-1,:q2] - edu_level[i-2,:q2] - edu_level[i-3,:q2] - edu_level[i-4,:q2] - edu_level[i,:q1]), edu_level[i,:pop_share])
        edu_level[i,:q3] = min(max(0.0, min(0.2 - edu_level[i-1,:q3] - edu_level[i-2,:q3] - edu_level[i-3,:q3] - edu_level[i-4,:q3], edu_level[i,:pop_share] - edu_level[i,:q1] - edu_level[i,:q2])), edu_level[i,:pop_share])
        edu_level[i,:q4] = min(max(0.0, min(0.2 - edu_level[i-1,:q4] - edu_level[i-2,:q4] - edu_level[i-3,:q4] - edu_level[i-4,:q4], edu_level[i,:pop_share] - edu_level[i,:q1] - edu_level[i,:q2] - edu_level[i,:q3])), edu_level[i,:pop_share])
        edu_level[i,:q5] = min(0.2 - edu_level[i-1,:q5] - edu_level[i-2,:q5] - edu_level[i-3,:q5] - edu_level[i-4,:q5], edu_level[i,:pop_share] - edu_level[i,:q1] - edu_level[i,:q2] - edu_level[i,:q3] - edu_level[i,:q4])
    else
        edu_level[i,:q1] = min(max(0.0, 0.2 - edu_level[i-1,:q1] - edu_level[i-2,:q1] - edu_level[i-3,:q1] - edu_level[i-4,:q1] - edu_level[i-5,:q1]), edu_level[i,:pop_share])
        edu_level[i,:q2] = min(max(0.0, 0.2 - edu_level[i-1,:q2] - edu_level[i-2,:q2] - edu_level[i-3,:q2] - edu_level[i-4,:q2] - edu_level[i-5,:q2] - edu_level[i,:q1]), edu_level[i,:pop_share])
        edu_level[i,:q3] = min(max(0.0, min(0.2 - edu_level[i-1,:q3] - edu_level[i-2,:q3] - edu_level[i-3,:q3] - edu_level[i-4,:q3] - edu_level[i-5,:q3], edu_level[i,:pop_share] - edu_level[i,:q1] - edu_level[i,:q2])), edu_level[i,:pop_share])
        edu_level[i,:q4] = min(max(0.0, min(0.2 - edu_level[i-1,:q4] - edu_level[i-2,:q4] - edu_level[i-3,:q4] - edu_level[i-4,:q4] - edu_level[i-5,:q4], edu_level[i,:pop_share] - edu_level[i,:q1] - edu_level[i,:q2] - edu_level[i,:q3])), edu_level[i,:pop_share])
        edu_level[i,:q5] = min(max(0.0, min(0.2 - edu_level[i-1,:q5] - edu_level[i-2,:q5] - edu_level[i-3,:q5] - edu_level[i-4,:q5] - edu_level[i-5,:q5], edu_level[i,:pop_share] - edu_level[i,:q1] - edu_level[i,:q2] - edu_level[i,:q3] - edu_level[i,:q4])), edu_level[i,:pop_share])
    end
end

# We then assume that migrants' income profile per education level is the same as the general population
edu_cross = stack(edu_level,[:q1,:q2,:q3,:q4,:q5])
rename!(edu_cross, :variable=>:quintile, :value=>:pop_quintile)
sort!(edu_cross, [:country,:edu,:quintile])
edu_cross[!,:outmig_quintile] = edu_cross[:,:pop_quintile] ./ edu_cross[:,:pop_share] .* edu_cross[:,:outmig_share]
edu_cross[!,:inmig_quintile] = edu_cross[:,:pop_quintile] ./ edu_cross[:,:pop_share] .* edu_cross[:,:inmig_share]

replace!(edu_cross.outmig_quintile, NaN => 0.0)
replace!(edu_cross.inmig_quintile, NaN => 0.0)

edu_quint = combine(d->(pop_quint=sum(d.pop_quintile),outmig_quint=sum(d.outmig_quintile),inmig_quint=sum(d.inmig_quintile)), groupby(edu_cross,[:country,:quintile]))


######################################### Analyse outmigration as a function of emigrants' income ##################################
# Prepare population data from the Wittgenstein Centre, based on historical data from the WPP 2019. We use data for 2010.
pop_allvariants = CSV.File("C:/Users/hmrb/Stanford_Benveniste Dropbox/Hélène Benveniste/migration-exposure-immobility/data_large/WPP2019.csv") |> DataFrame
# We use the Medium variant, the most commonly used. Unit: thousands
pop = @from i in pop_allvariants begin
    @where i.Variant == "Medium" && i.Time == 2010 
    @select {i.LocID, i.Location, i.PopTotal}
    @collect DataFrame
end
pop = innerjoin(pop, rename(iso3c_isonum,:iso3c=>:country,:isonum=>:LocID), on=:LocID)

# Prepare gdp data from the World Bank's WDI as available at the IIASA SSP database. We use data for 2010
# Unit: billion US$ 2005 / year PPP
gdp_unstacked = XLSX.readdata(joinpath(@__DIR__, "../input_data/gdphist.xlsx"), "data!A2:Q184")
gdp_unstacked = DataFrame(gdp_unstacked, :auto)
rename!(gdp_unstacked, Symbol.(Vector(gdp_unstacked[1,:])))
deleteat!(gdp_unstacked,1)
select!(gdp_unstacked, Not([:Model, Symbol("Scenario (History)"), :Variable, :Unit]))
gdp = stack(gdp_unstacked, 2:size(gdp_unstacked, 2))
rename!(gdp, :variable => :year0, :value => :gdp)
gdp[!,:year0] = map( x -> parse(Int, String(x)), gdp[!,:year0])

edu_quint = innerjoin(edu_quint, rename(pop, :PopTotal=>:pop)[:,3:4], on=:country)
edu_quint = innerjoin(edu_quint, rename(gdp[(gdp[:,:year0].==2010),:],:Region=>:country)[:,Not(:year0)], on = :country)

# Transform Gini coefficients into income quintiles (with migration)
# We assume that the income distribution can be fitted by a lognormal distribution 
# Thus, inequality depends on a single parameter sigma which uniquely determines the shape of the Lorenz curves. 
# The Gini coefficient also depends uniquely on this parameter (http://www.vcharite.univ-mrs.fr/PP/lubrano/cours/Lecture-4.pdf)
# In particular, Gini = 2 * phi(sigma/sqrt(2)) -1 ; Lorenz curve: p -> phi(phi^-1(p) - sigma)    with phi the cdf of Normal(0,1)
# So Lorenz curve can be described as function of Gini: p -> phi(phi^-1(p) - sqrt(2)*phi^-1((Gini+1)/2))
# Note: phi^-1 is, in effect, the quantile function
# We compute income quantiles: difference between values for two successive p on Lorenz curve
p = range(0, step=0.2, stop=1)          # here we use income quintiles
for q in 1:length(p)-1
    gini[!,Symbol(string("q", q))] = [cdf.(Normal(), quantile.(Normal(), p[q+1]) .- sqrt(2) .* quantile.(Normal(), (gini[!,:gini][i] + 1)/2)) - cdf.(Normal(), quantile.(Normal(), p[q]) .- sqrt(2) .* quantile.(Normal(), (gini[!,:gini][i] + 1)/2)) for i in eachindex(gini[:,1])]
end
gini_stack = stack(gini,[:q1,:q2,:q3,:q4,:q5])
rename!(gini_stack, :variable=>:quintile,:value=>:gdpshare_quint)

# Join data on Gini for 2010 (same for all SSP)
edu_quint = innerjoin(edu_quint, rename(gini_stack[.&(gini_stack[:,:year].==2010,gini_stack[:,:scenario].=="SSP2"),:],:iso=>:country)[:,[:country,:quintile,:gini,:gdpshare_quint]], on=[:country,:quintile])

# Calculate income per capita in each quintile and relative to average income per capita
edu_quint[!,:ypc_quint] = edu_quint[:,:gdp] .* 10^9 .* edu_quint[:,:gdpshare_quint] ./ (edu_quint[:,:pop] .* 1000 ./ 5)
edu_quint[!,:ypc_rel] = edu_quint[:,:ypc_quint] ./ (edu_quint[:,:gdp] .* 10^9 ./ (edu_quint[:,:pop] .* 1000))

edu_quint = innerjoin(edu_quint, rename(iso3c_fundregion, :iso3c=>:country), on=:country)
edu_quint = innerjoin(edu_quint, regions_fullname, on=:fundregion)


CSV.write(joinpath(@__DIR__,"../input_data/edu_quint_update.csv"),edu_quint)


# Aggregated at region level
ssp_2015_scen = combine(d -> (outmig = sum(d.outmig), inmig = sum(d.inmig)) ,groupby(ssp_edu[(ssp_edu[:,:period].==2015),:], [:region,:scen]))
ssp_2015 = combine(d -> (outmig = mean(d.outmig), inmig = mean(d.inmig)) ,groupby(ssp_2015_scen, [:region]))
rename!(ssp_2015, :region=>:countrynum)
ssp_2015 = innerjoin(ssp_2015 ,rename(iso3c_isonum, :isonum=>:countrynum, :iso3c=>:country), on=:countrynum)
edu_quint = innerjoin(edu_quint, ssp_2015[:,[:outmig,:inmig,:country]], on =:country)
edu_quint[:,:outmig_qnum] = edu_quint[:,:outmig_quint] .* edu_quint[:,:outmig]
edu_quint[:,:inmig_qnum] = edu_quint[:,:inmig_quint] .* edu_quint[:,:inmig]
edu_quint_reg = combine(d ->(outmig_reg=sum(d.outmig_qnum),inmig_reg=sum(d.inmig_qnum)), groupby(edu_quint, [:quintile,:regionname]))
edu_reg = combine(d->(outmig_tot=sum(d.outmig_reg),inmig_tot=sum(d.inmig_reg)), groupby(edu_quint_reg,[:regionname]))
edu_quint_reg = innerjoin(edu_quint_reg,edu_reg,on=:regionname)
edu_quint_reg[:,:outmig_quint_reg] = edu_quint_reg[:,:outmig_reg] ./ edu_quint_reg[:,:outmig_tot]
edu_quint_reg[:,:inmig_quint_reg] = edu_quint_reg[:,:inmig_reg] ./ edu_quint_reg[:,:inmig_tot]

edu_stack = stack(edu_quint_reg[:,[:quintile,:regionname,:outmig_quint_reg,:inmig_quint_reg]],[:outmig_quint_reg,:inmig_quint_reg])
rename!(edu_stack, :variable=>:migtype, :value=>:migshare)
edu_stack[:,:migtype] = map(x->SubString(String(x),1:6),edu_stack[:,:migtype])

edu_stack |> @vlplot(
    mark={:point,size=100,filled=true}, columns=4, wrap={"regionname:o", title=nothing, header={labelFontSize=18}}, 
    y={"migshare:q", title = "Share of migrants in quintile", axis={titleFontSize=16}}, 
    x={"quintile:o", axis={titleFontSize=16}}, 
    color={"regionname:o", scale={scheme=:category20}, legend=nothing},
    shape={"migtype:n",scale = {range=["triangle-up","circle"]},legend={title = "Migration in/out", titleFontSize=20, symbolSize=80, labelFontSize=16}}
) |> save(joinpath(@__DIR__, "../results/education/", "FigA2_update.png"))


####################################### Attribute income levels to bilateral migrant flows ########################################
edu_quint = CSV.File(joinpath(@__DIR__,"../input_data/edu_quint_update.csv")) |> DataFrame
migflow_alldata = CSV.File(joinpath(@__DIR__, "../input_data/ac19.csv")) |> DataFrame          # Use Abel and Cohen (2019)
# From Abel and Cohen's paper, we choose Azose and Raftery's data:based a demographic accounting, pseudo-Bayesian method, which performs the best
migflow_ar = migflow_alldata[:,[:year0, :orig, :dest, :da_pb_closed]]

edu_bil = innerjoin(
    rename(migflow_ar[(migflow_ar[:,:year0].==2010),Not(:year0)],:da_pb_closed=>:flow), 
    rename(edu_quint[:,[:country,:quintile,:outmig_quint,:ypc_quint]],:country=>:orig,:quintile=>:quint_orig,:ypc_quint=>:ypc_quint_orig),
    on=:orig
)
edu_bil = innerjoin(
    edu_bil, 
    rename(edu_quint[:,[:country,:quintile,:inmig_quint,:ypc_quint]],:country=>:dest,:quintile=>:quint_dest,:ypc_quint=>:ypc_quint_dest),
    on=:dest
)

# Strong assumption: the distribution of emigrants/immigrants among quintile levels is the same for all destinations/origins
edu_bil[!,:flow_quint] = edu_bil[:,:flow] .* edu_bil[:,:outmig_quint] .* edu_bil[:,:inmig_quint]

CSV.write("C:/Users/hmrb/Stanford_Benveniste Dropbox/Hélène Benveniste/migration-exposure-immobility/results_large/edu_bil_update.csv",edu_bil)


############################################# Calculate income terciles of migrants #######################################
ssp_edu = CSV.File(joinpath(@__DIR__, "../input_data/ssp_edu_update.csv")) |> DataFrame

edu_level = sort(
    combine(
        d->(pop=mean(d.pop),outmig=mean(d.outmig),inmig=mean(d.inmig),pop_share=mean(d.pop_share),outmig_share=mean(d.outmig_share),inmig_share=mean(d.inmig_share)),
        groupby(
            ssp_edu[(ssp_edu[:,:period].==2015),:],
            [:region,:period,:edu]
        )
    ),[:period,:region,:edu]
)
rename!(edu_level, :region => :countrynum)
edu_level = innerjoin(edu_level, rename(iso3c_isonum, :iso3c=>:country, :isonum=>:countrynum), on = :countrynum)
sort!(edu_level, [:country, :edu])

for name in [:t1,:t2,:t3]
    edu_level[!,name] = zeros(size(edu_level,1))
end
for i in eachindex(edu_level[:,1])
    if edu_level[i,:edu] == "e1"
        edu_level[i,:t1] = min(1/3,edu_level[i,:pop_share])
        edu_level[i,:t2] = min(1/3,max(edu_level[i,:pop_share]-1/3,0.0))
        edu_level[i,:t3] = min(1/3,max(edu_level[i,:pop_share]-2/3,0.0))
    elseif edu_level[i,:edu] == "e2"
        edu_level[i,:t1] = min(max(0.0, 1/3 - edu_level[i-1,:t1]), edu_level[i,:pop_share])
        edu_level[i,:t2] = min(1/3 - edu_level[i-1,:t2], edu_level[i,:pop_share] - edu_level[i,:t1])
        edu_level[i,:t3] = min(1/3 - edu_level[i-1,:t3], edu_level[i,:pop_share] - edu_level[i,:t1] - edu_level[i,:t2])
    elseif edu_level[i,:edu] == "e3"
        edu_level[i,:t1] = min(max(0.0, 1/3 - edu_level[i-1,:t1] - edu_level[i-2,:t1]), edu_level[i,:pop_share])
        edu_level[i,:t2] = min(max(0.0, min(1/3 - edu_level[i-1,:t2] - edu_level[i-2,:t2], edu_level[i,:pop_share] - edu_level[i,:t1])), edu_level[i,:pop_share])
        edu_level[i,:t3] = min(1/3 - edu_level[i-1,:t3] - edu_level[i-2,:t3], edu_level[i,:pop_share] - edu_level[i,:t1] - edu_level[i,:t2])
    elseif edu_level[i,:edu] == "e4"
        edu_level[i,:t1] = min(max(0.0, 1/3 - edu_level[i-1,:t1] - edu_level[i-2,:t1] - edu_level[i-3,:t1]), edu_level[i,:pop_share])
        edu_level[i,:t2] = min(max(0.0, 1/3 - edu_level[i-1,:t2] - edu_level[i-2,:t2] - edu_level[i-3,:t2] - edu_level[i,:t1]), edu_level[i,:pop_share])
        edu_level[i,:t3] = min(max(0.0, min(1/3 - edu_level[i-1,:t3] - edu_level[i-2,:t3] - edu_level[i-3,:t3], edu_level[i,:pop_share] - edu_level[i,:t1] - edu_level[i,:t2])), edu_level[i,:pop_share])
    elseif edu_level[i,:edu] == "e5"
        edu_level[i,:t1] = min(max(0.0, 1/3 - edu_level[i-1,:t1] - edu_level[i-2,:t1] - edu_level[i-3,:t1] - edu_level[i-4,:t1]), edu_level[i,:pop_share])
        edu_level[i,:t2] = min(max(0.0, 1/3 - edu_level[i-1,:t2] - edu_level[i-2,:t2] - edu_level[i-3,:t2] - edu_level[i-4,:t2] - edu_level[i,:t1]), edu_level[i,:pop_share])
        edu_level[i,:t3] = min(max(0.0, min(1/3 - edu_level[i-1,:t3] - edu_level[i-2,:t3] - edu_level[i-3,:t3] - edu_level[i-4,:t3], edu_level[i,:pop_share] - edu_level[i,:t1] - edu_level[i,:t2])), edu_level[i,:pop_share])
    else
        edu_level[i,:t1] = min(max(0.0, 1/3 - edu_level[i-1,:t1] - edu_level[i-2,:t1] - edu_level[i-3,:t1] - edu_level[i-4,:t1] - edu_level[i-5,:t1]), edu_level[i,:pop_share])
        edu_level[i,:t2] = min(max(0.0, 1/3 - edu_level[i-1,:t2] - edu_level[i-2,:t2] - edu_level[i-3,:t2] - edu_level[i-4,:t2] - edu_level[i-5,:t2] - edu_level[i,:t1]), edu_level[i,:pop_share])
        edu_level[i,:t3] = min(max(0.0, min(1/3 - edu_level[i-1,:t3] - edu_level[i-2,:t3] - edu_level[i-3,:t3] - edu_level[i-4,:t3] - edu_level[i-5,:t3], edu_level[i,:pop_share] - edu_level[i,:t1] - edu_level[i,:t2])), edu_level[i,:pop_share])
    end
end

edu_cross = stack(edu_level,[:t1,:t2,:t3])
rename!(edu_cross, :variable=>:tercile, :value=>:pop_tercile)
sort!(edu_cross, [:country,:edu,:tercile])
edu_cross[!,:outmig_tercile] = edu_cross[:,:pop_tercile] ./ edu_cross[:,:pop_share] .* edu_cross[:,:outmig_share]
edu_cross[!,:inmig_tercile] = edu_cross[:,:pop_tercile] ./ edu_cross[:,:pop_share] .* edu_cross[:,:inmig_share]
replace!(edu_cross.outmig_tercile, NaN => 0.0)
replace!(edu_cross.inmig_tercile, NaN => 0.0)

edu_terc = combine(d->(pop_terc=sum(d.pop_tercile),outmig_terc=sum(d.outmig_tercile),inmig_terc=sum(d.inmig_tercile)), groupby(edu_cross,[:country,:tercile]))

edu_terc = innerjoin(edu_terc, rename(pop, :PopTotal=>:pop)[:,3:4], on=:country)
edu_terc = innerjoin(edu_terc, rename(gdp[(gdp[:,:year0].==2010),:],:Region=>:country), on = :country)

gini = CSV.File(joinpath(@__DIR__, "../input_data/ssp_ginis.csv")) |> DataFrame
p = range(0, step=1/3, stop=1)     
for t in 1:length(p)-1
    gini[!,Symbol(string("t", t))] = [cdf.(Normal(), quantile.(Normal(), p[t+1]) .- sqrt(2) .* quantile.(Normal(), (gini[!,:gini][i] + 1)/2)) - cdf.(Normal(), quantile.(Normal(), p[t]) .- sqrt(2) .* quantile.(Normal(), (gini[!,:gini][i] + 1)/2)) for i in eachindex(gini[:,1])]
end
gini_stack_terc = stack(gini,[:t1,:t2,:t3])
rename!(gini_stack_terc, :variable=>:tercile,:value=>:gdpshare_terc)

edu_terc = innerjoin(edu_terc, rename(gini_stack_terc[.&(gini_stack_terc[:,:year].==2010,gini_stack_terc[:,:scenario].=="SSP2"),:],:iso=>:country)[:,[:country,:tercile,:gdpshare_terc]], on=[:country,:tercile])

edu_terc[!,:ypc_terc] = edu_terc[:,:gdp] .* 10^9 .* edu_terc[:,:gdpshare_terc] ./ (edu_terc[:,:pop] .* 1000 ./ 5)
edu_terc[!,:ypc_rel] = edu_terc[:,:ypc_terc] ./ (edu_terc[:,:gdp] .* 10^9 ./ (edu_terc[:,:pop] .* 1000))


CSV.write(joinpath(@__DIR__,"../input_data/edu_terc_update.csv"),edu_terc)


edu_bil_terc = innerjoin(
    rename(migflow_ar[(migflow_ar[:,:year0].==2010),Not(:year0)],:da_pb_closed=>:flow), 
    rename(edu_terc[:,[:country,:tercile,:outmig_terc,:ypc_terc]],:country=>:orig,:tercile=>:terc_orig,:ypc_terc=>:ypc_terc_orig),
    on=:orig
)
edu_bil_terc = innerjoin(
    edu_bil_terc, 
    rename(edu_terc[:,[:country,:tercile,:inmig_terc,:ypc_terc]],:country=>:dest,:tercile=>:terc_dest,:ypc_terc=>:ypc_terc_dest),
    on=:dest
)

edu_bil_terc[!,:flow_terc] = edu_bil_terc[:,:flow] .* edu_bil_terc[:,:outmig_terc] .* edu_bil_terc[:,:inmig_terc]


CSV.write("C:/Users/hmrb/Stanford_Benveniste Dropbox/Hélène Benveniste/migration-exposure-immobility/results_large/edu_bil_terc_update.csv",edu_bil_terc)