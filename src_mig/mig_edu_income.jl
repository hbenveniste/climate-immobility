using CSV, DataFrames, DelimitedFiles, ExcelFiles, XLSX
using Plots, VegaLite, FileIO, VegaDatasets, FilePaths, ImageIO, ImageMagick
using Statistics, Query, Distributions, StatsPlots


# Calculate income levels of migrants, using bilateral flows
# Education levels of migrants: use SSP projections. 

gini = CSV.File(joinpath(@__DIR__, "../../../../YSSP_IIASA/data/gini_rao/ssp_ginis.csv")) |> DataFrame
edu = ["e1","e2","e3","e4","e5","e6"]
iso3c_isonum = CSV.File(joinpath(@__DIR__,"../input_data/iso3c_isonum.csv")) |> DataFrame
iso3c_fundregion = CSV.File("../input_data/iso3c_fundregion.csv") |> DataFrame
regions_fullname = DataFrame(
    fundregion=["USA", "CAN", "WEU", "JPK", "ANZ", "EEU", "FSU", "MDE", "CAM", "LAM", "SAS", "SEA", "CHI", "MAF", "SSA", "SIS"],
    regionname = ["United States","Canada","Western Europe", "Japan & South Korea","Australia & New Zealand","Central & Eastern Europe","Former Soviet Union", "Middle East", "Central America", "South America","South Asia","Southeast Asia","China plus", "North Africa","Sub-Saharan Africa","Small Island States"]
)


################## Prepare population data: original SSP and no-migration version ####################
ssp1 = CSV.File(joinpath(@__DIR__, "../../../../YSSP-IIASA/data/pop_samirkc/SSP1.csv")) |> DataFrame
ssp2 = CSV.File(joinpath(@__DIR__, "../../../../YSSP-IIASA/data/pop_samirkc/SSP2.csv")) |> DataFrame
ssp3 = CSV.File(joinpath(@__DIR__, "../../../../YSSP-IIASA/data/pop_samirkc/SSP3.csv")) |> DataFrame
ssp4 = CSV.File(joinpath(@__DIR__, "../../../../YSSP-IIASA/data/pop_samirkc/SSP4.csv")) |> DataFrame
ssp5 = CSV.File(joinpath(@__DIR__, "../../../../YSSP-IIASA/data/pop_samirkc/SSP5.csv")) |> DataFrame

select!(ssp1, Not(:Column1))
select!(ssp2, Not(:Column1))
select!(ssp3, Not(:Column1))
select!(ssp4, Not([:Column1, :pattern, :nSx, :pop1, :deaths, :pop2, :pop3, :asfr, Symbol("pop3.shift"), :births, Symbol("deaths.nb"), :pop4, :area]))
select!(ssp5, Not([:Column1, :pattern, :nSx, :pop1, :deaths, :pop2, :pop3, :asfr, Symbol("pop3.shift"), :births, Symbol("deaths.nb"), :pop4, :area]))

ssp4[!,:scen] = repeat(["SSP4"], size(ssp4,1))
ssp5[!,:scen] = repeat(["SSP5"], size(ssp5,1))

select!(ssp4, :sex,:age,Not([:sex,:age]))
select!(ssp5, :sex,:age,Not([:sex,:age]))

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
CSV.write(joinpath(@__DIR__,"../../../results/ssp.csv"), ssp)

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
sort(ssp_edu,[:scen,:period,:region,:edu,])


################################################### Calculate education levels of migrants #########################################
# Plot evolution of outmig and inmig per education level for all SSP
ssp_edu |> @filter(_.period <2100) |> @vlplot(
    mark={:errorband, extent=:ci}, y={"outmig_share:q", title = "Shares, emigrants", axis={labelFontSize=20,titleFontSize=20}}, x={"period:o",title=nothing,labelFontSize=16}, row = {"scen:o", axis={labelFontSize=20}, title=nothing},
    color={"edu:o", scale={scheme=:dark2}, legend={title = "Education level", titleFontSize=20, symbolSize=80, labelFontSize=20, titleLimit=260}}
) |> save(joinpath(@__DIR__, "../results/education/", "FigA1a.png"))

ssp_edu |> @filter(_.period <2100) |> @vlplot(
    :line, y={"median(inmig_share)", title = "Shares, immigrants", axis={labelFontSize=20,titleFontSize=20}}, x={"period:o",labelFontSize=16, title=nothing}, row = {"scen:o", axis={labelFontSize=16}, title=nothing},
    color={"edu:o", scale={scheme=:dark2}, legend={title = "Education level", titleFontSize=20, symbolSize=80, labelFontSize=20, titleLimit=260}}
) |> save(joinpath(@__DIR__, "../results/education/", "FigA1b.png"))

