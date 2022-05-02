using DelimitedFiles, CSV, VegaLite, FileIO, VegaDatasets, FilePaths
using Statistics, DataFrames, Query

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

run(m_nice_ssp1_nomig)
run(m_nice_ssp2_nomig)
run(m_nice_ssp3_nomig)
run(m_nice_ssp4_nomig)
run(m_nice_ssp5_nomig)
run(m_fundnicessp1)
run(m_fundnicessp2)
run(m_fundnicessp3)
run(m_fundnicessp4)
run(m_fundnicessp5)
run(m_fund)


############################################## Compare emissions in Mig-NICE-FUND, in NICE-FUND with SSP and in FUND with original scenarios ########################3
ssps = ["SSP1-RCP1.9","SSP2-RCP4.5","SSP3-RCP7.0","SSP4-RCP6.0","SSP5-RCP8.5"]
regions = ["USA", "CAN", "WEU", "JPK", "ANZ", "EEU", "FSU", "MDE", "CAM", "LAM", "SAS", "SEA", "CHI", "MAF", "SSA", "SIS"]
years = 1951:2100

em = DataFrame(
    year = repeat(years, outer = length(ssps)*length(regions)),
    scen = repeat(ssps,inner = length(regions)*length(years)),
    fundregion = repeat(regions, outer = length(ssps), inner=length(years)),
)

