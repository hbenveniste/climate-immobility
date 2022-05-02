using DelimitedFiles, CSV, VegaLite, VegaDatasets, FileIO, FilePaths
using Statistics, DataFrames

using MimiFUND

include("main_mig_nice.jl")
include("fund_ssp_ineq.jl")


################# Compare original FUND model with original scenarios, NICE-FUND with SSP scenarios, and Mig-NICE-FUND with SSP scenarios zero migration ###############

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
run(m_fundnicessp1)
run(m_fundnicessp2)
run(m_fundnicessp3)
run(m_fundnicessp4)
run(m_fundnicessp5)
run(m_fund)


################################### Compare damages in absolute terms and in % of GDP in Mig-NICE-FUND and in NICE-FUND with SSP #####################
ssps = ["SSP1","SSP2","SSP3","SSP4","SSP5"]
regions = ["USA", "CAN", "WEU", "JPK", "ANZ", "EEU", "FSU", "MDE", "CAM", "LAM", "SAS", "SEA", "CHI", "MAF", "SSA", "SIS"]
years = 1951:2100

damages = DataFrame(
    year = repeat(years, outer = length(ssps)*length(regions)),
    scen = repeat(ssps,inner = length(regions)*length(years)),
    fundregion = repeat(regions, outer = length(ssps), inner=length(years)),
)

