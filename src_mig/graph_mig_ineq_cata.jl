using DelimitedFiles, CSV, VegaLite, FileIO, VegaDatasets, FilePaths
using Statistics, DataFrames, Query, Distributions

using MimiFUND


# Look at catastrophic damages: add term in (T^7) so that global GDP loss = 50% when T=6C 

include("main_mig_nice_cata.jl")


ssps = ["SSP1","SSP2","SSP3","SSP4","SSP5"]
regions = ["USA", "CAN", "WEU", "JPK", "ANZ", "EEU", "FSU", "MDE", "CAM", "LAM", "SAS", "SEA", "CHI", "MAF", "SSA", "SIS"]
years = 2015:2100


################# Compare original FUND model with original scenarios, NICE-FUND with SSP scenarios, and Mig-NICE-FUND with SSP scenarios zero migration #################

# Run models
m_nice_ssp1_cata = getmigrationnicecatamodel(scen="SSP1",migyesno="nomig",xi=1.0,omega=1.0)
m_nice_ssp2_cata = getmigrationnicecatamodel(scen="SSP2",migyesno="nomig",xi=1.0,omega=1.0)
m_nice_ssp3_cata = getmigrationnicecatamodel(scen="SSP3",migyesno="nomig",xi=1.0,omega=1.0)
m_nice_ssp4_cata = getmigrationnicecatamodel(scen="SSP4",migyesno="nomig",xi=1.0,omega=1.0)
m_nice_ssp5_cata = getmigrationnicecatamodel(scen="SSP5",migyesno="nomig",xi=1.0,omega=1.0)

run(m_nice_ssp1_cata;ntimesteps=151)
run(m_nice_ssp2_cata;ntimesteps=151)
run(m_nice_ssp3_cata;ntimesteps=151)
run(m_nice_ssp4_cata;ntimesteps=151)
run(m_nice_ssp5_cata;ntimesteps=151)

m_fund = getfund()
run(m_fund)


############################## Compare migrant flows and population levels in Mig-NICE-FUND for different income elasticities of damages (xi) ######################
# Default is done above: damages within a given region proportional to income (xi=1)

# Damages within a given region independent of income (xi=0)
m_nice_ssp1_cata_xi0 = getmigrationnicecatamodel(scen="SSP1",migyesno="nomig",xi=0.0,omega=1.0)
m_nice_ssp2_cata_xi0 = getmigrationnicecatamodel(scen="SSP2",migyesno="nomig",xi=0.0,omega=1.0)
m_nice_ssp3_cata_xi0 = getmigrationnicecatamodel(scen="SSP3",migyesno="nomig",xi=0.0,omega=1.0)
m_nice_ssp4_cata_xi0 = getmigrationnicecatamodel(scen="SSP4",migyesno="nomig",xi=0.0,omega=1.0)
m_nice_ssp5_cata_xi0 = getmigrationnicecatamodel(scen="SSP5",migyesno="nomig",xi=0.0,omega=1.0)
run(m_nice_ssp1_cata_xi0;ntimesteps=151)
run(m_nice_ssp2_cata_xi0;ntimesteps=151)
run(m_nice_ssp3_cata_xi0;ntimesteps=151)
run(m_nice_ssp4_cata_xi0;ntimesteps=151)
run(m_nice_ssp5_cata_xi0;ntimesteps=151)

# Damages within a given region inversely proportional to income (xi=-1)
m_nice_ssp1_cata_xim1 = getmigrationnicecatamodel(scen="SSP1",migyesno="nomig",xi=-1.0,omega=1.0)
m_nice_ssp2_cata_xim1 = getmigrationnicecatamodel(scen="SSP2",migyesno="nomig",xi=-1.0,omega=1.0)
m_nice_ssp3_cata_xim1 = getmigrationnicecatamodel(scen="SSP3",migyesno="nomig",xi=-1.0,omega=1.0)
m_nice_ssp4_cata_xim1 = getmigrationnicecatamodel(scen="SSP4",migyesno="nomig",xi=-1.0,omega=1.0)
m_nice_ssp5_cata_xim1 = getmigrationnicecatamodel(scen="SSP5",migyesno="nomig",xi=-1.0,omega=1.0)
run(m_nice_ssp1_cata_xim1;ntimesteps=151)
run(m_nice_ssp2_cata_xim1;ntimesteps=151)
run(m_nice_ssp3_cata_xim1;ntimesteps=151)
run(m_nice_ssp4_cata_xim1;ntimesteps=151)
run(m_nice_ssp5_cata_xim1;ntimesteps=151)


years = 1951:2100