# Plot changes in outmig/inmig compared to changes in pop
ssp_edu[!,:outmigpop_ratio] = ssp_edu[:,:outmig_share] ./ ssp_edu[:,:pop_share]
ssp_edu[!,:inmigpop_ratio] = ssp_edu[:,:inmig_share] ./ ssp_edu[:,:pop_share]
ssp_edu[!,:outmigpop_diff] = ssp_edu[:,:outmig_share] .- ssp_edu[:,:pop_share]
ssp_edu[!,:inmigpop_diff] = ssp_edu[:,:inmig_share] .- ssp_edu[:,:pop_share]

CSV.write(joinpath(@__DIR__, "../input_data/ssp_edu.csv"), ssp_edu)


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
edu_level[!,:countrynum] = map(x->parse(Int,SubString(x,3)), edu_level[:,:region])
edu_level = innerjoin(edu_level, rename(iso3c_isonum, :iso3c=>:country, :isonum=>:countrynum), on = :countrynum)
sort!(edu_level, [:country, :edu])
countries=unique(edu_level[:,:country])


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
edu_cross = stack(edu_level,12:16)
rename!(edu_cross, :variable=>:quintile, :value=>:pop_quintile)
sort!(edu_cross, [:country,:edu,:quintile])
edu_cross[!,:outmig_quintile] = edu_cross[:,:pop_quintile] ./ edu_cross[:,:pop_share] .* edu_cross[:,:outmig_share]
edu_cross[!,:inmig_quintile] = edu_cross[:,:pop_quintile] ./ edu_cross[:,:pop_share] .* edu_cross[:,:inmig_share]

edu_quint = combine(d->(pop_quint=sum(d.pop_quintile),outmig_quint=sum(d.outmig_quintile),inmig_quint=sum(d.inmig_quintile)), groupby(edu_cross,[:country,:quintile]))


######################################### Analyse outmigration as a function of emigrants' income ##################################
# Prepare population data from the Wittgenstein Centre, based on historical data from the WPP 2019. We use data for 2010.
pop_allvariants = CSV.File(joinpath(@__DIR__, "../input_data/WPP2019.csv")) |> DataFrame
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
edu_quint = innerjoin(edu_quint, rename(gdp[(gdp[:,:year0].==2010),:],:Region=>:country)[:,Not(1)], on = :country)

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
gini_stack = stack(gini,5:9)
rename!(gini_stack, :variable=>:quintile,:value=>:gdpshare_quint)

# Join data on Gini for 2010 (same for all SSP)
edu_quint = innerjoin(edu_quint, rename(gini_stack[.&(gini_stack[:,:year].==2010,gini_stack[:,:scenario].=="SSP2"),:],:iso=>:country)[:,union(1:2,4,6)], on=[:country,:quintile])

# Calculate income per capita in each quintile and relative to average income per capita
edu_quint[!,:ypc_quint] = edu_quint[:,:gdp] .* 10^9 .* edu_quint[:,:gdpshare_quint] ./ (edu_quint[:,:pop] .* 1000 ./ 5)
edu_quint[!,:ypc_rel] = edu_quint[:,:ypc_quint] ./ (edu_quint[:,:gdp] .* 10^9 ./ (edu_quint[:,:pop] .* 1000))

edu_quint = innerjoin(edu_quint, rename(iso3c_fundregion, :iso3c=>:country), on=:country)
edu_quint = innerjoin(edu_quint, regions_fullname, on=:fundregion)


CSV.write(joinpath(@__DIR__,"../input_data/edu_quint.csv"),edu_quint)


# Aggregated at region level
ssp_2015_scen = combine(d -> (outmig = sum(d.outmig), inmig = sum(d.inmig)) ,groupby(ssp_edu[(ssp_edu[:,:period].==2015),:], [:region,:scen]))
ssp_2015 = combine(d -> (outmig = mean(d.outmig), inmig = mean(d.inmig)) ,groupby(ssp_2015_scen, [:region]))
ssp_2015[:,:countrynum] = map(x->parse(Int,SubString(x,3)), ssp_2015[:,:region])
ssp_2015 = innerjoin(ssp_2015 ,rename(iso3c_isonum, :isonum=>:countrynum, :iso3c=>:country), on=:countrynum)
edu_quint = innerjoin(edu_quint, ssp_2015[:,[:outmig,:inmig,:country]], on =:country)
edu_quint[:,:outmig_qnum] = edu_quint[:,:outmig_quint] .* edu_quint[:,:outmig]
edu_quint[:,:inmig_qnum] = edu_quint[:,:inmig_quint] .* edu_quint[:,:inmig]
edu_quint_reg = combine(d ->(outmig_reg=sum(d.outmig_qnum),inmig_reg=sum(d.inmig_qnum)), groupby(edu_quint, [:quintile,:regionname]))
edu_reg = combine(d->(outmig_tot=sum(d.outmig_reg),inmig_tot=sum(d.inmig_reg)), groupby(edu_quint_reg,[:regionname]))
edu_quint_reg = innerjoin(edu_quint_reg,edu_reg,on=:regionname)
edu_quint_reg[:,:outmig_quint_reg] = edu_quint_reg[:,:outmig_reg] ./ edu_quint_reg[:,:outmig_tot]
edu_quint_reg[:,:inmig_quint_reg] = edu_quint_reg[:,:inmig_reg] ./ edu_quint_reg[:,:inmig_tot]