dam_migNICEFUND = vcat(
    collect(Iterators.flatten(m_nice_ssp1_nomig[:addimpact,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp2_nomig[:addimpact,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp3_nomig[:addimpact,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp4_nomig[:addimpact,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp5_nomig[:addimpact,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
damages[:,:damages_migNICEFUND] = dam_migNICEFUND
dam_nice_sspFUND = vcat(
    collect(Iterators.flatten(m_fundnicessp1[:impactaggregation,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_fundnicessp2[:impactaggregation,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_fundnicessp3[:impactaggregation,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_fundnicessp4[:impactaggregation,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_fundnicessp5[:impactaggregation,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
damages[:,:damages_sspFUND] = dam_nice_sspFUND
damages_origFUND = vcat(collect(Iterators.flatten(m_fund[:impactaggregation,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),missings(length(years)*length(regions)*4))
damages[:,:damages_origFUND] = damages_origFUND

dam_world = combine(d->(worlddamages_sspFUND=sum(d.damages_sspFUND),worlddamages_migNICEFUND=sum(d.damages_migNICEFUND),worlddamages_origFUND=sum(d.damages_origFUND)), groupby(damages,[:year,:scen]))
dam_world_p = dam_world[(map(x->mod(x,10)==0,dam_world[:,:year])),:]
dam_world_stack = stack(dam_world_p,[:worlddamages_sspFUND,:worlddamages_migNICEFUND,:worlddamages_origFUND],[:scen,:year])
rename!(dam_world_stack,:variable => :worlddamages_type, :value => :worlddamages)
data_ssp = dam_world_stack |> @filter(_.year >= 2015 && _.year <= 2100 && _.worlddamages_type != :worlddamages_origFUND) 
data_fund = dam_world_stack[:,Not(:scen)] |> @filter(_.year >= 2015 && _.year <= 2100 && _.worlddamages_type == :worlddamages_origFUND) 
@vlplot() + @vlplot(
    width=300, height=250, data = data_ssp,
    mark={:point, size=60}, x = {"year:o", axis={labelFontSize=16}, title=nothing}, y = {"worlddamages:q", title=nothing, axis={labelFontSize=16}}, 
    title = "Global damages for NICE-FUND with original SSP and Mig-NICE-FUND", 
    color = {"scen:n", scale={scheme=:category10}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}, 
    shape = {"worlddamages_type:o", scale={range=["circle","triangle-up"]}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}
) + @vlplot(
    mark={:line, strokeDash=[1,2]}, data = data_ssp, x = {"year:o", axis={labelFontSize=16}, title=nothing}, y = {"worlddamages:q", aggregate=:mean,type=:quantitative,title=nothing, axis={labelFontSize=16}}, 
    color = {"scen:n", scale={scheme=:category10}},
    detail = "worlddamages_type:o"
) + @vlplot(
    data = data_fund, mark={:line, strokeDash=[1,2], color = :black}, 
    x = {"year:o", axis={labelFontSize=16}, title=nothing}, y = {"worlddamages:q", aggregate=:mean,type=:quantitative, title=nothing, axis={labelFontSize=16}}, 
    detail = "worlddamages_type:o"
) |> save(joinpath(@__DIR__, "../results/damages_ineq/", "damages_world_v5.png"))


gdp_migNICEFUND = vcat(
    collect(Iterators.flatten(m_nice_ssp1_nomig[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp2_nomig[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp3_nomig[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp4_nomig[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp5_nomig[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
damages[:,:gdp_migNICEFUND] = gdp_migNICEFUND
gdp_sspFUND = vcat(
    collect(Iterators.flatten(m_fundnicessp1[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_fundnicessp2[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_fundnicessp3[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_fundnicessp4[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_fundnicessp5[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
damages[:,:gdp_sspFUND] = gdp_sspFUND
gdp_origFUND = vcat(collect(Iterators.flatten(m_fund[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),missings(length(years)*length(regions)*4))
damages[:,:gdp_origFUND] = gdp_origFUND
damages[:,:damgdp_migNICEFUND] = damages[:,:damages_migNICEFUND] ./ (damages[:,:gdp_migNICEFUND] .* 10^9)
damages[:,:damgdp_sspFUND] = damages[:,:damages_sspFUND] ./ (damages[:,:gdp_sspFUND] .* 10^9)
damages[:,:damgdp_origFUND] = damages[:,:damages_origFUND] ./ (damages[:,:gdp_origFUND] .* 10^9)

damages |> @filter(_.year >= 1990 && _.year <= 2100 && _.scen == "SSP2") |> @vlplot(
    repeat={column=[:damgdp_sspFUND, :damgdp_migNICEFUND]}
    ) + @vlplot(
    mark={:line, strokeWidth = 4}, width=300,
    x={"year:o", axis={labelFontSize=16, values = 1990:10:2100}, title=nothing},
    y={field={repeat=:column}, type = :quantitative, axis={labelFontSize=16}},
    color={"fundregion:o",scale={scheme="tableau20"}},
) |> save(joinpath(@__DIR__, "../results/damages_ineq/", "damgdp_mignice_SSP2_v5.png"))

worldgdp_migNICEFUND = vcat(
    collect(Iterators.flatten(m_nice_ssp1_nomig[:socioeconomic,:globalincome][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_nice_ssp2_nomig[:socioeconomic,:globalincome][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_nice_ssp3_nomig[:socioeconomic,:globalincome][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_nice_ssp4_nomig[:socioeconomic,:globalincome][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_nice_ssp5_nomig[:socioeconomic,:globalincome][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)]))
)
dam_world[:,:worldgdp_migNICEFUND] = worldgdp_migNICEFUND
worldgdp_sspFUND = vcat(
    collect(Iterators.flatten(m_fundnicessp1[:socioeconomic,:globalincome][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_fundnicessp2[:socioeconomic,:globalincome][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_fundnicessp3[:socioeconomic,:globalincome][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_fundnicessp4[:socioeconomic,:globalincome][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_fundnicessp5[:socioeconomic,:globalincome][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)]))
)
dam_world[:,:worldgdp_sspFUND] = worldgdp_sspFUND
worldgdp_origFUND = vcat(collect(Iterators.flatten(m_fund[:socioeconomic,:globalincome][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),missings(length(years)*4))
dam_world[:,:worldgdp_origFUND] = worldgdp_origFUND
dam_world_p = dam_world[(map(x->mod(x,10)==0,dam_world[:,:year])),:]
dam_world_p[:,:worlddamgdp_migNICEFUND] = dam_world_p[:,:worlddamages_migNICEFUND] ./ (dam_world_p[:,:worldgdp_migNICEFUND] .* 10^9)
dam_world_p[:,:worlddamgdp_sspFUND] = dam_world_p[:,:worlddamages_sspFUND] ./ (dam_world_p[:,:worldgdp_sspFUND] .* 10^9)
dam_world_p[:,:worlddamgdp_origFUND] = dam_world_p[:,:worlddamages_origFUND] ./ (dam_world_p[:,:worldgdp_origFUND] .* 10^9)
dam_world_stack = stack(dam_world_p,[:worlddamgdp_sspFUND,:worlddamgdp_migNICEFUND,:worlddamgdp_origFUND],[:scen,:year])
rename!(dam_world_stack,:variable => :worlddamgdp_type, :value => :worlddamgdp)
data_ssp = dam_world_stack |> @filter(_.year >= 2015 && _.year <= 2100 && _.worlddamgdp_type != :worlddamgdp_origFUND) 
data_fund = dam_world_stack[:,Not(:scen)] |> @filter(_.year >= 2015 && _.year <= 2100 && _.worlddamgdp_type == :worlddamgdp_origFUND) 
@vlplot() + @vlplot(
    width=300, height=250, data=data_ssp,
    mark={:point, size=60}, x = {"year:o", axis={labelFontSize=16}, title=nothing}, y = {"worlddamgdp:q", title=nothing, axis={labelFontSize=16}}, 
    title = "Global damages as share of GDP for NICE-FUND with original SSP and Mig-NICE-FUND", 
    color = {"scen:n", scale={scheme=:category10}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}, 
    shape = {"worlddamgdp_type:o", scale={range=["circle","triangle-up"]}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}
) + @vlplot(
    mark={:line, strokeDash=[1,2]}, data=data_ssp, x = {"year:o", axis={labelFontSize=16}, title=nothing}, y = {"worlddamgdp:q", aggregate=:mean,type=:quantitative,title=nothing, axis={labelFontSize=16}}, 
    color = {"scen:n", scale={scheme=:category10}},
    detail = "worlddamgdp_type:o"
) + @vlplot(
    data = data_fund, mark={:line, strokeDash=[1,2], color = :black}, 
    x = {"year:o", axis={labelFontSize=16}, title=nothing}, y = {"worlddamgdp:q", aggregate=:mean,type=:quantitative, title=nothing, axis={labelFontSize=16}}, 
    detail = "worlddamgdp_type:o"
) |> save(joinpath(@__DIR__, "../results/damages_ineq/", "damgdp_world_v5.png"))


############################################# Compare damages in Mig-NICE-FUND for different income elasticities of damages (xi) ##########################
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


dam_migNICEFUND_xi0 = vcat(
    collect(Iterators.flatten(m_nice_ssp1_nomig_xi0[:addimpact,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp2_nomig_xi0[:addimpact,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp3_nomig_xi0[:addimpact,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp4_nomig_xi0[:addimpact,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp5_nomig_xi0[:addimpact,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
damages[:,:damages_migNICEFUND_xi0] = dam_migNICEFUND_xi0
dam_migNICEFUND_xim1 = vcat(
    collect(Iterators.flatten(m_nice_ssp1_nomig_xim1[:addimpact,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp2_nomig_xim1[:addimpact,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp3_nomig_xim1[:addimpact,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp4_nomig_xim1[:addimpact,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp5_nomig_xim1[:addimpact,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
damages[:,:damages_migNICEFUND_xim1] = dam_migNICEFUND_xim1
gdp_migNICEFUND_xi0 = vcat(
    collect(Iterators.flatten(m_nice_ssp1_nomig_xi0[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp2_nomig_xi0[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp3_nomig_xi0[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp4_nomig_xi0[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp5_nomig_xi0[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
damages[:,:gdp_migNICEFUND_xi0] = gdp_migNICEFUND_xi0
gdp_migNICEFUND_xim1 = vcat(
    collect(Iterators.flatten(m_nice_ssp1_nomig_xim1[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp2_nomig_xim1[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp3_nomig_xim1[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp4_nomig_xim1[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp5_nomig_xim1[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
damages[:,:gdp_migNICEFUND_xim1] = gdp_migNICEFUND_xim1

damages[:,:damgdp_migNICEFUND_xi0] = damages[:,:damages_migNICEFUND_xi0] ./ (damages[:,:gdp_migNICEFUND_xi0] .* 10^9)
damages[:,:damgdp_migNICEFUND_xim1] = damages[:,:damages_migNICEFUND_xim1] ./ (damages[:,:gdp_migNICEFUND_xim1] .* 10^9)
rename!(damages, :damages_migNICEFUND => :dam_damprop, :damages_migNICEFUND_xi0 => :dam_damindep, :damages_migNICEFUND_xim1 => :dam_daminvprop)
rename!(damages, :damgdp_migNICEFUND => :damgdp_damprop, :damgdp_migNICEFUND_xi0 => :damgdp_damindep, :damgdp_migNICEFUND_xim1 => :damgdp_daminvprop)
rename!(damages, :damages_origFUND => :dam_origFUND, :damages_sspFUND => :dam_nice_sspFUND)

dam_world = combine(d->(worlddam_nice_sspFUND=sum(d.dam_nice_sspFUND),worlddam_damprop=sum(d.dam_damprop),worlddam_origFUND=sum(d.dam_origFUND),worlddam_damindep=sum(d.dam_damindep),worlddam_daminvprop=sum(d.dam_daminvprop)), groupby(damages,[:year,:scen]))
dam_world_p = dam_world[(map(x->mod(x,10)==0,dam_world[:,:year])),:]
dam_world_stack = stack(dam_world_p,[:worlddam_damprop,:worlddam_damindep,:worlddam_daminvprop],[:scen,:year])
rename!(dam_world_stack,:variable => :worlddamages_type, :value => :worlddamages)
dam_world_stack |> @filter(_.year >= 2015 && _.year <= 2100) |> @vlplot() + @vlplot(
    width=300, height=250, 
    mark={:point, size=50}, x = {"year:o", axis={labelFontSize=16}, title=nothing}, y = {"worlddamages:q", title=nothing, axis={labelFontSize=16}}, 
    title = "Global damages for Mig-NICE-FUND with various income elasticities of damages", 
    color = {"scen:n", scale={scheme=:category10}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}, 
    shape = {"worlddamages_type:o", scale={range=["circle","triangle-up", "square"]}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}
) + @vlplot(
    mark={:line, strokeDash=[1,2]}, x = {"year:o", axis={labelFontSize=16}, title=nothing}, y = {"worlddamages:q", aggregate=:mean,type=:quantitative,title=nothing, axis={labelFontSize=16}}, 
    color = {"scen:n", scale={scheme=:category10}},
    detail = "worlddamages_type:o"
) |> save(joinpath(@__DIR__, "../results/damages_ineq/", "damages_world_xi_v5.png"))

worldgdp_migNICEFUND_xi0 = vcat(
    collect(Iterators.flatten(m_nice_ssp1_nomig_xi0[:socioeconomic,:globalincome][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_nice_ssp2_nomig_xi0[:socioeconomic,:globalincome][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_nice_ssp3_nomig_xi0[:socioeconomic,:globalincome][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_nice_ssp4_nomig_xi0[:socioeconomic,:globalincome][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_nice_ssp5_nomig_xi0[:socioeconomic,:globalincome][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)]))
)
dam_world[:,:worldgdp_migNICEFUND_xi0] = worldgdp_migNICEFUND_xi0
worldgdp_migNICEFUND_xim1 = vcat(
    collect(Iterators.flatten(m_nice_ssp1_nomig_xim1[:socioeconomic,:globalincome][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_nice_ssp2_nomig_xim1[:socioeconomic,:globalincome][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_nice_ssp3_nomig_xim1[:socioeconomic,:globalincome][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_nice_ssp4_nomig_xim1[:socioeconomic,:globalincome][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_nice_ssp5_nomig_xim1[:socioeconomic,:globalincome][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)]))
)
dam_world[:,:worldgdp_migNICEFUND_xim1] = worldgdp_migNICEFUND_xim1

dam_world[:,:worldgdp_migNICEFUND] = worldgdp_migNICEFUND

dam_world_p = dam_world[(map(x->mod(x,10)==0,dam_world[:,:year])),:]
rename!(dam_world_p, :worldgdp_migNICEFUND => :worldgdp_damprop, :worldgdp_migNICEFUND_xi0 => :worldgdp_damindep, :worldgdp_migNICEFUND_xim1 => :worldgdp_daminvprop)

dam_world_p[:,:worlddamgdp_damprop] = dam_world_p[:,:worlddam_damprop] ./ (dam_world_p[:,:worldgdp_damprop] .* 10^9)
dam_world_p[:,:worlddamgdp_damindep] = dam_world_p[:,:worlddam_damindep] ./ (dam_world_p[:,:worldgdp_damindep] .* 10^9)
dam_world_p[:,:worlddamgdp_daminvprop] = dam_world_p[:,:worlddam_daminvprop] ./ (dam_world_p[:,:worldgdp_daminvprop] .* 10^9)

dam_world_stack = stack(dam_world_p,[:worlddamgdp_damprop,:worlddamgdp_damindep,:worlddamgdp_daminvprop],[:scen,:year])
rename!(dam_world_stack,:variable => :worlddamgdp_type, :value => :worlddamgdp)
dam_world_stack |> @filter(_.year >= 2015 && _.year <= 2100) |> @vlplot() + @vlplot(
    width=300, height=250, 
    mark={:point, size=50}, x = {"year:o", axis={labelFontSize=16}, title=nothing}, y = {"worlddamgdp:q", title=nothing, axis={labelFontSize=16}}, 
    title = "Global damages as share of GDP for Mig-NICE-FUND with various income elasticities of damages", 
    color = {"scen:n", scale={scheme=:category10}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}, 
    shape = {"worlddamgdp_type:o", scale={range=["circle","triangle-up", "square"]}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}
) + @vlplot(
    mark={:line, strokeDash=[1,2]}, x = {"year:o", axis={labelFontSize=16}, title=nothing}, y = {"worlddamgdp:q", aggregate=:mean,type=:quantitative,title=nothing, axis={labelFontSize=16}}, 
    color = {"scen:n", scale={scheme=:category10}},
    detail = "worlddamgdp_type:o"
) |> save(joinpath(@__DIR__, "../results/damages_ineq/", "damgdp_world_xi_v5.png"))


################################ Plot composition of damages per impact for each income elasticity of damages, SSP and region ###########################
dam_impact = innerjoin(damages[:,[:year, :scen, :fundregion, :dam_damprop, :dam_nice_sspFUND, :dam_origFUND, :dam_damindep, :dam_daminvprop]], dam_world_p[:,[:year, :scen]], on = [:year,:scen])
for imp in [:water,:forests,:heating,:cooling,:agcost,:drycost,:protcost,:hurrdam,:extratropicalstormsdam,:eloss_other,:species,:deadcost,:morbcost,:wetcost]
    imp_damprop = vcat(
        collect(Iterators.flatten(m_nice_ssp1_nomig[:impactaggregation,imp][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:])),
        collect(Iterators.flatten(m_nice_ssp2_nomig[:impactaggregation,imp][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:])),
        collect(Iterators.flatten(m_nice_ssp3_nomig[:impactaggregation,imp][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:])),
        collect(Iterators.flatten(m_nice_ssp4_nomig[:impactaggregation,imp][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:])),
        collect(Iterators.flatten(m_nice_ssp5_nomig[:impactaggregation,imp][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:]))
    )
    dam_impact[:,Symbol(string(imp,"_damprop"))] = imp_damprop
    imp_damindep = vcat(
        collect(Iterators.flatten(m_nice_ssp1_nomig_xi0[:impactaggregation,imp][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:])),
        collect(Iterators.flatten(m_nice_ssp2_nomig_xi0[:impactaggregation,imp][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:])),
        collect(Iterators.flatten(m_nice_ssp3_nomig_xi0[:impactaggregation,imp][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:])),
        collect(Iterators.flatten(m_nice_ssp4_nomig_xi0[:impactaggregation,imp][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:])),
        collect(Iterators.flatten(m_nice_ssp5_nomig_xi0[:impactaggregation,imp][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:]))
    )
    dam_impact[:,Symbol(string(imp,"_damindep"))] = imp_damindep
    imp_daminvprop = vcat(
        collect(Iterators.flatten(m_nice_ssp1_nomig_xim1[:impactaggregation,imp][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:])),
        collect(Iterators.flatten(m_nice_ssp2_nomig_xim1[:impactaggregation,imp][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:])),
        collect(Iterators.flatten(m_nice_ssp3_nomig_xim1[:impactaggregation,imp][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:])),
        collect(Iterators.flatten(m_nice_ssp4_nomig_xim1[:impactaggregation,imp][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:])),
        collect(Iterators.flatten(m_nice_ssp5_nomig_xim1[:impactaggregation,imp][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:]))
    )
    dam_impact[:,Symbol(string(imp,"_daminvprop"))] = imp_daminvprop
end

# We count as climate change damage only those attributed to differences in income resulting from climate change impacts
imp_damprop = vcat(
    collect(Iterators.flatten(sum(m_nice_ssp1_nomig[:migration,:deadmigcost][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp2_nomig[:migration,:deadmigcost][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp3_nomig[:migration,:deadmigcost][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp4_nomig[:migration,:deadmigcost][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp5_nomig[:migration,:deadmigcost][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1]))
)
imp_nocc_damprop = vcat(
    collect(Iterators.flatten(sum(m_nice_ssp1_nocc[:migration,:deadmigcost][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp2_nocc[:migration,:deadmigcost][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp3_nocc[:migration,:deadmigcost][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp4_nocc[:migration,:deadmigcost][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp5_nocc[:migration,:deadmigcost][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1]))
)
dam_impact[:,Symbol(string(:deadmigcost,"_damprop"))] = imp_damprop - imp_nocc_damprop
imp_damindep = vcat(
    collect(Iterators.flatten(sum(m_nice_ssp1_nomig_xi0[:migration,:deadmigcost][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp2_nomig_xi0[:migration,:deadmigcost][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp3_nomig_xi0[:migration,:deadmigcost][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp4_nomig_xi0[:migration,:deadmigcost][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp5_nomig_xi0[:migration,:deadmigcost][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1]))
)
imp_nocc_damindep = vcat(
    collect(Iterators.flatten(sum(m_nice_ssp1_nocc_xi0[:migration,:deadmigcost][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp2_nocc_xi0[:migration,:deadmigcost][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp3_nocc_xi0[:migration,:deadmigcost][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp4_nocc_xi0[:migration,:deadmigcost][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp5_nocc_xi0[:migration,:deadmigcost][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1]))
)
dam_impact[:,Symbol(string(:deadmigcost,"_damindep"))] = imp_damindep - imp_nocc_damindep
imp_daminvprop = vcat(
    collect(Iterators.flatten(sum(m_nice_ssp1_nomig_xim1[:migration,:deadmigcost][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp2_nomig_xim1[:migration,:deadmigcost][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp3_nomig_xim1[:migration,:deadmigcost][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp4_nomig_xim1[:migration,:deadmigcost][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp5_nomig_xim1[:migration,:deadmigcost][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1]))
)
imp_nocc_daminvprop = vcat(
    collect(Iterators.flatten(sum(m_nice_ssp1_nocc_xim1[:migration,:deadmigcost][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp2_nocc_xim1[:migration,:deadmigcost][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp3_nocc_xim1[:migration,:deadmigcost][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp4_nocc_xim1[:migration,:deadmigcost][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp5_nocc_xim1[:migration,:deadmigcost][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1]))
)
dam_impact[:,Symbol(string(:deadmigcost,"_daminvprop"))] = imp_daminvprop - imp_nocc_daminvprop

# Impacts coded as negative if damaging: recode as positive
for imp in [:water,:forests,:heating,:cooling,:agcost]
    for btype in [:_damprop,:_damindep,:_daminvprop]
        dam_impact[!,Symbol(string(imp,btype))] .*= -1
    end
end
for btype in [:_damprop,:_damindep,:_daminvprop]
    for imp in [:water,:forests,:heating,:cooling,:agcost,:drycost,:protcost,:hurrdam,:extratropicalstormsdam,:eloss_other,:species,:deadcost,:morbcost,:wetcost,:deadmigcost]
        dam_impact[!,Symbol(string("share_",imp,btype))] = dam_impact[!,Symbol(string(imp,btype))] ./ dam_impact[!,Symbol(string("dam",btype))] .* 1000000000
    end
end

dam_impact_stacked = stack(dam_impact, map(x -> Symbol(string(x,"_damprop")), [:water,:forests,:heating,:cooling,:agcost,:drycost,:protcost,:hurrdam,:extratropicalstormsdam,:eloss_other,:species,:deadcost,:morbcost,:wetcost,:deadmigcost]),[:year,:scen,:fundregion])
rename!(dam_impact_stacked, :variable => :impact, :value => :impact_dam)
dam_impact_stacked[!,:xi] = repeat(["_damprop"],size(dam_impact_stacked,1))
dam_impact_stacked[!,:impact] = map(x -> SubString(String(x),1:(length(String(x))-8)), dam_impact_stacked[!,:impact])

dam_impact_stacked_xi0 = stack(dam_impact, map(x -> Symbol(string(x,"_damindep")), [:water,:forests,:heating,:cooling,:agcost,:drycost,:protcost,:hurrdam,:extratropicalstormsdam,:eloss_other,:species,:deadcost,:morbcost,:wetcost,:deadmigcost]),[:year,:scen,:fundregion])
rename!(dam_impact_stacked_xi0, :variable => :impact, :value => :impact_dam)
dam_impact_stacked_xi0[!,:xi] = repeat(["_damindep"],size(dam_impact_stacked_xi0,1))
dam_impact_stacked_xi0[!,:impact] = map(x -> SubString(String(x),1:(length(String(x))-9)), dam_impact_stacked_xi0[!,:impact])

dam_impact_stacked_xim1 = stack(dam_impact, map(x -> Symbol(string(x,"_daminvprop")), [:water,:forests,:heating,:cooling,:agcost,:drycost,:protcost,:hurrdam,:extratropicalstormsdam,:eloss_other,:species,:deadcost,:morbcost,:wetcost,:deadmigcost]),[:year,:scen,:fundregion])
rename!(dam_impact_stacked_xim1, :variable => :impact, :value => :impact_dam)
dam_impact_stacked_xim1[!,:xi] = repeat(["_daminvprop"],size(dam_impact_stacked_xim1,1))
dam_impact_stacked_xim1[!,:impact] = map(x -> SubString(String(x),1:(length(String(x))-11)), dam_impact_stacked_xim1[!,:impact])

dam_impact_stacked = vcat(dam_impact_stacked, dam_impact_stacked_xi0, dam_impact_stacked_xim1)

regions_fullname = DataFrame(
    fundregion=regions,
    regionname = ["United States","Canada","Western Europe", "Japan & South Korea","Australia & New Zealand","Central & Eastern Europe","Former Soviet Union", "Middle East", "Central America", "South America","South Asia","Southeast Asia","China plus", "North Africa","Sub-Saharan Africa","Small Island States"]
)
dam_impact_stacked = innerjoin(dam_impact_stacked, regions_fullname, on=:fundregion)

for s in ssps
    dam_impact_stacked |> @filter(_.year ==2100 && _.scen == s && _.xi == "_damprop") |> @vlplot(
        mark={:bar}, width=350, height=300,
        x={"fundregion:o", axis={labelFontSize=16, labelAngle=-90}, ticks=false, domain=false, title=nothing, minExtent=80, scale={paddingInner=0.2,paddingOuter=0.2}},
        y={"impact_dam:q", aggregate = :sum, stack = true, title = "Billion USD2005", axis={titleFontSize=18, labelFontSize=16}},
        color={"impact:n",scale={scheme="category20c"},legend={title=string("Impact type"), titleFontSize=20, titleLimit=220, symbolSize=60, labelFontSize=18, labelLimit=220}},
        resolve = {scale={y=:independent}}, title={text=string("Damages in 2100, damages proportional to income, ", s), fontSize=20}
    ) |> save(joinpath(@__DIR__, "../results/damages_ineq/", string("impdam_",s,"_v5.png")))
end


########################### Calculate the proportion of migrants moving from a less to a more exposed region (in terms of damages/GDP) ###############
exposed = innerjoin(move[:,1:7], rename(rename(
    move[:,1:7], 
    :origin=>:dest,
    :destination=>:origin,
    :move_xi1=>:move_otherdir_xi1,
    :move_xi0=>:move_otherdir_xi0,
    :move_xim1=>:move_otherdir_xim1,
),:dest=>:destination), on = [:year,:scen,:origin,:destination])
for btype in [:_xi1,:_xi0,:_xim1]
    exposed[!,Symbol(string(:move_net,btype))] = exposed[!,Symbol(string(:move,btype))] .- exposed[!,Symbol(string(:move_otherdir,btype))]
end

exposed = innerjoin(exposed, rename(
    damages, 
    :fundregion => :origin, 
    :damgdp_damprop => :damgdp_or_damprop, 
    :damgdp_damindep => :damgdp_or_damindep, 
    :damgdp_daminvprop => :damgdp_or_daminvprop, 
)[:,[:year,:scen,:origin,:damgdp_or_damprop,:damgdp_or_damindep,:damgdp_or_daminvprop]], on = [:year,:scen,:origin])
exposed = innerjoin(exposed, rename(
    damages, 
    :fundregion => :destination, 
    :damgdp_damprop => :damgdp_dest_damprop, 
    :damgdp_damindep => :damgdp_dest_damindep, 
    :damgdp_daminvprop => :damgdp_dest_daminvprop, 
)[:,[:year,:scen,:destination,:damgdp_dest_damprop,:damgdp_dest_damindep,:damgdp_dest_daminvprop]], on = [:year,:scen,:destination])

rename!(exposed, :move_net_xi1 => :move_net_damprop, :move_net_xi0 => :move_net_damindep, :move_net_xim1 => :move_net_daminvprop)
for btype in [:_damprop,:_damindep,:_daminvprop]
    exposed[!,Symbol(string(:exposure,btype))] = [exposed[i,Symbol(string(:move_net,btype))] >0 ? (exposed[i,Symbol(string(:damgdp_dest,btype))] > exposed[i,Symbol(string(:damgdp_or,btype))] ? "increase" : "decrease") : (exposed[i,Symbol(string(:move_net,btype))] <0 ? ("") : "nomove") for i in 1:size(exposed,1)]
end

index_r = DataFrame(index=1:16,region=regions)
exposed = innerjoin(exposed,rename(index_r,:region=>:origin,:index=>:index_or),on=:origin)
exposed = innerjoin(exposed,rename(index_r,:region=>:destination,:index=>:index_dest),on=:destination)

exposure_damprop = combine(d -> (popexpo=sum(d.move_net_damprop)), groupby(exposed, [:year,:scen,:exposure_damprop]))
exposure_damindep = combine(d -> (popexpo=sum(d.move_net_damindep)), groupby(exposed, [:year,:scen,:exposure_damindep]))
exposure_daminvprop = combine(d -> (popexpo=sum(d.move_net_daminvprop)), groupby(exposed, [:year,:scen,:exposure_daminvprop]))
rename!(exposure_damprop,:x1=>:popmig_damprop,:exposure_damprop=>:exposure)
rename!(exposure_damindep,:x1=>:popmig_damindep,:exposure_damindep=>:exposure)
rename!(exposure_daminvprop,:x1=>:popmig_daminvprop,:exposure_daminvprop=>:exposure)
exposure = outerjoin(exposure_damprop, exposure_damindep, on = [:year,:scen,:exposure])
exposure = outerjoin(exposure, exposure_daminvprop, on = [:year,:scen,:exposure])
for name in [:popmig_damprop,:popmig_damindep,:popmig_daminvprop]
    for i in 1:size(exposure,1)
        if ismissing(exposure[i,name])
            exposure[i,name] = 0.0
        end
    end
end
sort!(exposure,[:scen,:year,:exposure])
exposure[.&(exposure[!,:year].==2100),:]

for btype in [:_damprop,:_damindep,:_daminvprop]
    exposed[!,Symbol(string(:damgdp_diff,btype))] = exposed[!,Symbol(string(:damgdp_dest,btype))] .- exposed[!,Symbol(string(:damgdp_or,btype))]
end
rename!(exposed, :move_xi1 => :move_damprop, :move_xi0 => :move_damindep, :move_xim1 => :move_daminvprop)
for btype in [:_damprop,:_damindep,:_daminvprop]
    exposed |> @filter(_.year == 2100) |> @vlplot(
        :bar, width=300, 
        x={Symbol(string(:damgdp_diff,btype)), type=:ordinal, bin={step = 0.02}, axis={labelFontSize=16}},
        y={Symbol(string(:move,btype)), aggregate=:sum, axis={labelFontSize=16}, title=nothing},
        row = {"scen:n", axis=nothing},
        color={"origin:o",scale={scheme="tableau20"}}
    ) |> save(joinpath(@__DIR__, "../results/damages_ineq/", string("exposure",btype,"_2100_v5.png")))
end

regions_fullname = DataFrame(
    fundregion=regions,
    regionname = ["United States","Canada","Western Europe","Japan & South Korea","Australia & New Zealand","Central & Eastern Europe","Former Soviet Union","Middle East","Central America","South America","South Asia","Southeast Asia","China plus","North Africa","Sub-Saharan Africa","Small Island States"]
)
exposed_all = DataFrame(
    scen = repeat(exposed[(exposed[!,:year].==2100),:scen],3),
    origin = repeat(exposed[(exposed[!,:year].==2100),:origin],3),
    destination = repeat(exposed[(exposed[!,:year].==2100),:destination],3),
    btype = vcat(repeat(["damprop"],size(exposed[(exposed[!,:year].==2100),:],1)), repeat(["damindep"],size(exposed[(exposed[!,:year].==2100),:],1)), repeat(["daminvprop"],size(exposed[(exposed[!,:year].==2100),:],1))),
    move = vcat(exposed[(exposed[!,:year].==2100),:move_damprop],exposed[(exposed[!,:year].==2100),:move_damindep],exposed[(exposed[!,:year].==2100),:move_daminvprop]),
    damgdp_diff = vcat(exposed[(exposed[!,:year].==2100),:damgdp_diff_damprop],exposed[(exposed[!,:year].==2100),:damgdp_diff_damindep],exposed[(exposed[!,:year].==2100),:damgdp_diff_daminvprop])
)
for i in 1:size(exposed_all,1)
    if exposed_all[i,:move] == 0
        exposed_all[i,:damgdp_diff] = 0
    end
end
exposed_all = innerjoin(exposed_all, rename(regions_fullname, :fundregion => :origin, :regionname => :originname), on= :origin)
exposed_all = innerjoin(exposed_all, rename(regions_fullname, :fundregion => :destination, :regionname => :destinationname), on= :destination)
for s in ssps
    exposed_all |> @filter(_.scen == s) |> @vlplot(
        mark={:point, size=60}, width=300, columns=4, wrap={"originname:o", title=nothing, header={labelFontSize=24}}, 
        x={"damgdp_diff:q", axis={labelFontSize=16}, title="Change in Exposure, % point", titleFontSize=20},
        y={"move:q", title = "Number of Emigrants", axis={labelFontSize=16}, titleFontSize=20},
        color={"btype:o",scale={scheme=:darkmulti},legend={title=string("Exposure Change, ",s), titleFontSize=18, titleLimit=220, symbolSize=60, labelFontSize=20, labelLimit=220, offset=2}},
        shape="btype:o",
        resolve = {scale={y=:independent}}
    ) |> save(joinpath(@__DIR__, "../results/damages_ineq/", string("exposure_",s,"_v5.png")))
end
exposed_all[!,:scen_btype] = [string(exposed_all[i,:scen],"_",exposed_all[i,:btype]) for i in 1:size(exposed_all,1)]
exposed_all |> @vlplot(
    mark={:point, size=60}, width=300, height=250, columns=4, wrap={"originname:o", title=nothing, header={labelFontSize=24}}, 
    x={"damgdp_diff:q", axis={labelFontSize=16}, title="Change in Exposure, % point", titleFontSize=20},
    y={"move:q", title = "Number of Emigrants", axis={labelFontSize=16}, titleFontSize=20},
    color={"scen_btype:o",scale={scheme=:category20c},legend={title=string("Exposure Change"), titleFontSize=18, titleLimit=220, symbolSize=60, labelFontSize=20, labelLimit=220, offset=2}},
    shape="scen_btype:o",
    resolve = {scale={y=:independent}}
) |> save(joinpath(@__DIR__, "../results/damages_ineq/", string("exposure_v5.png")))

exposed_all |> @vlplot(
    mark={:point, size=80}, width=220, columns=4, wrap={"originname:o", title=nothing, header={labelFontSize=24}}, 
    y={"damgdp_diff:q", axis={labelFontSize=16, titleFontSize=16}, title="Change in Exposure, % point"},
    x={"scen:o", title = nothing, axis={labelFontSize=16}},
    size= {"move:q", legend=nothing},
    color={"btype:o",scale={scheme=:darkmulti},legend={title=string("Migrant outflows"), titleFontSize=24, titleLimit=240, symbolSize=100, labelFontSize=24, labelLimit=260, offset=10}},
    shape="btype:o",
    resolve = {scale={size=:independent}}
) |> save(joinpath(@__DIR__, "../results/damages_ineq/", string("exposure_allscen_v5.png")))

exp_sum = combine(d->sum(d.move), groupby(exposed_all, [:scen,:origin,:btype]))
exposed_all = innerjoin(exposed_all, rename(exp_sum, :x1 => :leave), on=[:scen,:origin,:btype])
exposed_all[!,:move_share] = exposed_all[!,:move] ./ exposed_all[!,:leave]
for i in 1:size(exposed_all,1) ; if exposed_all[i,:move] == 0.0 && exposed_all[i,:leave] == 0 ; exposed_all[i,:move_share] = 0 end end
exposed_average = combine(d->sum(d.damgdp_diff .* d.move_share), groupby(exposed_all, [:scen,:origin,:originname,:btype,:scen_btype]))
rename!(exposed_average, :x1 => :damgdp_diff_av)
exposed_average |> @vlplot(
    mark={:point, size=80}, width=220, columns=4, wrap={"originname:o", title=nothing, header={labelFontSize=24}}, 
    y={"damgdp_diff_av:q", scale={domain=[-0.08,0.08]}, axis={labelFontSize=16, titleFontSize=16}, title="Change in Exposure, % point"},
    x={"scen:o", title = nothing, axis={labelFontSize=16}},
    color={"btype:o",scale={scheme=:darkmulti},legend={title=string("Emigrants"), titleFontSize=24, titleLimit=220, symbolSize=100, labelFontSize=24, labelLimit=260, offset=10}},
    shape="btype:o",
    resolve = {scale={size=:independent}}
) |> save(joinpath(@__DIR__, "../results/damages_ineq/", string("exposure_averaged_v5.png")))

exposed_average |> @filter(_.scen == "SSP2" && (_.origin == "WEU" || _.origin == "MAF" || _.origin == "MDE" || _.origin == "SEA" || _.origin == "LAM")) |> @vlplot(
    mark={:point, size=80}, width=400, 
    y={"damgdp_diff_av:q", scale={domain=[-0.05,0.05]}, axis={labelFontSize=16, titleFontSize=16}, title="Change in Exposure, % pt"},
    x={"originname:o", title = nothing, axis={labelFontSize=16,labelAngle=-60}},
    color={"btype:o",scale={scheme=:darkmulti},legend={title=string("Emigrants"), titleFontSize=16, titleLimit=220, symbolSize=100, labelFontSize=16, labelLimit=260, offset=10}},
    shape="btype:o"
) |> save(joinpath(@__DIR__, "../results/damages_ineq/", string("exposure_averaged_select_v5.png")))


###################################################### Plot geographical maps ########################################################################
world110m = dataset("world-110m")

isonum_fundregion = CSV.read(joinpath(@__DIR__,"../input_data/isonum_fundregion.csv"), DataFrame)

damages_maps = leftjoin(damages, isonum_fundregion, on = :fundregion)
damages_maps[!,:damdiff_damindep] = (damages_maps[!,:dam_damindep] ./ map(x->abs(x), damages_maps[!,:dam_damprop]) .- 1) .* 100
damages_maps[!,:damdiff_daminvprop] = (damages_maps[!,:dam_daminvprop] ./ map(x->abs(x), damages_maps[!,:dam_damprop]) .- 1) .* 100

for s in ssps
    @vlplot(width=800, height=600) + @vlplot(mark={:geoshape, stroke = :lightgray}, 
        data={values=world110m, format={type=:topojson, feature=:countries}}, 
        transform = [{lookup=:id, from={data=filter(row -> row[:scen] == s && row[:year] == 2100, damages_maps), key=:isonum, fields=[string(:dam_damprop)]}}],
        projection={type=:naturalEarth1}, title = {text=string("Damages, damages proportional to income, 2100, ", s),fontSize=24}, 
        color = {:dam_damprop, type=:quantitative, scale={scheme=:pinkyellowgreen,domain=[-10^12,10^12]}, legend={title=string("USD2005"), titleFontSize=20, titleLimit=220, symbolSize=60, labelFontSize=24, labelLimit=220, offset=2}}
    ) |> save(joinpath(@__DIR__, "../results/world_maps_ineq/", string("dam_damprop_", s, "_v5.png")))
end
for s in ssps
    @vlplot(width=800, height=600) + @vlplot(mark={:geoshape, stroke = :lightgray}, 
        data={values=world110m, format={type=:topojson, feature=:countries}}, 
        transform = [{lookup=:id, from={data=filter(row -> row[:scen] == s && row[:year] == 2100, damages_maps), key=:isonum, fields=[string(:damdiff,:_damindep)]}}],
        projection={type=:naturalEarth1}, title = {text=string("Damages independent of income, 2100, ", s),fontSize=24}, 
        color = {Symbol(string(:damdiff,:_damindep)), type=:quantitative, scale={domain=[-200,200], scheme=:blueorange}, legend={title="% vs proportional", titleFontSize=20, symbolSize=60, labelFontSize=24}}
    ) |> save(joinpath(@__DIR__, "../results/world_maps_ineq/", string("damdiff",:_damindep,"_", s, "_v5.png")))
end
for s in ssps
    @vlplot(width=800, height=600) + @vlplot(mark={:geoshape, stroke = :lightgray}, 
        data={values=world110m, format={type=:topojson, feature=:countries}}, 
        transform = [{lookup=:id, from={data=filter(row -> row[:scen] == s && row[:year] == 2100, damages_maps), key=:isonum, fields=[string(:damdiff,:_daminvprop)]}}],
        projection={type=:naturalEarth1}, title = {text=string("Damages inversely proportional to income, 2100, ", s),fontSize=20}, 
        color = {Symbol(string(:damdiff,:_daminvprop)), type=:quantitative, scale={domain=[-200,200], scheme=:blueorange}, legend={title="% vs proportional", titleFontSize=20, symbolSize=60, labelFontSize=24}}
    ) |> save(joinpath(@__DIR__, "../results/world_maps_ineq/", string("damdiff",:_daminvprop,"_", s, "_v5.png")))
end

damgdp_maps = leftjoin(damages, isonum_fundregion, on = :fundregion)
for btype in [:_damprop,:_damindep,:_daminvprop]
    damgdp_maps[!,Symbol(:damgdp,btype)] .*= 100
end
damgdp_maps[!,:damgdpdiff_damindep] = (damgdp_maps[!,:damgdp_damindep] ./ map(x->abs(x), damgdp_maps[!,:damgdp_damprop]) .- 1) .* 100
damgdp_maps[!,:damgdpdiff_daminvprop] = (damgdp_maps[!,:damgdp_daminvprop] ./ map(x->abs(x), damgdp_maps[!,:damgdp_damprop]) .- 1) .* 100

for s in ssps
    @vlplot(width=800, height=600) + @vlplot(mark={:geoshape, stroke = :lightgray}, 
        data={values=world110m, format={type=:topojson, feature=:countries}}, 
        transform = [{lookup=:id, from={data=filter(row -> row[:scen] == s && row[:year] == 2100, damgdp_maps), key=:isonum, fields=[string(:damgdp_damprop)]}}],
        projection={type=:naturalEarth1}, title = {text=string("Exposure, damages proportional to income, 2100, ", s),fontSize=24}, 
        color = {:damgdp_damprop, type=:quantitative, scale={scheme=:pinkyellowgreen,domain=[-5,5]}, legend={title=string("% GDP"), titleFontSize=20, titleLimit=220, symbolSize=60, labelFontSize=24, labelLimit=220, offset=2}}
    ) |> save(joinpath(@__DIR__, "../results/world_maps_ineq/", string("damgdp_damprop_", s, "_v5.png")))
end
for s in ssps
    @vlplot(width=800, height=600) + @vlplot(mark={:geoshape, stroke = :lightgray}, 
        data={values=world110m, format={type=:topojson, feature=:countries}}, 
        transform = [{lookup=:id, from={data=filter(row -> row[:scen] == s && row[:year] == 2100, damgdp_maps), key=:isonum, fields=[string(:damgdp_damindep)]}}],
        projection={type=:naturalEarth1}, title = {text=string("Exposure, Damages independent of income, 2100, ", s),fontSize=24}, 
        color = {:damgdp_damindep, type=:quantitative, scale={scheme=:pinkyellowgreen,domain=[-5,5]}, legend={title=string("% GDP"), titleFontSize=20, titleLimit=220, symbolSize=60, labelFontSize=24, labelLimit=220, offset=2}}
    ) |> save(joinpath(@__DIR__, "../results/world_maps_ineq/", string("damgdp_damindep_", s, "_v5.png")))
end
for s in ssps
    @vlplot(width=800, height=600) + @vlplot(mark={:geoshape, stroke = :lightgray}, 
        data={values=world110m, format={type=:topojson, feature=:countries}}, 
        transform = [{lookup=:id, from={data=filter(row -> row[:scen] == s && row[:year] == 2100, damgdp_maps), key=:isonum, fields=[string(:damgdp_daminvprop)]}}],
        projection={type=:naturalEarth1}, title = {text=string("Exposure, Damages inversely proportional to income, 2100, ", s),fontSize=24}, 
        color = {:damgdp_daminvprop, type=:quantitative, scale={scheme=:pinkyellowgreen,domain=[-5,5]}, legend={title=string("% GDP"), titleFontSize=20, titleLimit=220, symbolSize=60, labelFontSize=24, labelLimit=220, offset=2}}
    ) |> save(joinpath(@__DIR__, "../results/world_maps_ineq/", string("damgdp_daminvprop_", s, "_v5.png")))
end
for s in ssps
    @vlplot(width=800, height=600) + @vlplot(mark={:geoshape, stroke = :lightgray}, 
        data={values=world110m, format={type=:topojson, feature=:countries}}, 
        transform = [{lookup=:id, from={data=filter(row -> row[:scen] == s && row[:year] == 2100, damgdp_maps), key=:isonum, fields=[string(:damgdpdiff,:_damindep)]}}],
        projection={type=:naturalEarth1}, title = {text=string("Damages independent of income, 2100, ", s),fontSize=24}, 
        color = {Symbol(string(:damgdpdiff,:_damindep)), type=:quantitative, scale={domain=[-200,200], scheme=:blueorange}, legend={title="% vs proportional", titleFontSize=20, symbolSize=60, labelFontSize=24}}
    ) |> save(joinpath(@__DIR__, "../results/world_maps_ineq/", string("damgdpdiff",:_damindep,"_", s, "_v5.png")))
end
for s in ssps
    @vlplot(width=800, height=600) + @vlplot(mark={:geoshape, stroke = :lightgray}, 
        data={values=world110m, format={type=:topojson, feature=:countries}}, 
        transform = [{lookup=:id, from={data=filter(row -> row[:scen] == s && row[:year] == 2100, damgdp_maps), key=:isonum, fields=[string(:damgdpdiff,:_daminvprop)]}}],
        projection={type=:naturalEarth1}, title = {text=string("Damages inversely proportional to income, 2100, ", s),fontSize=24}, 
        color = {Symbol(string(:damgdpdiff,:_daminvprop)), type=:quantitative, scale={domain=[-200,200], scheme=:blueorange}, legend={title="% vs proportional", titleFontSize=20, symbolSize=60, labelFontSize=24}}
    ) |> save(joinpath(@__DIR__, "../results/world_maps_ineq/", string("damgdpdiff",:_daminvprop,"_", s, "_v5.png")))
end


############################################################## Register regional damages for period 1990-2015 ########################################
# We focus on SSP2 and damages proportional to income (virtually no difference with other scenarios)
damcalib = damages[.&(damages[:,:year].>=1990,damages[:,:year].<=2015,map(x->mod(x,5)==0,damages[:,:year]),damages[:,:scen].=="SSP2"),[:year,:fundregion,:damgdp_damprop]]
#CSV.write(joinpath(@__DIR__,"../input_data/damcalib.csv"),damcalib;writeheader=false)


############################################ Compute damages shock on income for lower quintiles #########################################
income_shock = DataFrame(
    year = repeat(years, outer = length(ssps)*length(regions)*5),
    scen = repeat(ssps,inner = length(regions)*length(years)*5),
    fundregion = repeat(regions, outer = length(ssps)*5, inner=length(years)),
    quintile = repeat(1:5, outer = length(ssps), inner=length(years)*length(regions))
)

income_distr_xi1 = vcat(
    collect(Iterators.flatten(m_nice_ssp1_nomig[:socioeconomic,:income_distribution][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp2_nomig[:socioeconomic,:income_distribution][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp3_nomig[:socioeconomic,:income_distribution][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp4_nomig[:socioeconomic,:income_distribution][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp5_nomig[:socioeconomic,:income_distribution][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))
)
income_shock[:,:income_distr_damprop] = income_distr_xi1
income_distr_xi0 = vcat(
    collect(Iterators.flatten(m_nice_ssp1_nomig_xi0[:socioeconomic,:income_distribution][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp2_nomig_xi0[:socioeconomic,:income_distribution][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp3_nomig_xi0[:socioeconomic,:income_distribution][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp4_nomig_xi0[:socioeconomic,:income_distribution][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp5_nomig_xi0[:socioeconomic,:income_distribution][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))
)
income_shock[:,:income_distr_damindep] = income_distr_xi0
income_distr_xim1 = vcat(
    collect(Iterators.flatten(m_nice_ssp1_nomig_xim1[:socioeconomic,:income_distribution][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp2_nomig_xim1[:socioeconomic,:income_distribution][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp3_nomig_xim1[:socioeconomic,:income_distribution][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp4_nomig_xim1[:socioeconomic,:income_distribution][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp5_nomig_xim1[:socioeconomic,:income_distribution][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))
)
income_shock[:,:income_distr_daminvprop] = income_distr_xim1
damage_distr_xi1 = vcat(
    collect(Iterators.flatten(m_nice_ssp1_nomig[:socioeconomic,:damage_distribution][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp2_nomig[:socioeconomic,:damage_distribution][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp3_nomig[:socioeconomic,:damage_distribution][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp4_nomig[:socioeconomic,:damage_distribution][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp5_nomig[:socioeconomic,:damage_distribution][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))
)
income_shock[:,:damage_distr_damprop] = damage_distr_xi1
damage_distr_xi0 = vcat(
    collect(Iterators.flatten(m_nice_ssp1_nomig_xi0[:socioeconomic,:damage_distribution][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp2_nomig_xi0[:socioeconomic,:damage_distribution][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp3_nomig_xi0[:socioeconomic,:damage_distribution][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp4_nomig_xi0[:socioeconomic,:damage_distribution][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp5_nomig_xi0[:socioeconomic,:damage_distribution][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))
)
income_shock[:,:damage_distr_damindep] = damage_distr_xi0
damage_distr_xim1 = vcat(
    collect(Iterators.flatten(m_nice_ssp1_nomig_xim1[:socioeconomic,:damage_distribution][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp2_nomig_xim1[:socioeconomic,:damage_distribution][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp3_nomig_xim1[:socioeconomic,:damage_distribution][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp4_nomig_xim1[:socioeconomic,:damage_distribution][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp5_nomig_xim1[:socioeconomic,:damage_distribution][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))
)
income_shock[:,:damage_distr_daminvprop] = damage_distr_xim1

income_shock = innerjoin(income_shock, damages[:,[:year,:scen,:fundregion,:damgdp_damprop,:damgdp_damindep,:damgdp_daminvprop]], on=[:year,:scen,:fundregion])
income_shock[!,:income_shock_damprop] = income_shock[:,:damage_distr_damprop] .* income_shock[:,:damgdp_damprop] ./ income_shock[:,:income_distr_damprop]
income_shock[!,:income_shock_damindep] = income_shock[:,:damage_distr_damindep] .* income_shock[:,:damgdp_damindep] ./ income_shock[:,:income_distr_damindep]
income_shock[!,:income_shock_daminvprop] = income_shock[:,:damage_distr_daminvprop] .* income_shock[:,:damgdp_daminvprop] ./ income_shock[:,:income_distr_daminvprop]

income_shock_p = income_shock[(map(x->mod(x,10)==0,income_shock[:,:year])),:]

income_shock_s = stack(
    income_shock_p, 
    [:income_shock_damprop,:income_shock_damindep,:income_shock_daminvprop], 
    [:scen, :quintile ,:fundregion, :year]
)
rename!(income_shock_s, :variable => :income_shock_type, :value => :income_shock)
income_shock_s[!,:damage_elasticity] = map(x->SubString(String(x),14), income_shock_s[:,:income_shock_type])
income_shock_s[!,:type_name] = [income_shock_s[i,:damage_elasticity]=="damprop" ? "proportional" : (income_shock_s[i,:damage_elasticity]=="damindep" ? "independent" : "inversely prop.") for i in 1:size(income_shock_s,1)]
income_shock_s = innerjoin(income_shock_s, regions_fullname, on =:fundregion)
for s in ssps
    income_shock_s |> @filter(_.year >= 2015 && _.year <= 2100 && _.scen == s) |> @vlplot(
        mark={:point,size=60}, width=300, height=250, columns=4, wrap={"regionname:o", title=nothing, header={labelFontSize=24}}, 
        x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
        y={"income_shock:q", title = "Damages as share of income", axis={labelFontSize=20,titleFontSize=20}},
        color={"quintile:o",scale={scheme=:darkmulti},legend={title = "Quintile", titleFontSize=20, symbolSize=80, labelFontSize=20}},
        shape={"type_name:o",scale={range=["circle","triangle-up","square"],domain=["proportional","independent","inversely prop."]},legend={title = "Damages elasticity", titleFontSize=20, titleLimit=260, symbolSize=80, labelFontSize=20}},
        resolve = {scale={y=:independent}}
    ) |> save(joinpath(@__DIR__, "../results/damages_ineq/", string("income_shock_",s,"_v5.png")))
end

income_shock_maps = leftjoin(income_shock_s, isonum_fundregion, on = :fundregion)
for s in ssps
    for d in ["damprop","damindep","daminvprop"]
        @vlplot(width=800, height=600) + @vlplot(mark={:geoshape, stroke = :lightgray}, 
            data={values=world110m, format={type=:topojson, feature=:countries}}, 
            transform = [{lookup=:id, from={data=filter(row -> row[:scen] == s && row[:year] == 2100 && row[:damage_elasticity] == d && row[:quintile] == 1, income_shock_maps), key=:isonum, fields=[string(:income_shock)]}}],
            projection={type=:naturalEarth1}, title = {text=string("SSP2-RCP4.5"),fontSize=24}, 
            color = {:income_shock, type=:quantitative, scale={domain=[-1.2,1.2], scheme=:blueorange}, legend={title="Share of income", titleFontSize=20, titleLimit=260, symbolSize=60, labelFontSize=20, labelLimit=220}}
        ) |> save(joinpath(@__DIR__, "../results/world_maps_ineq/", string("income_shock_q1_", s, "_", d, "_v5.pdf")))
    end
end

for s in ssps
    for d in ["damprop","damindep","daminvprop"]
        @vlplot(width=800, height=600) + @vlplot(mark={:geoshape, stroke = :lightgray}, 
            data={values=world110m, format={type=:topojson, feature=:countries}}, 
            transform = [{lookup=:id, from={data=filter(row -> row[:scen] == s && row[:year] == 2100 && row[:damage_elasticity] == d && row[:quintile] == 5, income_shock_maps), key=:isonum, fields=[string(:income_shock)]}}],
            projection={type=:naturalEarth1}, title = {text=string("SSP2-RCP4.5"),fontSize=24}, 
            color = {:income_shock, type=:quantitative, scale={domain=[-0.5,0.5], scheme=:blueorange}, legend={title="Share of income", titleFontSize=20, titleLimit=260, symbolSize=60, labelFontSize=20, labelLimit=220}}
        ) |> save(joinpath(@__DIR__, "../results/world_maps_ineq/", string("income_shock_q5_", s, "_", d, "_v5.png")))
    end
end