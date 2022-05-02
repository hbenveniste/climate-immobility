using DelimitedFiles, CSV, VegaLite, FileIO, VegaDatasets, FilePaths
using Statistics, DataFrames, Query, Distributions

using MimiFUND

include("main_mig_nice.jl")
include("fund_ssp_ineq.jl")

################# Compare original FUND model with original scenarios, NICE-FUND with SSP scenarios, and Mig-NICE-FUND with SSP scenarios zero migration #################

# Run models
m_nice_ssp1_nomig = getmigrationnicemodel(scen="SSP1",migyesno="nomig",xi=1.0,omega=1.0)
m_nice_ssp2_nomig = getmigrationnicemodel(scen="SSP2",migyesno="nomig",xi=1.0,omega=1.0)
m_nice_ssp3_nomig = getmigrationnicemodel(scen="SSP3",migyesno="nomig",xi=1.0,omega=1.0)
m_nice_ssp4_nomig = getmigrationnicemodel(scen="SSP4",migyesno="nomig",xi=1.0,omega=1.0)
m_nice_ssp5_nomig = getmigrationnicemodel(scen="SSP5",migyesno="nomig",xi=1.0,omega=1.0)

m_fundnicessp1 = getsspnicemodel(scen="SSP1",migyesno="mig",xi=1.0,omega=1.0)
m_fundnicessp2 = getsspnicemodel(scen="SSP2",migyesno="mig",xi=1.0,omega=1.0)
m_fundnicessp3 = getsspnicemodel(scen="SSP3",migyesno="mig",xi=1.0,omega=1.0)
m_fundnicessp4 = getsspnicemodel(scen="SSP4",migyesno="mig",xi=1.0,omega=1.0)
m_fundnicessp5 = getsspnicemodel(scen="SSP5",migyesno="mig",xi=1.0,omega=1.0)

m_fund = getfund()

run(m_nice_ssp1_nomig;ntimesteps=151)
run(m_nice_ssp2_nomig;ntimesteps=151)
run(m_nice_ssp3_nomig;ntimesteps=151)
run(m_nice_ssp4_nomig;ntimesteps=151)
run(m_nice_ssp5_nomig;ntimesteps=151)
run(m_fundnicessp1;ntimesteps=151)
run(m_fundnicessp2;ntimesteps=151)
run(m_fundnicessp3;ntimesteps=151)
run(m_fundnicessp4;ntimesteps=151)
run(m_fundnicessp5;ntimesteps=151)
run(m_fund)

################################## Compare migrant flows obtained with Mig-NICE-FUND to those in original SSP ######################################
mig_f = CSV.read(joinpath(@__DIR__, "../input_data/sspmig_fundregions.csv"), DataFrame)
ssps = ["SSP1","SSP2","SSP3","SSP4","SSP5"]
regions = ["USA", "CAN", "WEU", "JPK", "ANZ", "EEU", "FSU", "MDE", "CAM", "LAM", "SAS", "SEA", "CHI", "MAF", "SSA", "SIS"]
years = 2015:2100