edu_stack = stack(edu_quint_reg[:,union(1:2,7:8)],3:4)
rename!(edu_stack, :variable=>:migtype, :value=>:migshare)
edu_stack[:,:migtype] = map(x->SubString(String(x),1:6),edu_stack[:,:migtype])

edu_stack |> @vlplot(
    mark={:point,size=100,filled=true}, columns=4, wrap={"regionname:o", title=nothing, header={labelFontSize=18}}, 
    y={"migshare:q", title = "Share of migrants in quintile", axis={titleFontSize=16}}, 
    x={"quintile:o", axis={titleFontSize=16}}, 
    color={"regionname:o", scale={scheme=:category20}, legend=nothing},
    shape={"migtype:n",scale = {range=["triangle-up","circle"]},legend={title = "Migration in/out", titleFontSize=20, symbolSize=80, labelFontSize=16}}
) |> save(joinpath(@__DIR__, "../results/education/", "FigA2.png"))


####################################### Attribute income levels to bilateral migrant flows ########################################
edu_quint = CSV.File(joinpath(@__DIR__,"../input_data/edu_quint.csv")) |> DataFrame
migflow_alldata = CSV.File(joinpath(@__DIR__, "../input_data/ac19.csv")) |> DataFrame          # Use Abel and Cohen (2019)
# From Abel and Cohen's paper, we choose Azose and Raftery's data:based a demographic accounting, pseudo-Bayesian method, which performs the best
migflow_ar = migflow_alldata[:,[:year0, :orig, :dest, :da_pb_closed]]

edu_bil = innerjoin(
    rename(migflow_ar[(migflow_ar[:,:year0].==2010),Not(1)],:da_pb_closed=>:flow), 
    rename(edu_quint[:,union(1:2,4,10)],:country=>:orig,:quintile=>:quint_orig,:ypc_quint=>:ypc_quint_orig),
    on=:orig
)
edu_bil = innerjoin(
    edu_bil, 
    rename(edu_quint[:,union(1:2,5,10)],:country=>:dest,:quintile=>:quint_dest,:ypc_quint=>:ypc_quint_dest),
    on=:dest
)

# Strong assumption: the distribution of emigrants/immigrants among quintile levels is the same for all destinations/origins
edu_bil[!,:flow_quint] = edu_bil[:,:flow] .* edu_bil[:,:outmig_quint] .* edu_bil[:,:inmig_quint]

CSV.write(joinpath(@__DIR__,"../../../results/edu_bil.csv"),edu_bil)


############################################# Calculate income terciles of migrants #######################################
ssp_edu = CSV.File(joinpath(@__DIR__, "../input_data/ssp_edu.csv")) |> DataFrame

edu_level = sort(
    combine(
        d->(pop=mean(d.pop),outmig=mean(d.outmig),inmig=mean(d.inmig),pop_share=mean(d.pop_share),outmig_share=mean(d.outmig_share),inmig_share=mean(d.inmig_share)),
        groupby(
            ssp_edu[(ssp_edu[:,:period].==2015),:],
            [:region,:period,:edu]
        )
    ),[:period,:region,:edu]
)
edu_level[!,:countrynum] = map(x->parse(Int,SubString(x,3)), edu_level[:,:region])
edu_level = innerjoin(edu_level, rename(iso3c_isonum, :iso3c=>:country, :isonum=>:countrynum), on = :countrynum)
sort!(edu_level, [:country, :edu])
countries=unique(edu_level[:,:country])

for name in [:t1,:t2,:t3]
    edu_level[!,name] = zeros(size(edu_level,1))
end
for i in eachindex(edu_level[:1])
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