migration_cata = DataFrame(
    year = repeat(years, outer = length(ssps)*length(regions)),
    scen = repeat(ssps,inner = length(regions)*length(years)),
    fundregion = repeat(regions, outer = length(ssps), inner=length(years)),
)
enter_cata_xi1 = vcat(
    collect(Iterators.flatten(sum(m_nice_ssp1_cata[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp2_cata[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp3_cata[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp4_cata[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp5_cata[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1]))
)
migration_cata[:,:enter_cata_xi1] = enter_cata_xi1
leave_cata_xi1 = vcat(
    collect(Iterators.flatten(sum(m_nice_ssp1_cata[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp2_cata[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp3_cata[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp4_cata[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp5_cata[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1]))
)
migration_cata[:,:leave_cata_xi1] = leave_cata_xi1
popu_cata_xi1 = vcat(
    collect(Iterators.flatten(m_nice_ssp1_cata[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp2_cata[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp3_cata[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp4_cata[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp5_cata[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
migration_cata[:,:pop_cata_xi1] = popu_cata_xi1

enter_cata_xi0 = vcat(
    collect(Iterators.flatten(sum(m_nice_ssp1_cata_xi0[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp2_cata_xi0[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp3_cata_xi0[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp4_cata_xi0[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp5_cata_xi0[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1]))
)
migration_cata[:,:enter_cata_xi0] = enter_cata_xi0
leave_cata_xi0 = vcat(
    collect(Iterators.flatten(sum(m_nice_ssp1_cata_xi0[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp2_cata_xi0[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp3_cata_xi0[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp4_cata_xi0[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp5_cata_xi0[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1]))
)
migration_cata[:,:leave_cata_xi0] = leave_cata_xi0
popu_cata_xi0 = vcat(
    collect(Iterators.flatten(m_nice_ssp1_cata_xi0[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp2_cata_xi0[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp3_cata_xi0[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp4_cata_xi0[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp5_cata_xi0[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
migration_cata[:,:pop_cata_xi0] = popu_cata_xi0

enter_cata_xim1 = vcat(
    collect(Iterators.flatten(sum(m_nice_ssp1_cata_xim1[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp2_cata_xim1[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp3_cata_xim1[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp4_cata_xim1[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp5_cata_xim1[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1]))
)
migration_cata[:,:enter_cata_xim1] = enter_cata_xim1
leave_cata_xim1 = vcat(
    collect(Iterators.flatten(sum(m_nice_ssp1_cata_xim1[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp2_cata_xim1[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp3_cata_xim1[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp4_cata_xim1[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp5_cata_xim1[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1]))
)
migration_cata[:,:leave_cata_xim1] = leave_cata_xim1
popu_cata_xim1 = vcat(
    collect(Iterators.flatten(m_nice_ssp1_cata_xim1[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp2_cata_xim1[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp3_cata_xim1[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp4_cata_xim1[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp5_cata_xim1[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
migration_cata[:,:pop_cata_xim1] = popu_cata_xim1

# Look at emigrants without residual from gravity (residual same for all SSP, xi, CC or not)
migration_cata[!,:leave_cata_gravres] = repeat(sum(m_nice_ssp2_cata[:migration,:gravres_qi],dims=[2,3,4])[:,1,1,1],inner=length(1951:2100),outer=length(ssps))

migration_cata_p = migration_cata[(map(x->mod(x,10)==0,migration_cata[:,:year])),:]

pop_cata_all = stack(
    rename(migration_cata, :pop_cata_xi1 => :pop_cata_damageprop, :pop_cata_xi0 => :pop_cata_damageindep, :pop_cata_xim1 => :pop_cata_damageinvprop), 
    [:pop_cata_damageprop,:pop_cata_damageindep,:pop_cata_damageinvprop], 
    [:scen, :fundregion, :year]
)
rename!(pop_cata_all, :variable => :pop_type, :value => :pop)
for s in ssps
    pop_cata_all |> @filter(_.year >= 2015 && _.year <= 2100 && _.scen == s) |> @vlplot(
        mark={:line, strokeWidth = 4}, width=300, height=250, columns=4, wrap="fundregion:o", 
        x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
        y={"pop:q", title = nothing, axis={labelFontSize=16}},
        color={"pop_type:o",scale={scheme=:darkmulti},legend={titleFontSize=16, symbolSize=40, labelFontSize=16}},
        resolve = {scale={y=:independent}}
    ) |> save(joinpath(@__DIR__, "../results/migflow_ineq/", string("pop_cata_",s,"_v5.png")))
end
pop_cata_all[!,:scen_pop_type] = [string(pop_cata_all[i,:scen],"_",SubString(string(pop_cata_all[i,:pop_type]),4)) for i in 1:size(pop_cata_all,1)]
pop_cata_all |> @filter(_.year >= 2015 && _.year <= 2100) |> @vlplot(
    mark={:line, strokeWidth = 4}, width=300, height=250, columns=4, wrap="fundregion:o", 
    x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
    y={"pop:q", title = nothing, axis={labelFontSize=16}},
    title = "Income per capita for world regions, SSP narratives and various income elasticities of damages",
    color={"scen_pop_type:o",scale={scheme=:category20c},legend={titleFontSize=16, symbolSize=40, labelFontSize=16}},
    resolve = {scale={y=:independent}}
) |> save(joinpath(@__DIR__, "../results/migflow_ineq/", string("pop_cata_v5.png")))


worldpop_cata = DataFrame(
    year = repeat(years, outer = length(ssps)),
    scen = repeat(ssps,inner = length(years)),
)
worldpop_cata_migniceFUND = vcat(
    collect(Iterators.flatten(m_nice_ssp1_cata[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_nice_ssp2_cata[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_nice_ssp3_cata[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_nice_ssp4_cata[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_nice_ssp5_cata[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)]))
)
worldpop_cata[:,:worldpop_cata_migniceFUND] = worldpop_cata_migniceFUND
worldpop_cata_xi1 = vcat(
    collect(Iterators.flatten(m_nice_ssp1_cata[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_nice_ssp2_cata[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_nice_ssp3_cata[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_nice_ssp4_cata[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_nice_ssp5_cata[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)]))
)
worldpop_cata[:,:worldpop_cata_xi1] = worldpop_cata_xi1
worldpop_cata_xi0 = vcat(
    collect(Iterators.flatten(m_nice_ssp1_cata_xi0[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_nice_ssp2_cata_xi0[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_nice_ssp3_cata_xi0[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_nice_ssp4_cata_xi0[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_nice_ssp5_cata_xi0[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)]))
)
worldpop_cata[:,:worldpop_cata_xi0] = worldpop_cata_xi0
worldpop_cata_xim1 = vcat(
    collect(Iterators.flatten(m_nice_ssp1_cata_xim1[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_nice_ssp2_cata_xim1[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_nice_ssp3_cata_xim1[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_nice_ssp4_cata_xim1[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_nice_ssp5_cata_xim1[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)]))
)
worldpop_cata[:,:worldpop_cata_xim1] = worldpop_cata_xim1

worldpop_cata_p = worldpop_cata[(map(x->mod(x,10)==0,worldpop_cata[:,:year])),:]

worldpop_cata_stack = stack(worldpop_cata_p,[:worldpop_cata_xi1,:worldpop_cata_xi0,:worldpop_cata_xim1],[:scen,:year])
rename!(worldpop_cata_stack,:variable => :worldpop_cata_type, :value => :worldpop_cata)
worldpop_cata_stack |> @filter(_.year >= 2015 && _.year <= 2100) |> @vlplot(
    width=300, height=250,
    mark={:point, size=50}, x = {"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing}, y = {"worldpop_cata:q", title=nothing, axis={labelFontSize=16}}, 
    title = "Global population for Mig-NICE-FUND with various income elasticities of damages", 
    color = {"scen:n", scale={scheme=:category10}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}, 
    shape = {"worldpop_cata_type:o", scale={range=["circle", "triangle-up", "square"]}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}
) + @vlplot(
    mark={:line, strokeDash=[1,2]}, x = {"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing}, y = {"worldpop_cata:q", aggregate=:mean,type=:quantitative,title=nothing, axis={labelFontSize=16}}, 
    color = {"scen:n", scale={scheme=:category10}},
    detail = "worldpop_cata_type:o"
) |> save(joinpath(@__DIR__, "../results/migflow_ineq/", "pop_cata_world_xi_v5.png"))


migration_cata_quint = DataFrame(
    year = repeat(years, outer = length(ssps)*length(regions)*5),
    scen = repeat(ssps,inner = length(regions)*length(years)*5),
    fundregion = repeat(regions, outer = length(ssps)*5, inner=length(years)),
    quintile = repeat(1:5, outer = length(ssps), inner=length(years)*length(regions))
)
enter_cata_quint_xi1 = vcat(
    collect(Iterators.flatten(m_nice_ssp1_cata[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp2_cata[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp3_cata[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp4_cata[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp5_cata[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))
)
migration_cata_quint[:,:enter_cata_quint_xi1] = enter_cata_quint_xi1
leave_cata_quint_xi1 = vcat(
    collect(Iterators.flatten(m_nice_ssp1_cata[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp2_cata[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp3_cata[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp4_cata[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp5_cata[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))
)
migration_cata_quint[:,:leave_cata_quint_xi1] = leave_cata_quint_xi1

enter_cata_quint_xi0 = vcat(
    collect(Iterators.flatten(m_nice_ssp1_cata_xi0[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp2_cata_xi0[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp3_cata_xi0[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp4_cata_xi0[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp5_cata_xi0[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))
)
migration_cata_quint[:,:enter_cata_quint_xi0] = enter_cata_quint_xi0
leave_cata_quint_xi0 = vcat(
    collect(Iterators.flatten(m_nice_ssp1_cata_xi0[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp2_cata_xi0[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp3_cata_xi0[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp4_cata_xi0[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp5_cata_xi0[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))
)
migration_cata_quint[:,:leave_cata_quint_xi0] = leave_cata_quint_xi0

enter_cata_quint_xim1 = vcat(
    collect(Iterators.flatten(m_nice_ssp1_cata_xim1[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp2_cata_xim1[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp3_cata_xim1[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp4_cata_xim1[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp5_cata_xim1[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))
)
migration_cata_quint[:,:enter_cata_quint_xim1] = enter_cata_quint_xim1
leave_cata_quint_xim1 = vcat(
    collect(Iterators.flatten(m_nice_ssp1_cata_xim1[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp2_cata_xim1[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp3_cata_xim1[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp4_cata_xim1[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp5_cata_xim1[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))
)
migration_cata_quint[:,:leave_cata_quint_xim1] = leave_cata_quint_xim1

# Look at emigrants without residual from gravity (residual same for all SSP, xi, CC or not)
migration_cata_quint[!,:leave_cata_quint_gravres] = repeat(collect(Iterators.flatten(sum(m_nice_ssp2_cata[:migration,:gravres_qi],dims=[2,4])[:,1,:,1])),inner=length(1951:2100),outer=length(ssps))

migration_cata_quint_p = migration_cata_quint[(map(x->mod(x,10)==0,migration_cata_quint[:,:year])),:]

leave_cata_quint = stack(
    rename(migration_cata_quint_p, :leave_cata_quint_xi1 => :leave_cata_quint_damageprop, :leave_cata_quint_xi0 => :leave_cata_quint_damageindep, :leave_cata_quint_xim1 => :leave_cata_quint_damageinvprop), 
    [:leave_cata_quint_damageprop,:leave_cata_quint_damageindep,:leave_cata_quint_damageinvprop], 
    [:scen, :quintile ,:fundregion, :year]
)
rename!(leave_cata_quint, :variable => :leave_type, :value => :leave_cata_quint)
for s in ssps
    leave_cata_quint |> @filter(_.year >= 2015 && _.year <= 2100 && _.scen == s) |> @vlplot(
        mark={:point,size=60}, width=300, height=250, columns=4, wrap="fundregion:o", 
        x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
        y={"leave_cata_quint:q", title = nothing, axis={labelFontSize=16}},
        color={"quintile:o",scale={scheme=:darkmulti},legend={titleFontSize=16, symbolSize=40, labelFontSize=16}},
        shape={"leave_type:o",legend={titleFontSize=16, symbolSize=40, labelFontSize=16}},
        resolve = {scale={y=:independent}}
    ) |> save(joinpath(@__DIR__, "../results/migflow_ineq/", string("leave_cata_quint_",s,"_v5.png")))
end

migration_cata_quint = innerjoin(migration_cata_quint, migration_cata[:,[:year,:scen,:fundregion,:leave_cata_xi1,:leave_cata_xi0,:leave_cata_xim1]], on=[:scen,:year,:fundregion])
migration_cata_quint[!,:leave_cata_share_xi1] = migration_cata_quint[:,:leave_cata_quint_xi1] ./ migration_cata_quint[:,:leave_cata_xi1]
migration_cata_quint[!,:leave_cata_share_xi0] = migration_cata_quint[:,:leave_cata_quint_xi0] ./ migration_cata_quint[:,:leave_cata_xi0]
migration_cata_quint[!,:leave_cata_share_xim1] = migration_cata_quint[:,:leave_cata_quint_xim1] ./ migration_cata_quint[:,:leave_cata_xim1]
for i in 1:size(migration_cata_quint, 1)
    if migration_cata_quint[i,:leave_cata_xi1] == 0.0 ; migration_cata_quint[i,:leave_cata_share_xi1] = 0.0 end
    if migration_cata_quint[i,:leave_cata_xi0] == 0.0 ; migration_cata_quint[i,:leave_cata_share_xi0] = 0.0 end
    if migration_cata_quint[i,:leave_cata_xim1] == 0.0 ; migration_cata_quint[i,:leave_cata_share_xim1] = 0.0 end
end

migration_cata_quint_p = migration_cata_quint[(map(x->mod(x,10)==0,migration_cata_quint[:,:year])),:]

leave_cata_share = stack(
    rename(migration_cata_quint_p, :leave_cata_share_xi1 => :leave_cata_share_damageprop,:leave_cata_share_xi0 => :leave_cata_share_damageindep, :leave_cata_share_xim1 => :leave_cata_share_damageinvprop), 
    [:leave_cata_share_damageprop,:leave_cata_share_damageindep,:leave_cata_share_damageinvprop], 
    [:scen, :quintile ,:fundregion, :year]
)
rename!(leave_cata_share, :variable => :leave_cata_share_type, :value => :leave_cata_share)
for s in ssps
    leave_cata_share |> @filter(_.year >= 2015 && _.year <= 2100 && _.scen == s) |> @vlplot(
        mark={:point,size=60}, width=300, height=250, columns=4, wrap="fundregion:o", 
        x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
        y={"leave_cata_share:q", title = nothing, axis={labelFontSize=16}},
        color={"quintile:o",scale={scheme=:darkmulti},legend={titleFontSize=16, symbolSize=40, labelFontSize=16}},
        shape={"leave_cata_share_type:o",legend={titleFontSize=16, symbolSize=40, labelFontSize=16}},
        resolve = {scale={y=:independent}}
    ) |> save(joinpath(@__DIR__, "../results/migflow_ineq/", string("leave_cata_share_",s,"_v5.png")))
end


#################################### Look at net migrant flows for different income elasticities of damages ######################################
migration_cata[!,:netmig_cata_damageprop] = migration_cata[!,:enter_cata_xi1] .- migration_cata[!,:leave_cata_xi1]
migration_cata[!,:netmig_cata_damageindep] = migration_cata[!,:enter_cata_xi0] .- migration_cata[!,:leave_cata_xi0]
migration_cata[!,:netmig_cata_damageinvprop] = migration_cata[!,:enter_cata_xim1] .- migration_cata[!,:leave_cata_xim1]

netmig_cata_all = stack(
    migration_cata, 
    [:netmig_cata_damageprop,:netmig_cata_damageindep,:netmig_cata_damageinvprop], 
    [:scen, :fundregion, :year]
)
rename!(netmig_cata_all, :variable => :netmig_type, :value => :netmig)
regions_fullname = DataFrame(
    fundregion=regions,
    regionname = [
        "United States (USA)",
        "Canada (CAN)",
        "Western Europe (WEU)",
        "Japan & South Korea (JPK)",
        "Australia & New Zealand (ANZ)",
        "Central & Eastern Europe (EEU)",
        "Former Soviet Union (FSU)",
        "Middle East (MDE)",
        "Central America (CAM)",
        "South America (LAM)",
        "South Asia (SAS)",
        "Southeast Asia (SEA)",
        "China plus (CHI)",
        "North Africa (MAF)",
        "Sub-Saharan Africa (SSA)",
        "Small Island States (SIS)"
    ]
)
netmig_cata_all = innerjoin(netmig_cata_all,regions_fullname, on=:fundregion)

for s in ssps
    netmig_cata_all |> @filter(_.year >= 2015 && _.year <= 2100 && _.scen == s) |> @vlplot(
        mark={:line, strokeWidth = 4}, width=300, height=250, columns=4, wrap={"regionname:o", title=nothing, header={labelFontSize=24}}, 
        x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
        y={"netmig:q", title = "Net migrants", axis={labelFontSize=16,titleFontSize=16}},
        color={"netmig_type:o",scale={scheme=:darkmulti},legend={title=string("Net migration, ",s), titleFontSize=20, titleLimit=220, symbolSize=60, labelFontSize=24, labelLimit=280, offset=2}},
        resolve = {scale={y=:independent}}
    ) |> save(joinpath(@__DIR__, "../results/migflow_ineq/", string("netmig_cata_",s,"_v5.png")))
end
netmig_cata_all[!,:scen_netmig_type] = [string(netmig_cata_all[i,:scen],"_",SubString(string(netmig_cata_all[i,:netmig_type]),8)) for i in 1:size(netmig_cata_all,1)]
netmig_cata_all |> @filter(_.year >= 2015 && _.year <= 2100) |> @vlplot(
    mark={:line, strokeWidth = 4}, width=300, height=250, columns=4, wrap="fundregion:o", 
    x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
    y={"netmig:q", title = nothing, axis={labelFontSize=16}},
    title = "Net migration flows for world regions, SSP narratives and various income elasticities of damages",
    color={"scen_netmig_type:o",scale={scheme=:category20c},legend={titleFontSize=16, symbolSize=40, labelFontSize=16}},
    resolve = {scale={y=:independent}}
) |> save(joinpath(@__DIR__, "../results/migflow_ineq/", string("netmig_cata_v5.png")))

mig_cata_all = stack(
    rename(migration_cata, :enter_cata_xi1 => :enter_cata_damageprop, :enter_cata_xi0 => :enter_cata_damageindep, :enter_cata_xim1 => :enter_cata_damageinvprop, :leave_cata_xi1 => :leave_cata_damageprop, :leave_cata_xi0 => :leave_cata_damageindep, :leave_cata_xim1 => :leave_cata_damageinvprop), 
    [:enter_cata_damageprop, :enter_cata_damageindep, :enter_cata_damageinvprop, :leave_cata_damageprop, :leave_cata_damageindep, :leave_cata_damageinvprop], 
    [:scen, :fundregion, :year]
)
rename!(mig_cata_all, :variable => :mig_type, :value => :mig)
mig_cata_all[!,:mig] = [in(mig_cata_all[i,:mig_type], [:leave_cata_damageprop,:leave_cata_damageindep,:leave_cata_damageinvprop]) ? mig_cata_all[i,:mig] * (-1) : mig_cata_all[i,:mig] for i in 1:size(mig_cata_all,1)]
mig_cata_all = innerjoin(mig_cata_all,regions_fullname, on=:fundregion)
for s in ssps
    mig_cata_all |> @filter(_.year >= 2015 && _.year <= 2100 && _.scen == s) |> @vlplot(
        mark={:line, strokeWidth = 4}, width=300, height=250, columns=4, wrap={"regionname:o", title=nothing, header={labelFontSize=24}}, 
        x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
        y={"mig:q", title = nothing, axis={labelFontSize=16}},
        color={"mig_type:o",scale={scheme="category20c"},legend={title=nothing, symbolSize=60, labelFontSize=20, labelLimit=220,}},
        resolve = {scale={y=:independent}}
    ) |> save(joinpath(@__DIR__, "../results/migflow_ineq/", string("mig_cata_",s,"_v5.png")))
end


############################################# Plot heat tables of migrant flows in 2100 ############################################################
move_cata = DataFrame(
    year = repeat(years, outer = length(ssps)*length(regions)*length(regions)),
    scen = repeat(ssps,inner = length(regions)*length(years)*length(regions)),
    origin = repeat(regions, outer = length(ssps)*length(regions), inner=length(years)),
    destination = repeat(regions, outer = length(ssps), inner=length(years)*length(regions))
)

move_cata_xi1 = vcat(
    collect(Iterators.flatten(sum(m_nice_ssp1_cata[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:,:,:],dims=[4,5])[:,:,:,1,1])),
    collect(Iterators.flatten(sum(m_nice_ssp2_cata[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:,:,:],dims=[4,5])[:,:,:,1,1])),
    collect(Iterators.flatten(sum(m_nice_ssp3_cata[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:,:,:],dims=[4,5])[:,:,:,1,1])),
    collect(Iterators.flatten(sum(m_nice_ssp4_cata[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:,:,:],dims=[4,5])[:,:,:,1,1])),
    collect(Iterators.flatten(sum(m_nice_ssp5_cata[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:,:,:],dims=[4,5])[:,:,:,1,1]))
)
move_cata[:,:move_cata_xi1] = move_cata_xi1
move_cata_xi0 = vcat(
    collect(Iterators.flatten(sum(m_nice_ssp1_cata_xi0[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:,:,:],dims=[4,5])[:,:,:,1,1])),
    collect(Iterators.flatten(sum(m_nice_ssp2_cata_xi0[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:,:,:],dims=[4,5])[:,:,:,1,1])),
    collect(Iterators.flatten(sum(m_nice_ssp3_cata_xi0[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:,:,:],dims=[4,5])[:,:,:,1,1])),
    collect(Iterators.flatten(sum(m_nice_ssp4_cata_xi0[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:,:,:],dims=[4,5])[:,:,:,1,1])),
    collect(Iterators.flatten(sum(m_nice_ssp5_cata_xi0[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:,:,:],dims=[4,5])[:,:,:,1,1]))
)
move_cata[:,:move_cata_xi0] = move_cata_xi0
move_cata_xim1 = vcat(
    collect(Iterators.flatten(sum(m_nice_ssp1_cata_xim1[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:,:,:],dims=[4,5])[:,:,:,1,1])),
    collect(Iterators.flatten(sum(m_nice_ssp2_cata_xim1[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:,:,:],dims=[4,5])[:,:,:,1,1])),
    collect(Iterators.flatten(sum(m_nice_ssp3_cata_xim1[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:,:,:],dims=[4,5])[:,:,:,1,1])),
    collect(Iterators.flatten(sum(m_nice_ssp4_cata_xim1[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:,:,:],dims=[4,5])[:,:,:,1,1])),
    collect(Iterators.flatten(sum(m_nice_ssp5_cata_xim1[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:,:,:],dims=[4,5])[:,:,:,1,1]))
)
move_cata[:,:move_cata_xim1] = move_cata_xim1

move_cata = innerjoin(
    move_cata, 
    rename(
        migration_cata, 
        :fundregion => :origin, 
        :leave_cata_xi1 => :leave_or_xi1, 
        :pop_cata_xi1 => :pop_or_xi1, 
        :leave_cata_xi0 => :leave_or_xi0, 
        :pop_cata_xi0 => :pop_or_xi0, 
        :leave_cata_xim1 => :leave_or_xim1, 
        :pop_cata_xim1 => :pop_or_xim1
    )[:,[:year,:scen,:origin,:leave_or_xi1,:pop_or_xi1,:leave_or_xi0,:pop_or_xi0,:leave_or_xim1,:pop_or_xim1]],
    on = [:year,:scen,:origin]
)
move_cata = innerjoin(
    move_cata, 
    rename(
        migration_cata, 
        :fundregion => :destination, 
        :enter_cata_xi1 => :enter_dest_xi1, 
        :pop_cata_xi1 => :pop_dest_xi1, 
        :enter_cata_xi0 => :enter_dest_xi0, 
        :pop_cata_xi0 => :pop_dest_xi0, 
        :enter_cata_xim1 => :enter_dest_xim1, 
        :pop_cata_xim1 => :pop_dest_xim1
    )[:,[:year,:scen,:destination,:enter_dest_xi1,:pop_dest_xi1,:enter_dest_xi0,:pop_dest_xi0,:enter_dest_xim1,:pop_dest_xim1]],
    on = [:year,:scen,:destination]
)

move_cata[:,:migshare_or_xi1] = move_cata[:,:move_cata_xi1] ./ move_cata[:,:leave_or_xi1]
move_cata[:,:migshare_or_xi0] = move_cata[:,:move_cata_xi0] ./ move_cata[:,:leave_or_xi0]
move_cata[:,:migshare_or_xim1] = move_cata[:,:move_cata_xim1] ./ move_cata[:,:leave_or_xim1]
move_cata[:,:migshare_dest_xi1] = move_cata[:,:move_cata_xi1] ./ move_cata[:,:enter_dest_xi1]
move_cata[:,:migshare_dest_xi0] = move_cata[:,:move_cata_xi0] ./ move_cata[:,:enter_dest_xi0]
move_cata[:,:migshare_dest_xim1] = move_cata[:,:move_cata_xim1] ./ move_cata[:,:enter_dest_xim1]
for i in 1:size(move_cata,1)
    if move_cata[i,:leave_or_xi1] == 0 ; move_cata[i,:migshare_or_xi1] = 0 end
    if move_cata[i,:leave_or_xi0] == 0 ; move_cata[i,:migshare_or_xi0] = 0 end
    if move_cata[i,:leave_or_xim1] == 0 ; move_cata[i,:migshare_or_xim1] = 0 end
    if move_cata[i,:enter_dest_xi1] == 0 ; move_cata[i,:migshare_dest_xi1] = 0 end
    if move_cata[i,:enter_dest_xi0] == 0 ; move_cata[i,:migshare_dest_xi0] = 0 end
    if move_cata[i,:enter_dest_xim1] == 0 ; move_cata[i,:migshare_dest_xim1] = 0 end
end

move_cata |> @filter(_.year == 2100) |> @vlplot(
    :rect, y="origin:n", x="destination:n", column = {"scen:o", axis={labelFontSize=16}, title=nothing},
    color={"move_cata_xi1:q", scale={domain=[0,2*10^5], scheme=:goldred}},title = string("Damages proportional to income, 2100")
) |> save(joinpath(@__DIR__, "../results/migflow_ineq/", string("migflow_cata_xi1_v5.png")))
move_cata |> @filter(_.year == 2100) |> @vlplot(
    :rect, y=:origin, x=:destination, column = {"scen:o", axis={labelFontSize=16}, title=nothing},
    color={"migshare_or_xi1:q", scale={domain=[0,1], scheme=:goldred}},title = string("Damages proportional to income, 2100")
) |> save(joinpath(@__DIR__, "../results/migflow_ineq/", string("migflow_cata_share_or_xi1_v5.png")))
move_cata |> @filter(_.year == 2100) |> @vlplot(
    :rect, y=:origin, x=:destination, column = {"scen:o", axis={labelFontSize=16}, title=nothing},
    color={"migshare_dest_xi1:q", scale={domain=[0,1], scheme=:goldred}},title = string("Damages proportional to income, 2100")
) |> save(joinpath(@__DIR__, "../results/migflow_ineq/", string("migflow_cata_share_dest_xi1_v5.png")))
move_cata |> @filter(_.year == 2100) |> @vlplot(
    :rect, y=:origin, x=:destination, column = {"scen:o", axis={labelFontSize=16}, title=nothing},
    color={"move_cata_xi0:q", scale={domain=[0,2*10^5], scheme=:goldred}},title = string("Damages independent of income, 2100")
) |> save(joinpath(@__DIR__, "../results/migflow_ineq/", string("migflow_cata_xi0_v5.png")))
move_cata |> @filter(_.year == 2100) |> @vlplot(
    :rect, y=:origin, x=:destination, column = {"scen:o", axis={labelFontSize=16}, title=nothing},
    color={"migshare_or_xi0:q", scale={domain=[0,1], scheme=:goldred}},title = string("Damages independent of income, 2100")
) |> save(joinpath(@__DIR__, "../results/migflow_ineq/", string("migflow_cata_share_or_xi0_v5.png")))
move_cata |> @filter(_.year == 2100) |> @vlplot(
    :rect, y=:origin, x=:destination, column = {"scen:o", axis={labelFontSize=16}, title=nothing},
    color={"migshare_dest_xi0:q", scale={domain=[0,1], scheme=:goldred}},title = string("Damages independent of income, 2100")
) |> save(joinpath(@__DIR__, "../results/migflow_ineq/", string("migflow_cata_share_dest_xi0_v5.png")))
move_cata |> @filter(_.year == 2100) |> @vlplot(
    :rect, y=:origin, x=:destination, column = {"scen:o", axis={labelFontSize=16}, title=nothing},
    color={"move_cata_xim1:q", scale={domain=[0,2*10^5], scheme=:goldred}},title = string("Damages inversely proportional to income, 2100")
) |> save(joinpath(@__DIR__, "../results/migflow_ineq/", string("migflow_cata_xim1_v5.png")))
move_cata |> @filter(_.year == 2100) |> @vlplot(
    :rect, y=:origin, x=:destination, column = {"scen:o", axis={labelFontSize=16}, title=nothing},
    color={"migshare_or_xim1:q", scale={domain=[0,1], scheme=:goldred}},title = string("Damages inversely proportional to income, 2100")
) |> save(joinpath(@__DIR__, "../results/migflow_ineq/", string("migflow_cata_share_or_xim1_v5.png")))
move_cata |> @filter(_.year == 2100) |> @vlplot(
    :rect, y=:origin, x=:destination, column = {"scen:o", axis={labelFontSize=16}, title=nothing},
    color={"migshare_dest_xim1:q", scale={domain=[0,1], scheme=:goldred}},title = string("Damages inversely proportional to income, 2100")
) |> save(joinpath(@__DIR__, "../results/migflow_ineq/", string("migflow_cata_share_dest_xim1_v5.png")))


###################################### Plot geographical maps #####################################
world110m = dataset("world-110m")

isonum_fundregion = CSV.read(joinpath(@__DIR__,"../input_data/isonum_fundregion.csv"), DataFrame)
migration_cata_maps = leftjoin(migration_cata, isonum_fundregion, on = :fundregion)
migration_cata_maps[!,:popdiff_xi0] = migration_cata_maps[!,:pop_cata_xi0] ./ migration_cata_maps[!,:pop_cata_xi1] .- 1
migration_cata_maps[!,:popdiff_xim1] = migration_cata_maps[!,:pop_cata_xim1] ./ migration_cata_maps[!,:pop_cata_xi1] .- 1

for s in ssps
    @vlplot(width=800, height=600) + @vlplot(mark={:geoshape, stroke = :lightgray}, 
        data={values=world110m, format={type=:topojson, feature=:countries}}, 
        transform = [{lookup=:id, from={data=filter(row -> row[:scen] == s && row[:year] == 2100, migration_cata_maps), key=:isonum, fields=[string(:pop_cata_xi1)]}}],
        projection={type=:naturalEarth1}, #title = {text=string("Population levels by 2100 for Damages proportional to income, ", s),fontSize=20}, 
        color = {:pop_cata_xi1, type=:quantitative, scale={scheme=:blues}, legend={title=nothing, symbolSize=40, labelFontSize=16}}
    ) |> save(joinpath(@__DIR__, "../results/world_maps_ineq/", string("pop_cata_xi1_", s, "_v5.png")))
end
for s in ssps
    @vlplot(width=800, height=600) + @vlplot(mark={:geoshape, stroke = :lightgray}, 
        data={values=world110m, format={type=:topojson, feature=:countries}}, 
        transform = [{lookup=:id, from={data=filter(row -> row[:scen] == s && row[:year] == 2100, migration_cata_maps), key=:isonum, fields=[string(:popdiff,:_xi0)]}}],
        projection={type=:naturalEarth1}, #title = {text=string("Relative changes in population by 2100 for closed vs Damages proportional to income, ", s),fontSize=20}, 
        color = {Symbol(string(:popdiff,:_xi0)), type=:quantitative, scale={domain=[-0.05,0.05], scheme=:redblue}, legend={title=nothing, symbolSize=40, labelFontSize=16}}
    ) |> save(joinpath(@__DIR__, "../results/world_maps_ineq/", string("popdiff_cata_",:_xi0,"_", s, "_v5.png")))
end
for s in ssps
    @vlplot(width=800, height=600) + @vlplot(mark={:geoshape, stroke = :lightgray}, 
        data={values=world110m, format={type=:topojson, feature=:countries}}, 
        transform = [{lookup=:id, from={data=filter(row -> row[:scen] == s && row[:year] == 2100, migration_cata_maps), key=:isonum, fields=[string(:popdiff,:_xim1)]}}],
        projection={type=:naturalEarth1}, #title = {text=string("Relative changes in population by 2100 for more open vs Damages proportional to income, ", s),fontSize=20}, 
        color = {Symbol(string(:popdiff,:_xim1)), type=:quantitative, scale={domain=[-0.05,0.05], scheme=:redblue}, legend={title=nothing, symbolSize=40, labelFontSize=16}}
    ) |> save(joinpath(@__DIR__, "../results/world_maps_ineq/", string("popdiff_cata_",:_xim1,"_", s, "_v5.png")))
end


################################################ Compare to without climate change ##################################
# Look at net migrant flows for different income elasticities of damages
migration_cata_nocc = migration_cata[:,[:year, :scen, :fundregion, :leave_cata_xi1, :leave_cata_xi0, :leave_cata_xim1, :leave_cata_gravres, :netmig_cata_damageprop, :netmig_cata_damageindep, :netmig_cata_damageinvprop]]

enter_cata_nocc_xi1 = vcat(
    collect(Iterators.flatten(sum(m_nice_ssp1_nocc[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp2_nocc[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp3_nocc[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp4_nocc[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp5_nocc[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1]))
)
migration_cata_nocc[:,:enter_cata_nocc_xi1] = enter_cata_nocc_xi1
leave_cata_nocc_xi1 = vcat(
    collect(Iterators.flatten(sum(m_nice_ssp1_nocc[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp2_nocc[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp3_nocc[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp4_nocc[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp5_nocc[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1]))
)
migration_cata_nocc[:,:leave_cata_nocc_xi1] = leave_cata_nocc_xi1

enter_cata_nocc_xi0 = vcat(
    collect(Iterators.flatten(sum(m_nice_ssp1_nocc_xi0[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp2_nocc_xi0[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp3_nocc_xi0[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp4_nocc_xi0[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp5_nocc_xi0[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1]))
)
migration_cata_nocc[:,:enter_cata_nocc_xi0] = enter_cata_nocc_xi0
leave_cata_nocc_xi0 = vcat(
    collect(Iterators.flatten(sum(m_nice_ssp1_nocc_xi0[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp2_nocc_xi0[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp3_nocc_xi0[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp4_nocc_xi0[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp5_nocc_xi0[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1]))
)
migration_cata_nocc[:,:leave_cata_nocc_xi0] = leave_cata_nocc_xi0

enter_cata_nocc_xim1 = vcat(
    collect(Iterators.flatten(sum(m_nice_ssp1_nocc_xim1[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp2_nocc_xim1[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp3_nocc_xim1[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp4_nocc_xim1[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp5_nocc_xim1[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1]))
)
migration_cata_nocc[:,:enter_cata_nocc_xim1] = enter_cata_nocc_xim1
leave_cata_nocc_xim1 = vcat(
    collect(Iterators.flatten(sum(m_nice_ssp1_nocc_xim1[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp2_nocc_xim1[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp3_nocc_xim1[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp4_nocc_xim1[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp5_nocc_xim1[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1]))
)
migration_cata_nocc[:,:leave_cata_nocc_xim1] = leave_cata_nocc_xim1

migration_cata_nocc[!,:netmig_cata_nocc_damageprop] = migration_cata_nocc[!,:enter_cata_nocc_xi1] .- migration_cata_nocc[!,:leave_cata_nocc_xi1]
migration_cata_nocc[!,:netmig_cata_nocc_damageindep] = migration_cata_nocc[!,:enter_cata_nocc_xi0] .- migration_cata_nocc[!,:leave_cata_nocc_xi0]
migration_cata_nocc[!,:netmig_cata_nocc_damageinvprop] = migration_cata_nocc[!,:enter_cata_nocc_xim1] .- migration_cata_nocc[!,:leave_cata_nocc_xim1]

migration_cata_nocc[!,:leave_cata_nores_xi1] = migration_cata_nocc[:,:leave_cata_xi1] - migration_cata_nocc[:,:leave_cata_gravres]
migration_cata_nocc[!,:leave_cata_nores_xi0] = migration_cata_nocc[:,:leave_cata_xi0] - migration_cata_nocc[:,:leave_cata_gravres]
migration_cata_nocc[!,:leave_cata_nores_xim1] = migration_cata_nocc[:,:leave_cata_xim1] - migration_cata_nocc[:,:leave_cata_gravres]
migration_cata_nocc[!,:leave_cata_nocc_nores_xi1] = migration_cata_nocc[:,:leave_cata_nocc_xi1] - migration_cata_nocc[:,:leave_cata_gravres]
migration_cata_nocc[!,:leave_cata_nocc_nores_xi0] = migration_cata_nocc[:,:leave_cata_nocc_xi0] - migration_cata_nocc[:,:leave_cata_gravres]
migration_cata_nocc[!,:leave_cata_nocc_nores_xim1] = migration_cata_nocc[:,:leave_cata_nocc_xim1] - migration_cata_nocc[:,:leave_cata_gravres]

# Plot both net migration with and without climate change
netmig_cata_nocc_all = rename(stack(
    migration_cata_nocc, 
    [:netmig_cata_damageprop,:netmig_cata_damageindep,:netmig_cata_damageinvprop,:netmig_cata_nocc_damageprop,:netmig_cata_nocc_damageindep,:netmig_cata_nocc_damageinvprop], 
    [:scen, :fundregion, :year]
), :variable => :netmig_type, :value => :netmig)
netmig_cata_nocc_all[!,:xi] = [(netmig_cata_nocc_all[i,:netmig_type] == Symbol("netmig_cata_damageprop") || netmig_cata_nocc_all[i,:netmig_type] == Symbol("netmig_cata_nocc_damageprop")) ? "damageprop" : ((netmig_cata_nocc_all[i,:netmig_type] == Symbol("netmig_cata_damageindep") || netmig_cata_nocc_all[i,:netmig_type] == Symbol("netmig_cata_nocc_damageindep")) ? "damageindep" : "damageinvprop") for i in 1:size(netmig_cata_nocc_all,1)]
netmig_cata_nocc_all[!,:ccornot] = [(SubString(String(netmig_cata_nocc_all[i,:netmig_type]), 1:11) == "netmig_cata_nocc") ? "nocc" : "cc" for i in 1:size(netmig_cata_nocc_all,1)] 
netmig_cata_nocc_all = innerjoin(netmig_cata_nocc_all,regions_fullname, on=:fundregion)
for s in ssps
    netmig_cata_nocc_all[(map(x->mod(x,10)==0,netmig_cata_nocc_all[:,:year])),:] |> @filter(_.year >= 2015 && _.year <= 2100 && _.scen == s) |> @vlplot(
        mark={:point, size = 50}, columns=4, wrap={"regionname:o", title=nothing, header={labelFontSize=24}}, 
        x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
        y={"netmig:q", title = nothing, axis={labelFontSize=16}},
        color={"xi:o",scale={scheme=:darkmulti},legend={title=string("Net migration, ",s), titleFontSize=20, titleLimit=220, symbolSize=60, labelFontSize=24, labelLimit=280, offset=2}},
        shape = {"ccornot:o", legend={titleFontSize=16, symbolSize=40, labelFontSize=16}},
        resolve = {scale={y=:independent}}
    ) |> save(joinpath(@__DIR__, "../results/migflow_ineq/", string("netmig_cata_nocc_",s,"_v5.png")))
end

# Plot differences in net migration with and without climate change
netmig_cata_nocc_both = rename(stack(
    migration_cata_nocc, 
    [:netmig_cata_damageprop,:netmig_cata_damageindep,:netmig_cata_damageinvprop], 
    [:scen, :fundregion, :year]
), :variable => :netmig_type, :value => :netmig)
netmig_cata_nocc = rename(stack(
    migration_cata_nocc, 
    [:netmig_cata_nocc_damageprop,:netmig_cata_nocc_damageindep,:netmig_cata_nocc_damageinvprop],
    [:scen, :fundregion, :year]
), :variable => :netmig_cata_nocc_type, :value => :netmig_cata_nocc)
sort!(netmig_cata_nocc_both, [:scen,:fundregion,:year])
sort!(netmig_cata_nocc, [:scen,:fundregion,:year])
netmig_cata_nocc_both[!,:netmig_cata_nocc] = netmig_cata_nocc[:,:netmig_cata_nocc]
netmig_cata_nocc_both[!,:xi] = [SubString(String(netmig_cata_nocc_both[i,:netmig_type]), 8) for i in 1:size(netmig_cata_nocc_both,1)]
netmig_cata_nocc_both = innerjoin(netmig_cata_nocc_both,regions_fullname, on=:fundregion)
netmig_cata_nocc_both[!,:netmig_diff] = netmig_cata_nocc_both[:,:netmig] .- netmig_cata_nocc_both[:,:netmig_cata_nocc]

for s in ssps
    netmig_cata_nocc_both |> @filter(_.year >= 2015 && _.year <= 2100 && _.scen == s) |> @vlplot(
        mark={:line, strokeWidth = 4}, width=300, height=250, columns=4, wrap={"regionname:o", title=nothing, header={labelFontSize=24}}, 
        x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
        y={"netmig_diff:q", title = nothing, axis={labelFontSize=16}},
        color={"xi:o",scale={scheme=:darkmulti},legend={title=string("Net migration, ",s), titleFontSize=20, titleLimit=220, symbolSize=60, labelFontSize=24, labelLimit=280, offset=2}},
        resolve = {scale={y=:independent}}
    ) |> save(joinpath(@__DIR__, "../results/migflow_ineq/", string("netmig_cata_ccdiff_",s,"_v5.png")))
end

# Plot differences in migration (people leaving a place) with and without climate change
leave_cata_nocc_both = rename(stack(
    rename(migration_cata_nocc, :leave_cata_xi1=>:leave_cata_damageprop, :leave_cata_xi0=>:leave_cata_damageindep, :leave_cata_xim1=>:leave_cata_damageinvprop), 
    [:leave_cata_damageprop,:leave_cata_damageindep,:leave_cata_damageinvprop], 
    [:scen, :fundregion, :year]
), :variable => :leave_type, :value => :leave)
leave_cata_nocc = rename(stack(
    rename(migration_cata_nocc, :leave_cata_nocc_xi1=>:leave_cata_nocc_damageprop, :leave_cata_nocc_xi0=>:leave_cata_nocc_damageindep, :leave_cata_nocc_xim1=>:leave_cata_nocc_damageinvprop), 
    [:leave_cata_nocc_damageprop,:leave_cata_nocc_damageindep,:leave_cata_nocc_damageinvprop],
    [:scen, :fundregion, :year]
), :variable => :leave_cata_nocc_type, :value => :leave_cata_nocc)
leave_cata_nores = rename(stack(
    rename(migration_cata_nocc, :leave_cata_nores_xi1=>:leave_cata_nores_damageprop, :leave_cata_nores_xi0=>:leave_cata_nores_damageindep, :leave_cata_nores_xim1=>:leave_cata_nores_damageinvprop), 
    [:leave_cata_nores_damageprop,:leave_cata_nores_damageindep,:leave_cata_nores_damageinvprop], 
    [:scen, :fundregion, :year]
), :variable => :leave_cata_nores_type, :value => :leave_cata_nores)
leave_cata_nocc_nores = rename(stack(
    rename(migration_cata_nocc, :leave_cata_nocc_nores_xi1=>:leave_cata_nocc_nores_damageprop, :leave_cata_nocc_nores_xi0=>:leave_cata_nocc_nores_damageindep, :leave_cata_nocc_nores_xim1=>:leave_cata_nocc_nores_damageinvprop), 
    [:leave_cata_nocc_nores_damageprop,:leave_cata_nocc_nores_damageindep,:leave_cata_nocc_nores_damageinvprop],
    [:scen, :fundregion, :year]
), :variable => :leave_cata_nocc_nores_type, :value => :leave_cata_nocc_nores)
sort!(leave_cata_nocc_both, [:scen,:fundregion,:year])
sort!(leave_cata_nocc, [:scen,:fundregion,:year])
sort!(leave_cata_nores, [:scen,:fundregion,:year])
sort!(leave_cata_nocc_nores, [:scen,:fundregion,:year])
leave_cata_nocc_both[!,:leave_cata_nocc] = leave_cata_nocc[:,:leave_cata_nocc]
leave_cata_nocc_both[!,:leave_cata_nores] = leave_cata_nores[:,:leave_cata_nores]
leave_cata_nocc_both[!,:leave_cata_nocc_nores] = leave_cata_nocc_nores[:,:leave_cata_nocc_nores]
leave_cata_nocc_both[!,:xi] = [SubString(String(leave_cata_nocc_both[i,:leave_type]), 7) for i in 1:size(leave_cata_nocc_both,1)]
leave_cata_nocc_both = innerjoin(leave_cata_nocc_both,regions_fullname, on=:fundregion)
leave_cata_nocc_both[!,:leave_cata_diff] = leave_cata_nocc_both[:,:leave] .- leave_cata_nocc_both[:,:leave_cata_nocc]
leave_cata_nocc_both[!,:leave_cata_nores_diff] = leave_cata_nocc_both[:,:leave_cata_nores] .- leave_cata_nocc_both[:,:leave_cata_nocc_nores]

for s in ssps
    leave_cata_nocc_both |> @filter(_.year >= 2015 && _.year <= 2100 && _.scen == s) |> @vlplot(
        mark={:line, strokeWidth = 4}, width=300, height=250, columns=4, wrap={"regionname:o", title=nothing, header={labelFontSize=24}}, 
        x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
        y={"leave_cata_diff:q", title = nothing, axis={labelFontSize=16}},
        color={"xi:o",scale={scheme=:darkmulti},legend={title=string("Net migration, ",s), titleFontSize=20, titleLimit=220, symbolSize=60, labelFontSize=24, labelLimit=280, offset=2}},
        resolve = {scale={y=:independent}}
    ) |> save(joinpath(@__DIR__, "../results/migflow_ineq/", string("leave_cata_ccdiff_reg_",s,"_v5.png")))
end

leave_cata_nocc_tot = combine(d->(leave_cata_diff=sum(d.leave_cata_nores_diff),leave=sum(d.leave_cata_nores)), groupby(leave_cata_nocc_both, [:scen,:year,:xi]))
leave_cata_nocc_tot[!,:scen_ccshare_type] = [string(leave_cata_nocc_tot[i,:scen],"_",string(leave_cata_nocc_tot[i,:xi])) for i in 1:size(leave_cata_nocc_tot,1)]
leave_cata_nocc_tot |> @filter(_.year >= 2015 && _.year <= 2100) |> @vlplot(
    mark={:line, strokeWidth = 4}, width=300, height=250,  
    x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
    y={"leave_cata_diff:q", title = nothing, axis={labelFontSize=16}},
    color={"scen_ccshare_type:o",scale={scheme=:category20c},legend={titleFontSize=16, symbolSize=40, labelFontSize=16}},
    resolve = {scale={y=:independent}}
) |> save(joinpath(@__DIR__, "../results/migflow_ineq/", string("leave_cata_ccdiff_v5.png")))
for s in ssps
    leave_cata_nocc_tot |> @filter(_.year >= 2015 && _.year <= 2100 && _.scen == s) |> @vlplot(
        mark={:line, strokeWidth = 4}, width=300, height=250, 
        x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
        y={"leave_cata_diff:q", title = "Number of additional migrants with climate change", axis={labelFontSize=16}},
        color={"xi:o",scale={scheme=:darkmulti},legend={title=string("Damage elasticity of income, ",s), titleFontSize=20, titleLimit=220, symbolSize=60, labelFontSize=24, labelLimit=280, offset=2}}
    ) |> save(joinpath(@__DIR__, "../results/migflow_ineq/", string("leave_cata_ccdiff_",s,"_v5.png")))
end

leave_cata_nocc_tot[!,:ccshare] = leave_cata_nocc_tot[:,:leave_cata_diff] ./ leave_cata_nocc_tot[:,:leave]
for i in 1:size(leave_cata_nocc_tot,1) ; if leave_cata_nocc_tot[i,:leave] == 0.0 ; leave_cata_nocc_tot[i,:ccshare] = 0 end end
leave_cata_nocc_tot[.&(leave_cata_nocc_tot[:,:year].==2100),:]
combine(d->sum(d.leave), groupby(leave_cata_nocc_tot[.&(leave_cata_nocc_tot[:,:year].>=2020,leave_cata_nocc_tot[:,:year].<=2040),:], [:scen,:xi]))

# Plot results
leave_cata_nocc_tot |> @filter(_.year >= 2015 && _.year <= 2100) |> @vlplot(
    mark={:line, strokeWidth = 4}, width=300, height=250,  
    x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
    y={"ccshare:q", title = nothing, axis={labelFontSize=16}},
    color={"scen_ccshare_type:o",scale={scheme=:category20c},legend={titleFontSize=16, symbolSize=40, labelFontSize=16}},
    resolve = {scale={y=:independent}}
) |> save(joinpath(@__DIR__, "../results/migflow_ineq/", string("leave_cata_ccshare_v5.png")))
for s in ssps
    leave_cata_nocc_tot |> @filter(_.year >= 2015 && _.year <= 2100 && _.scen == s) |> @vlplot(
        mark={:line, strokeWidth = 4}, width=300, height=250, 
        x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
        y={"ccshare:q", title = "Effect of climate change on global migration flows", axis={labelFontSize=16, titleFontSize=14}},
        color={"xi:o",scale={scheme=:darkmulti},legend={title=string("Damage elasticity of income, ",s), titleFontSize=20, titleLimit=220, symbolSize=60, labelFontSize=24, labelLimit=280, offset=2}}
    ) |> save(joinpath(@__DIR__, "../results/migflow_ineq/", string("leave_cata_ccshare_",s,"_v5.png")))
end


# Plot differences in migration with and without climate change for each quintile
enter_cata_quint_cata_nocc_xi1 = vcat(
    collect(Iterators.flatten(m_nice_ssp1_nocc[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp2_nocc[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp3_nocc[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp4_nocc[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp5_nocc[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))
)
migration_cata_quint[:,:enter_cata_quint_cata_nocc_xi1] = enter_cata_quint_cata_nocc_xi1
leave_cata_quint_cata_nocc_xi1 = vcat(
    collect(Iterators.flatten(m_nice_ssp1_nocc[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp2_nocc[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp3_nocc[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp4_nocc[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp5_nocc[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))
)
migration_cata_quint[:,:leave_cata_quint_cata_nocc_xi1] = leave_cata_quint_cata_nocc_xi1

enter_cata_quint_cata_nocc_xi0 = vcat(
    collect(Iterators.flatten(m_nice_ssp1_nocc_xi0[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp2_nocc_xi0[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp3_nocc_xi0[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp4_nocc_xi0[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp5_nocc_xi0[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))
)
migration_cata_quint[:,:enter_cata_quint_cata_nocc_xi0] = enter_cata_quint_cata_nocc_xi0
leave_cata_quint_cata_nocc_xi0 = vcat(
    collect(Iterators.flatten(m_nice_ssp1_nocc_xi0[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp2_nocc_xi0[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp3_nocc_xi0[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp4_nocc_xi0[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp5_nocc_xi0[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))
)
migration_cata_quint[:,:leave_cata_quint_cata_nocc_xi0] = leave_cata_quint_cata_nocc_xi0

enter_cata_quint_cata_nocc_xim1 = vcat(
    collect(Iterators.flatten(m_nice_ssp1_nocc_xim1[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp2_nocc_xim1[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp3_nocc_xim1[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp4_nocc_xim1[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp5_nocc_xim1[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))
)
migration_cata_quint[:,:enter_cata_quint_cata_nocc_xim1] = enter_cata_quint_cata_nocc_xim1
leave_cata_quint_cata_nocc_xim1 = vcat(
    collect(Iterators.flatten(m_nice_ssp1_nocc_xim1[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp2_nocc_xim1[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp3_nocc_xim1[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp4_nocc_xim1[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp5_nocc_xim1[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))
)
migration_cata_quint[:,:leave_cata_quint_cata_nocc_xim1] = leave_cata_quint_cata_nocc_xim1

migration_cata_quint[!,:leave_cata_quint_diff_xi1] = migration_cata_quint[:,:leave_cata_quint_xi1] .- migration_cata_quint[:,:leave_cata_quint_cata_nocc_xi1]
migration_cata_quint[!,:leave_cata_quint_diff_xi0] = migration_cata_quint[:,:leave_cata_quint_xi0] .- migration_cata_quint[:,:leave_cata_quint_cata_nocc_xi0]
migration_cata_quint[!,:leave_cata_quint_diff_xim1] = migration_cata_quint[:,:leave_cata_quint_xim1] .- migration_cata_quint[:,:leave_cata_quint_cata_nocc_xim1]

migration_cata_quint_p = migration_cata_quint[(map(x->mod(x,10)==0,migration_cata_quint[:,:year])),:]

leave_cata_quint_cata_nocc = stack(
    rename(migration_cata_quint_p, :leave_cata_quint_diff_xi1 => :leave_cata_quint_diff_damageprop, :leave_cata_quint_diff_xi0 => :leave_cata_quint_diff_damageindep, :leave_cata_quint_diff_xim1 => :leave_cata_quint_diff_damageinvprop), 
    [:leave_cata_quint_diff_damageprop,:leave_cata_quint_diff_damageindep,:leave_cata_quint_diff_damageinvprop], 
    [:scen, :quintile ,:fundregion, :year]
)
rename!(leave_cata_quint_cata_nocc, :variable => :leave_type, :value => :leave_cata_quint_diff_nocc)
leave_cata_quint_cata_nocc[!,:leave_type] = map(x->SubString(string(x),18),leave_cata_quint_cata_nocc[:,:leave_type])

for s in ssps
    leave_cata_quint_cata_nocc |> @filter(_.year >= 2015 && _.year <= 2100 && _.scen == s) |> @vlplot(
        mark={:point,size=60}, width=300, height=250, columns=4, wrap="fundregion:o", 
        x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
        y={"leave_cata_quint_diff_nocc:q", title = nothing, axis={labelFontSize=16}},
        color={"quintile:o",scale={scheme=:darkmulti},legend={titleFontSize=16, symbolSize=40, labelFontSize=16}},
        shape={"leave_type:o",legend={titleFontSize=16, symbolSize=40, labelFontSize=16}},
        resolve = {scale={y=:independent}}
    ) |> save(joinpath(@__DIR__, "../results/migflow_ineq/", string("leave_cata_quint_cata_nocc_",s,"_v5.png")))
end

migration_cata_quint[!,:leave_cata_quint_ccshare_xi1] = (migration_cata_quint[:,:leave_cata_quint_xi1] .- migration_cata_quint[:,:leave_cata_quint_cata_nocc_xi1]) ./ (migration_cata_quint[:,:leave_cata_quint_cata_nocc_xi1] .- migration_cata_quint[:,:leave_cata_quint_gravres])
migration_cata_quint[!,:leave_cata_quint_ccshare_xi0] = (migration_cata_quint[:,:leave_cata_quint_xi0] .- migration_cata_quint[:,:leave_cata_quint_cata_nocc_xi0]) ./ (migration_cata_quint[:,:leave_cata_quint_cata_nocc_xi0] .- migration_cata_quint[:,:leave_cata_quint_gravres])
migration_cata_quint[!,:leave_cata_quint_ccshare_xim1] = (migration_cata_quint[:,:leave_cata_quint_xim1] .- migration_cata_quint[:,:leave_cata_quint_cata_nocc_xim1]) ./ (migration_cata_quint[:,:leave_cata_quint_cata_nocc_xim1] .- migration_cata_quint[:,:leave_cata_quint_gravres])

migration_cata_quint_p = migration_cata_quint[(map(x->mod(x,10)==0,migration_cata_quint[:,:year])),:]

leave_cata_quint_ccshare = stack(
    rename(migration_cata_quint_p, :leave_cata_quint_ccshare_xi1 => :leave_cata_quint_ccshare_damageprop, :leave_cata_quint_ccshare_xi0 => :leave_cata_quint_ccshare_damageindep, :leave_cata_quint_ccshare_xim1 => :leave_cata_quint_ccshare_damageinvprop), 
    [:leave_cata_quint_ccshare_damageprop,:leave_cata_quint_ccshare_damageindep,:leave_cata_quint_ccshare_damageinvprop], 
    [:scen, :quintile ,:fundregion, :year]
)
rename!(leave_cata_quint_ccshare, :variable => :leave_type, :value => :leave_cata_quint_ccshare_nocc)
leave_cata_quint_ccshare[!,:damage_elasticity] = map(x->SubString(string(x),26),leave_cata_quint_ccshare[:,:leave_type])
leave_cata_quint_ccshare[!,:type_name] = [leave_cata_quint_ccshare[i,:damage_elasticity]=="damageprop" ? "proportional" : (leave_cata_quint_ccshare[i,:damage_elasticity]=="damageindep" ? "independent" : "inversely prop.") for i in 1:size(leave_cata_quint_ccshare,1)]
leave_cata_quint_ccshare = innerjoin(leave_cata_quint_ccshare, regions_fullname, on=:fundregion)

for s in ssps
    leave_cata_quint_ccshare |> @filter(_.year >= 2015 && _.year <= 2100 && _.scen == s) |> @vlplot(
        mark={:point,size=60}, width=300, height=250, columns=4, wrap={"regionname:o", title=nothing, header={labelFontSize=24}}, 
        x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
        y={"leave_cata_quint_ccshare_nocc:q", title = "Emigrants, catastrophic CC", axis={labelFontSize=20,titleFontSize=20}},
        color={"quintile:o",scale={scheme=:darkmulti},legend={title = "Quintile", titleFontSize=20, symbolSize=80, labelFontSize=20}},
        shape={"type_name:o",scale={range=["circle","triangle-up","square"],domain=["proportional","independent","inversely prop."]},legend={title = "Damages elasticity", titleFontSize=20, titleLimit=260, symbolSize=80, labelFontSize=20}},
        resolve = {scale={y=:independent}}
    ) |> save(joinpath(@__DIR__, "../results/migflow_ineq/", string("leave_cata_quint_ccshare_",s,"_v5.png")))
end

# Plot associated maps
leave_cata_maps = leftjoin(leave_cata_quint_ccshare, isonum_fundregion, on = :fundregion)
for s in ssps
    for d in ["damageprop","damageindep","damageinvprop"]
        @vlplot(width=800, height=600) + @vlplot(mark={:geoshape, stroke = :lightgray}, 
            data={values=world110m, format={type=:topojson, feature=:countries}}, 
            transform = [{lookup=:id, from={data=filter(row -> row[:scen] == s && row[:year] == 2100 && row[:damage_elasticity] == d && row[:quintile] == 1, leave_cata_maps), key=:isonum, fields=[string(:leave_cata_quint_ccshare_nocc)]}}],
            projection={type=:naturalEarth1}, title = {text=string("SSP2-RCP4.5, catastrophic damages"),fontSize=24}, 
            color = {:leave_cata_quint_ccshare_nocc, type=:quantitative, scale={domain=[-0.4,0.4], scheme=:pinkyellowgreen}, legend={title="Change vs no CC", titleFontSize=20, titleLimit=260, symbolSize=60, labelFontSize=20, labelLimit=220}}
        ) |> save(joinpath(@__DIR__, "../results/world_maps_ineq/", string("leave_cata_q1_ccshare_", s, "_", d, "_v5.pdf")))
    end
end


################################ Compare inequality (Gini) in Mig-NICE-FUND for different income elasticities of damages (xi) #######################
gini_cata = DataFrame(
    year = repeat(years, outer = length(ssps)*length(regions)),
    scen = repeat(ssps,inner = length(regions)*length(years)),
    fundregion = repeat(regions, outer = length(ssps), inner=length(years))
)

gini_migNICEFUND = vcat(
    collect(Iterators.flatten(m_nice_ssp1_nomig[:socioeconomic,:inequality][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp2_nomig[:socioeconomic,:inequality][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp3_nomig[:socioeconomic,:inequality][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp4_nomig[:socioeconomic,:inequality][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp5_nomig[:socioeconomic,:inequality][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
gini_cata[:,:gini_migNICEFUND] = gini_migNICEFUND
gini_cata_migNICEFUND = vcat(
    collect(Iterators.flatten(m_nice_ssp1_cata[:socioeconomic,:inequality][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp2_cata[:socioeconomic,:inequality][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp3_cata[:socioeconomic,:inequality][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp4_cata[:socioeconomic,:inequality][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp5_cata[:socioeconomic,:inequality][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
gini_cata[:,:gini_cata_migNICEFUND] = gini_cata_migNICEFUND
gini_cata_migNICEFUND_xi0 = vcat(
    collect(Iterators.flatten(m_nice_ssp1_cata_xi0[:socioeconomic,:inequality][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp2_cata_xi0[:socioeconomic,:inequality][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp3_cata_xi0[:socioeconomic,:inequality][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp4_cata_xi0[:socioeconomic,:inequality][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp5_cata_xi0[:socioeconomic,:inequality][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
gini_cata[:,:gini_cata_migNICEFUND_xi0] = gini_cata_migNICEFUND_xi0
gini_cata_migNICEFUND_xim1 = vcat(
    collect(Iterators.flatten(m_nice_ssp1_cata_xim1[:socioeconomic,:inequality][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp2_cata_xim1[:socioeconomic,:inequality][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp3_cata_xim1[:socioeconomic,:inequality][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp4_cata_xim1[:socioeconomic,:inequality][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp5_cata_xim1[:socioeconomic,:inequality][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
gini_cata[:,:gini_cata_migNICEFUND_xim1] = gini_cata_migNICEFUND_xim1

gini_cata_p = gini_cata[(map(x->mod(x,10)==0,gini_cata[:,:year])),:]

gini_cata_xi_all = stack(gini_cata_p, [:gini_cata_migNICEFUND,:gini_cata_migNICEFUND_xi0,:gini_cata_migNICEFUND_xim1], [:scen, :fundregion, :year])
rename!(gini_cata_xi_all, :variable => :gini_cata_type, :value => :gini_cata)
gini_cata_xi_all[!,:gini_cata_type] = map(x->SubString(string(x),11), gini_cata_xi_all[:,:gini_cata_type])
for r in regions
    data_ssp = gini_cata_xi_all |> @filter(_.year <= 2100 && _.year >= 2015  && _.fundregion==r) 
    @vlplot() + @vlplot(
        width=300, height=250, data = data_ssp,
        mark={:point, size=30}, x = {"year:o", axis={labelFontSize=16}, title=nothing}, y = {"gini_cata:q", title=nothing, axis={labelFontSize=16}}, 
        title = string("Gini of region ",r," for SSP, NICE-FUND with SSP and Mig-NICE-FUND with SSP zero migration"), 
        color = {"scen:n", scale={scheme=:category10}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}, 
        shape = {"gini_cata_type:o", legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}
    ) + @vlplot(
        mark={:line, strokeDash=[1,2]}, data = data_ssp, x = {"year:o", axis={labelFontSize=16}, title=nothing}, y = {"gini_cata:q", aggregate=:mean,type=:quantitative,title=nothing, axis={labelFontSize=16}}, 
        color = {"scen:n", scale={scheme=:category10}},
        detail = "gini_cata_type:o"
    ) |> save(joinpath(@__DIR__, "../results/inequality/", string("gini_cata_mignice_xi_", r, "_v5.png")))
end

gini_cata_all = stack(gini_cata_p, [:gini_cata_migNICEFUND,:gini_migNICEFUND], [:scen, :fundregion, :year])
rename!(gini_cata_all, :variable => :gini_cata_type, :value => :gini_cata)
gini_cata_all |> @filter(_.year <= 2100 && _.year >= 2015) |> @vlplot(
    width=300, height=250, columns=4, wrap={"fundregion:o", title=nothing, header={labelFontSize=24}}, mark={:point, size=60}, 
    x = {"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing}, 
    y = {"gini_cata:q", title=nothing, axis={labelFontSize=16}}, 
    color = {"scen:n", scale={scheme=:category10}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}, 
    shape = {"gini_cata_type:o", legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}
) |> save(joinpath(@__DIR__, "../results/inequality/", string("gini_cata_v5.png")))

############################################## Compare increases in damages in catastrophic case ################################

years = 1951:2100

damages_cata = DataFrame(
    year = repeat(years, outer = length(ssps)*length(regions)),
    scen = repeat(ssps,inner = length(regions)*length(years)),
    fundregion = repeat(regions, outer = length(ssps), inner=length(years)),
)

dam_migNICEFUND = vcat(
    collect(Iterators.flatten(m_nice_ssp1_cata[:addimpact,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp2_cata[:addimpact,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp3_cata[:addimpact,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp4_cata[:addimpact,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp5_cata[:addimpact,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
damages_cata[:,:damages_migNICEFUND] = dam_migNICEFUND
gdp_migNICEFUND = vcat(
    collect(Iterators.flatten(m_nice_ssp1_cata[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp2_cata[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp3_cata[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp4_cata[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp5_cata[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
damages_cata[:,:gdp_migNICEFUND] = gdp_migNICEFUND
dam_migNICEFUND_xi0 = vcat(
    collect(Iterators.flatten(m_nice_ssp1_cata_xi0[:addimpact,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp2_cata_xi0[:addimpact,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp3_cata_xi0[:addimpact,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp4_cata_xi0[:addimpact,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp5_cata_xi0[:addimpact,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
damages_cata[:,:damages_migNICEFUND_xi0] = dam_migNICEFUND_xi0
dam_migNICEFUND_xim1 = vcat(
    collect(Iterators.flatten(m_nice_ssp1_cata_xim1[:addimpact,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp2_cata_xim1[:addimpact,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp3_cata_xim1[:addimpact,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp4_cata_xim1[:addimpact,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp5_cata_xim1[:addimpact,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
damages_cata[:,:damages_migNICEFUND_xim1] = dam_migNICEFUND_xim1
gdp_migNICEFUND_xi0 = vcat(
    collect(Iterators.flatten(m_nice_ssp1_cata_xi0[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp2_cata_xi0[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp3_cata_xi0[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp4_cata_xi0[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp5_cata_xi0[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
damages_cata[:,:gdp_migNICEFUND_xi0] = gdp_migNICEFUND_xi0
gdp_migNICEFUND_xim1 = vcat(
    collect(Iterators.flatten(m_nice_ssp1_cata_xim1[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp2_cata_xim1[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp3_cata_xim1[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp4_cata_xim1[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp5_cata_xim1[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
damages_cata[:,:gdp_migNICEFUND_xim1] = gdp_migNICEFUND_xim1

damages_cata[:,:damgdp_migNICEFUND] = damages_cata[:,:damages_migNICEFUND] ./ (damages_cata[:,:gdp_migNICEFUND] .* 10^9)
damages_cata[:,:damgdp_migNICEFUND_xi0] = damages_cata[:,:damages_migNICEFUND_xi0] ./ (damages_cata[:,:gdp_migNICEFUND_xi0] .* 10^9)
damages_cata[:,:damgdp_migNICEFUND_xim1] = damages_cata[:,:damages_migNICEFUND_xim1] ./ (damages_cata[:,:gdp_migNICEFUND_xim1] .* 10^9)
rename!(damages_cata, :damages_migNICEFUND => :dam_damprop, :damages_migNICEFUND_xi0 => :dam_damindep, :damages_migNICEFUND_xim1 => :dam_daminvprop)
rename!(damages_cata, :damgdp_migNICEFUND => :damgdp_damprop, :damgdp_migNICEFUND_xi0 => :damgdp_damindep, :damgdp_migNICEFUND_xim1 => :damgdp_daminvprop)

dam_cata_world = combine(d->(worlddam_damprop=sum(d.dam_damprop),worlddam_damindep=sum(d.dam_damindep),worlddam_daminvprop=sum(d.dam_daminvprop)), groupby(damages_cata,[:year,:scen]))

worldgdp_migNICEFUND = vcat(
    collect(Iterators.flatten(m_nice_ssp1_cata[:socioeconomic,:globalincome][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_nice_ssp2_cata[:socioeconomic,:globalincome][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_nice_ssp3_cata[:socioeconomic,:globalincome][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_nice_ssp4_cata[:socioeconomic,:globalincome][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_nice_ssp5_cata[:socioeconomic,:globalincome][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)]))
)
dam_cata_world[:,:worldgdp_migNICEFUND] = worldgdp_migNICEFUND
worldgdp_migNICEFUND_xi0 = vcat(
    collect(Iterators.flatten(m_nice_ssp1_cata_xi0[:socioeconomic,:globalincome][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_nice_ssp2_cata_xi0[:socioeconomic,:globalincome][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_nice_ssp3_cata_xi0[:socioeconomic,:globalincome][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_nice_ssp4_cata_xi0[:socioeconomic,:globalincome][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_nice_ssp5_cata_xi0[:socioeconomic,:globalincome][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)]))
)
dam_cata_world[:,:worldgdp_migNICEFUND_xi0] = worldgdp_migNICEFUND_xi0
worldgdp_migNICEFUND_xim1 = vcat(
    collect(Iterators.flatten(m_nice_ssp1_cata_xim1[:socioeconomic,:globalincome][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_nice_ssp2_cata_xim1[:socioeconomic,:globalincome][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_nice_ssp3_cata_xim1[:socioeconomic,:globalincome][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_nice_ssp4_cata_xim1[:socioeconomic,:globalincome][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_nice_ssp5_cata_xim1[:socioeconomic,:globalincome][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)]))
)
dam_cata_world[:,:worldgdp_migNICEFUND_xim1] = worldgdp_migNICEFUND_xim1

dam_cata_world_p = dam_cata_world[(map(x->mod(x,10)==0,dam_cata_world[:,:year])),:]
rename!(dam_cata_world_p, :worldgdp_migNICEFUND => :worldgdp_damprop, :worldgdp_migNICEFUND_xi0 => :worldgdp_damindep, :worldgdp_migNICEFUND_xim1 => :worldgdp_daminvprop)

dam_cata_world_p[:,:worlddamgdp_damprop] = dam_cata_world_p[:,:worlddam_damprop] ./ (dam_cata_world_p[:,:worldgdp_damprop] .* 10^9)
dam_cata_world_p[:,:worlddamgdp_damindep] = dam_cata_world_p[:,:worlddam_damindep] ./ (dam_cata_world_p[:,:worldgdp_damindep] .* 10^9)
dam_cata_world_p[:,:worlddamgdp_daminvprop] = dam_cata_world_p[:,:worlddam_daminvprop] ./ (dam_cata_world_p[:,:worldgdp_daminvprop] .* 10^9)

dam_cata_world_stack = stack(dam_cata_world_p,[:worlddamgdp_damprop,:worlddamgdp_damindep,:worlddamgdp_daminvprop],[:scen,:year])
rename!(dam_cata_world_stack,:variable => :worlddamgdp_type, :value => :worlddamgdp)
dam_cata_world_stack[!,:worlddamgdp_type] = map(x->SubString(String(x),13), dam_cata_world_stack[:,:worlddamgdp_type])
dam_cata_world_stack |> @filter(_.year >= 2015 && _.year <= 2100) |> @vlplot() + @vlplot(
    width=300, height=250, 
    mark={:point, size=50}, x = {"year:o", axis={labelFontSize=16}, title=nothing}, y = {"worlddamgdp:q", title=nothing, axis={labelFontSize=16}}, 
    title = "Global catastrophic damages as share of GDP", 
    color = {"scen:n", scale={scheme=:category10}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}, 
    shape = {"worlddamgdp_type:o", scale={range=["circle","triangle-up", "square"]}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}
) + @vlplot(
    mark={:line, strokeDash=[1,2]}, x = {"year:o", axis={labelFontSize=16}, title=nothing}, y = {"worlddamgdp:q", aggregate=:mean,type=:quantitative,title=nothing, axis={labelFontSize=16}}, 
    color = {"scen:n", scale={scheme=:category10}},
    detail = "worlddamgdp_type:o"
) |> save(joinpath(@__DIR__, "../results/damages_ineq/", "damgdp_cata_world_xi_v5.png"))


############################################ Compute damages shock on income for lower quintiles when xi = -1 #########################################
income_cata_shock = DataFrame(
    year = repeat(years, outer = length(ssps)*length(regions)*5),
    scen = repeat(ssps,inner = length(regions)*length(years)*5),
    fundregion = repeat(regions, outer = length(ssps)*5, inner=length(years)),
    quintile = repeat(1:5, outer = length(ssps), inner=length(years)*length(regions))
)

income_distr_xi1 = vcat(
    collect(Iterators.flatten(m_nice_ssp1_cata[:socioeconomic,:income_distribution][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp2_cata[:socioeconomic,:income_distribution][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp3_cata[:socioeconomic,:income_distribution][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp4_cata[:socioeconomic,:income_distribution][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp5_cata[:socioeconomic,:income_distribution][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))
)
income_cata_shock[:,:income_distr_damprop] = income_distr_xi1
income_distr_xi0 = vcat(
    collect(Iterators.flatten(m_nice_ssp1_cata_xi0[:socioeconomic,:income_distribution][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp2_cata_xi0[:socioeconomic,:income_distribution][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp3_cata_xi0[:socioeconomic,:income_distribution][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp4_cata_xi0[:socioeconomic,:income_distribution][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp5_cata_xi0[:socioeconomic,:income_distribution][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))
)
income_cata_shock[:,:income_distr_damindep] = income_distr_xi0
income_distr_xim1 = vcat(
    collect(Iterators.flatten(m_nice_ssp1_cata_xim1[:socioeconomic,:income_distribution][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp2_cata_xim1[:socioeconomic,:income_distribution][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp3_cata_xim1[:socioeconomic,:income_distribution][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp4_cata_xim1[:socioeconomic,:income_distribution][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp5_cata_xim1[:socioeconomic,:income_distribution][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))
)
income_cata_shock[:,:income_distr_daminvprop] = income_distr_xim1
damage_cata_distr_xi1 = vcat(
    collect(Iterators.flatten(m_nice_ssp1_cata[:socioeconomic,:damage_distribution][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp2_cata[:socioeconomic,:damage_distribution][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp3_cata[:socioeconomic,:damage_distribution][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp4_cata[:socioeconomic,:damage_distribution][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp5_cata[:socioeconomic,:damage_distribution][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))
)
income_cata_shock[:,:damage_cata_distr_damprop] = damage_cata_distr_xi1
damage_cata_distr_xi0 = vcat(
    collect(Iterators.flatten(m_nice_ssp1_cata_xi0[:socioeconomic,:damage_distribution][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp2_cata_xi0[:socioeconomic,:damage_distribution][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp3_cata_xi0[:socioeconomic,:damage_distribution][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp4_cata_xi0[:socioeconomic,:damage_distribution][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp5_cata_xi0[:socioeconomic,:damage_distribution][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))
)
income_cata_shock[:,:damage_cata_distr_damindep] = damage_cata_distr_xi0
damage_cata_distr_xim1 = vcat(
    collect(Iterators.flatten(m_nice_ssp1_cata_xim1[:socioeconomic,:damage_distribution][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp2_cata_xim1[:socioeconomic,:damage_distribution][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp3_cata_xim1[:socioeconomic,:damage_distribution][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp4_cata_xim1[:socioeconomic,:damage_distribution][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp5_cata_xim1[:socioeconomic,:damage_distribution][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))
)
income_cata_shock[:,:damage_cata_distr_daminvprop] = damage_cata_distr_xim1

income_cata_shock = innerjoin(income_cata_shock, damages[:,[:year,:scen,:fundregion,:damgdp_damprop,:damgdp_damindep,:damgdp_daminvprop]], on=[:year,:scen,:fundregion])
income_cata_shock[!,:income_cata_shock_damprop] = income_cata_shock[:,:damage_cata_distr_damprop] .* income_cata_shock[:,:damgdp_damprop] ./ income_cata_shock[:,:income_distr_damprop]
income_cata_shock[!,:income_cata_shock_damindep] = income_cata_shock[:,:damage_cata_distr_damindep] .* income_cata_shock[:,:damgdp_damindep] ./ income_cata_shock[:,:income_distr_damindep]
income_cata_shock[!,:income_cata_shock_daminvprop] = income_cata_shock[:,:damage_cata_distr_daminvprop] .* income_cata_shock[:,:damgdp_daminvprop] ./ income_cata_shock[:,:income_distr_daminvprop]

income_cata_shock_p = income_cata_shock[(map(x->mod(x,10)==0,income_cata_shock[:,:year])),:]

income_cata_shock_s = stack(
    income_cata_shock_p, 
    [:income_cata_shock_damprop,:income_cata_shock_damindep,:income_cata_shock_daminvprop], 
    [:scen, :quintile ,:fundregion, :year]
)
rename!(income_cata_shock_s, :variable => :income_cata_shock_type, :value => :income_cata_shock)
income_cata_shock_s[!,:damage_elasticity] = map(x->SubString(String(x),19), income_cata_shock_s[:,:income_cata_shock_type])
income_cata_shock_s[!,:type_name] = [income_cata_shock_s[i,:damage_elasticity]=="damprop" ? "proportional" : (income_cata_shock_s[i,:damage_elasticity]=="damindep" ? "independent" : "inversely prop.") for i in 1:size(income_cata_shock_s,1)]
income_cata_shock_s = innerjoin(income_cata_shock_s, regions_fullname, on =:fundregion)
for s in ssps
    income_cata_shock_s |> @filter(_.year >= 2015 && _.year <= 2100 && _.scen == s) |> @vlplot(
        mark={:point,size=60}, width=300, height=250, columns=4, wrap={"regionname:o", title=nothing, header={labelFontSize=24}}, 
        x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
        y={"income_cata_shock:q", title = "Damages as share of income", axis={labelFontSize=20,titleFontSize=20}},
        color={"quintile:o",scale={scheme=:darkmulti},legend={title = "Quintile", titleFontSize=20, symbolSize=80, labelFontSize=20}},
        shape={"type_name:o",scale={range=["circle","triangle-up","square"],domain=["proportional","independent","inversely prop."]},legend={title = "Damages elasticity", titleFontSize=20, titleLimit=260, symbolSize=80, labelFontSize=20}},
        resolve = {scale={y=:independent}}
    ) |> save(joinpath(@__DIR__, "../results/damages_ineq/", string("income_cata_shock_",s,"_v5.png")))
end

income_cata_shock_maps = leftjoin(income_cata_shock_s, isonum_fundregion, on = :fundregion)
for s in ssps
    for d in ["damprop","damindep","daminvprop"]
        @vlplot(width=800, height=600) + @vlplot(mark={:geoshape, stroke = :lightgray}, 
            data={values=world110m, format={type=:topojson, feature=:countries}}, 
            transform = [{lookup=:id, from={data=filter(row -> row[:scen] == s && row[:year] == 2100 && row[:damage_elasticity] == d && row[:quintile] == 1, income_cata_shock_maps), key=:isonum, fields=[string(:income_cata_shock)]}}],
            projection={type=:naturalEarth1}, title = {text=string("Quintile 1, 2100, SSP2-RCP4.5, damages inversely prop."),fontSize=24}, 
            color = {:income_cata_shock, type=:quantitative, scale={domain=[-0.5,0.5], scheme=:blueorange}, legend={title="Share of income", titleFontSize=20, titleLimit=260, symbolSize=60, labelFontSize=20, labelLimit=220}}
        ) |> save(joinpath(@__DIR__, "../results/world_maps_ineq/", string("income_cata_shock_q1_", s, "_", d, "_v5.png")))
    end
end


########################################### Compare temperature in catastrophic Mig-NICE-FUND for different income elasticities of damages (xi) #####################################
ssps = ["SSP1-RCP1.9","SSP2-RCP4.5","SSP3-RCP7.0","SSP4-RCP6.0","SSP5-RCP8.5"]

temp_cata = DataFrame(
    year = repeat(years, outer = length(ssps)),
    scen = repeat(ssps,inner = length(years)),
)

temp_cata_migFUND = vcat(
    collect(Iterators.flatten(m_nice_ssp1_cata[:climatedynamics,:temp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp2_cata[:climatedynamics,:temp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp3_cata[:climatedynamics,:temp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp4_cata[:climatedynamics,:temp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp5_cata[:climatedynamics,:temp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
temp_cata[:,:temp_cata_migFUND] = temp_cata_migFUND
temp_cata_migFUND_xi0 = vcat(
    collect(Iterators.flatten(m_nice_ssp1_cata_xi0[:climatedynamics,:temp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp2_cata_xi0[:climatedynamics,:temp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp3_cata_xi0[:climatedynamics,:temp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp4_cata_xi0[:climatedynamics,:temp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp5_cata_xi0[:climatedynamics,:temp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
temp_cata[:,:temp_cata_migFUND_xi0] = temp_cata_migFUND_xi0
temp_cata_migFUND_xim1 = vcat(
    collect(Iterators.flatten(m_nice_ssp1_cata_xim1[:climatedynamics,:temp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp2_cata_xim1[:climatedynamics,:temp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp3_cata_xim1[:climatedynamics,:temp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp4_cata_xim1[:climatedynamics,:temp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp5_cata_xim1[:climatedynamics,:temp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
temp_cata[:,:temp_cata_migFUND_xim1] = temp_cata_migFUND_xim1

temp_cata_p = temp_cata[(map(x->mod(x,10)==0,temp_cata[:,:year])),:]
rename!(temp_cata_p, :temp_cata_migFUND => :temp_cata_damprop, :temp_cata_migFUND_xi0 => :temp_cata_damindep, :temp_cata_migFUND_xim1 => :temp_cata_daminvprop)

temp_cata_all = stack(temp_cata_p, [:temp_cata_damprop,:temp_cata_damindep,:temp_cata_daminvprop], [:scen, :year])
rename!(temp_cata_all, :variable => :temp_cata_type, :value => :temp)
temp_cata_all[!,:xi] = [SubString(String(temp_cata_all[i,:temp_cata_type]), 6) for i in 1:size(temp_cata_all,1)]

temp_cata_all |> @filter(_.year <= 2100) |> @vlplot(
    width=300, height=250, mark={:point, size=80}, 
    x = {"year:o", axis={labelFontSize=16, values = 1951:10:2100}, title=nothing}, y = {"temp:q", title="Temperature increase, degC", axis={labelFontSize=16,titleFontSize=16}}, 
    #title = "Global temperature for Mig-NICE-FUND with various income elasticities of damages", 
    color = {"scen:n", scale={scheme=:category10}, legend={title="Climate scenario", titleFontSize=20, titleLimit=220, symbolSize=60, labelFontSize=18, labelLimit=280}}, 
    shape = {"xi:o", scale={range=["circle", "triangle-up", "square","cross"]}, legend={title="income elasticity of damages", titleFontSize=20, titleLimit=220, symbolSize=60, labelFontSize=18, labelLimit=280}}
) + @vlplot(
    mark={:line, strokeDash=[1,2]}, 
    x = {"year:o", axis={labelFontSize=16, values = 1951:10:2100}, title=nothing}, y = {"temp:q", aggregate=:mean,typ=:quantitative,title="Temperature increase, degC", axis={labelFontSize=16,titleFontSize=16}}, 
    color = {"scen:n", scale={scheme=:category10}, legend={title="Climate scenario", titleFontSize=20, titleLimit=220, symbolSize=60, labelFontSize=18, labelLimit=280}},
    detail = "xi:o"
) |> save(joinpath(@__DIR__, "../results/temperature_ineq/", "temp_cata_world_xi_v5.png"))


####################################################### Store results ####################################################
# Create function that gathers relevant results for the period 1950-2100
function nice_cata_fund_mig(m::Mimi.Model)
    # deal with regions*regions dimensions first. For regions*regions*quintiles*quintiles, results too big to be stored on Github
    dr = getdataframe(m,:migration => :remshare)[1:151*16*16,:]
    rename(dr,:regions=>:origins)
    dr[:,:destinations]=repeat(regions,inner=16,outer=151)
    #db = getdataframe(m, :migration => (:move, :migstock, :rem))[1:5*5*16*16*151,:]
    #rename(db,:regions=>:origins,:quintiles=>:quintiles_origin)
    #db[:,:destinations]=repeat(regions,inner=16*5*5,outer=151)
    #db[:,:quintiles_destination]=repeat(1:5,inner=5,outer=16*16*151)

    # deal with all
    result = Dict("temperature" => getdataframe(m, :climatedynamics => :temp)[1:151,:],  
        "co2_atmosphere" => getdataframe(m, :climateco2cycle => :acco2)[1:151,:], 
        "emissions" => getdataframe(m, :emissions => (:emission, :co2red))[1:16*151,:], 
        "populationin1" => getdataframe(m, :population => :populationin1)[1:16*151,:],
        "globalpopulation" => getdataframe(m, :population => :globalpopulation)[1:151,:],
        "migration" => getdataframe(m, :migration => (:pop, :income, :entermig, :leavemig, :deadmig, :deadmigcost, :receive, :send, :remittances))[1:5*16*151,:], 
        #"bilateral_migration" => db,
        "remshare" => dr,
        "income" => getdataframe(m, :socioeconomic => (:income, :ypc, :inequality))[1:16*151,:], 
        "globalincome" => getdataframe(m, :socioeconomic => (:globalincome, :globalypc))[1:151,:],
        "distributions" => getdataframe(m, :socioeconomic => (:income_distribution, :mitigation_distribution, :damage_distribution))[1:5*16*151,:],
        "loss" => getdataframe(m, :addimpact => (:loss, :elossall, :slossall))[1:16*151,:],
        "impacts" => getdataframe(m, :impactaggregation => (:water, :forests, :heating, :cooling, :agcost, :drycost, :protcost, :hurrdam, :extratropicalstormsdam, :eloss_other, :species, :deadcost, :morbcost, :wetcost))[1:16*151,:]
    )
    return result
end

# Do you want to save your results (true = save results)?
save_results = true

models_cata = Dict(
    "m_nice_ssp1_cata" => m_nice_ssp1_cata, "m_nice_ssp2_cata" => m_nice_ssp2_cata, "m_nice_ssp3_cata" => m_nice_ssp3_cata, "m_nice_ssp4_cata" => m_nice_ssp4_cata, "m_nice_ssp5_cata" => m_nice_ssp5_cata,
    "m_nice_ssp1_cata_xi0" => m_nice_ssp1_cata_xi0, "m_nice_ssp2_cata_xi0" => m_nice_ssp2_cata_xi0, "m_nice_ssp3_cata_xi0" => m_nice_ssp3_cata_xi0, "m_nice_ssp4_cata_xi0" => m_nice_ssp4_cata_xi0, "m_nice_ssp5_cata_xi0" => m_nice_ssp5_cata_xi0,
    "m_nice_ssp1_cata_xim1" => m_nice_ssp1_cata_xim1, "m_nice_ssp2_cata_xim1" => m_nice_ssp2_cata_xim1, "m_nice_ssp3_cata_xim1" => m_nice_ssp3_cata_xim1, "m_nice_ssp4_cata_xim1" => m_nice_ssp4_cata_xim1, "m_nice_ssp5_cata_xim1" => m_nice_ssp5_cata_xim1,
)

for (n,m) in models_cata
    results = nice_cata_fund_mig(m)

    if save_results
        # Directory to save results.
        output_directory = joinpath(@__DIR__, "..", "results", "runs", string(n))
        mkdir(output_directory)
        
        # Save model output as CSV files.
        for f in results
            CSV.write(joinpath(output_directory, string(f[1], ".csv")), f[2])
        end
    end
end