migmodel = DataFrame(
    year = repeat(years, outer = length(ssps)*length(regions)),
    scen = repeat(ssps,inner = length(regions)*length(years)),
    fundregion = repeat(regions, outer = length(ssps), inner=length(years)),
)
enter = vcat(
    collect(Iterators.flatten(sum(m_nice_ssp1_nomig[:migration,:entermig][MimiFUND.getindexfromyear(2015):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp2_nomig[:migration,:entermig][MimiFUND.getindexfromyear(2015):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp3_nomig[:migration,:entermig][MimiFUND.getindexfromyear(2015):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp4_nomig[:migration,:entermig][MimiFUND.getindexfromyear(2015):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp5_nomig[:migration,:entermig][MimiFUND.getindexfromyear(2015):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1]))
)
migmodel[:,:enter] = enter
leave = vcat(
    collect(Iterators.flatten(sum(m_nice_ssp1_nomig[:migration,:leavemig][MimiFUND.getindexfromyear(2015):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp2_nomig[:migration,:leavemig][MimiFUND.getindexfromyear(2015):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp3_nomig[:migration,:leavemig][MimiFUND.getindexfromyear(2015):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp4_nomig[:migration,:leavemig][MimiFUND.getindexfromyear(2015):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp5_nomig[:migration,:leavemig][MimiFUND.getindexfromyear(2015):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1]))
)
migmodel[:,:leave] = leave
popu = vcat(
    collect(Iterators.flatten(m_nice_ssp1_nomig[:population,:populationin1][MimiFUND.getindexfromyear(2015):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp2_nomig[:population,:populationin1][MimiFUND.getindexfromyear(2015):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp3_nomig[:population,:populationin1][MimiFUND.getindexfromyear(2015):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp4_nomig[:population,:populationin1][MimiFUND.getindexfromyear(2015):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp5_nomig[:population,:populationin1][MimiFUND.getindexfromyear(2015):MimiFUND.getindexfromyear(2100),:]))
)
migmodel[:,:pop] = popu

migmodel[:,:period] = migmodel[:,:year] .- map(x->mod(x,5),migmodel[:,:year])
migmodel_p = combine(d->(entermig = sum(d.enter)./10^3,leavemig = sum(d.leave)./10^3,pop=first(d.pop)./10^3), groupby(migmodel, [:scen,:fundregion,:period]))

comparemig = innerjoin(mig_f,migmodel_p,on=[:scen,:fundregion,:period])
rename!(comparemig, :popmig => :pop_SSP, :pop => :pop_migniceFUND, :entermig => :enter_migniceFUND, :leavemig => :leave_migniceFUND, :inmig =>:enter_SSP, :outmig =>:leave_SSP)

pop_world = combine(d->(worldpop_SSP=sum(d.pop_SSP),worldpop_migniceFUND=sum(d.pop_migniceFUND)), groupby(comparemig,[:period,:scen]))
pop_world_stack = stack(pop_world,[:worldpop_SSP,:worldpop_migniceFUND],[:scen,:period])
rename!(pop_world_stack,:variable => :worldpop_type, :value => :worldpop)
pop_world_stack |> @filter(_.period < 2100) |> @vlplot(
    width=300, height=250,
    mark={:point, size=60}, x = {"period:o", axis={labelFontSize=16}, title=nothing}, y = {"worldpop:q", title=nothing, axis={labelFontSize=16}}, 
    title = "Global population for Mig-NICE-FUND and original SSP", 
    color = {"scen:n", scale={scheme=:category10}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}, 
    shape = {"worldpop_type:o", scale={range=["triangle-up","circle"]}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}
) + @vlplot(
    mark={:line, strokeDash=[1,2]}, x = {"period:o", axis={labelFontSize=16}, title=nothing}, y = {"worldpop:q", aggregate=:mean,type=:quantitative,title=nothing, axis={labelFontSize=16}}, 
    color = {"scen:n", scale={scheme=:category10}},
    detail = "worldpop_type:o"
) |> save(joinpath(@__DIR__, "../results/migflow_ineq/", "pop_world_v5.png"))


############################## Compare migrant flows and population levels in Mig-NICE-FUND for different income elasticities of damages (xi) ######################
# Default is done above: damages within a given region proportional to income (xi=1)

# Damages within a given region independent of income (xi=0)
m_nice_ssp1_nomig_xi0 = getmigrationnicemodel(scen="SSP1",migyesno="nomig",xi=0.0,omega=1.0)
m_nice_ssp2_nomig_xi0 = getmigrationnicemodel(scen="SSP2",migyesno="nomig",xi=0.0,omega=1.0)
m_nice_ssp3_nomig_xi0 = getmigrationnicemodel(scen="SSP3",migyesno="nomig",xi=0.0,omega=1.0)
m_nice_ssp4_nomig_xi0 = getmigrationnicemodel(scen="SSP4",migyesno="nomig",xi=0.0,omega=1.0)
m_nice_ssp5_nomig_xi0 = getmigrationnicemodel(scen="SSP5",migyesno="nomig",xi=0.0,omega=1.0)
run(m_nice_ssp1_nomig_xi0;ntimesteps=151)
run(m_nice_ssp2_nomig_xi0;ntimesteps=151)
run(m_nice_ssp3_nomig_xi0;ntimesteps=151)
run(m_nice_ssp4_nomig_xi0;ntimesteps=151)
run(m_nice_ssp5_nomig_xi0;ntimesteps=151)

m_fundnicessp1_xi0 = getsspnicemodel(scen="SSP1",migyesno="mig",xi=0.0,omega=1.0)
m_fundnicessp2_xi0 = getsspnicemodel(scen="SSP2",migyesno="mig",xi=0.0,omega=1.0)
m_fundnicessp3_xi0 = getsspnicemodel(scen="SSP3",migyesno="mig",xi=0.0,omega=1.0)
m_fundnicessp4_xi0 = getsspnicemodel(scen="SSP4",migyesno="mig",xi=0.0,omega=1.0)
m_fundnicessp5_xi0 = getsspnicemodel(scen="SSP5",migyesno="mig",xi=0.0,omega=1.0)
run(m_fundnicessp1_xi0)
run(m_fundnicessp2_xi0)
run(m_fundnicessp3_xi0)
run(m_fundnicessp4_xi0)
run(m_fundnicessp5_xi0)

# Damages within a given region inversely proportional to income (xi=-1)
m_nice_ssp1_nomig_xim1 = getmigrationnicemodel(scen="SSP1",migyesno="nomig",xi=-1.0,omega=1.0)
m_nice_ssp2_nomig_xim1 = getmigrationnicemodel(scen="SSP2",migyesno="nomig",xi=-1.0,omega=1.0)
m_nice_ssp3_nomig_xim1 = getmigrationnicemodel(scen="SSP3",migyesno="nomig",xi=-1.0,omega=1.0)
m_nice_ssp4_nomig_xim1 = getmigrationnicemodel(scen="SSP4",migyesno="nomig",xi=-1.0,omega=1.0)
m_nice_ssp5_nomig_xim1 = getmigrationnicemodel(scen="SSP5",migyesno="nomig",xi=-1.0,omega=1.0)
run(m_nice_ssp1_nomig_xim1;ntimesteps=151)
run(m_nice_ssp2_nomig_xim1;ntimesteps=151)
run(m_nice_ssp3_nomig_xim1;ntimesteps=151)
run(m_nice_ssp4_nomig_xim1;ntimesteps=151)
run(m_nice_ssp5_nomig_xim1;ntimesteps=151)

m_fundnicessp1_xim1 = getsspnicemodel(scen="SSP1",migyesno="mig",xi=-1.0,omega=1.0)
m_fundnicessp2_xim1 = getsspnicemodel(scen="SSP2",migyesno="mig",xi=-1.0,omega=1.0)
m_fundnicessp3_xim1 = getsspnicemodel(scen="SSP3",migyesno="mig",xi=-1.0,omega=1.0)
m_fundnicessp4_xim1 = getsspnicemodel(scen="SSP4",migyesno="mig",xi=-1.0,omega=1.0)
m_fundnicessp5_xim1 = getsspnicemodel(scen="SSP5",migyesno="mig",xi=-1.0,omega=1.0)
run(m_fundnicessp1_xim1)
run(m_fundnicessp2_xim1)
run(m_fundnicessp3_xim1)
run(m_fundnicessp4_xim1)
run(m_fundnicessp5_xim1)


years = 1951:2100

migration = DataFrame(
    year = repeat(years, outer = length(ssps)*length(regions)),
    scen = repeat(ssps,inner = length(regions)*length(years)),
    fundregion = repeat(regions, outer = length(ssps), inner=length(years)),
)
enter_xi1 = vcat(
    collect(Iterators.flatten(sum(m_nice_ssp1_nomig[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp2_nomig[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp3_nomig[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp4_nomig[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp5_nomig[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1]))
)
migration[:,:enter_xi1] = enter_xi1
leave_xi1 = vcat(
    collect(Iterators.flatten(sum(m_nice_ssp1_nomig[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp2_nomig[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp3_nomig[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp4_nomig[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp5_nomig[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1]))
)
migration[:,:leave_xi1] = leave_xi1
popu_xi1 = vcat(
    collect(Iterators.flatten(m_nice_ssp1_nomig[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp2_nomig[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp3_nomig[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp4_nomig[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp5_nomig[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
migration[:,:pop_xi1] = popu_xi1

enter_xi0 = vcat(
    collect(Iterators.flatten(sum(m_nice_ssp1_nomig_xi0[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp2_nomig_xi0[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp3_nomig_xi0[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp4_nomig_xi0[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp5_nomig_xi0[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1]))
)
migration[:,:enter_xi0] = enter_xi0
leave_xi0 = vcat(
    collect(Iterators.flatten(sum(m_nice_ssp1_nomig_xi0[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp2_nomig_xi0[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp3_nomig_xi0[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp4_nomig_xi0[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp5_nomig_xi0[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1]))
)
migration[:,:leave_xi0] = leave_xi0
popu_xi0 = vcat(
    collect(Iterators.flatten(m_nice_ssp1_nomig_xi0[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp2_nomig_xi0[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp3_nomig_xi0[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp4_nomig_xi0[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp5_nomig_xi0[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
migration[:,:pop_xi0] = popu_xi0

enter_xim1 = vcat(
    collect(Iterators.flatten(sum(m_nice_ssp1_nomig_xim1[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp2_nomig_xim1[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp3_nomig_xim1[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp4_nomig_xim1[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp5_nomig_xim1[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1]))
)
migration[:,:enter_xim1] = enter_xim1
leave_xim1 = vcat(
    collect(Iterators.flatten(sum(m_nice_ssp1_nomig_xim1[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp2_nomig_xim1[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp3_nomig_xim1[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp4_nomig_xim1[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp5_nomig_xim1[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1]))
)
migration[:,:leave_xim1] = leave_xim1
popu_xim1 = vcat(
    collect(Iterators.flatten(m_nice_ssp1_nomig_xim1[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp2_nomig_xim1[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp3_nomig_xim1[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp4_nomig_xim1[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp5_nomig_xim1[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
migration[:,:pop_xim1] = popu_xim1

# Look at emigrants without residual from gravity (residual same for all SSP, xi, CC or not)
migration[!,:leave_gravres] = repeat(sum(m_nice_ssp2_nomig[:migration,:gravres_qi],dims=[2,3,4])[:,1,1,1],inner=length(1951:2100),outer=length(ssps))

migration_p = migration[(map(x->mod(x,10)==0,migration[:,:year])),:]

pop_all = stack(
    rename(migration, :pop_xi1 => :pop_damageprop, :pop_xi0 => :pop_damageindep, :pop_xim1 => :pop_damageinvprop), 
    [:pop_damageprop,:pop_damageindep,:pop_damageinvprop], 
    [:scen, :fundregion, :year]
)
rename!(pop_all, :variable => :pop_type, :value => :pop)
for s in ssps
    pop_all |> @filter(_.year >= 2015 && _.year <= 2100 && _.scen == s) |> @vlplot(
        mark={:line, strokeWidth = 4}, width=300, height=250, columns=4, wrap="fundregion:o", 
        x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
        y={"pop:q", title = nothing, axis={labelFontSize=16}},
        color={"pop_type:o",scale={scheme=:darkmulti},legend={titleFontSize=16, symbolSize=40, labelFontSize=16}},
        resolve = {scale={y=:independent}}
    ) |> save(joinpath(@__DIR__, "../results/migflow_ineq/", string("pop_",s,"_v5.png")))
end
pop_all[!,:scen_pop_type] = [string(pop_all[i,:scen],"_",SubString(string(pop_all[i,:pop_type]),4)) for i in 1:size(pop_all,1)]
pop_all |> @filter(_.year >= 2015 && _.year <= 2100) |> @vlplot(
    mark={:line, strokeWidth = 4}, width=300, height=250, columns=4, wrap="fundregion:o", 
    x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
    y={"pop:q", title = nothing, axis={labelFontSize=16}},
    title = "Income per capita for world regions, SSP narratives and various income elasticities of damages",
    color={"scen_pop_type:o",scale={scheme=:category20c},legend={titleFontSize=16, symbolSize=40, labelFontSize=16}},
    resolve = {scale={y=:independent}}
) |> save(joinpath(@__DIR__, "../results/migflow_ineq/", string("pop_v5.png")))


worldpop = DataFrame(
    year = repeat(years, outer = length(ssps)),
    scen = repeat(ssps,inner = length(years)),
)
worldpop_sspniceFUND = vcat(
    collect(Iterators.flatten(m_fundnicessp1[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_fundnicessp2[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_fundnicessp3[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_fundnicessp4[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_fundnicessp5[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)]))
)
worldpop[:,:worldpop_sspniceFUND] = worldpop_sspniceFUND
worldpop_migniceFUND = vcat(
    collect(Iterators.flatten(m_nice_ssp1_nomig[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_nice_ssp2_nomig[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_nice_ssp3_nomig[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_nice_ssp4_nomig[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_nice_ssp5_nomig[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)]))
)
worldpop[:,:worldpop_migniceFUND] = worldpop_migniceFUND
worldpop_xi1 = vcat(
    collect(Iterators.flatten(m_nice_ssp1_nomig[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_nice_ssp2_nomig[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_nice_ssp3_nomig[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_nice_ssp4_nomig[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_nice_ssp5_nomig[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)]))
)
worldpop[:,:worldpop_xi1] = worldpop_xi1
worldpop_xi0 = vcat(
    collect(Iterators.flatten(m_nice_ssp1_nomig_xi0[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_nice_ssp2_nomig_xi0[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_nice_ssp3_nomig_xi0[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_nice_ssp4_nomig_xi0[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_nice_ssp5_nomig_xi0[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)]))
)
worldpop[:,:worldpop_xi0] = worldpop_xi0
worldpop_xim1 = vcat(
    collect(Iterators.flatten(m_nice_ssp1_nomig_xim1[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_nice_ssp2_nomig_xim1[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_nice_ssp3_nomig_xim1[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_nice_ssp4_nomig_xim1[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_nice_ssp5_nomig_xim1[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)]))
)
worldpop[:,:worldpop_xim1] = worldpop_xim1

worldpop_p = worldpop[(map(x->mod(x,10)==0,worldpop[:,:year])),:]

worldpop_stack = stack(worldpop_p,[:worldpop_xi1,:worldpop_xi0,:worldpop_xim1],[:scen,:year])
rename!(worldpop_stack,:variable => :worldpop_type, :value => :worldpop)
worldpop_stack |> @filter(_.year >= 2015 && _.year <= 2100) |> @vlplot(
    width=300, height=250,
    mark={:point, size=50}, x = {"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing}, y = {"worldpop:q", title=nothing, axis={labelFontSize=16}}, 
    title = "Global population for Mig-NICE-FUND with various income elasticities of damages", 
    color = {"scen:n", scale={scheme=:category10}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}, 
    shape = {"worldpop_type:o", scale={range=["circle", "triangle-up", "square"]}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}
) + @vlplot(
    mark={:line, strokeDash=[1,2]}, x = {"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing}, y = {"worldpop:q", aggregate=:mean,type=:quantitative,title=nothing, axis={labelFontSize=16}}, 
    color = {"scen:n", scale={scheme=:category10}},
    detail = "worldpop_type:o"
) |> save(joinpath(@__DIR__, "../results/migflow_ineq/", "pop_world_xi_v5.png"))


migration_quint = DataFrame(
    year = repeat(years, outer = length(ssps)*length(regions)*5),
    scen = repeat(ssps,inner = length(regions)*length(years)*5),
    fundregion = repeat(regions, outer = length(ssps)*5, inner=length(years)),
    quintile = repeat(1:5, outer = length(ssps), inner=length(years)*length(regions))
)
enter_quint_xi1 = vcat(
    collect(Iterators.flatten(m_nice_ssp1_nomig[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp2_nomig[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp3_nomig[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp4_nomig[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp5_nomig[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))
)
migration_quint[:,:enter_quint_xi1] = enter_quint_xi1
leave_quint_xi1 = vcat(
    collect(Iterators.flatten(m_nice_ssp1_nomig[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp2_nomig[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp3_nomig[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp4_nomig[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp5_nomig[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))
)
migration_quint[:,:leave_quint_xi1] = leave_quint_xi1

enter_quint_xi0 = vcat(
    collect(Iterators.flatten(m_nice_ssp1_nomig_xi0[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp2_nomig_xi0[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp3_nomig_xi0[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp4_nomig_xi0[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp5_nomig_xi0[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))
)
migration_quint[:,:enter_quint_xi0] = enter_quint_xi0
leave_quint_xi0 = vcat(
    collect(Iterators.flatten(m_nice_ssp1_nomig_xi0[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp2_nomig_xi0[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp3_nomig_xi0[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp4_nomig_xi0[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp5_nomig_xi0[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))
)
migration_quint[:,:leave_quint_xi0] = leave_quint_xi0

enter_quint_xim1 = vcat(
    collect(Iterators.flatten(m_nice_ssp1_nomig_xim1[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp2_nomig_xim1[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp3_nomig_xim1[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp4_nomig_xim1[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp5_nomig_xim1[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))
)
migration_quint[:,:enter_quint_xim1] = enter_quint_xim1
leave_quint_xim1 = vcat(
    collect(Iterators.flatten(m_nice_ssp1_nomig_xim1[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp2_nomig_xim1[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp3_nomig_xim1[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp4_nomig_xim1[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp5_nomig_xim1[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))
)
migration_quint[:,:leave_quint_xim1] = leave_quint_xim1

# Look at emigrants without residual from gravity (residual same for all SSP, xi, CC or not)
migration_quint[!,:leave_quint_gravres] = repeat(collect(Iterators.flatten(sum(m_nice_ssp2_nomig[:migration,:gravres_qi],dims=[2,4])[:,1,:,1])),inner=length(1951:2100),outer=length(ssps))

migration_quint_p = migration_quint[(map(x->mod(x,10)==0,migration_quint[:,:year])),:]


###################################### Plot number of people leaving and entering a given place and quintile ###########################
leave_quint = stack(
    rename(migration_quint_p, :leave_quint_xi1 => :leave_quint_damageprop, :leave_quint_xi0 => :leave_quint_damageindep, :leave_quint_xim1 => :leave_quint_damageinvprop), 
    [:leave_quint_damageprop,:leave_quint_damageindep,:leave_quint_damageinvprop], 
    [:scen, :quintile ,:fundregion, :year]
)
rename!(leave_quint, :variable => :leave_type, :value => :leave_quint)
leave_quint[!,:leave_type] = map(x->SubString(String(x), 13), leave_quint[:,:leave_type])
leave_quint[!,:type_name] = [leave_quint[i,:leave_type]=="damageprop" ? "proportional" : (leave_quint[i,:leave_type]=="damageindep" ? "independent" : "inversely prop.") for i in 1:size(leave_quint,1)]
regions_fullname = DataFrame(
    fundregion=regions,
    regionname = ["United States","Canada","Western Europe", "Japan & South Korea","Australia & New Zealand","Central & Eastern Europe","Former Soviet Union", "Middle East", "Central America", "South America","South Asia","Southeast Asia","China plus", "North Africa","Sub-Saharan Africa","Small Island States"]
)
leave_quint = innerjoin(leave_quint, regions_fullname, on =:fundregion)
for s in ssps
    leave_quint |> @filter(_.year >= 2015 && _.year <= 2100 && _.scen == s) |> @vlplot(
        mark={:point,size=60}, width=300, height=250, columns=4, wrap={"regionname:o", title=nothing, header={labelFontSize=24}}, 
        x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
        y={"leave_quint:q", title = "Total emigrants", axis={labelFontSize=20,titleFontSize=20}},
        color={"quintile:o",scale={scheme=:darkmulti},legend={title = "Quintile", titleFontSize=20, symbolSize=80, labelFontSize=20}},
        shape={"type_name:o",scale={range=["circle","triangle-up","square"],domain=["proportional","independent","inversely prop."]},legend={title = "Damages elasticity", titleFontSize=20, titleLimit=260, symbolSize=80, labelFontSize=20}},
        resolve = {scale={y=:independent}}
    ) |> save(joinpath(@__DIR__, "../results/migflow_ineq/", string("leave_quint_",s,"_v5.png")))
end
for s in ssps
    leave_quint |> @filter(_.year >= 2015 && _.year <= 2100 && _.scen == s && _.leave_type == "damageinvprop") |> @vlplot(
        mark={:line,point={filled=true,size=80}}, width=300, height=250, columns=4, wrap={"regionname:o", title=nothing, header={labelFontSize=24}}, 
        x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
        y={"leave_quint:q", title = "Total emigrants", axis={labelFontSize=20,titleFontSize=20}},
        color={"quintile:o",scale={scheme=:darkmulti},legend={title = "Quintile", titleFontSize=20, symbolSize=80, labelFontSize=20, offset=40}},
        #shape={"leave_type:o",legend={title = "Damages elasticity", titleFontSize=20, titleLimit=260, symbolSize=80, labelFontSize=20}},
        resolve = {scale={y=:independent}}
    ) |> save(joinpath(@__DIR__, "../results/migflow_ineq/", string("leave_quint_daminvprop_",s,"_v5.pdf")))
end
leave_quint |> @filter(_.year >= 2015 && _.year <= 2100 && _.scen == "SSP2" && _.leave_type == "damageindep" && _.fundregion == "LAM") |> @vlplot(
    mark={:line,point={filled=true,size=80}}, width=300, height=250, 
    x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
    y={"leave_quint:q", title = "Total emigrants", axis={labelFontSize=20,titleFontSize=20}},
    color={"quintile:o",scale={scheme=:darkmulti},legend={title = "Quintile", titleFontSize=20, symbolSize=80, labelFontSize=20}},
    title= "South America", config={title={fontSize=24}}
) |> save(joinpath(@__DIR__, "../results/migflow_ineq/", string("leave_quint_LAM_damindep_SSP2_v5.png")))

enter_quint = stack(
    rename(migration_quint_p, :enter_quint_xi1 => :enter_quint_damageprop, :enter_quint_xi0 => :enter_quint_damageindep, :enter_quint_xim1 => :enter_quint_damageinvprop), 
    [:enter_quint_damageprop,:enter_quint_damageindep,:enter_quint_damageinvprop], 
    [:scen, :quintile ,:fundregion, :year]
)
rename!(enter_quint, :variable => :enter_type, :value => :enter_quint)
enter_quint[!,:enter_type] = map(x->SubString(String(x), 13), enter_quint[:,:enter_type])
enter_quint = innerjoin(enter_quint, regions_fullname, on =:fundregion)
for s in ssps
    enter_quint |> @filter(_.year >= 2015 && _.year <= 2100 && _.scen == s) |> @vlplot(
        mark={:point,size=60}, width=300, height=250, columns=4, wrap={"regionname:o", title=nothing, header={labelFontSize=24}}, 
        x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
        y={"enter_quint:q", title = "Total immigrants", axis={labelFontSize=20,titleFontSize=20}},
        color={"quintile:o",scale={scheme=:darkmulti},legend={title = "Quintile", titleFontSize=20, symbolSize=80, labelFontSize=20}},
        shape={"enter_type:o",legend={title = "Damages elasticity", titleFontSize=20, titleLimit=260, symbolSize=80, labelFontSize=20}},
        resolve = {scale={y=:independent}}
    ) |> save(joinpath(@__DIR__, "../results/migflow_ineq/", string("enter_quint_",s,"_v5.png")))
end
for s in ssps
    enter_quint |> @filter(_.year >= 2015 && _.year <= 2100 && _.scen == s && _.enter_type == "damageinvprop") |> @vlplot(
        mark={:line,point={filled=true,size=80}}, width=300, height=250, columns=4, wrap={"regionname:o", title=nothing, header={labelFontSize=24}}, 
        x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
        y={"enter_quint:q", title = "Total immigrants", axis={labelFontSize=20,titleFontSize=20}},
        color={"quintile:o",scale={scheme=:darkmulti},legend={title = "Quintile", titleFontSize=20, symbolSize=80, labelFontSize=20,offset=20}},
        #shape={"enter_type:o",legend={title = "Damages elasticity", titleFontSize=20, titleLimit=260, symbolSize=80, labelFontSize=20}},
        resolve = {scale={y=:independent}}
    ) |> save(joinpath(@__DIR__, "../results/migflow_ineq/", string("enter_quint_daminvprop_",s,"_v5.pdf")))
end
enter_quint |> @filter(_.year >= 2015 && _.year <= 2100 && _.scen == "SSP2" && _.enter_type == "damageindep" && _.fundregion == "LAM") |> @vlplot(
    mark={:line,point={filled=true,size=80}}, width=300, height=250, 
    x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
    y={"enter_quint:q", title = "Total immigrants", axis={labelFontSize=20,titleFontSize=20}},
    color={"quintile:o",scale={scheme=:darkmulti},legend={title = "Quintile", titleFontSize=20, symbolSize=80, labelFontSize=20}},
    title= "South America", config={title={fontSize=24}}
) |> save(joinpath(@__DIR__, "../results/migflow_ineq/", string("enter_quint_LAM_damindep_SSP2_v5.png")))


mig_quint_all = stack(
    rename(migration_quint, :enter_quint_xi1 => :enter_quint_damprop, :enter_quint_xi0 => :enter_quint_damindep, :enter_quint_xim1 => :enter_quint_daminvprop, :leave_quint_xi1 => :leave_quint_damprop, :leave_quint_xi0 => :leave_quint_damindep, :leave_quint_xim1 => :leave_quint_daminvprop), 
    [:enter_quint_damprop, :enter_quint_damindep, :enter_quint_daminvprop, :leave_quint_damprop, :leave_quint_damindep, :leave_quint_daminvprop], 
    [:scen, :quintile, :fundregion, :year]
)
rename!(mig_quint_all, :variable => :mig_type, :value => :mig)
mig_quint_all[!,:mig_quint] = [in(mig_quint_all[i,:mig_type], [:leave_quint_damprop,:leave_quint_damindep,:leave_quint_daminvprop]) ? mig_quint_all[i,:mig] * (-1) : mig_quint_all[i,:mig] for i in 1:size(mig_quint_all,1)]
for s in ssps
    mig_quint_all |> @filter(_.year >= 2015 && _.year <= 2100 && _.scen == s) |> @vlplot(
        mark={:point,size=60}, width=300, height=250, columns=4, wrap="fundregion:o", 
        x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
        y={"mig_quint:q", title = nothing, axis={labelFontSize=16}},
        color={"quintile:o",scale={scheme=:darkmulti},legend={titleFontSize=16, symbolSize=40, labelFontSize=16}},
        shape={"mig_type:o",legend={titleFontSize=16, symbolSize=40, labelFontSize=16}},
        resolve = {scale={y=:independent}}
    ) |> save(joinpath(@__DIR__, "../results/migflow_ineq/", string("mig_quint_",s,"_v5.png")))
end

migration_quint[!,:netmig_quint_damageprop] = migration_quint[!,:enter_quint_xi1] .- migration_quint[!,:leave_quint_xi1]
migration_quint[!,:netmig_quint_damageindep] = migration_quint[!,:enter_quint_xi0] .- migration_quint[!,:leave_quint_xi0]
migration_quint[!,:netmig_quint_damageinvprop] = migration_quint[!,:enter_quint_xim1] .- migration_quint[!,:leave_quint_xim1]

netmig_quint_all = stack(
    migration_quint, 
    [:netmig_quint_damageprop,:netmig_quint_damageindep,:netmig_quint_damageinvprop], 
    [:scen, :quintile, :fundregion, :year]
)
rename!(netmig_quint_all, :variable => :netmig_quint_type, :value => :netmig_quint)
netmig_quint_all = innerjoin(netmig_quint_all,regions_fullname, on=:fundregion)
netmig_quint_all_p = netmig_quint_all[(map(x->mod(x,10)==0,netmig_quint_all[:,:year])),:]
netmig_quint_all_p[!,:netmig_quint_type] = map(x->SubString(String(x), 14), netmig_quint_all_p[:,:netmig_quint_type])
netmig_quint_all_p[!,:type_name] = [netmig_quint_all_p[i,:netmig_quint_type]=="damageprop" ? "proportional" : (netmig_quint_all_p[i,:netmig_quint_type]=="damageindep" ? "independent" : "inversely prop.") for i in 1:size(netmig_quint_all_p,1)]

for s in ssps
    netmig_quint_all_p |> @filter(_.year >= 2015 && _.year <= 2100 && _.scen == s) |> @vlplot(
        mark={:point,size=60}, width=300, height=250, columns=4, wrap={"regionname:o", title=nothing, header={labelFontSize=24}}, 
        x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
        y={"netmig_quint:q", title = "Net migrants", axis={labelFontSize=16,titleFontSize=16}},
        color={"quintile:o",scale={scheme=:darkmulti},legend={title=string("Quintile, ",s), titleFontSize=20, titleLimit=220, symbolSize=80, labelFontSize=20}},
        shape={"type_name:o",scale={range=["circle","triangle-up","square"],domain=["proportional","independent","inversely prop."]},legend={title = "Damages elasticity", titleFontSize=20, titleLimit=260, symbolSize=80, labelFontSize=20}},
        resolve = {scale={y=:independent}}
    ) |> save(joinpath(@__DIR__, "../results/migflow_ineq/", string("netmig_quint_",s,"_v5.png")))
end

migration_quint = innerjoin(migration_quint, migration[:,[:year,:scen,:fundregion,:leave_xi1,:leave_xi0,:leave_xim1]], on=[:scen,:year,:fundregion])
migration_quint[!,:leave_share_xi1] = migration_quint[:,:leave_quint_xi1] ./ migration_quint[:,:leave_xi1]
migration_quint[!,:leave_share_xi0] = migration_quint[:,:leave_quint_xi0] ./ migration_quint[:,:leave_xi0]
migration_quint[!,:leave_share_xim1] = migration_quint[:,:leave_quint_xim1] ./ migration_quint[:,:leave_xim1]
for i in 1:size(migration_quint, 1)
    if migration_quint[i,:leave_xi1] == 0.0 ; migration_quint[i,:leave_share_xi1] = 0.0 end
    if migration_quint[i,:leave_xi0] == 0.0 ; migration_quint[i,:leave_share_xi0] = 0.0 end
    if migration_quint[i,:leave_xim1] == 0.0 ; migration_quint[i,:leave_share_xim1] = 0.0 end
end

migration_quint_p = migration_quint[(map(x->mod(x,10)==0,migration_quint[:,:year])),:]

leave_share = stack(
    rename(migration_quint_p, :leave_share_xi1 => :leave_share_damageprop,:leave_share_xi0 => :leave_share_damageindep, :leave_share_xim1 => :leave_share_damageinvprop), 
    [:leave_share_damageprop,:leave_share_damageindep,:leave_share_damageinvprop], 
    [:scen, :quintile ,:fundregion, :year]
)
rename!(leave_share, :variable => :leave_share_type, :value => :leave_share)
for s in ssps
    leave_share |> @filter(_.year >= 2015 && _.year <= 2100 && _.scen == s) |> @vlplot(
        mark={:point,size=60}, width=300, height=250, columns=4, wrap="fundregion:o", 
        x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
        y={"leave_share:q", title = nothing, axis={labelFontSize=16}},
        color={"quintile:o",scale={scheme=:darkmulti},legend={titleFontSize=16, symbolSize=40, labelFontSize=16}},
        shape={"leave_share_type:o",legend={titleFontSize=16, symbolSize=40, labelFontSize=16}},
        resolve = {scale={y=:independent}}
    ) |> save(joinpath(@__DIR__, "../results/migflow_ineq/", string("leave_share_",s,"_v5.png")))
end


############################################ Look at migrant stocks ######################################################
migstock_xi1 = vcat(
    collect(Iterators.flatten(sum(m_nice_ssp1_nomig[:migration,:migstock][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:,:,:],dims=[2,4])[:,1,:,1,:])),
    collect(Iterators.flatten(sum(m_nice_ssp2_nomig[:migration,:migstock][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:,:,:],dims=[2,4])[:,1,:,1,:])),
    collect(Iterators.flatten(sum(m_nice_ssp3_nomig[:migration,:migstock][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:,:,:],dims=[2,4])[:,1,:,1,:])),
    collect(Iterators.flatten(sum(m_nice_ssp4_nomig[:migration,:migstock][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:,:,:],dims=[2,4])[:,1,:,1,:])),
    collect(Iterators.flatten(sum(m_nice_ssp5_nomig[:migration,:migstock][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:,:,:],dims=[2,4])[:,1,:,1,:]))
)
migration_quint[:,:migstock_xi1] = migstock_xi1
migstock_xi0 = vcat(
    collect(Iterators.flatten(sum(m_nice_ssp1_nomig_xi0[:migration,:migstock][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:,:,:],dims=[2,4])[:,1,:,1,:])),
    collect(Iterators.flatten(sum(m_nice_ssp2_nomig_xi0[:migration,:migstock][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:,:,:],dims=[2,4])[:,1,:,1,:])),
    collect(Iterators.flatten(sum(m_nice_ssp3_nomig_xi0[:migration,:migstock][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:,:,:],dims=[2,4])[:,1,:,1,:])),
    collect(Iterators.flatten(sum(m_nice_ssp4_nomig_xi0[:migration,:migstock][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:,:,:],dims=[2,4])[:,1,:,1,:])),
    collect(Iterators.flatten(sum(m_nice_ssp5_nomig_xi0[:migration,:migstock][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:,:,:],dims=[2,4])[:,1,:,1,:]))
)
migration_quint[:,:migstock_xi0] = migstock_xi0
migstock_xim1 = vcat(
    collect(Iterators.flatten(sum(m_nice_ssp1_nomig_xim1[:migration,:migstock][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:,:,:],dims=[2,4])[:,1,:,1,:])),
    collect(Iterators.flatten(sum(m_nice_ssp2_nomig_xim1[:migration,:migstock][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:,:,:],dims=[2,4])[:,1,:,1,:])),
    collect(Iterators.flatten(sum(m_nice_ssp3_nomig_xim1[:migration,:migstock][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:,:,:],dims=[2,4])[:,1,:,1,:])),
    collect(Iterators.flatten(sum(m_nice_ssp4_nomig_xim1[:migration,:migstock][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:,:,:],dims=[2,4])[:,1,:,1,:])),
    collect(Iterators.flatten(sum(m_nice_ssp5_nomig_xim1[:migration,:migstock][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:,:,:],dims=[2,4])[:,1,:,1,:]))
)
migration_quint[:,:migstock_xim1] = migstock_xim1

migration_quint_p = migration_quint[(map(x->mod(x,10)==0,migration_quint[:,:year])),:]

migstock_quint = stack(
    rename(migration_quint_p, :migstock_xi1 => :migstock_damageprop, :migstock_xi0 => :migstock_damageindep, :migstock_xim1 => :migstock_damageinvprop), 
    [:migstock_damageprop,:migstock_damageindep,:migstock_damageinvprop], 
    [:scen, :quintile ,:fundregion, :year]
)
rename!(migstock_quint, :variable => :migstock_type, :value => :migstock)
migstock_quint[!,:migstock_type] = map(x->SubString(String(x), 10), migstock_quint[:,:migstock_type])
migstock_quint[!,:type_name] = [migstock_quint[i,:migstock_type]=="damageprop" ? "proportional" : (migstock_quint[i,:migstock_type]=="damageindep" ? "independent" : "inversely prop.") for i in 1:size(migstock_quint,1)]
migstock_quint = innerjoin(migstock_quint, regions_fullname, on =:fundregion)
for s in ssps
    migstock_quint |> @filter(_.year >= 2015 && _.year <= 2100 && _.scen == s) |> @vlplot(
        mark={:point,size=60}, width=300, height=250, columns=4, wrap={"regionname:o", title=nothing, header={labelFontSize=24}}, 
        x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
        y={"migstock:q", title = "Immigrants stock", axis={labelFontSize=20,titleFontSize=20}},
        color={"quintile:o",scale={scheme=:darkmulti},legend={title = "Quintile", titleFontSize=20, symbolSize=80, labelFontSize=20}},
        shape={"type_name:o",scale={range=["circle","triangle-up","square"],domain=["proportional","independent","inversely prop."]},legend={title = "Damages elasticity", titleFontSize=20, titleLimit=260, symbolSize=80, labelFontSize=20}},
        resolve = {scale={y=:independent}}
    ) |> save(joinpath(@__DIR__, "../results/migflow_ineq/", string("migstock_quint_",s,"_v5.png")))
end


#################################### Look at net migrant flows for different income elasticities of damages ######################################
migration[!,:netmig_damageprop] = migration[!,:enter_xi1] .- migration[!,:leave_xi1]
migration[!,:netmig_damageindep] = migration[!,:enter_xi0] .- migration[!,:leave_xi0]
migration[!,:netmig_damageinvprop] = migration[!,:enter_xim1] .- migration[!,:leave_xim1]

netmig_all = stack(
    migration, 
    [:netmig_damageprop,:netmig_damageindep,:netmig_damageinvprop], 
    [:scen, :fundregion, :year]
)
rename!(netmig_all, :variable => :netmig_type, :value => :netmig)
netmig_all = innerjoin(netmig_all,regions_fullname, on=:fundregion)

for s in ssps
    netmig_all |> @filter(_.year >= 2015 && _.year <= 2100 && _.scen == s) |> @vlplot(
        mark={:line, strokeWidth = 4}, width=300, height=250, columns=4, wrap={"regionname:o", title=nothing, header={labelFontSize=24}}, 
        x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
        y={"netmig:q", title = "Net migrants", axis={labelFontSize=16,titleFontSize=16}},
        color={"netmig_type:o",scale={scheme=:darkmulti},legend={title=string("Net migration, ",s), titleFontSize=20, titleLimit=220, symbolSize=60, labelFontSize=24, labelLimit=280, offset=2}},
        resolve = {scale={y=:independent}}
    ) |> save(joinpath(@__DIR__, "../results/migflow_ineq/", string("netmig_",s,"_v5.png")))
end
netmig_all[!,:scen_netmig_type] = [string(netmig_all[i,:scen],"_",SubString(string(netmig_all[i,:netmig_type]),8)) for i in 1:size(netmig_all,1)]
netmig_all |> @filter(_.year >= 2015 && _.year <= 2100) |> @vlplot(
    mark={:line, strokeWidth = 4}, width=300, height=250, columns=4, wrap="fundregion:o", 
    x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
    y={"netmig:q", title = nothing, axis={labelFontSize=16}},
    title = "Net migration flows for world regions, SSP narratives and various income elasticities of damages",
    color={"scen_netmig_type:o",scale={scheme=:category20c},legend={titleFontSize=16, symbolSize=40, labelFontSize=16}},
    resolve = {scale={y=:independent}}
) |> save(joinpath(@__DIR__, "../results/migflow_ineq/", string("netmig_v5.png")))

mig_all = stack(
    rename(migration, :enter_xi1 => :enter_damageprop, :enter_xi0 => :enter_damageindep, :enter_xim1 => :enter_damageinvprop, :leave_xi1 => :leave_damageprop, :leave_xi0 => :leave_damageindep, :leave_xim1 => :leave_damageinvprop), 
    [:enter_damageprop, :enter_damageindep, :enter_damageinvprop, :leave_damageprop, :leave_damageindep, :leave_damageinvprop], 
    [:scen, :fundregion, :year]
)
rename!(mig_all, :variable => :mig_type, :value => :mig)
mig_all[!,:mig] = [in(mig_all[i,:mig_type], [:leave_damageprop,:leave_damageindep,:leave_damageinvprop]) ? mig_all[i,:mig] * (-1) : mig_all[i,:mig] for i in 1:size(mig_all,1)]
mig_all = innerjoin(mig_all,regions_fullname, on=:fundregion)
for s in ssps
    mig_all |> @filter(_.year >= 2015 && _.year <= 2100 && _.scen == s) |> @vlplot(
        mark={:line, strokeWidth = 4}, width=300, height=250, columns=4, wrap={"regionname:o", title=nothing, header={labelFontSize=24}}, 
        x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
        y={"mig:q", title = nothing, axis={labelFontSize=16}},
        color={"mig_type:o",scale={scheme="category20c"},legend={title=nothing, symbolSize=60, labelFontSize=20, labelLimit=220,}},
        resolve = {scale={y=:independent}}
    ) |> save(joinpath(@__DIR__, "../results/migflow_ineq/", string("mig_",s,"_v5.png")))
end


############################################# Plot heat tables of migrant flows in 2100 ############################################################
move = DataFrame(
    year = repeat(years, outer = length(ssps)*length(regions)*length(regions)),
    scen = repeat(ssps,inner = length(regions)*length(years)*length(regions)),
    origin = repeat(regions, outer = length(ssps)*length(regions), inner=length(years)),
    destination = repeat(regions, outer = length(ssps), inner=length(years)*length(regions))
)

move_xi1 = vcat(
    collect(Iterators.flatten(sum(m_nice_ssp1_nomig[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:,:,:],dims=[4,5])[:,:,:,1,1])),
    collect(Iterators.flatten(sum(m_nice_ssp2_nomig[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:,:,:],dims=[4,5])[:,:,:,1,1])),
    collect(Iterators.flatten(sum(m_nice_ssp3_nomig[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:,:,:],dims=[4,5])[:,:,:,1,1])),
    collect(Iterators.flatten(sum(m_nice_ssp4_nomig[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:,:,:],dims=[4,5])[:,:,:,1,1])),
    collect(Iterators.flatten(sum(m_nice_ssp5_nomig[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:,:,:],dims=[4,5])[:,:,:,1,1]))
)
move[:,:move_xi1] = move_xi1
move_xi0 = vcat(
    collect(Iterators.flatten(sum(m_nice_ssp1_nomig_xi0[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:,:,:],dims=[4,5])[:,:,:,1,1])),
    collect(Iterators.flatten(sum(m_nice_ssp2_nomig_xi0[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:,:,:],dims=[4,5])[:,:,:,1,1])),
    collect(Iterators.flatten(sum(m_nice_ssp3_nomig_xi0[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:,:,:],dims=[4,5])[:,:,:,1,1])),
    collect(Iterators.flatten(sum(m_nice_ssp4_nomig_xi0[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:,:,:],dims=[4,5])[:,:,:,1,1])),
    collect(Iterators.flatten(sum(m_nice_ssp5_nomig_xi0[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:,:,:],dims=[4,5])[:,:,:,1,1]))
)
move[:,:move_xi0] = move_xi0
move_xim1 = vcat(
    collect(Iterators.flatten(sum(m_nice_ssp1_nomig_xim1[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:,:,:],dims=[4,5])[:,:,:,1,1])),
    collect(Iterators.flatten(sum(m_nice_ssp2_nomig_xim1[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:,:,:],dims=[4,5])[:,:,:,1,1])),
    collect(Iterators.flatten(sum(m_nice_ssp3_nomig_xim1[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:,:,:],dims=[4,5])[:,:,:,1,1])),
    collect(Iterators.flatten(sum(m_nice_ssp4_nomig_xim1[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:,:,:],dims=[4,5])[:,:,:,1,1])),
    collect(Iterators.flatten(sum(m_nice_ssp5_nomig_xim1[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:,:,:],dims=[4,5])[:,:,:,1,1]))
)
move[:,:move_xim1] = move_xim1

move = innerjoin(
    move, 
    rename(
        migration, 
        :fundregion => :origin, 
        :leave_xi1 => :leave_or_xi1, 
        :pop_xi1 => :pop_or_xi1, 
        :leave_xi0 => :leave_or_xi0, 
        :pop_xi0 => :pop_or_xi0, 
        :leave_xim1 => :leave_or_xim1, 
        :pop_xim1 => :pop_or_xim1
    )[:,[:year,:scen,:origin,:leave_or_xi1,:pop_or_xi1,:leave_or_xi0,:pop_or_xi0,:leave_or_xim1,:pop_or_xim1]],
    on = [:year,:scen,:origin]
)
move = innerjoin(
    move, 
    rename(
        migration, 
        :fundregion => :destination, 
        :enter_xi1 => :enter_dest_xi1, 
        :pop_xi1 => :pop_dest_xi1, 
        :enter_xi0 => :enter_dest_xi0, 
        :pop_xi0 => :pop_dest_xi0, 
        :enter_xim1 => :enter_dest_xim1, 
        :pop_xim1 => :pop_dest_xim1
    )[:,[:year,:scen,:destination,:enter_dest_xi1,:pop_dest_xi1,:enter_dest_xi0,:pop_dest_xi0,:enter_dest_xim1,:pop_dest_xim1]],
    on = [:year,:scen,:destination]
)

move[:,:migshare_or_xi1] = move[:,:move_xi1] ./ move[:,:leave_or_xi1]
move[:,:migshare_or_xi0] = move[:,:move_xi0] ./ move[:,:leave_or_xi0]
move[:,:migshare_or_xim1] = move[:,:move_xim1] ./ move[:,:leave_or_xim1]
move[:,:migshare_dest_xi1] = move[:,:move_xi1] ./ move[:,:enter_dest_xi1]
move[:,:migshare_dest_xi0] = move[:,:move_xi0] ./ move[:,:enter_dest_xi0]
move[:,:migshare_dest_xim1] = move[:,:move_xim1] ./ move[:,:enter_dest_xim1]
for i in 1:size(move,1)
    if move[i,:leave_or_xi1] == 0 ; move[i,:migshare_or_xi1] = 0 end
    if move[i,:leave_or_xi0] == 0 ; move[i,:migshare_or_xi0] = 0 end
    if move[i,:leave_or_xim1] == 0 ; move[i,:migshare_or_xim1] = 0 end
    if move[i,:enter_dest_xi1] == 0 ; move[i,:migshare_dest_xi1] = 0 end
    if move[i,:enter_dest_xi0] == 0 ; move[i,:migshare_dest_xi0] = 0 end
    if move[i,:enter_dest_xim1] == 0 ; move[i,:migshare_dest_xim1] = 0 end
end

move |> @filter(_.year == 2100) |> @vlplot(
    :rect, y="origin:n", x="destination:n", column = {"scen:o", axis={labelFontSize=16}, title=nothing},
    color={"move_xi1:q", scale={domain=[0,2*10^5], scheme=:goldred}},title = string("Damages proportional to income, 2100")
) |> save(joinpath(@__DIR__, "../results/migflow_ineq/", string("migflow_xi1_v5.png")))
move |> @filter(_.year == 2100) |> @vlplot(
    :rect, y=:origin, x=:destination, column = {"scen:o", axis={labelFontSize=16}, title=nothing},
    color={"migshare_or_xi1:q", scale={domain=[0,1], scheme=:goldred}},title = string("Damages proportional to income, 2100")
) |> save(joinpath(@__DIR__, "../results/migflow_ineq/", string("migflow_share_or_xi1_v5.png")))
move |> @filter(_.year == 2100) |> @vlplot(
    :rect, y=:origin, x=:destination, column = {"scen:o", axis={labelFontSize=16}, title=nothing},
    color={"migshare_dest_xi1:q", scale={domain=[0,1], scheme=:goldred}},title = string("Damages proportional to income, 2100")
) |> save(joinpath(@__DIR__, "../results/migflow_ineq/", string("migflow_share_dest_xi1_v5.png")))
move |> @filter(_.year == 2100) |> @vlplot(
    :rect, y=:origin, x=:destination, column = {"scen:o", axis={labelFontSize=16}, title=nothing},
    color={"move_xi0:q", scale={domain=[0,2*10^5], scheme=:goldred}},title = string("Damages independent of income, 2100")
) |> save(joinpath(@__DIR__, "../results/migflow_ineq/", string("migflow_xi0_v5.png")))
move |> @filter(_.year == 2100) |> @vlplot(
    :rect, y=:origin, x=:destination, column = {"scen:o", axis={labelFontSize=16}, title=nothing},
    color={"migshare_or_xi0:q", scale={domain=[0,1], scheme=:goldred}},title = string("Damages independent of income, 2100")
) |> save(joinpath(@__DIR__, "../results/migflow_ineq/", string("migflow_share_or_xi0_v5.png")))
move |> @filter(_.year == 2100) |> @vlplot(
    :rect, y=:origin, x=:destination, column = {"scen:o", axis={labelFontSize=16}, title=nothing},
    color={"migshare_dest_xi0:q", scale={domain=[0,1], scheme=:goldred}},title = string("Damages independent of income, 2100")
) |> save(joinpath(@__DIR__, "../results/migflow_ineq/", string("migflow_share_dest_xi0_v5.png")))
move |> @filter(_.year == 2100) |> @vlplot(
    :rect, y=:origin, x=:destination, column = {"scen:o", axis={labelFontSize=16}, title=nothing},
    color={"move_xim1:q", scale={domain=[0,2*10^5], scheme=:goldred}},title = string("Damages inversely proportional to income, 2100")
) |> save(joinpath(@__DIR__, "../results/migflow_ineq/", string("migflow_xim1_v5.png")))
move |> @filter(_.year == 2100) |> @vlplot(
    :rect, y=:origin, x=:destination, column = {"scen:o", axis={labelFontSize=16}, title=nothing},
    color={"migshare_or_xim1:q", scale={domain=[0,1], scheme=:goldred}},title = string("Damages inversely proportional to income, 2100")
) |> save(joinpath(@__DIR__, "../results/migflow_ineq/", string("migflow_share_or_xim1_v5.png")))
move |> @filter(_.year == 2100) |> @vlplot(
    :rect, y=:origin, x=:destination, column = {"scen:o", axis={labelFontSize=16}, title=nothing},
    color={"migshare_dest_xim1:q", scale={domain=[0,1], scheme=:goldred}},title = string("Damages inversely proportional to income, 2100")
) |> save(joinpath(@__DIR__, "../results/migflow_ineq/", string("migflow_share_dest_xim1_v5.png")))


###################################### Plot geographical maps #####################################
world110m = dataset("world-110m")

isonum_fundregion = CSV.read(joinpath(@__DIR__,"../input_data/isonum_fundregion.csv"),DataFrame)
migration_maps = leftjoin(migration, isonum_fundregion, on = :fundregion)
migration_maps[!,:popdiff_xi0] = migration_maps[!,:pop_xi0] ./ migration_maps[!,:pop_xi1] .- 1
migration_maps[!,:popdiff_xim1] = migration_maps[!,:pop_xim1] ./ migration_maps[!,:pop_xi1] .- 1

for s in ssps
    @vlplot(width=800, height=600) + @vlplot(mark={:geoshape, stroke = :lightgray}, 
        data={values=world110m, format={type=:topojson, feature=:countries}}, 
        transform = [{lookup=:id, from={data=filter(row -> row[:scen] == s && row[:year] == 2100, migration_maps), key=:isonum, fields=[string(:pop_xi1)]}}],
        projection={type=:naturalEarth1}, #title = {text=string("Population levels by 2100 for Damages proportional to income, ", s),fontSize=20}, 
        color = {:pop_xi1, type=:quantitative, scale={scheme=:blues}, legend={title=nothing, symbolSize=40, labelFontSize=16}}
    ) |> save(joinpath(@__DIR__, "../results/world_maps_ineq/", string("pop_xi1_", s, "_v5.png")))
end
for s in ssps
    @vlplot(width=800, height=600) + @vlplot(mark={:geoshape, stroke = :lightgray}, 
        data={values=world110m, format={type=:topojson, feature=:countries}}, 
        transform = [{lookup=:id, from={data=filter(row -> row[:scen] == s && row[:year] == 2100, migration_maps), key=:isonum, fields=[string(:popdiff,:_xi0)]}}],
        projection={type=:naturalEarth1}, #title = {text=string("Relative changes in population by 2100 for closed vs Damages proportional to income, ", s),fontSize=20}, 
        color = {Symbol(string(:popdiff,:_xi0)), type=:quantitative, scale={domain=[-0.05,0.05], scheme=:redblue}, legend={title=nothing, symbolSize=40, labelFontSize=16}}
    ) |> save(joinpath(@__DIR__, "../results/world_maps_ineq/", string("popdiff",:_xi0,"_", s, "_v5.png")))
end
for s in ssps
    @vlplot(width=800, height=600) + @vlplot(mark={:geoshape, stroke = :lightgray}, 
        data={values=world110m, format={type=:topojson, feature=:countries}}, 
        transform = [{lookup=:id, from={data=filter(row -> row[:scen] == s && row[:year] == 2100, migration_maps), key=:isonum, fields=[string(:popdiff,:_xim1)]}}],
        projection={type=:naturalEarth1}, #title = {text=string("Relative changes in population by 2100 for more open vs Damages proportional to income, ", s),fontSize=20}, 
        color = {Symbol(string(:popdiff,:_xim1)), type=:quantitative, scale={domain=[-0.05,0.05], scheme=:redblue}, legend={title=nothing, symbolSize=40, labelFontSize=16}}
    ) |> save(joinpath(@__DIR__, "../results/world_maps_ineq/", string("popdiff",:_xim1,"_", s, "_v5.png")))
end


################################################ Compare to without climate change ##################################
# Run models without climate change
# Damages proportional to income
m_nice_ssp1_nocc = getmigrationnicemodel(scen="SSP1",migyesno="nomig",xi=1.0,omega=1.0)
m_nice_ssp2_nocc = getmigrationnicemodel(scen="SSP2",migyesno="nomig",xi=1.0,omega=1.0)
m_nice_ssp3_nocc = getmigrationnicemodel(scen="SSP3",migyesno="nomig",xi=1.0,omega=1.0)
m_nice_ssp4_nocc = getmigrationnicemodel(scen="SSP4",migyesno="nomig",xi=1.0,omega=1.0)
m_nice_ssp5_nocc = getmigrationnicemodel(scen="SSP5",migyesno="nomig",xi=1.0,omega=1.0)
set_param!(m_nice_ssp1_nocc, :runwithoutdamage, true)
set_param!(m_nice_ssp2_nocc,:runwithoutdamage, true)
set_param!(m_nice_ssp3_nocc,:runwithoutdamage, true)
set_param!(m_nice_ssp4_nocc,:runwithoutdamage, true)
set_param!(m_nice_ssp5_nocc,:runwithoutdamage, true)
update_param!(m_nice_ssp1_nocc,:currtax, m_fund[:emissions,:currtax])
update_param!(m_nice_ssp2_nocc,:currtax, m_fund[:emissions,:currtax])
update_param!(m_nice_ssp3_nocc,:currtax, m_fund[:emissions,:currtax])
update_param!(m_nice_ssp4_nocc,:currtax, m_fund[:emissions,:currtax])
update_param!(m_nice_ssp5_nocc,:currtax, m_fund[:emissions,:currtax])
run(m_nice_ssp1_nocc;ntimesteps=151)
run(m_nice_ssp2_nocc;ntimesteps=151)
run(m_nice_ssp3_nocc;ntimesteps=151)
run(m_nice_ssp4_nocc;ntimesteps=151)
run(m_nice_ssp5_nocc;ntimesteps=151)

# Damages independent of income between regions
m_nice_ssp1_nocc_xi0 = getmigrationnicemodel(scen="SSP1",migyesno="nomig",xi=0.0,omega=1.0)
m_nice_ssp2_nocc_xi0 = getmigrationnicemodel(scen="SSP2",migyesno="nomig",xi=0.0,omega=1.0)
m_nice_ssp3_nocc_xi0 = getmigrationnicemodel(scen="SSP3",migyesno="nomig",xi=0.0,omega=1.0)
m_nice_ssp4_nocc_xi0 = getmigrationnicemodel(scen="SSP4",migyesno="nomig",xi=0.0,omega=1.0)
m_nice_ssp5_nocc_xi0 = getmigrationnicemodel(scen="SSP5",migyesno="nomig",xi=0.0,omega=1.0)
set_param!(m_nice_ssp1_nocc_xi0,:runwithoutdamage, true)
set_param!(m_nice_ssp2_nocc_xi0,:runwithoutdamage, true)
set_param!(m_nice_ssp3_nocc_xi0,:runwithoutdamage, true)
set_param!(m_nice_ssp4_nocc_xi0,:runwithoutdamage, true)
set_param!(m_nice_ssp5_nocc_xi0,:runwithoutdamage, true)
update_param!(m_nice_ssp1_nocc_xi0,:currtax, m_fund[:emissions,:currtax])
update_param!(m_nice_ssp2_nocc_xi0,:currtax, m_fund[:emissions,:currtax])
update_param!(m_nice_ssp3_nocc_xi0,:currtax, m_fund[:emissions,:currtax])
update_param!(m_nice_ssp4_nocc_xi0,:currtax, m_fund[:emissions,:currtax])
update_param!(m_nice_ssp5_nocc_xi0,:currtax, m_fund[:emissions,:currtax])
run(m_nice_ssp1_nocc_xi0;ntimesteps=151)
run(m_nice_ssp2_nocc_xi0;ntimesteps=151)
run(m_nice_ssp3_nocc_xi0;ntimesteps=151)
run(m_nice_ssp4_nocc_xi0;ntimesteps=151)
run(m_nice_ssp5_nocc_xi0;ntimesteps=151)

# Damages inversely proportional to income between regions
m_nice_ssp1_nocc_xim1 = getmigrationnicemodel(scen="SSP1",migyesno="nomig",xi=-1.0,omega=1.0)
m_nice_ssp2_nocc_xim1 = getmigrationnicemodel(scen="SSP2",migyesno="nomig",xi=-1.0,omega=1.0)
m_nice_ssp3_nocc_xim1 = getmigrationnicemodel(scen="SSP3",migyesno="nomig",xi=-1.0,omega=1.0)
m_nice_ssp4_nocc_xim1 = getmigrationnicemodel(scen="SSP4",migyesno="nomig",xi=-1.0,omega=1.0)
m_nice_ssp5_nocc_xim1 = getmigrationnicemodel(scen="SSP5",migyesno="nomig",xi=-1.0,omega=1.0)
set_param!(m_nice_ssp1_nocc_xim1,:runwithoutdamage, true)
set_param!(m_nice_ssp2_nocc_xim1,:runwithoutdamage, true)
set_param!(m_nice_ssp3_nocc_xim1,:runwithoutdamage, true)
set_param!(m_nice_ssp4_nocc_xim1,:runwithoutdamage, true)
set_param!(m_nice_ssp5_nocc_xim1,:runwithoutdamage, true)
update_param!(m_nice_ssp1_nocc_xim1,:currtax, m_fund[:emissions,:currtax])
update_param!(m_nice_ssp2_nocc_xim1,:currtax, m_fund[:emissions,:currtax])
update_param!(m_nice_ssp3_nocc_xim1,:currtax, m_fund[:emissions,:currtax])
update_param!(m_nice_ssp4_nocc_xim1,:currtax, m_fund[:emissions,:currtax])
update_param!(m_nice_ssp5_nocc_xim1,:currtax, m_fund[:emissions,:currtax])
run(m_nice_ssp1_nocc_xim1;ntimesteps=151)
run(m_nice_ssp2_nocc_xim1;ntimesteps=151)
run(m_nice_ssp3_nocc_xim1;ntimesteps=151)
run(m_nice_ssp4_nocc_xim1;ntimesteps=151)
run(m_nice_ssp5_nocc_xim1;ntimesteps=151)


# Look at net migrant flows for different income elasticities of damages
migration_nocc = migration[:,[:year, :scen, :fundregion, :leave_xi1, :leave_xi0, :leave_xim1, :leave_gravres, :netmig_damageprop, :netmig_damageindep, :netmig_damageinvprop]]

enter_nocc_xi1 = vcat(
    collect(Iterators.flatten(sum(m_nice_ssp1_nocc[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp2_nocc[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp3_nocc[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp4_nocc[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp5_nocc[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1]))
)
migration_nocc[:,:enter_nocc_xi1] = enter_nocc_xi1
leave_nocc_xi1 = vcat(
    collect(Iterators.flatten(sum(m_nice_ssp1_nocc[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp2_nocc[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp3_nocc[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp4_nocc[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp5_nocc[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1]))
)
migration_nocc[:,:leave_nocc_xi1] = leave_nocc_xi1

enter_nocc_xi0 = vcat(
    collect(Iterators.flatten(sum(m_nice_ssp1_nocc_xi0[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp2_nocc_xi0[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp3_nocc_xi0[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp4_nocc_xi0[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp5_nocc_xi0[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1]))
)
migration_nocc[:,:enter_nocc_xi0] = enter_nocc_xi0
leave_nocc_xi0 = vcat(
    collect(Iterators.flatten(sum(m_nice_ssp1_nocc_xi0[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp2_nocc_xi0[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp3_nocc_xi0[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp4_nocc_xi0[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp5_nocc_xi0[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1]))
)
migration_nocc[:,:leave_nocc_xi0] = leave_nocc_xi0

enter_nocc_xim1 = vcat(
    collect(Iterators.flatten(sum(m_nice_ssp1_nocc_xim1[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp2_nocc_xim1[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp3_nocc_xim1[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp4_nocc_xim1[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp5_nocc_xim1[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1]))
)
migration_nocc[:,:enter_nocc_xim1] = enter_nocc_xim1
leave_nocc_xim1 = vcat(
    collect(Iterators.flatten(sum(m_nice_ssp1_nocc_xim1[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp2_nocc_xim1[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp3_nocc_xim1[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp4_nocc_xim1[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp5_nocc_xim1[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1]))
)
migration_nocc[:,:leave_nocc_xim1] = leave_nocc_xim1

migration_nocc[!,:netmig_nocc_damageprop] = migration_nocc[!,:enter_nocc_xi1] .- migration_nocc[!,:leave_nocc_xi1]
migration_nocc[!,:netmig_nocc_damageindep] = migration_nocc[!,:enter_nocc_xi0] .- migration_nocc[!,:leave_nocc_xi0]
migration_nocc[!,:netmig_nocc_damageinvprop] = migration_nocc[!,:enter_nocc_xim1] .- migration_nocc[!,:leave_nocc_xim1]

migration_nocc[!,:leave_nores_xi1] = migration_nocc[:,:leave_xi1] - migration_nocc[:,:leave_gravres]
migration_nocc[!,:leave_nores_xi0] = migration_nocc[:,:leave_xi0] - migration_nocc[:,:leave_gravres]
migration_nocc[!,:leave_nores_xim1] = migration_nocc[:,:leave_xim1] - migration_nocc[:,:leave_gravres]
migration_nocc[!,:leave_nocc_nores_xi1] = migration_nocc[:,:leave_nocc_xi1] - migration_nocc[:,:leave_gravres]
migration_nocc[!,:leave_nocc_nores_xi0] = migration_nocc[:,:leave_nocc_xi0] - migration_nocc[:,:leave_gravres]
migration_nocc[!,:leave_nocc_nores_xim1] = migration_nocc[:,:leave_nocc_xim1] - migration_nocc[:,:leave_gravres]

# Plot both net migration with and without climate change
netmig_nocc_all = rename(stack(
    migration_nocc, 
    [:netmig_damageprop,:netmig_damageindep,:netmig_damageinvprop,:netmig_nocc_damageprop,:netmig_nocc_damageindep,:netmig_nocc_damageinvprop], 
    [:scen, :fundregion, :year]
), :variable => :netmig_type, :value => :netmig)
netmig_nocc_all[!,:xi] = [(netmig_nocc_all[i,:netmig_type] == Symbol("netmig_damageprop") || netmig_nocc_all[i,:netmig_type] == Symbol("netmig_nocc_damageprop")) ? "damageprop" : ((netmig_nocc_all[i,:netmig_type] == Symbol("netmig_damageindep") || netmig_nocc_all[i,:netmig_type] == Symbol("netmig_nocc_damageindep")) ? "damageindep" : "damageinvprop") for i in 1:size(netmig_nocc_all,1)]
netmig_nocc_all[!,:ccornot] = [(SubString(String(netmig_nocc_all[i,:netmig_type]), 1:11) == "netmig_nocc") ? "nocc" : "cc" for i in 1:size(netmig_nocc_all,1)] 
netmig_nocc_all = innerjoin(netmig_nocc_all,regions_fullname, on=:fundregion)
for s in ssps
    netmig_nocc_all[(map(x->mod(x,10)==0,netmig_nocc_all[:,:year])),:] |> @filter(_.year >= 2015 && _.year <= 2100 && _.scen == s) |> @vlplot(
        mark={:point, size = 50}, columns=4, wrap={"regionname:o", title=nothing, header={labelFontSize=24}}, 
        x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
        y={"netmig:q", title = nothing, axis={labelFontSize=16}},
        color={"xi:o",scale={scheme=:darkmulti},legend={title=string("Net migration, ",s), titleFontSize=20, titleLimit=220, symbolSize=60, labelFontSize=24, labelLimit=280, offset=2}},
        shape = {"ccornot:o", legend={titleFontSize=16, symbolSize=40, labelFontSize=16}},
        resolve = {scale={y=:independent}}
    ) |> save(joinpath(@__DIR__, "../results/migflow_ineq/", string("netmig_nocc_",s,"_v5.png")))
end

# Plot differences in net migration with and without climate change
netmig_nocc_both = rename(stack(
    migration_nocc, 
    [:netmig_damageprop,:netmig_damageindep,:netmig_damageinvprop], 
    [:scen, :fundregion, :year]
), :variable => :netmig_type, :value => :netmig)
netmig_nocc = rename(stack(
    migration_nocc, 
    [:netmig_nocc_damageprop,:netmig_nocc_damageindep,:netmig_nocc_damageinvprop],
    [:scen, :fundregion, :year]
), :variable => :netmig_nocc_type, :value => :netmig_nocc)
sort!(netmig_nocc_both, [:scen,:fundregion,:year])
sort!(netmig_nocc, [:scen,:fundregion,:year])
netmig_nocc_both[!,:netmig_nocc] = netmig_nocc[:,:netmig_nocc]
netmig_nocc_both[!,:xi] = [SubString(String(netmig_nocc_both[i,:netmig_type]), 8) for i in 1:size(netmig_nocc_both,1)]
netmig_nocc_both = innerjoin(netmig_nocc_both,regions_fullname, on=:fundregion)
netmig_nocc_both[!,:netmig_diff] = netmig_nocc_both[:,:netmig] .- netmig_nocc_both[:,:netmig_nocc]

for s in ssps
    netmig_nocc_both |> @filter(_.year >= 2015 && _.year <= 2100 && _.scen == s) |> @vlplot(
        mark={:line, strokeWidth = 4}, width=300, height=250, columns=4, wrap={"regionname:o", title=nothing, header={labelFontSize=24}}, 
        x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
        y={"netmig_diff:q", title = nothing, axis={labelFontSize=16}},
        color={"xi:o",scale={scheme=:darkmulti},legend={title=string("Net migration, ",s), titleFontSize=20, titleLimit=220, symbolSize=60, labelFontSize=24, labelLimit=280, offset=2}},
        resolve = {scale={y=:independent}}
    ) |> save(joinpath(@__DIR__, "../results/migflow_ineq/", string("netmig_ccdiff_",s,"_v5.png")))
end

# Plot differences in migration (people leaving a place) with and without climate change
leave_nocc_both = rename(stack(
    rename(migration_nocc, :leave_xi1=>:leave_damageprop, :leave_xi0=>:leave_damageindep, :leave_xim1=>:leave_damageinvprop), 
    [:leave_damageprop,:leave_damageindep,:leave_damageinvprop], 
    [:scen, :fundregion, :year]
), :variable => :leave_type, :value => :leave)
leave_nocc = rename(stack(
    rename(migration_nocc, :leave_nocc_xi1=>:leave_nocc_damageprop, :leave_nocc_xi0=>:leave_nocc_damageindep, :leave_nocc_xim1=>:leave_nocc_damageinvprop), 
    [:leave_nocc_damageprop,:leave_nocc_damageindep,:leave_nocc_damageinvprop],
    [:scen, :fundregion, :year]
), :variable => :leave_nocc_type, :value => :leave_nocc)
leave_nores = rename(stack(
    rename(migration_nocc, :leave_nores_xi1=>:leave_nores_damageprop, :leave_nores_xi0=>:leave_nores_damageindep, :leave_nores_xim1=>:leave_nores_damageinvprop), 
    [:leave_nores_damageprop,:leave_nores_damageindep,:leave_nores_damageinvprop], 
    [:scen, :fundregion, :year]
), :variable => :leave_nores_type, :value => :leave_nores)
leave_nocc_nores = rename(stack(
    rename(migration_nocc, :leave_nocc_nores_xi1=>:leave_nocc_nores_damageprop, :leave_nocc_nores_xi0=>:leave_nocc_nores_damageindep, :leave_nocc_nores_xim1=>:leave_nocc_nores_damageinvprop), 
    [:leave_nocc_nores_damageprop,:leave_nocc_nores_damageindep,:leave_nocc_nores_damageinvprop],
    [:scen, :fundregion, :year]
), :variable => :leave_nocc_nores_type, :value => :leave_nocc_nores)
sort!(leave_nocc_both, [:scen,:fundregion,:year])
sort!(leave_nocc, [:scen,:fundregion,:year])
sort!(leave_nores, [:scen,:fundregion,:year])
sort!(leave_nocc_nores, [:scen,:fundregion,:year])
leave_nocc_both[!,:leave_nocc] = leave_nocc[:,:leave_nocc]
leave_nocc_both[!,:leave_nores] = leave_nores[:,:leave_nores]
leave_nocc_both[!,:leave_nocc_nores] = leave_nocc_nores[:,:leave_nocc_nores]
leave_nocc_both[!,:xi] = [SubString(String(leave_nocc_both[i,:leave_type]), 7) for i in 1:size(leave_nocc_both,1)]
leave_nocc_both = innerjoin(leave_nocc_both,regions_fullname, on=:fundregion)
leave_nocc_both[!,:leave_diff] = leave_nocc_both[:,:leave] .- leave_nocc_both[:,:leave_nocc]
leave_nocc_both[!,:leave_nores_diff] = leave_nocc_both[:,:leave_nores] .- leave_nocc_both[:,:leave_nocc_nores]

for s in ssps
    leave_nocc_both |> @filter(_.year >= 2015 && _.year <= 2100 && _.scen == s) |> @vlplot(
        mark={:line, strokeWidth = 4}, width=300, height=250, columns=4, wrap={"regionname:o", title=nothing, header={labelFontSize=24}}, 
        x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
        y={"leave_diff:q", title = nothing, axis={labelFontSize=16}},
        color={"xi:o",scale={scheme=:darkmulti},legend={title=string("Net migration, ",s), titleFontSize=20, titleLimit=220, symbolSize=60, labelFontSize=24, labelLimit=280, offset=2}},
        resolve = {scale={y=:independent}}
    ) |> save(joinpath(@__DIR__, "../results/migflow_ineq/", string("leave_ccdiff_reg_",s,"_v5.png")))
end

leave_nocc_tot = combine(d->(leave_diff=sum(d.leave_nores_diff),leave=sum(d.leave_nores)), groupby(leave_nocc_both, [:scen,:year,:xi]))
leave_nocc_tot[!,:scen_ccshare_type] = [string(leave_nocc_tot[i,:scen],"_",string(leave_nocc_tot[i,:xi])) for i in 1:size(leave_nocc_tot,1)]
leave_nocc_tot |> @filter(_.year >= 2015 && _.year <= 2100) |> @vlplot(
    mark={:line, strokeWidth = 4}, width=300, height=250,  
    x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
    y={"leave_diff:q", title = nothing, axis={labelFontSize=16}},
    color={"scen_ccshare_type:o",scale={scheme=:category20c},legend={titleFontSize=16, symbolSize=40, labelFontSize=16}},
    resolve = {scale={y=:independent}}
) |> save(joinpath(@__DIR__, "../results/migflow_ineq/", string("leave_ccdiff_v5.png")))
for s in ssps
    leave_nocc_tot |> @filter(_.year >= 2015 && _.year <= 2100 && _.scen == s) |> @vlplot(
        mark={:line, strokeWidth = 4}, width=300, height=250, 
        x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
        y={"leave_diff:q", title = "Number of additional migrants with climate change", axis={labelFontSize=16}},
        color={"xi:o",scale={scheme=:darkmulti},legend={title=string("Damage elasticity of income, ",s), titleFontSize=20, titleLimit=220, symbolSize=60, labelFontSize=24, labelLimit=280, offset=2}}
    ) |> save(joinpath(@__DIR__, "../results/migflow_ineq/", string("leave_ccdiff_",s,"_v5.png")))
end

leave_nocc_tot[!,:ccshare] = leave_nocc_tot[:,:leave_diff] ./ leave_nocc_tot[:,:leave]
for i in 1:size(leave_nocc_tot,1) ; if leave_nocc_tot[i,:leave] == 0.0 ; leave_nocc_tot[i,:ccshare] = 0 end end
leave_nocc_tot[.&(leave_nocc_tot[:,:year].==2100),:]
combine(d->sum(d.leave), groupby(leave_nocc_tot[.&(leave_nocc_tot[:,:year].>=2020,leave_nocc_tot[:,:year].<=2040),:], [:scen,:xi]))

# Plot results
leave_nocc_tot |> @filter(_.year >= 2015 && _.year <= 2100) |> @vlplot(
    mark={:line, strokeWidth = 4}, width=300, height=250,  
    x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
    y={"ccshare:q", title = nothing, axis={labelFontSize=16}},
    color={"scen_ccshare_type:o",scale={scheme=:category20c},legend={titleFontSize=16, symbolSize=40, labelFontSize=16}},
    resolve = {scale={y=:independent}}
) |> save(joinpath(@__DIR__, "../results/migflow_ineq/", string("leave_ccshare_v5.png")))
for s in ssps
    leave_nocc_tot |> @filter(_.year >= 2015 && _.year <= 2100 && _.scen == s) |> @vlplot(
        mark={:line, strokeWidth = 4}, width=300, height=250, 
        x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
        y={"ccshare:q", title = "Effect of climate change on global migration flows", axis={labelFontSize=16, titleFontSize=14}},
        color={"xi:o",scale={scheme=:darkmulti},legend={title=string("Damage elasticity of income, ",s), titleFontSize=20, titleLimit=220, symbolSize=60, labelFontSize=24, labelLimit=280, offset=2}}
    ) |> save(joinpath(@__DIR__, "../results/migflow_ineq/", string("leave_ccshare_",s,"_v5.png")))
end


# Plot differences in migration with and without climate change for each quintile
enter_quint_nocc_xi1 = vcat(
    collect(Iterators.flatten(m_nice_ssp1_nocc[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp2_nocc[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp3_nocc[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp4_nocc[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp5_nocc[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))
)
migration_quint[:,:enter_quint_nocc_xi1] = enter_quint_nocc_xi1
leave_quint_nocc_xi1 = vcat(
    collect(Iterators.flatten(m_nice_ssp1_nocc[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp2_nocc[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp3_nocc[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp4_nocc[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp5_nocc[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))
)
migration_quint[:,:leave_quint_nocc_xi1] = leave_quint_nocc_xi1

enter_quint_nocc_xi0 = vcat(
    collect(Iterators.flatten(m_nice_ssp1_nocc_xi0[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp2_nocc_xi0[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp3_nocc_xi0[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp4_nocc_xi0[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp5_nocc_xi0[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))
)
migration_quint[:,:enter_quint_nocc_xi0] = enter_quint_nocc_xi0
leave_quint_nocc_xi0 = vcat(
    collect(Iterators.flatten(m_nice_ssp1_nocc_xi0[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp2_nocc_xi0[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp3_nocc_xi0[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp4_nocc_xi0[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp5_nocc_xi0[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))
)
migration_quint[:,:leave_quint_nocc_xi0] = leave_quint_nocc_xi0

enter_quint_nocc_xim1 = vcat(
    collect(Iterators.flatten(m_nice_ssp1_nocc_xim1[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp2_nocc_xim1[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp3_nocc_xim1[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp4_nocc_xim1[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp5_nocc_xim1[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))
)
migration_quint[:,:enter_quint_nocc_xim1] = enter_quint_nocc_xim1
leave_quint_nocc_xim1 = vcat(
    collect(Iterators.flatten(m_nice_ssp1_nocc_xim1[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp2_nocc_xim1[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp3_nocc_xim1[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp4_nocc_xim1[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp5_nocc_xim1[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))
)
migration_quint[:,:leave_quint_nocc_xim1] = leave_quint_nocc_xim1

migration_quint[!,:leave_quint_diff_xi1] = migration_quint[:,:leave_quint_xi1] .- migration_quint[:,:leave_quint_nocc_xi1]
migration_quint[!,:leave_quint_diff_xi0] = migration_quint[:,:leave_quint_xi0] .- migration_quint[:,:leave_quint_nocc_xi0]
migration_quint[!,:leave_quint_diff_xim1] = migration_quint[:,:leave_quint_xim1] .- migration_quint[:,:leave_quint_nocc_xim1]

migration_quint_p = migration_quint[(map(x->mod(x,10)==0,migration_quint[:,:year])),:]

leave_quint_nocc = stack(
    rename(migration_quint_p, :leave_quint_diff_xi1 => :leave_quint_diff_damageprop, :leave_quint_diff_xi0 => :leave_quint_diff_damageindep, :leave_quint_diff_xim1 => :leave_quint_diff_damageinvprop), 
    [:leave_quint_diff_damageprop,:leave_quint_diff_damageindep,:leave_quint_diff_damageinvprop], 
    [:scen, :quintile ,:fundregion, :year]
)
rename!(leave_quint_nocc, :variable => :leave_type, :value => :leave_quint_diff_nocc)
leave_quint_nocc[!,:leave_type] = map(x->SubString(string(x),18),leave_quint_nocc[:,:leave_type])

for s in ssps
    leave_quint_nocc |> @filter(_.year >= 2015 && _.year <= 2100 && _.scen == s) |> @vlplot(
        mark={:point,size=60}, width=300, height=250, columns=4, wrap="fundregion:o", 
        x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
        y={"leave_quint_diff_nocc:q", title = nothing, axis={labelFontSize=16}},
        color={"quintile:o",scale={scheme=:darkmulti},legend={titleFontSize=16, symbolSize=40, labelFontSize=16}},
        shape={"leave_type:o",legend={titleFontSize=16, symbolSize=40, labelFontSize=16}},
        resolve = {scale={y=:independent}}
    ) |> save(joinpath(@__DIR__, "../results/migflow_ineq/", string("leave_quint_nocc_",s,"_v5.png")))
end

migration_quint[!,:leave_quint_ccshare_xi1] = (migration_quint[:,:leave_quint_xi1] .- migration_quint[:,:leave_quint_nocc_xi1]) ./ (migration_quint[:,:leave_quint_nocc_xi1] .- migration_quint[:,:leave_quint_gravres])
migration_quint[!,:leave_quint_ccshare_xi0] = (migration_quint[:,:leave_quint_xi0] .- migration_quint[:,:leave_quint_nocc_xi0]) ./ (migration_quint[:,:leave_quint_nocc_xi0] .- migration_quint[:,:leave_quint_gravres])
migration_quint[!,:leave_quint_ccshare_xim1] = (migration_quint[:,:leave_quint_xim1] .- migration_quint[:,:leave_quint_nocc_xim1]) ./ (migration_quint[:,:leave_quint_nocc_xim1] .- migration_quint[:,:leave_quint_gravres])

migration_quint_p = migration_quint[(map(x->mod(x,10)==0,migration_quint[:,:year])),:]

leave_quint_ccshare = stack(
    rename(migration_quint_p, :leave_quint_ccshare_xi1 => :leave_quint_ccshare_damageprop, :leave_quint_ccshare_xi0 => :leave_quint_ccshare_damageindep, :leave_quint_ccshare_xim1 => :leave_quint_ccshare_damageinvprop), 
    [:leave_quint_ccshare_damageprop,:leave_quint_ccshare_damageindep,:leave_quint_ccshare_damageinvprop], 
    [:scen, :quintile ,:fundregion, :year]
)
rename!(leave_quint_ccshare, :variable => :leave_type, :value => :leave_quint_ccshare_nocc)
leave_quint_ccshare[!,:damage_elasticity] = map(x->SubString(string(x),21),leave_quint_ccshare[:,:leave_type])
leave_quint_ccshare[!,:type_name] = [leave_quint_ccshare[i,:damage_elasticity]=="damageprop" ? "proportional" : (leave_quint_ccshare[i,:damage_elasticity]=="damageindep" ? "independent" : "inversely prop.") for i in 1:size(leave_quint_ccshare,1)]
leave_quint_ccshare = innerjoin(leave_quint_ccshare, regions_fullname, on=:fundregion)
for s in ssps
    leave_quint_ccshare |> @filter(_.year >= 2015 && _.year <= 2100 && _.scen == s) |> @vlplot(
        mark={:point,size=60}, width=300, height=250, columns=4, wrap={"regionname:o", title=nothing, header={labelFontSize=24}}, 
        x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
        y={"leave_quint_ccshare_nocc:q", title = "CC effect on total emigrants", axis={labelFontSize=20,titleFontSize=20}},
        color={"quintile:o",scale={scheme=:darkmulti},legend={title = "Quintile", titleFontSize=20, symbolSize=80, labelFontSize=20}},
        shape={"type_name:o",scale={range=["circle","triangle-up","square"],domain=["proportional","independent","inversely prop."]},legend={title = "Damages elasticity", titleFontSize=20, titleLimit=260, symbolSize=80, labelFontSize=20}},
        resolve = {scale={y=:independent}}
    ) |> save(joinpath(@__DIR__, "../results/migflow_ineq/", string("leave_quint_ccshare_",s,"_v5.png")))
end

# Plot associated maps
leave_maps = leftjoin(leave_quint_ccshare, isonum_fundregion, on = :fundregion)
for s in ssps
    for d in ["damageprop","damageindep","damageinvprop"]
        @vlplot(width=800, height=600) + @vlplot(mark={:geoshape, stroke = :lightgray}, 
            data={values=world110m, format={type=:topojson, feature=:countries}}, 
            transform = [{lookup=:id, from={data=filter(row -> row[:scen] == s && row[:year] == 2100 && row[:damage_elasticity] == d && row[:quintile] == 1, leave_maps), key=:isonum, fields=[string(:leave_quint_ccshare_nocc)]}}],
            projection={type=:naturalEarth1}, title = {text=string("SSP2-RCP4.5"),fontSize=24}, 
            color = {:leave_quint_ccshare_nocc, type=:quantitative, scale={domain=[-0.4,0.4], scheme=:pinkyellowgreen}, legend={title="Change vs no CC", titleFontSize=20, titleLimit=260, symbolSize=60, labelFontSize=20, labelLimit=220}}
        ) |> save(joinpath(@__DIR__, "../results/world_maps_ineq/", string("leave_q1_ccshare_", s, "_", d, "_v5.pdf")))
    end
end

# Plot numbers of migrants without climate change per quintile, but summed over decades
migration_quint[:,:decade] = map(x->div(x,10)*10,migration_quint[:,:year])
leave_dec = combine( d->(leave_quint_diff_dec_damageprop = sum(d.leave_quint_diff_xi1), leave_quint_diff_dec_damageindep = sum(d.leave_quint_diff_xi0), leave_quint_diff_dec_damageinvprop = sum(d.leave_quint_diff_xim1)), groupby(migration_quint, [:decade,:scen,:fundregion,:quintile]))
leave_quint_dec_nocc = stack(
    leave_dec, 
    [:leave_quint_diff_dec_damageprop,:leave_quint_diff_dec_damageindep,:leave_quint_diff_dec_damageinvprop], 
    [:scen, :quintile ,:fundregion, :decade]
)
rename!(leave_quint_dec_nocc, :variable => :leave_type, :value => :leave_quint_diff_dec_nocc)
leave_quint_dec_nocc[!,:leave_type] = map(x->SubString(string(x),22),leave_quint_dec_nocc[:,:leave_type])
leave_quint_dec_nocc[!,:type_name] = [leave_quint_dec_nocc[i,:leave_type]=="damageprop" ? "proportional" : (leave_quint_dec_nocc[i,:leave_type]=="damageindep" ? "independent" : "inversely prop.") for i in 1:size(leave_quint_dec_nocc,1)]
leave_quint_dec_nocc = innerjoin(leave_quint_dec_nocc, regions_fullname, on=:fundregion)

for s in ssps
    leave_quint_dec_nocc |> @filter(_.decade >= 2010 && _.decade <= 2100 && _.scen == s) |> @vlplot(
        mark={:point,size=60}, width=300, height=250, columns=4, wrap={"regionname:o", title=nothing, header={labelFontSize=24}}, 
        x={"decade:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
        y={"leave_quint_diff_dec_nocc:q", title = "Change in emigrants", axis={labelFontSize=20,titleFontSize=20}},
        color={"quintile:o",scale={scheme=:darkmulti},legend={title = "Quintile", titleFontSize=20, symbolSize=80, labelFontSize=20}},
        shape={"type_name:o",scale={range=["circle","triangle-up","square"],domain=["proportional","independent","inversely prop."]},legend={title = "Damages elasticity", titleFontSize=20, titleLimit=260, symbolSize=80, labelFontSize=20}},
        resolve = {scale={y=:independent}}
    ) |> save(joinpath(@__DIR__, "../results/migflow_ineq/", string("leave_quint_dec_nocc_",s,"_v5.png")))
end


################################################ Sensitivity analysis: shut down dynamic vulnerability in FUND ###########################
# Test only for SSP2 and for damages independent of income
# Set all income elasticities to 0, following Dell and Moore 2017
m_nice_ssp2_novuln_xi0 = getmigrationnicemodel(scen="SSP2",migyesno="nomig",xi=0.0,omega=1.0)
set_param!(m_nice_ssp2_novuln_xi0,:ceel,0.0)
set_param!(m_nice_ssp2_novuln_xi0,:agel,0.0)
set_param!(m_nice_ssp2_novuln_xi0,:forel,0.0)
set_param!(m_nice_ssp2_novuln_xi0,:wrel,0.0)
set_param!(m_nice_ssp2_novuln_xi0,:heel,0.0)
set_param!(m_nice_ssp2_novuln_xi0,:wvel,0.0)
set_param!(m_nice_ssp2_novuln_xi0,:diamortel,0.0)
set_param!(m_nice_ssp2_novuln_xi0,:vbel,0.0)
set_param!(m_nice_ssp2_novuln_xi0,:hurrdamel,0.0)
set_param!(m_nice_ssp2_novuln_xi0,:hurrdeadel,0.0)
set_param!(m_nice_ssp2_novuln_xi0,:extratropicalstormsdamel,0.0)
set_param!(m_nice_ssp2_novuln_xi0,:extratropicalstormsdeadel,0.0)
set_param!(m_nice_ssp2_novuln_xi0,:vslel,0.0)
set_param!(m_nice_ssp2_novuln_xi0,:vmorbel,0.0)

run(m_nice_ssp2_novuln_xi0;ntimesteps=151)


migration_quint_novuln = DataFrame(
    year = repeat(years, outer = length(regions)*5),
    fundregion = repeat(regions, outer = 5, inner=length(years)),
    quintile = repeat(1:5, inner=length(years)*length(regions))
)
leave_quint_novuln_xi0 = collect(Iterators.flatten(m_nice_ssp2_novuln_xi0[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))
migration_quint_novuln[:,:leave_quint_novuln_xi0] = leave_quint_novuln_xi0
leave_quint_nocc_xi0 = collect(Iterators.flatten(m_nice_ssp2_nocc_xi0[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))
migration_quint_novuln[:,:leave_quint_nocc_xi0] = leave_quint_nocc_xi0
migration_quint_novuln[!,:leave_quint_diff_xi0] = migration_quint_novuln[:,:leave_quint_novuln_xi0] .- migration_quint_novuln[:,:leave_quint_nocc_xi0]

migration_quint_novuln[!,:leave_quint_gravres] = repeat(collect(Iterators.flatten(sum(m_nice_ssp2_nomig[:migration,:gravres_qi],dims=[2,4])[:,1,:,1])),inner=length(1951:2100))
migration_quint_novuln[!,:leave_quint_ccshare_xi0] = (migration_quint_novuln[:,:leave_quint_novuln_xi0] .- migration_quint_novuln[:,:leave_quint_nocc_xi0]) ./ (migration_quint_novuln[:,:leave_quint_nocc_xi0] .- migration_quint_novuln[:,:leave_quint_gravres])

migration_quint_novuln_p = migration_quint_novuln[(map(x->mod(x,10)==0,migration_quint_novuln[:,:year])),:]

migration_quint_novuln_p = innerjoin(migration_quint_novuln_p, regions_fullname, on=:fundregion)

# Plot associated maps
leave_novuln_maps = leftjoin(migration_quint_novuln_p, isonum_fundregion, on = :fundregion)

@vlplot(width=800, height=600) + @vlplot(mark={:geoshape, stroke = :lightgray}, 
    data={values=world110m, format={type=:topojson, feature=:countries}}, 
    transform = [{lookup=:id, from={data=filter(row -> row[:year] == 2100 && row[:quintile] == 1, leave_novuln_maps), key=:isonum, fields=[string(:leave_quint_ccshare_xi0)]}}],
    projection={type=:naturalEarth1}, title = {text=string("Emigrants from quintile 1, SSP2, damageindep"),fontSize=20}, 
    color = {:leave_quint_ccshare_xi0, type=:quantitative, scale={domain=[-0.4,0.4], scheme=:pinkyellowgreen}, legend={title="Change vs no CC", titleFontSize=20, titleLimit=260, symbolSize=60, labelFontSize=20, labelLimit=220}}
) |> save(joinpath(@__DIR__, "../results/world_maps_ineq/", string("leave_q1_ccshare_novuln_SSP2_damindep_v5.png")))


# Test for when we divide the CO2 fertilization effect by 10, and multiply all other damages by 10.
# Test only for SSP2 and for damages inversely proportional to income
m_nice_ssp2_nofert_xi0 = getmigrationnicemodel(scen="SSP2",migyesno="nomig",xi=0.0,omega=1.0)
update_param!(m_nice_ssp2_nofert_xi0, :agcbm, map(x->x/10,m_nice_ssp2_nomig[:impactagriculture,:agcbm]))
set_param!(m_nice_ssp2_nofert_xi0, :consleak, 2.5)

run(m_nice_ssp2_nofert_xi0;ntimesteps=151)


migration_quint_nofert = DataFrame(
    year = repeat(years, outer = length(regions)*5),
    fundregion = repeat(regions, outer = 5, inner=length(years)),
    quintile = repeat(1:5, inner=length(years)*length(regions))
)
leave_quint_nofert_xi0 = collect(Iterators.flatten(m_nice_ssp2_nofert_xi0[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))
migration_quint_nofert[:,:leave_quint_nofert_xi0] = leave_quint_nofert_xi0
leave_quint_nocc_xi0 = collect(Iterators.flatten(m_nice_ssp2_nocc_xi0[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))
migration_quint_nofert[:,:leave_quint_nocc_xi0] = leave_quint_nocc_xi0
migration_quint_nofert[!,:leave_quint_diff_xi0] = migration_quint_nofert[:,:leave_quint_nofert_xi0] .- migration_quint_nofert[:,:leave_quint_nocc_xi0]

migration_quint_nofert[!,:leave_quint_gravres] = repeat(collect(Iterators.flatten(sum(m_nice_ssp2_nomig[:migration,:gravres_qi],dims=[2,4])[:,1,:,1])),inner=length(1951:2100))
migration_quint_nofert[!,:leave_quint_ccshare_xi0] = (migration_quint_nofert[:,:leave_quint_nofert_xi0] .- migration_quint_nofert[:,:leave_quint_nocc_xi0]) ./ (migration_quint_nofert[:,:leave_quint_nocc_xi0] .- migration_quint_nofert[:,:leave_quint_gravres])

migration_quint_nofert_p = migration_quint_nofert[(map(x->mod(x,10)==0,migration_quint_nofert[:,:year])),:]

migration_quint_nofert_p = innerjoin(migration_quint_nofert_p, regions_fullname, on=:fundregion)

# Plot graph over time
migration_quint_nofert_p |> @filter(_.year >= 2015 && _.year <= 2100) |> @vlplot(
    mark={:point,filled=true,size=80}, width=300, height=250, columns=4, wrap={"regionname:o", title=nothing, header={labelFontSize=24}}, 
    x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
    y={"leave_quint_ccshare_xi0:q", title = "CC effect on total emigrants", axis={labelFontSize=20,titleFontSize=20}},
    color={"quintile:o",scale={scheme=:darkmulti},legend={title = "Quintile", titleFontSize=20, symbolSize=80, labelFontSize=20}},
    #shape={"damage_elasticity:o",legend={title = "Damages elasticity", titleFontSize=20, titleLimit=260, symbolSize=80, labelFontSize=20}},
    resolve = {scale={y=:independent}}
) |> save(joinpath(@__DIR__, "../results/migflow_ineq/", string("leave_quint_ccshare_nofert_SSP2_damindep_v5.png")))

# Plot associated maps
leave_nofert_maps = leftjoin(migration_quint_nofert_p, isonum_fundregion, on = :fundregion)

@vlplot(width=800, height=600) + @vlplot(mark={:geoshape, stroke = :lightgray}, 
    data={values=world110m, format={type=:topojson, feature=:countries}}, 
    transform = [{lookup=:id, from={data=filter(row -> row[:year] == 2100 && row[:quintile] == 1, leave_nofert_maps), key=:isonum, fields=[string(:leave_quint_ccshare_xi0)]}}],
    projection={type=:naturalEarth1}, title = {text=string("Emigrants from quintile 1, SSP2, damageindep"),fontSize=20}, 
    color = {:leave_quint_ccshare_xi0, type=:quantitative, scale={domain=[-0.25,0.25], scheme=:pinkyellowgreen}, legend={title="Change vs no CC", titleFontSize=20, titleLimit=260, symbolSize=60, labelFontSize=20, labelLimit=220}}
) |> save(joinpath(@__DIR__, "../results/world_maps_ineq/", string("leave_q1_ccshare_nofert_SSP2_damindep_v5.png")))


############################################################### Compare to no resource constraint ####################################################
# Test only for SSP2 and for damages independent of income
m_nice_ssp2_noconst_xi0 = getmigrationnicemodel(scen="SSP2",migyesno="nomig",xi=0.0,omega=1.0)
set_param!(m_nice_ssp2_noconst_xi0, :beta4_quint, zeros(5))

run(m_nice_ssp2_noconst_xi0;ntimesteps=151)

# Plot effect of climate change on emigration of poorest populations without resource constraint
migration_quint_noconst = DataFrame(
    year = repeat(years, outer = length(regions)*5),
    fundregion = repeat(regions, outer = 5, inner=length(years)),
    quintile = repeat(1:5, inner=length(years)*length(regions))
)
leave_quint_noconst_xi0 = collect(Iterators.flatten(m_nice_ssp2_noconst_xi0[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))
migration_quint_noconst[:,:leave_quint_noconst_xi0] = leave_quint_noconst_xi0
leave_quint_nocc_xi0 = collect(Iterators.flatten(m_nice_ssp2_nocc_xi0[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))
migration_quint_noconst[:,:leave_quint_nocc_xi0] = leave_quint_nocc_xi0
migration_quint_noconst[!,:leave_quint_diff_xi0] = migration_quint_noconst[:,:leave_quint_noconst_xi0] .- migration_quint_noconst[:,:leave_quint_nocc_xi0]

migration_quint_noconst[!,:leave_quint_gravres] = repeat(collect(Iterators.flatten(sum(m_nice_ssp2_nomig[:migration,:gravres_qi],dims=[2,4])[:,1,:,1])),inner=length(1951:2100))
migration_quint_noconst[!,:leave_quint_ccshare_xi0] = (migration_quint_noconst[:,:leave_quint_noconst_xi0] .- migration_quint_noconst[:,:leave_quint_nocc_xi0]) ./ (migration_quint_noconst[:,:leave_quint_nocc_xi0] .- migration_quint_noconst[:,:leave_quint_gravres])

migration_quint_noconst_p = migration_quint_noconst[(map(x->mod(x,10)==0,migration_quint_noconst[:,:year])),:]

migration_quint_noconst_p = innerjoin(migration_quint_noconst_p, regions_fullname, on=:fundregion)

# Plot graph over time
migration_quint_noconst_p |> @filter(_.year >= 2015 && _.year <= 2100) |> @vlplot(
    mark={:point,filled=true,size=80}, width=300, height=250, columns=4, wrap={"regionname:o", title=nothing, header={labelFontSize=24}}, 
    x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
    y={"leave_quint_ccshare_xi0:q", title = "CC effect on total emigrants", axis={labelFontSize=20,titleFontSize=20}},
    color={"quintile:o",scale={scheme=:darkmulti},legend={title = "Quintile", titleFontSize=20, symbolSize=80, labelFontSize=20}},
    #shape={"damage_elasticity:o",legend={title = "Damages elasticity", titleFontSize=20, titleLimit=260, symbolSize=80, labelFontSize=20}},
    resolve = {scale={y=:independent}}
) |> save(joinpath(@__DIR__, "../results/migflow_ineq/", string("leave_quint_ccshare_noconst_SSP2_damindep_v5.png")))

# Plot associated maps
leave_noconst_maps = leftjoin(migration_quint_noconst_p, isonum_fundregion, on = :fundregion)

@vlplot(width=800, height=600) + @vlplot(mark={:geoshape, stroke = :lightgray}, 
    data={values=world110m, format={type=:topojson, feature=:countries}}, 
    transform = [{lookup=:id, from={data=filter(row -> row[:year] == 2100 && row[:quintile] == 1, leave_noconst_maps), key=:isonum, fields=[string(:leave_quint_ccshare_xi0)]}}],
    projection={type=:naturalEarth1}, title = {text=string("Emigrants from quintile 1, SSP2, damageindep"),fontSize=20}, 
    color = {:leave_quint_ccshare_xi0, type=:quantitative, scale={domain=[-1.0,1.0], scheme=:pinkyellowgreen}, legend={title="Change vs no CC", titleFontSize=20, titleLimit=260, symbolSize=60, labelFontSize=20, labelLimit=220}}
) |> save(joinpath(@__DIR__, "../results/world_maps_ineq/", string("leave_q1_ccshare_noconst_SSP2_damindep_v5.png")))


# Plot difference in total income per region and per quintile
migration_quint_noconst[:,:gdp_quint_xi0] = collect(Iterators.flatten(m_nice_ssp2_nomig_xi0[:migration,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))
migration_quint_noconst[:,:gdp_quint_noconst_xi0] = collect(Iterators.flatten(m_nice_ssp2_noconst_xi0[:migration,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))
migration_quint_noconst[:,:rel_const_gdp_xi0] = migration_quint_noconst[:,:gdp_quint_xi0] ./ migration_quint_noconst[:,:gdp_quint_noconst_xi0] .- 1.0

migration_quint_noconst[:,:pop_quint_xi0] = collect(Iterators.flatten(m_nice_ssp2_nomig_xi0[:migration,:pop][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))
migration_quint_noconst[:,:pop_quint_noconst_xi0] = collect(Iterators.flatten(m_nice_ssp2_noconst_xi0[:migration,:pop][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))
migration_quint_noconst[:,:ypc_quint_xi0] = migration_quint_noconst[:,:gdp_quint_xi0] ./ migration_quint_noconst[:,:pop_quint_xi0] .* 1000
migration_quint_noconst[:,:ypc_quint_noconst_xi0] = migration_quint_noconst[:,:gdp_quint_noconst_xi0] ./ migration_quint_noconst[:,:pop_quint_noconst_xi0] .* 1000
migration_quint_noconst[:,:rel_const_ypc_xi0] = migration_quint_noconst[:,:ypc_quint_xi0] ./ migration_quint_noconst[:,:ypc_quint_noconst_xi0] .- 1.0

migration_quint_noconst = innerjoin(migration_quint_noconst, regions_fullname, on =:fundregion)

migration_quint_noconst |> @filter(_.year >= 2015 && _.year <= 2100) |> @vlplot(
    mark={:line,point={filled=true,size=80}}, width=300, height=250, columns=4, wrap={"regionname:o", title=nothing, header={labelFontSize=24}}, 
    x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
    y={"rel_const_gdp_xi0:q", title = "Effect of constraint on total income", axis={labelFontSize=20,titleFontSize=20}},
    color={"quintile:o",scale={scheme=:darkmulti},legend={title = "Quintile", titleFontSize=20, symbolSize=80, labelFontSize=20}},
    #shape={"leave_type:o",legend={title = "Damages elasticity", titleFontSize=20, titleLimit=260, symbolSize=80, labelFontSize=20}},
    resolve = {scale={y=:independent}}
) |> save(joinpath(@__DIR__, "../results/migflow_ineq/", string("relconst_gdp_quint_damindep_SSP2_v5.png")))

migration_quint_noconst |> @filter(_.year >= 2015 && _.year <= 2100) |> @vlplot(
    mark={:line,point={filled=true,size=80}}, width=300, height=250, columns=4, wrap={"regionname:o", title=nothing, header={labelFontSize=24}}, 
    x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
    y={"rel_const_ypc_xi0:q", title = "Effect of constraint on per capita income", axis={labelFontSize=20,titleFontSize=20}},
    color={"quintile:o",scale={scheme=:darkmulti},legend={title = "Quintile", titleFontSize=20, symbolSize=80, labelFontSize=20}},
    #shape={"leave_type:o",legend={title = "Damages elasticity", titleFontSize=20, titleLimit=260, symbolSize=80, labelFontSize=20}},
    resolve = {scale={y=:independent}}
) |> save(joinpath(@__DIR__, "../results/migflow_ineq/", string("relconst_ypc_quint_damindep_SSP2_v5.png")))

# Plot associated maps
relconst_maps = leftjoin(migration_quint_noconst, isonum_fundregion, on = :fundregion)

@vlplot(width=800, height=600) + @vlplot(mark={:geoshape, stroke = :lightgray}, 
    data={values=world110m, format={type=:topojson, feature=:countries}}, 
    transform = [{lookup=:id, from={data=filter(row -> row[:year] == 2100 && row[:quintile] == 1, relconst_maps), key=:isonum, fields=[string(:rel_const_gdp_xi0)]}}],
    projection={type=:naturalEarth1}, title = {text=string("Income in quintile 1, SSP2, damageindep"),fontSize=20}, 
    color = {:rel_const_gdp_xi0, type=:quantitative, scale={domain=[-0.1,0.1], scheme=:pinkyellowgreen}, legend={title="Resource constraint effect", titleFontSize=20, titleLimit=260, symbolSize=60, labelFontSize=20, labelLimit=220}}
) |> save(joinpath(@__DIR__, "../results/world_maps_ineq/", string("relconst_q1_damindep_SSP2_v5.png")))


# Plot difference in total damages per region and per quintile
migration_quint_noconst[:,:damage_distr_xi0] = collect(Iterators.flatten(m_nice_ssp2_nomig_xi0[:socioeconomic,:damage_distribution][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))
migration_quint_noconst = innerjoin(migration_quint_noconst, damages[(damages[:,:scen].=="SSP2"),[:year,:fundregion,:dam_damindep]], on =[:year,:fundregion])
migration_quint_noconst[:,:dam_quint_xi0] = migration_quint_noconst[:,:damage_distr_xi0] .* migration_quint_noconst[:,:dam_damindep]
migration_quint_noconst[:,:damgdp_quint_xi0] = migration_quint_noconst[:,:dam_quint_xi0] ./ (migration_quint_noconst[:,:gdp_quint_xi0] .* 10^9)

migration_quint_noconst[:,:damage_distr_noconst_xi0] = collect(Iterators.flatten(m_nice_ssp2_noconst_xi0[:socioeconomic,:damage_distribution][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))
damages_noconst = DataFrame(year = repeat(years, outer = length(regions)),fundregion = repeat(regions, inner=length(years)))
damages_noconst[:,:dam_noconst_xi0] = collect(Iterators.flatten(m_nice_ssp2_noconst_xi0[:addimpact,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
migration_quint_noconst = innerjoin(migration_quint_noconst, damages_noconst[:,[:year,:fundregion,:dam_noconst_xi0]], on =[:year,:fundregion])
migration_quint_noconst[:,:dam_quint_noconst_xi0] = migration_quint_noconst[:,:damage_distr_noconst_xi0] .* migration_quint_noconst[:,:dam_noconst_xi0]
migration_quint_noconst[:,:damgdp_quint_noconst_xi0] = migration_quint_noconst[:,:dam_quint_noconst_xi0] ./ (migration_quint_noconst[:,:gdp_quint_noconst_xi0] .* 10^9)

migration_quint_noconst[:,:rel_const_dam_xi0] = migration_quint_noconst[:,:dam_quint_xi0] ./ migration_quint_noconst[:,:dam_quint_noconst_xi0] .- 1.0
migration_quint_noconst[:,:rel_const_damgdp_xi0] = migration_quint_noconst[:,:damgdp_quint_xi0] ./ migration_quint_noconst[:,:damgdp_quint_noconst_xi0] .- 1.0

# Plot associated maps
relconst_maps = leftjoin(migration_quint_noconst, isonum_fundregion, on = :fundregion)

@vlplot(width=800, height=600) + @vlplot(mark={:geoshape, stroke = :lightgray}, 
    data={values=world110m, format={type=:topojson, feature=:countries}}, 
    transform = [{lookup=:id, from={data=filter(row -> row[:year] == 2100 && row[:quintile] == 1, relconst_maps), key=:isonum, fields=[string(:rel_const_dam_xi0)]}}],
    projection={type=:naturalEarth1}, title = {text=string("Damages in quintile 1, SSP2, damages independant"),fontSize=20}, 
    color = {:rel_const_dam_xi0, type=:quantitative, scale={domain=[-0.3,0.3], scheme=:purpleorange}, legend={title="Resource constraint effect", titleFontSize=20, titleLimit=260, symbolSize=60, labelFontSize=20, labelLimit=220}}
) |> save(joinpath(@__DIR__, "../results/world_maps_ineq/", string("relconst_dam_q1_damindep_SSP2_v5.png")))

@vlplot(width=800, height=600) + @vlplot(mark={:geoshape, stroke = :lightgray}, 
    data={values=world110m, format={type=:topojson, feature=:countries}}, 
    transform = [{lookup=:id, from={data=filter(row -> row[:year] == 2100 && row[:quintile] == 1, relconst_maps), key=:isonum, fields=[string(:rel_const_damgdp_xi0)]}}],
    projection={type=:naturalEarth1}, title = {text=string("Damages per GDP in quintile 1, SSP2, damages independant"),fontSize=20}, 
    color = {:rel_const_damgdp_xi0, type=:quantitative, scale={domain=[-0.3,0.3], scheme=:purpleorange}, legend={title="Resource constraint effect", titleFontSize=20, titleLimit=260, symbolSize=60, labelFontSize=20, labelLimit=220}}
) |> save(joinpath(@__DIR__, "../results/world_maps_ineq/", string("relconst_damgdp_q1_damindep_SSP2_v5.png")))


# Plot effect of remittances vs damages on income 
migration_quint_noconst[:,:receive_quint_xi0] = collect(Iterators.flatten(m_nice_ssp2_noconst_xi0[:migration,:receive][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))
migration_quint_noconst[:,:remgdp_quint_damindep] = migration_quint_noconst[:,:receive_quint_xi0] ./ migration_quint_noconst[:,:gdp_quint_xi0]
migration_quint_noconst[:,:remdam_quint_damindep] = migration_quint_noconst[:,:remgdp_quint_damindep] .- migration_quint_noconst[:,:damgdp_quint_noconst_xi0]

migration_quint_noconst |> @filter(_.year >= 2015 && _.year <= 2100) |> @vlplot(
    mark={:point,size=60}, width=300, height=250, columns=4, wrap={"regionname:o", title=nothing, header={labelFontSize=24}}, 
    x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
    y={"remdam_quint_damindep:q", title = "(Damages - Remittances) / GDP", axis={labelFontSize=20,titleFontSize=20}},
    color={"quintile:o",scale={scheme=:darkmulti},legend={title = "Quintile", titleFontSize=20, symbolSize=80, labelFontSize=20}},
    #shape={"type_name:o",scale={range=["circle","triangle-up","square"],domain=["proportional","independent","inversely prop."]},legend={title = "Damages elasticity", titleFontSize=20, titleLimit=260, symbolSize=80, labelFontSize=20}},
    resolve = {scale={y=:independent}}
) |> save(joinpath(@__DIR__, "../results/damages_ineq/", string("remdam_quint_noconst_SSP2_indep_v5.png")))

remdam_quint_noconst_maps = leftjoin(migration_quint_noconst, isonum_fundregion, on = :fundregion)
for y in [2020, 2050, 2100]
    @vlplot(width=800, height=600) + @vlplot(mark={:geoshape, stroke = :lightgray}, 
        data={values=world110m, format={type=:topojson, feature=:countries}}, 
        transform = [{lookup=:id, from={data=filter(row -> row[:year] == y && row[:quintile] == 1, remdam_quint_noconst_maps), key=:isonum, fields=[string(:remdam_quint_damindep)]}}],
        projection={type=:naturalEarth1}, title = {text=string("SSP3-RCP7.0, ", y),fontSize=24}, 
        color = {:remdam_quint_damindep, type=:quantitative, scale={domain=[-0.5,0.5], scheme=:purplegreen}, legend={title="Share of income", titleFontSize=20, titleLimit=260, symbolSize=60, labelFontSize=20, labelLimit=220}}
    ) |> save(joinpath(@__DIR__, "../results/world_maps_ineq/", string("remdam_quint_q1_noconst_SSP2_indep_",y ,"_v5.png")))
end


####################################################### Store results ####################################################
# Create function that gathers relevant results for the period 1950-2100
function nice_fund_mig(m::Mimi.Model)
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
        "loss" => getdataframe(m, :addimpact => (:loss, :elossall, :slossall))[1:16*151,:],     # for models with migration (m_nice...)
        #"loss" => getdataframe(m, :impactaggregation => :loss)[1:16*151,:],     # for models without migration (fund...)
        "impacts" => getdataframe(m, :impactaggregation => (:water, :forests, :heating, :cooling, :agcost, :drycost, :protcost, :hurrdam, :extratropicalstormsdam, :eloss_other, :species, :deadcost, :morbcost, :wetcost))[1:16*151,:]
    )
    return result
end

# Do you want to save your results (true = save results)?
save_results = true

models = Dict(
    "m_nice_ssp1_nomig" => m_nice_ssp1_nomig, "m_nice_ssp2_nomig" => m_nice_ssp2_nomig, "m_nice_ssp3_nomig" => m_nice_ssp3_nomig, "m_nice_ssp4_nomig" => m_nice_ssp4_nomig, "m_nice_ssp5_nomig" => m_nice_ssp5_nomig,
    #"m_fundnicessp1"=> m_fundnicessp1, "m_fundnicessp2" => m_fundnicessp2, "m_fundnicessp3" => m_fundnicessp3, "m_fundnicessp4" => m_fundnicessp4, "m_fundnicessp5" => m_fundnicessp5, 
    #"m_fund" => m_fund, 
    "m_nice_ssp1_nomig_xi0" => m_nice_ssp1_nomig_xi0, "m_nice_ssp2_nomig_xi0" => m_nice_ssp2_nomig_xi0, "m_nice_ssp3_nomig_xi0" => m_nice_ssp3_nomig_xi0, "m_nice_ssp4_nomig_xi0" => m_nice_ssp4_nomig_xi0, "m_nice_ssp5_nomig_xi0" => m_nice_ssp5_nomig_xi0,
    "m_nice_ssp1_nomig_xim1" => m_nice_ssp1_nomig_xim1, "m_nice_ssp2_nomig_xim1" => m_nice_ssp2_nomig_xim1, "m_nice_ssp3_nomig_xim1" => m_nice_ssp3_nomig_xim1, "m_nice_ssp4_nomig_xim1" => m_nice_ssp4_nomig_xim1, "m_nice_ssp5_nomig_xim1" => m_nice_ssp5_nomig_xim1,
    "m_nice_ssp1_nocc" => m_nice_ssp1_nocc, "m_nice_ssp2_nocc" => m_nice_ssp2_nocc, "m_nice_ssp3_nocc" => m_nice_ssp3_nocc, "m_nice_ssp4_nocc" => m_nice_ssp4_nocc, "m_nice_ssp5_nocc" => m_nice_ssp5_nocc,
    "m_nice_ssp1_nocc_xi0" => m_nice_ssp1_nocc_xi0, "m_nice_ssp2_nocc_xi0" => m_nice_ssp2_nocc_xi0, "m_nice_ssp3_nocc_xi0" => m_nice_ssp3_nocc_xi0, "m_nice_ssp4_nocc_xi0" => m_nice_ssp4_nocc_xi0, "m_nice_ssp5_nocc_xi0" => m_nice_ssp5_nocc_xi0,
    "m_nice_ssp1_nocc_xim1" => m_nice_ssp1_nocc_xim1, "m_nice_ssp2_nocc_xim1" => m_nice_ssp2_nocc_xim1, "m_nice_ssp3_nocc_xim1" => m_nice_ssp3_nocc_xim1, "m_nice_ssp4_nocc_xim1" => m_nice_ssp4_nocc_xim1, "m_nice_ssp5_nocc_xim1" => m_nice_ssp5_nocc_xim1,
    #"m_nice_ssp2_novuln_xi0" => m_nice_ssp2_novuln_xi0,
    #"m_nice_ssp2_nofert_xi0" => m_nice_ssp2_nofert_xi0,
    "m_nice_ssp2_noconst_xi0" => m_nice_ssp2_noconst_xi0
)

for (n,m) in models
    results = nice_fund_mig(m)

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