edu_cross = stack(edu_level,12:14)
rename!(edu_cross, :variable=>:tercile, :value=>:pop_tercile)
sort!(edu_cross, [:country,:edu,:tercile])
edu_cross[!,:outmig_tercile] = edu_cross[:,:pop_tercile] ./ edu_cross[:,:pop_share] .* edu_cross[:,:outmig_share]
edu_cross[!,:inmig_tercile] = edu_cross[:,:pop_tercile] ./ edu_cross[:,:pop_share] .* edu_cross[:,:inmig_share]

edu_terc = combine(d->(pop_terc=sum(d.pop_tercile),outmig_terc=sum(d.outmig_tercile),inmig_terc=sum(d.inmig_tercile)), groupby(edu_cross,[:country,:tercile]))

pop_allvariants = CSV.File(joinpath(@__DIR__, "../input_data/WPP2019.csv")) |> DataFrame
pop = @from i in pop_allvariants begin
    @where i.Variant == "Medium" && i.Time == 2010 
    @select {i.LocID, i.Location, i.PopTotal}
    @collect DataFrame
end
pop = innerjoin(pop, rename(iso3c_isonum,:iso3c=>:country,:isonum=>:LocID), on=:LocID)

gdp_unstacked = XLSX.openxlsx(joinpath(@__DIR__, "../input_data/gdphist.xlsx")) do xf
    DataFrame(XLSX.gettable(xf["data"];first_row=2)...)
end
select!(gdp_unstacked, Not([:Model, Symbol("Scenario (History)"), :Variable, :Unit]))
gdp = stack(gdp_unstacked, 2:size(gdp_unstacked, 2))
rename!(gdp, :variable => :year0, :value => :gdp)
gdp[!,:year0] = map( x -> parse(Int, String(x)), gdp[!,:year0])

edu_terc = innerjoin(edu_terc, rename(pop, :PopTotal=>:pop)[:,3:4], on=:country)
edu_terc = innerjoin(edu_terc, rename(gdp[(gdp[:,:year0].==2010),:],:Region=>:country), on = :country)

gini = CSV.File(joinpath(@__DIR__, "../../../../YSSP-IIASA/data/gini_rao/ssp_ginis.csv")) |> DataFrame
p = range(0, step=1/3, stop=1)     
for t in 1:length(p)-1
    gini[!,Symbol(string("t", t))] = [cdf.(Normal(), quantile.(Normal(), p[t+1]) .- sqrt(2) .* quantile.(Normal(), (gini[!,:gini][i] + 1)/2)) - cdf.(Normal(), quantile.(Normal(), p[t]) .- sqrt(2) .* quantile.(Normal(), (gini[!,:gini][i] + 1)/2)) for i in eachindex(gini[:1])]
end
gini_stack = stack(gini,5:7)
rename!(gini_stack, :variable=>:tercile,:value=>:gdpshare_terc)

edu_terc = innerjoin(edu_terc, rename(gini_stack[.&(gini_stack[:,:year].==2010,gini_stack[:,:scenario].=="SSP2"),:],:iso=>:country)[:,union(2,5:6)], on=[:country,:tercile])

edu_terc[!,:ypc_terc] = edu_terc[:,:gdp] .* 10^9 .* edu_terc[:,:gdpshare_terc] ./ (edu_terc[:,:pop] .* 1000 ./ 5)
edu_terc[!,:ypc_rel] = edu_terc[:,:ypc_terc] ./ (edu_terc[:,:gdp] .* 10^9 ./ (edu_terc[:,:pop] .* 1000))

CSV.write(joinpath(@__DIR__,"../input_data/edu_terc.csv"),edu_terc)

migflow_alldata = CSV.File(joinpath(@__DIR__, "../input_data/ac19.csv")) |> DataFrame
migflow_ar = migflow_alldata[:,[:year0, :orig, :dest, :da_pb_closed]]

edu_bil_terc = innerjoin(
    rename(migflow_ar[(migflow_ar[:,:year0].==2010),Not(1)],:da_pb_closed=>:flow), 
    rename(edu_terc[:,union(1:2,4,10)],:country=>:orig,:tercile=>:terc_orig,:ypc_terc=>:ypc_terc_orig),
    on=:orig
)
edu_bil_terc = innerjoin(
    edu_bil_terc, 
    rename(edu_terc[:,union(1:2,5,10)],:country=>:dest,:tercile=>:terc_dest,:ypc_terc=>:ypc_terc_dest),
    on=:dest
)

edu_bil_terc[!,:flow_terc] = edu_bil_terc[:,:flow] .* edu_bil_terc[:,:outmig_terc] .* edu_bil_terc[:,:inmig_terc]

CSV.write(joinpath(@__DIR__,"../../../results/edu_bil_terc.csv"),edu_bil_terc)