em_migNICEFUND = vcat(
    collect(Iterators.flatten(m_nice_ssp1_nomig[:emissions,:emission][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp2_nomig[:emissions,:emission][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp3_nomig[:emissions,:emission][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp4_nomig[:emissions,:emission][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp5_nomig[:emissions,:emission][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
em[:,:em_migNICEFUND] = em_migNICEFUND
em_nice_sspNICEFUND = vcat(
    collect(Iterators.flatten(m_fundnicessp1[:emissions,:emission][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_fundnicessp2[:emissions,:emission][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_fundnicessp3[:emissions,:emission][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_fundnicessp4[:emissions,:emission][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_fundnicessp5[:emissions,:emission][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
em[:,:em_nice_sspNICEFUND] = em_nice_sspNICEFUND
em_origFUND = vcat(collect(Iterators.flatten(m_fund[:emissions,:emission][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),missings(length(years)*length(regions)*4))
em[:,:em_origFUND] = em_origFUND

em_world = combine(d->(worldem_nice_sspNICEFUND=sum(d.em_nice_sspNICEFUND),worldem_migNICEFUND=sum(d.em_migNICEFUND),worldem_origFUND=sum(d.em_origFUND)), groupby(em,[:year,:scen]))
em_world_p = em_world[(map(x->mod(x,10)==0,em_world[:,:year])),:]
em_world_stack = stack(em_world_p,[:worldem_nice_sspNICEFUND,:worldem_migNICEFUND,:worldem_origFUND],[:scen,:year])
rename!(em_world_stack,:variable => :worldem_type, :value => :worldem)
data_ssp = em_world_stack |> @filter(_.year >= 2015 && _.year <= 2100 && _.worldem_type != :worldem_origFUND) 
data_fund = em_world_stack[:,Not(:scen)] |> @filter(_.year >= 2015 && _.year <= 2100 && _.worldem_type == :worldem_origFUND) 
@vlplot() + @vlplot(
    width=300, height=250, data = data_ssp,
    mark={:point, size=30}, x = {"year:o", axis={labelFontSize=16}, title=nothing}, y = {"worldem:q", title=nothing, axis={labelFontSize=16}}, 
    title = "Global emissions for FUND with original SSP and Mig-NICE-FUND", 
    color = {"scen:n", scale={scheme=:category10}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}, 
    shape = {"worldem_type:o", scale={range=["circle","triangle-up"]}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}
) + @vlplot(
    mark={:line, strokeDash=[1,2]}, data = data_ssp, x = {"year:o", axis={labelFontSize=16}, title=nothing}, y = {"worldem:q", aggregate=:mean,type=:quantitative,title=nothing, axis={labelFontSize=16}}, 
    color = {"scen:n", scale={scheme=:category10}},
    detail = "worldem_type:o"
) + @vlplot(
    data = data_fund, mark={:line, strokeDash=[1,2], color = :black}, 
    x = {"year:o", axis={labelFontSize=16}, title=nothing}, y = {"worldem:q", aggregate=:mean,type=:quantitative, title=nothing, axis={labelFontSize=16}}, 
    detail = "worldem_type:o"
) |> save(joinpath(@__DIR__, "../results/emissions_ineq/", "em_world_v5.png"))


pop_migNICEFUND = vcat(
    collect(Iterators.flatten(m_nice_ssp1_nomig[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp2_nomig[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp3_nomig[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp4_nomig[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp5_nomig[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
em[:,:pop_migNICEFUND] = pop_migNICEFUND
pop_sspNICEFUND = vcat(
    collect(Iterators.flatten(m_fundnicessp1[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_fundnicessp2[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_fundnicessp3[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_fundnicessp4[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_fundnicessp5[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
em[:,:pop_sspNICEFUND] = pop_sspNICEFUND
pop_origFUND = vcat(collect(Iterators.flatten(m_fund[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),missings(length(years)*length(regions)*4))
em[:,:pop_origFUND] = pop_origFUND

em[!,:empc_migNICEFUND] = em[!,:em_migNICEFUND] ./ em[!,:pop_migNICEFUND] .* 10^6           # Emissions in MtCO2
em[!,:empc_sspNICEFUND] = em[!,:em_nice_sspNICEFUND] ./ em[!,:pop_sspNICEFUND] .* 10^6
em[!,:empc_origFUND] = em[!,:em_origFUND] ./ em[!,:pop_origFUND] .* 10^6

worldpop_migNICEFUND = vcat(
    collect(Iterators.flatten(m_nice_ssp1_nomig[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_nice_ssp2_nomig[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_nice_ssp3_nomig[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_nice_ssp4_nomig[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_nice_ssp5_nomig[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)]))
)
em_world[:,:worldpop_migNICEFUND] = worldpop_migNICEFUND
worldpop_sspNICEFUND = vcat(
    collect(Iterators.flatten(m_fundnicessp1[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_fundnicessp2[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_fundnicessp3[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_fundnicessp4[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_fundnicessp5[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)]))
)
em_world[:,:worldpop_sspNICEFUND] = worldpop_sspNICEFUND
worldpop_origFUND = vcat(collect(Iterators.flatten(m_fund[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),missings(length(years)*4))
em_world[:,:worldpop_origFUND] = worldpop_origFUND

em_world[!,:worldempc_migNICEFUND] = em_world[!,:worldem_migNICEFUND] ./ em_world[!,:worldpop_migNICEFUND] .* 10^6           # Emissions in MtCO2
em_world[!,:worldempc_sspNICEFUND] = em_world[!,:worldem_nice_sspNICEFUND] ./ em_world[!,:worldpop_sspNICEFUND] .* 10^6
em_world[!,:worldempc_origFUND] = em_world[!,:worldem_origFUND] ./ em_world[!,:worldpop_origFUND] .* 10^6

em_world_p = em_world[(map(x->mod(x,10)==0,em_world[:,:year])),:]
em_world_stack = stack(em_world_p,[:worldempc_sspNICEFUND,:worldempc_migNICEFUND,:worldempc_origFUND],[:scen,:year])
rename!(em_world_stack,:variable => :worldempc_type, :value => :worldempc)
data_ssp = em_world_stack |> @filter(_.year >= 2015 && _.year <= 2100 && _.worldempc_type != :worldempc_origFUND) 
data_fund = em_world_stack[:,Not(:scen)] |> @filter(_.year >= 2015 && _.year <= 2100 && _.worldempc_type == :worldempc_origFUND) 
@vlplot()+@vlplot(
    width=300, height=250,data=data_ssp,
    mark={:point, size=60}, x = {"year:o", axis={labelFontSize=16}, title=nothing}, y = {"worldempc:q", title=nothing, axis={labelFontSize=16}}, 
    title = "Global emissions per capita for FUND with original SSP and Mig-NICE-FUND", 
    color = {"scen:n", scale={scheme=:category10}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}, 
    shape = {"worldempc_type:o", scale={range=["circle","triangle-up"]}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}
) + @vlplot(
    mark={:line, strokeDash=[1,2]}, data=data_ssp,x = {"year:o", axis={labelFontSize=16}, title=nothing}, y = {"worldempc:q", aggregate=:mean,type=:quantitative,title=nothing, axis={labelFontSize=16}}, 
    color = {"scen:n", scale={scheme=:category10}},
    detail = "worldempc_type:o"
) + @vlplot(
    data = data_fund, mark={:line, strokeDash=[1,2], color = :black}, 
    x = {"year:o", axis={labelFontSize=16}, title=nothing}, y = {"worldempc:q", aggregate=:mean,type=:quantitative, title=nothing, axis={labelFontSize=16}}, 
    detail = "worldempc_type:o"
) |> save(joinpath(@__DIR__, "../results/emissions_ineq/", "empc_world_v5.png"))


############################################### Compare emissions in Mig-NICE-FUND for different income elasticities of damages (xi) ##########################################
# Default is done above: damages within a given region proportional to income (xi=1)

# Damages within a given region independent of income (xi=0)
m_nice_ssp1_nomig_xi0 = getmigrationnicemodel(scen="SSP1",migyesno="nomig",xi=0.0,omega=1.0)
m_nice_ssp2_nomig_xi0 = getmigrationnicemodel(scen="SSP2",migyesno="nomig",xi=0.0,omega=1.0)
m_nice_ssp3_nomig_xi0 = getmigrationnicemodel(scen="SSP3",migyesno="nomig",xi=0.0,omega=1.0)
m_nice_ssp4_nomig_xi0 = getmigrationnicemodel(scen="SSP4",migyesno="nomig",xi=0.0,omega=1.0)
m_nice_ssp5_nomig_xi0 = getmigrationnicemodel(scen="SSP5",migyesno="nomig",xi=0.0,omega=1.0)
run(m_nice_ssp1_nomig_xi0)
run(m_nice_ssp2_nomig_xi0)
run(m_nice_ssp3_nomig_xi0)
run(m_nice_ssp4_nomig_xi0)
run(m_nice_ssp5_nomig_xi0)

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
run(m_nice_ssp1_nomig_xim1)
run(m_nice_ssp2_nomig_xim1)
run(m_nice_ssp3_nomig_xim1)
run(m_nice_ssp4_nomig_xim1)
run(m_nice_ssp5_nomig_xim1)

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


em_migNICEFUND_xi0 = vcat(
    collect(Iterators.flatten(m_nice_ssp1_nomig_xi0[:emissions,:emission][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp2_nomig_xi0[:emissions,:emission][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp3_nomig_xi0[:emissions,:emission][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp4_nomig_xi0[:emissions,:emission][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp5_nomig_xi0[:emissions,:emission][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
em[:,:em_migNICEFUND_xi0] = em_migNICEFUND_xi0
em_migNICEFUND_xim1 = vcat(
    collect(Iterators.flatten(m_nice_ssp1_nomig_xim1[:emissions,:emission][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp2_nomig_xim1[:emissions,:emission][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp3_nomig_xim1[:emissions,:emission][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp4_nomig_xim1[:emissions,:emission][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp5_nomig_xim1[:emissions,:emission][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
em[:,:em_migNICEFUND_xim1] = em_migNICEFUND_xim1
pop_migNICEFUND_xi0 = vcat(
    collect(Iterators.flatten(m_nice_ssp1_nomig_xi0[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp2_nomig_xi0[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp3_nomig_xi0[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp4_nomig_xi0[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp5_nomig_xi0[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
em[:,:pop_migNICEFUND_xi0] = pop_migNICEFUND_xi0
pop_migNICEFUND_xim1 = vcat(
    collect(Iterators.flatten(m_nice_ssp1_nomig_xim1[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp2_nomig_xim1[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp3_nomig_xim1[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp4_nomig_xim1[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp5_nomig_xim1[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
em[:,:pop_migNICEFUND_xim1] = pop_migNICEFUND_xim1

em[!,:empc_migNICEFUND_xi0] = em[!,:em_migNICEFUND_xi0] ./ em[!,:pop_migNICEFUND_xi0] .* 10^6           # Emissions in MtCO2
em[!,:empc_migNICEFUND_xim1] = em[!,:em_migNICEFUND_xim1] ./ em[!,:pop_migNICEFUND_xim1] .* 10^6

em_p = em[(map(x->mod(x,10)==0,em[:,:year])),:]
rename!(em_p, :empc_migNICEFUND => :empc_damprop, :empc_migNICEFUND_xi0 => :empc_damindep, :empc_migNICEFUND_xim1 => :empc_daminvprop)
rename!(em_p, :em_migNICEFUND => :em_damprop, :em_migNICEFUND_xi0 => :em_damindep, :em_migNICEFUND_xim1 => :em_daminvprop)

em_world = combine(d->(worldem_migNICEFUND=sum(d.em_migNICEFUND),worldem_migNICEFUND_xi0=sum(d.em_migNICEFUND_xi0),worldem_migNICEFUND_xim1=sum(d.em_migNICEFUND_xim1)), groupby(em,[:year,:scen]))

worldpop_migNICEFUND_xi0 = vcat(
    collect(Iterators.flatten(m_nice_ssp1_nomig_xi0[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_nice_ssp2_nomig_xi0[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_nice_ssp3_nomig_xi0[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_nice_ssp4_nomig_xi0[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_nice_ssp5_nomig_xi0[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)]))
)
em_world[:,:worldpop_migNICEFUND_xi0] = worldpop_migNICEFUND_xi0
worldpop_migNICEFUND_xim1 = vcat(
    collect(Iterators.flatten(m_nice_ssp1_nomig_xim1[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_nice_ssp2_nomig_xim1[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_nice_ssp3_nomig_xim1[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_nice_ssp4_nomig_xim1[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_nice_ssp5_nomig_xim1[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)]))
)
em_world[:,:worldpop_migNICEFUND_xim1] = worldpop_migNICEFUND_xim1

em_world[:,:worldempc_migNICEFUND_xi0] = em_world[!,:worldem_migNICEFUND_xi0] ./ em_world[!,:worldpop_migNICEFUND_xi0] .* 10^6  
em_world[:,:worldempc_migNICEFUND_xim1] = em_world[!,:worldem_migNICEFUND_xim1] ./ em_world[!,:worldpop_migNICEFUND_xim1] .* 10^6

em_world[:,:worldpop_migNICEFUND] = worldpop_migNICEFUND
em_world[!,:worldempc_migNICEFUND] = em_world[!,:worldem_migNICEFUND] ./ em_world[!,:worldpop_migNICEFUND] .* 10^6           # Emissions in MtCO2

em_world_p = em_world[(map(x->mod(x,10)==0,em_world[:,:year])),:]
rename!(em_world_p, :worldempc_migNICEFUND => :worldempc_damprop, :worldempc_migNICEFUND_xi0 => :worldempc_damindep, :worldempc_migNICEFUND_xim1 => :worldempc_daminvprop)
rename!(em_world_p, :worldem_migNICEFUND => :worldem_damprop, :worldem_migNICEFUND_xi0 => :worldem_damindep, :worldem_migNICEFUND_xim1 => :worldem_daminvprop)

em_world_stack = stack(em_world_p,[:worldem_damprop,:worldem_damindep,:worldem_daminvprop],[:scen,:year])
rename!(em_world_stack,:variable => :worldem_type, :value => :worldem)
em_world_stack |> @filter(_.year >= 2015 && _.year <= 2100)  |> @vlplot()+@vlplot(
    width=300, height=250, mark={:point, size=50}, 
    x = {"year:o", axis={labelFontSize=16}, title=nothing}, 
    y = {"worldem:q", title="World CO2 emissions, Mt CO2", axis={labelFontSize=16,titleFontSize=16}}, 
    #title = "Global emissions for Mig-NICE-FUND with various income elasticities of damages", 
    color = {"scen:n", scale={scheme=:category10}, legend=nothing}, 
    shape = {"worldem_type:o", scale={range=["circle","triangle-up", "square"]}, legend=nothing}
) + @vlplot(
    mark={:line, strokeDash=[1,2]}, x = {"year:o", axis={labelFontSize=16}, title=nothing}, 
    y = {"worldem:q", aggregate=:mean,type=:quantitative,title="World CO2 emissions, Mt CO2", axis={labelFontSize=16,titleFontSize=16}}, 
    color = {"scen:n", scale={scheme=:category10}, legend=nothing},
    detail = "worldem_type:o"
) |> save(joinpath(@__DIR__, "../results/emissions_ineq/", "em_world_xi_v5.png"))

em_world_stack = stack(em_world_p,[:worldempc_damprop,:worldempc_damindep,:worldempc_daminvprop],[:scen,:year])
rename!(em_world_stack,:variable => :worldempc_type, :value => :worldempc)
em_world_stack |> @filter(_.year >= 2015 && _.year <= 2100)  |> @vlplot()+@vlplot(
    width=300, height=250,
    mark={:point, size=50}, x = {"year:o", axis={labelFontSize=16}, title=nothing}, y = {"worldempc:q", title=nothing, axis={labelFontSize=16}}, 
    title = "Global emissions per capita for Mig-NICE-FUND with various income elasticities of damages", 
    color = {"scen:n", scale={scheme=:category10}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}, 
    shape = {"worldempc_type:o", scale={range=["circle","triangle-up", "square"]}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}
) + @vlplot(
    mark={:line, strokeDash=[1,2]}, x = {"year:o", axis={labelFontSize=16}, title=nothing}, y = {"worldempc:q", aggregate=:mean,type=:quantitative,title=nothing, axis={labelFontSize=16}}, 
    color = {"scen:n", scale={scheme=:category10}},
    detail = "worldempc_type:o"
) |> save(joinpath(@__DIR__, "../results/emissions_ineq/", "empc_world_xi_v5.png"))


############################################# Look at empc for different income elasticities of damages ###############################################
empc_all = stack(
    rename(em, :empc_migNICEFUND => :empc_damprop, :empc_migNICEFUND_xi0 => :empc_damindep, :empc_migNICEFUND_xim1 => :empc_daminvprop), 
    [:empc_damprop,:empc_damindep,:empc_daminvprop], 
    [:scen, :fundregion, :year]
)
rename!(empc_all, :variable => :empc_type, :value => :empc)
for s in ssps
    empc_all |> @filter(_.year >= 2010 && _.year <= 2100 && _.scen == s) |> @vlplot(
        mark={:line, strokeWidth = 4}, width=300, height=250, columns=4, wrap="fundregion:o", 
        x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
        y={"empc:q", title = nothing, axis={labelFontSize=16}},
        color={"empc_type:o",scale={scheme=:darkgreen},legend={titleFontSize=16, symbolSize=40, labelFontSize=16}},
        resolve = {scale={y=:independent}}
    ) |> save(joinpath(@__DIR__, "../results/emissions_ineq/", string("empc_",s,"_v5.png")))
end
empc_all[!,:scen_empc_type] = [string(empc_all[i,:scen],"_",SubString(string(empc_all[i,:empc_type]),4)) for i in 1:size(empc_all,1)]
empc_all |> @filter(_.year >= 2010 && _.year <= 2100) |> @vlplot(
    mark={:line, strokeWidth = 4}, width=300, height=250, columns=4, wrap="fundregion:o", 
    x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
    y={"empc:q", title = nothing, axis={labelFontSize=16}},
    title = "Emissions per capita for world regions, SSP narratives and various income elasticities of damages",
    color={"scen_empc_type:o",scale={scheme=:category20c},legend={titleFontSize=16, symbolSize=40, labelFontSize=16}},
    resolve = {scale={y=:independent}}
) |> save(joinpath(@__DIR__, "../results/emissions_ineq/", string("empc_v5.png")))


################################################################## Plot geographical maps ###########################################################
world110m = dataset("world-110m")

isonum_fundregion = CSV.read(joinpath(@__DIR__,"../input_data/isonum_fundregion.csv"), DataFrame)
em_maps = leftjoin(em, isonum_fundregion, on = :fundregion)
em_maps[!,:emdiff_damindep] = (em_maps[!,:em_migNICEFUND_xi0] ./ em_maps[!,:em_migNICEFUND] .- 1) .* 100
em_maps[!,:emdiff_daminvprop] = (em_maps[!,:em_migNICEFUND_xim1] ./ em_maps[!,:em_migNICEFUND] .- 1) .* 100
em_maps[!,:empcdiff_damindep] = (em_maps[!,:empc_migNICEFUND_xi0] ./ em_maps[!,:empc_migNICEFUND] .- 1) .* 100
em_maps[!,:empcdiff_daminvprop] = (em_maps[!,:empc_migNICEFUND_xim1] ./ em_maps[!,:empc_migNICEFUND] .- 1) .* 100

for s in ssps
    @vlplot(width=800, height=600) + @vlplot(mark={:geoshape, stroke = :lightgray}, 
        data={values=world110m, format={type=:topojson, feature=:countries}}, 
        transform = [{lookup=:id, from={data=filter(row -> row[:scen] == s && row[:year] == 2100, em_maps), key=:isonum, fields=[string(:em_migNICEFUND)]}}],
        projection={type=:naturalEarth1}, title = {text=string("Emissions levels by 2100 for damages proportional to income, ", s),fontSize=24}, 
        color = {:em_migNICEFUND, type=:quantitative, scale={scheme=:greens,domain=[-1000,9000]}, legend={title=string("MtCO2"), titleFontSize=20, titleLimit=220, symbolSize=60, labelFontSize=24, labelLimit=220, offset=2}}
    ) |> save(joinpath(@__DIR__, "../results/world_maps_ineq/", string("em_damprop_", s, "_v5.png")))
end
for s in ssps
    @vlplot(width=800, height=600) + @vlplot(mark={:geoshape, stroke = :lightgray}, 
        data={values=world110m, format={type=:topojson, feature=:countries}}, 
        transform = [{lookup=:id, from={data=filter(row -> row[:scen] == s && row[:year] == 2100, em_maps), key=:isonum, fields=[string(:emdiff,:_damindep)]}}],
        projection={type=:naturalEarth1}, title = {text=string("damages independent of income, 2100, ", s),fontSize=24}, 
        color = {Symbol(string(:emdiff,:_damindep)), type=:quantitative, scale={domain=[-20,20], scheme=:redblue}, legend={title="% vs proportional", titleFontSize=20, symbolSize=60, labelFontSize=24}}
    ) |> save(joinpath(@__DIR__, "../results/world_maps_ineq/", string("emdiff",:_damindep,"_", s, "_v5.png")))
end
for s in ssps
    @vlplot(width=800, height=600) + @vlplot(mark={:geoshape, stroke = :lightgray}, 
        data={values=world110m, format={type=:topojson, feature=:countries}}, 
        transform = [{lookup=:id, from={data=filter(row -> row[:scen] == s && row[:year] == 2100, em_maps), key=:isonum, fields=[string(:emdiff,:_daminvprop)]}}],
        projection={type=:naturalEarth1}, title = {text=string("damages inversely proportional to income, 2100, ", s),fontSize=24}, 
        color = {Symbol(string(:emdiff,:_daminvprop)), type=:quantitative, scale={domain=[-20,20], scheme=:redblue}, legend={title="% vs proportional", titleFontSize=20, symbolSize=60, labelFontSize=24}}
    ) |> save(joinpath(@__DIR__, "../results/world_maps_ineq/", string("emdiff",:_daminvprop,"_", s, "_v5.png")))
end

for s in ssps
    @vlplot(width=800, height=600) + @vlplot(mark={:geoshape, stroke = :lightgray}, 
        data={values=world110m, format={type=:topojson, feature=:countries}}, 
        transform = [{lookup=:id, from={data=filter(row -> row[:scen] == s && row[:year] == 2100, em_maps), key=:isonum, fields=[string(:empc_migNICEFUND)]}}],
        projection={type=:naturalEarth1}, title = {text=string("Emissions per capita levels by 2100 for damages proportional to income, ", s),fontSize=24}, 
        color = {:empc_migNICEFUND, type=:quantitative, scale={scheme=:greens,domain=[-5,25]}, legend={title=string("MtCO2/cap"), titleFontSize=20, titleLimit=220, symbolSize=60, labelFontSize=24, labelLimit=220, offset=2}}
    ) |> save(joinpath(@__DIR__, "../results/world_maps_ineq/", string("empc_damprop_", s, "_v5.png")))
end
for s in ssps
    @vlplot(width=800, height=600) + @vlplot(mark={:geoshape, stroke = :lightgray}, 
        data={values=world110m, format={type=:topojson, feature=:countries}}, 
        transform = [{lookup=:id, from={data=filter(row -> row[:scen] == s && row[:year] == 2100, em_maps), key=:isonum, fields=[string(:empcdiff,:_damindep)]}}],
        projection={type=:naturalEarth1}, title = {text=string("damages independent of income, 2100, ", s),fontSize=24}, 
        color = {Symbol(string(:empcdiff,:_damindep)), type=:quantitative, scale={domain=[-2,2], scheme=:redblue}, legend={title="% vs proportional", titleFontSize=20, symbolSize=60, labelFontSize=24}}
    ) |> save(joinpath(@__DIR__, "../results/world_maps_ineq/", string("empcdiff",:_damindep,"_", s, "_v5.png")))
end
for s in ssps
    @vlplot(width=800, height=600) + @vlplot(mark={:geoshape, stroke = :lightgray}, 
        data={values=world110m, format={type=:topojson, feature=:countries}}, 
        transform = [{lookup=:id, from={data=filter(row -> row[:scen] == s && row[:year] == 2100, em_maps), key=:isonum, fields=[string(:empcdiff,:_daminvprop)]}}],
        projection={type=:naturalEarth1}, title = {text=string("damages inversely proportional to income, 2100, ", s),fontSize=24}, 
        color = {Symbol(string(:empcdiff,:_daminvprop)), type=:quantitative, scale={domain=[-2,2], scheme=:redblue}, legend={title="% vs proportional", titleFontSize=20, symbolSize=60, labelFontSize=24}}
    ) |> save(joinpath(@__DIR__, "../results/world_maps_ineq/", string("empcdiff",:_daminvprop,"_", s, "_v5.png")))
end