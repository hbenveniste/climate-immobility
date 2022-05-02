using DelimitedFiles, CSV, VegaLite, VegaDatasets, FileIO, FilePaths
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


################################ Compare income in absolute terms and in per capita in Mig-NICE-FUND and in NICE-FUND with SSP #######################3
ssps = ["SSP1","SSP2","SSP3","SSP4","SSP5"]
regions = ["USA", "CAN", "WEU", "JPK", "ANZ", "EEU", "FSU", "MDE", "CAM", "LAM", "SAS", "SEA", "CHI", "MAF", "SSA", "SIS"]
years = 1951:2100

income = DataFrame(
    year = repeat(years, outer = length(ssps)*length(regions)),
    scen = repeat(ssps,inner = length(regions)*length(years)),
    fundregion = repeat(regions, outer = length(ssps), inner=length(years)),
)

gdp_migNICEFUND = vcat(
    collect(Iterators.flatten(m_nice_ssp1_nomig[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp2_nomig[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp3_nomig[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp4_nomig[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp5_nomig[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
income[:,:gdp_migNICEFUND] = gdp_migNICEFUND
gdp_sspNICEFUND = vcat(
    collect(Iterators.flatten(m_fundnicessp1[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_fundnicessp2[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_fundnicessp3[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_fundnicessp4[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_fundnicessp5[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
income[:,:gdp_sspNICEFUND] = gdp_sspNICEFUND
gdp_origFUND = vcat(collect(Iterators.flatten(m_fund[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),missings(length(years)*length(regions)*4))
income[:,:gdp_origFUND] = gdp_origFUND

income_world = combine(d->(worldgdp_sspNICEFUND=sum(d.gdp_sspNICEFUND),worldgdp_migNICEFUND=sum(d.gdp_migNICEFUND),worldgdp_origFUND=sum(d.gdp_origFUND)), groupby(income,[:year,:scen]))
income_world_p = income_world[(map(x->mod(x,10)==0,income_world[:,:year])),:]
income_world_stack = stack(income_world_p,[:worldgdp_sspNICEFUND,:worldgdp_migNICEFUND,:worldgdp_origFUND],[:scen,:year])
rename!(income_world_stack,:variable => :worldgdp_type, :value => :worldgdp)
data_ssp = income_world_stack |> @filter(_.year >= 2015 && _.year <= 2100 && _.worldgdp_type != :worldgdp_origFUND) 
data_fund = income_world_stack[:,Not(:scen)] |> @filter(_.year >= 2015 && _.year <= 2100 && _.worldgdp_type == :worldgdp_origFUND) 
@vlplot() + @vlplot(
    width=300, height=250, data = data_ssp,
    mark={:point, size=30}, x = {"year:o", axis={labelFontSize=16}, title=nothing}, y = {"worldgdp:q", title=nothing, axis={labelFontSize=16}}, 
    title = "Global income for FUND with original SSP and Mig-NICE-FUND", 
    color = {"scen:n", scale={scheme=:category10}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}, 
    shape = {"worldgdp_type:o", scale={range=["circle","triangle-up"]}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}
) + @vlplot(
    mark={:line, strokeDash=[1,2]}, data = data_ssp, x = {"year:o", axis={labelFontSize=16}, title=nothing}, y = {"worldgdp:q", aggregate=:mean,type=:quantitative,title=nothing, axis={labelFontSize=16}}, 
    color = {"scen:n", scale={scheme=:category10}},
    detail = "worldgdp_type:o"
) + @vlplot(
    data = data_fund, mark={:line, strokeDash=[1,2], color = :black}, 
    x = {"year:o", axis={labelFontSize=16}, title=nothing}, y = {"worldgdp:q", aggregate=:mean,type=:quantitative, title=nothing, axis={labelFontSize=16}}, 
    detail = "worldgdp_type:o"
) |> save(joinpath(@__DIR__, "../results/income_ineq/", "gdp_world_v5.png"))


ypc_migNICEFUND = vcat(
    collect(Iterators.flatten(m_nice_ssp1_nomig[:socioeconomic,:ypc][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp2_nomig[:socioeconomic,:ypc][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp3_nomig[:socioeconomic,:ypc][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp4_nomig[:socioeconomic,:ypc][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp5_nomig[:socioeconomic,:ypc][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
income[:,:ypc_migNICEFUND] = ypc_migNICEFUND
ypc_sspNICEFUND = vcat(
    collect(Iterators.flatten(m_fundnicessp1[:socioeconomic,:ypc][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_fundnicessp2[:socioeconomic,:ypc][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_fundnicessp3[:socioeconomic,:ypc][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_fundnicessp4[:socioeconomic,:ypc][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_fundnicessp5[:socioeconomic,:ypc][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
income[:,:ypc_sspNICEFUND] = ypc_sspNICEFUND
ypc_origFUND = vcat(collect(Iterators.flatten(m_fund[:socioeconomic,:ypc][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),missings(length(years)*length(regions)*4))
income[:,:ypc_origFUND] = ypc_origFUND

worldypc_migNICEFUND = vcat(
    collect(Iterators.flatten(m_nice_ssp1_nomig[:socioeconomic,:globalypc][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_nice_ssp2_nomig[:socioeconomic,:globalypc][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_nice_ssp3_nomig[:socioeconomic,:globalypc][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_nice_ssp4_nomig[:socioeconomic,:globalypc][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_nice_ssp5_nomig[:socioeconomic,:globalypc][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)]))
)
income_world[:,:worldypc_migNICEFUND] = worldypc_migNICEFUND
worldypc_sspNICEFUND = vcat(
    collect(Iterators.flatten(m_fundnicessp1[:socioeconomic,:globalypc][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_fundnicessp2[:socioeconomic,:globalypc][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_fundnicessp3[:socioeconomic,:globalypc][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_fundnicessp4[:socioeconomic,:globalypc][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_fundnicessp5[:socioeconomic,:globalypc][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)]))
)
income_world[:,:worldypc_sspNICEFUND] = worldypc_sspNICEFUND
worldypc_origFUND = vcat(collect(Iterators.flatten(m_fund[:socioeconomic,:globalypc][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),missings(length(years)*4))
income_world[:,:worldypc_origFUND] = worldypc_origFUND
income_world_p = income_world[(map(x->mod(x,10)==0,income_world[:,:year])),:]
income_world_stack = stack(income_world_p,[:worldypc_sspNICEFUND,:worldypc_migNICEFUND,:worldypc_origFUND],[:scen,:year])
rename!(income_world_stack,:variable => :worldypc_type, :value => :worldypc)
data_ssp = income_world_stack |> @filter(_.year >= 2015 && _.year <= 2100 && _.worldypc_type != :worldypc_origFUND) 
data_fund = income_world_stack[:,Not(:scen)] |> @filter(_.year >= 2015 && _.year <= 2100 && _.worldypc_type == :worldypc_origFUND) 
@vlplot()+@vlplot(
    width=300, height=250,data=data_ssp,
    mark={:point, size=60}, x = {"year:o", axis={labelFontSize=16}, title=nothing}, y = {"worldypc:q", title=nothing, axis={labelFontSize=16}}, 
    title = "Global income per capita for FUND with original SSP and Mig-NICE-FUND", 
    color = {"scen:n", scale={scheme=:category10}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}, 
    shape = {"worldypc_type:o", scale={range=["circle","triangle-up"]}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}
) + @vlplot(
    mark={:line, strokeDash=[1,2]}, data=data_ssp,x = {"year:o", axis={labelFontSize=16}, title=nothing}, y = {"worldypc:q", aggregate=:mean,type=:quantitative,title=nothing, axis={labelFontSize=16}}, 
    color = {"scen:n", scale={scheme=:category10}},
    detail = "worldypc_type:o"
) + @vlplot(
    data = data_fund, mark={:line, strokeDash=[1,2], color = :black}, 
    x = {"year:o", axis={labelFontSize=16}, title=nothing}, y = {"worldypc:q", aggregate=:mean,type=:quantitative, title=nothing, axis={labelFontSize=16}}, 
    detail = "worldypc_type:o"
) |> save(joinpath(@__DIR__, "../results/income_ineq/", "ypc_world_v5.png"))


######################################### Compare income in Mig-NICE-FUND for different income elasticities of damages (xi) #######################
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


gdp_migNICEFUND_xi0 = vcat(
    collect(Iterators.flatten(m_nice_ssp1_nomig_xi0[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp2_nomig_xi0[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp3_nomig_xi0[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp4_nomig_xi0[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp5_nomig_xi0[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
income[:,:gdp_migNICEFUND_xi0] = gdp_migNICEFUND_xi0
gdp_migNICEFUND_xim1 = vcat(
    collect(Iterators.flatten(m_nice_ssp1_nomig_xim1[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp2_nomig_xim1[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp3_nomig_xim1[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp4_nomig_xim1[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp5_nomig_xim1[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
income[:,:gdp_migNICEFUND_xim1] = gdp_migNICEFUND_xim1
ypc_migNICEFUND_xi0 = vcat(
    collect(Iterators.flatten(m_nice_ssp1_nomig_xi0[:socioeconomic,:ypc][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp2_nomig_xi0[:socioeconomic,:ypc][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp3_nomig_xi0[:socioeconomic,:ypc][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp4_nomig_xi0[:socioeconomic,:ypc][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp5_nomig_xi0[:socioeconomic,:ypc][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
income[:,:ypc_migNICEFUND_xi0] = ypc_migNICEFUND_xi0
ypc_migNICEFUND_xim1 = vcat(
    collect(Iterators.flatten(m_nice_ssp1_nomig_xim1[:socioeconomic,:ypc][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp2_nomig_xim1[:socioeconomic,:ypc][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp3_nomig_xim1[:socioeconomic,:ypc][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp4_nomig_xim1[:socioeconomic,:ypc][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp5_nomig_xim1[:socioeconomic,:ypc][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
income[:,:ypc_migNICEFUND_xim1] = ypc_migNICEFUND_xim1

income_p = income[(map(x->mod(x,10)==0,income[:,:year])),:]
rename!(income_p, :ypc_migNICEFUND => :ypc_xi1, :ypc_migNICEFUND_xi0 => :ypc_xi0, :ypc_migNICEFUND_xim1 => :ypc_xim1)
rename!(income_p, :gdp_migNICEFUND => :gdp_xi1, :gdp_migNICEFUND_xi0 => :gdp_xi0, :gdp_migNICEFUND_xim1 => :gdp_xim1)

worldgdp_migNICEFUND_xi0 = vcat(
    collect(Iterators.flatten(m_nice_ssp1_nomig_xi0[:socioeconomic,:globalincome][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_nice_ssp2_nomig_xi0[:socioeconomic,:globalincome][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_nice_ssp3_nomig_xi0[:socioeconomic,:globalincome][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_nice_ssp4_nomig_xi0[:socioeconomic,:globalincome][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_nice_ssp5_nomig_xi0[:socioeconomic,:globalincome][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)]))
)
income_world[:,:worldgdp_migNICEFUND_xi0] = worldgdp_migNICEFUND_xi0
worldgdp_migNICEFUND_xim1 = vcat(
    collect(Iterators.flatten(m_nice_ssp1_nomig_xim1[:socioeconomic,:globalincome][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_nice_ssp2_nomig_xim1[:socioeconomic,:globalincome][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_nice_ssp3_nomig_xim1[:socioeconomic,:globalincome][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_nice_ssp4_nomig_xim1[:socioeconomic,:globalincome][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_nice_ssp5_nomig_xim1[:socioeconomic,:globalincome][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)]))
)
income_world[:,:worldgdp_migNICEFUND_xim1] = worldgdp_migNICEFUND_xim1
worldypc_migNICEFUND_xi0 = vcat(
    collect(Iterators.flatten(m_nice_ssp1_nomig_xi0[:socioeconomic,:globalypc][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_nice_ssp2_nomig_xi0[:socioeconomic,:globalypc][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_nice_ssp3_nomig_xi0[:socioeconomic,:globalypc][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_nice_ssp4_nomig_xi0[:socioeconomic,:globalypc][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_nice_ssp5_nomig_xi0[:socioeconomic,:globalypc][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)]))
)
income_world[:,:worldypc_migNICEFUND_xi0] = worldypc_migNICEFUND_xi0
worldypc_migNICEFUND_xim1 = vcat(
    collect(Iterators.flatten(m_nice_ssp1_nomig_xim1[:socioeconomic,:globalypc][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_nice_ssp2_nomig_xim1[:socioeconomic,:globalypc][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_nice_ssp3_nomig_xim1[:socioeconomic,:globalypc][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_nice_ssp4_nomig_xim1[:socioeconomic,:globalypc][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_nice_ssp5_nomig_xim1[:socioeconomic,:globalypc][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)]))
)
income_world[:,:worldypc_migNICEFUND_xim1] = worldypc_migNICEFUND_xim1

income_world_p = income_world[(map(x->mod(x,10)==0,income_world[:,:year])),:]
rename!(income_world_p, :worldypc_migNICEFUND => :worldypc_xi1, :worldypc_migNICEFUND_xi0 => :worldypc_xi0, :worldypc_migNICEFUND_xim1 => :worldypc_xim1)
rename!(income_world_p, :worldgdp_migNICEFUND => :worldgdp_xi1, :worldgdp_migNICEFUND_xi0 => :worldgdp_xi0, :worldgdp_migNICEFUND_xim1 => :worldgdp_xim1)

gdp_world_stack = stack(income_world_p,[:worldgdp_xi1,:worldgdp_xi0,:worldgdp_xim1],[:scen,:year])
rename!(gdp_world_stack,:variable => :worldgdp_type, :value => :worldgdp)
gdp_world_stack |> @filter(_.year >= 2015 && _.year <= 2100)  |> @vlplot()+@vlplot(
    width=300, height=250,
    mark={:point, size=50}, x = {"year:o", axis={labelFontSize=16}, title=nothing}, y = {"worldgdp:q", title=nothing, axis={labelFontSize=16}}, 
    title = "Global income per capita for Mig-NICE-FUND with various income elasticities of damages", 
    color = {"scen:n", scale={scheme=:category10}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}, 
    shape = {"worldgdp_type:o", scale={range=["circle","triangle-up", "square"]}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}
) + @vlplot(
    mark={:line, strokeDash=[1,2]}, x = {"year:o", axis={labelFontSize=16}, title=nothing}, y = {"worldgdp:q", aggregate=:mean,type=:quantitative,title=nothing, axis={labelFontSize=16}}, 
    color = {"scen:n", scale={scheme=:category10}},
    detail = "worldgdp_type:o"
) |> save(joinpath(@__DIR__, "../results/income_ineq/", "gdp_world_xi_v5.png"))

income_world_stack = stack(income_world_p,[:worldypc_xi1,:worldypc_xi0,:worldypc_xim1],[:scen,:year])
rename!(income_world_stack,:variable => :worldypc_type, :value => :worldypc)
income_world_stack |> @filter(_.year >= 2015 && _.year <= 2100)  |> @vlplot()+@vlplot(
    width=300, height=250,
    mark={:point, size=50}, x = {"year:o", axis={labelFontSize=16}, title=nothing}, y = {"worldypc:q", title=nothing, axis={labelFontSize=16}}, 
    title = "Global income per capita for Mig-NICE-FUND with various income elasticities of damages", 
    color = {"scen:n", scale={scheme=:category10}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}, 
    shape = {"worldypc_type:o", scale={range=["circle","triangle-up", "square"]}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}
) + @vlplot(
    mark={:line, strokeDash=[1,2]}, x = {"year:o", axis={labelFontSize=16}, title=nothing}, y = {"worldypc:q", aggregate=:mean,type=:quantitative,title=nothing, axis={labelFontSize=16}}, 
    color = {"scen:n", scale={scheme=:category10}},
    detail = "worldypc_type:o"
) |> save(joinpath(@__DIR__, "../results/income_ineq/", "ypc_world_xi_v5.png"))


# Look at ypc for different income elasticities of damages
ypc_all = stack(
    rename(income, :ypc_migNICEFUND => :ypc_damprop, :ypc_migNICEFUND_xi0 => :ypc_damindep, :ypc_migNICEFUND_xim1 => :ypc_daminvprop), 
    [:ypc_damprop,:ypc_damindep,:ypc_daminvprop], 
    [:scen, :fundregion, :year]
)
rename!(ypc_all, :variable => :ypc_type, :value => :ypc)
for s in ssps
    ypc_all |> @filter(_.year >= 2015 && _.year <= 2100 && _.scen == s) |> @vlplot(
        mark={:line, strokeWidth = 4}, width=300, height=250, columns=4, wrap="fundregion:o", 
        x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
        y={"ypc:q", title = nothing, axis={labelFontSize=16}},
        color={"ypc_type:o",scale={scheme=:darkgreen},legend={titleFontSize=16, symbolSize=40, labelFontSize=16}},
        resolve = {scale={y=:independent}}
    ) |> save(joinpath(@__DIR__, "../results/income_ineq/", string("ypc_",s,"_v5.png")))
end
ypc_all[!,:scen_ypc_type] = [string(ypc_all[i,:scen],"_",SubString(string(ypc_all[i,:ypc_type]),4)) for i in 1:size(ypc_all,1)]
ypc_all |> @filter(_.year >= 2015 && _.year <= 2100) |> @vlplot(
    mark={:line, strokeWidth = 4}, width=300, height=250, columns=4, wrap="fundregion:o", 
    x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
    y={"ypc:q", title = nothing, axis={labelFontSize=16}},
    title = "Income per capita for world regions, SSP narratives and various income elasticities of damages",
    color={"scen_ypc_type:o",scale={scheme=:category20c},legend={titleFontSize=16, symbolSize=40, labelFontSize=16}},
    resolve = {scale={y=:independent}}
) |> save(joinpath(@__DIR__, "../results/income_ineq/", string("ypc_v5.png")))


######################################## Plot heat tables and geographical maps of remittances flows in 2100 ############################################
rem = DataFrame(
    year = repeat(years, outer = length(ssps)*length(regions)*length(regions)),
    scen = repeat(ssps,inner = length(regions)*length(years)*length(regions)),
    origin = repeat(regions, outer = length(ssps)*length(regions), inner=length(years)),
    destination = repeat(regions, outer = length(ssps), inner=length(years)*length(regions))
)

rem_xi1 = vcat(
    collect(Iterators.flatten(sum(m_nice_ssp1_nomig[:migration,:rem][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:,:,:],dims=[4,5])[:,:,:,1,1])),
    collect(Iterators.flatten(sum(m_nice_ssp2_nomig[:migration,:rem][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:,:,:],dims=[4,5])[:,:,:,1,1])),
    collect(Iterators.flatten(sum(m_nice_ssp3_nomig[:migration,:rem][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:,:,:],dims=[4,5])[:,:,:,1,1])),
    collect(Iterators.flatten(sum(m_nice_ssp4_nomig[:migration,:rem][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:,:,:],dims=[4,5])[:,:,:,1,1])),
    collect(Iterators.flatten(sum(m_nice_ssp5_nomig[:migration,:rem][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:,:,:],dims=[4,5])[:,:,:,1,1]))
)
rem[:,:rem_xi1] = rem_xi1
rem_xi0 = vcat(
    collect(Iterators.flatten(sum(m_nice_ssp1_nomig_xi0[:migration,:rem][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:,:,:],dims=[4,5])[:,:,:,1,1])),
    collect(Iterators.flatten(sum(m_nice_ssp2_nomig_xi0[:migration,:rem][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:,:,:],dims=[4,5])[:,:,:,1,1])),
    collect(Iterators.flatten(sum(m_nice_ssp3_nomig_xi0[:migration,:rem][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:,:,:],dims=[4,5])[:,:,:,1,1])),
    collect(Iterators.flatten(sum(m_nice_ssp4_nomig_xi0[:migration,:rem][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:,:,:],dims=[4,5])[:,:,:,1,1])),
    collect(Iterators.flatten(sum(m_nice_ssp5_nomig_xi0[:migration,:rem][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:,:,:],dims=[4,5])[:,:,:,1,1]))
)
rem[:,:rem_xi0] = rem_xi0
rem_xim1 = vcat(
    collect(Iterators.flatten(sum(m_nice_ssp1_nomig_xim1[:migration,:rem][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:,:,:],dims=[4,5])[:,:,:,1,1])),
    collect(Iterators.flatten(sum(m_nice_ssp2_nomig_xim1[:migration,:rem][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:,:,:],dims=[4,5])[:,:,:,1,1])),
    collect(Iterators.flatten(sum(m_nice_ssp3_nomig_xim1[:migration,:rem][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:,:,:],dims=[4,5])[:,:,:,1,1])),
    collect(Iterators.flatten(sum(m_nice_ssp4_nomig_xim1[:migration,:rem][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:,:,:],dims=[4,5])[:,:,:,1,1])),
    collect(Iterators.flatten(sum(m_nice_ssp5_nomig_xim1[:migration,:rem][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:,:,:],dims=[4,5])[:,:,:,1,1]))
)
rem[:,:rem_xim1] = rem_xim1

receive_xi1 = vcat(
    collect(Iterators.flatten(sum(m_nice_ssp1_nomig[:migration,:receive][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp2_nomig[:migration,:receive][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp3_nomig[:migration,:receive][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp4_nomig[:migration,:receive][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp5_nomig[:migration,:receive][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1]))
)
income[:,:receive_xi1] = receive_xi1
receive_xi0 = vcat(
    collect(Iterators.flatten(sum(m_nice_ssp1_nomig_xi0[:migration,:receive][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp2_nomig_xi0[:migration,:receive][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp3_nomig_xi0[:migration,:receive][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp4_nomig_xi0[:migration,:receive][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp5_nomig_xi0[:migration,:receive][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1]))
)
income[:,:receive_xi0] = receive_xi0
receive_xim1 = vcat(
    collect(Iterators.flatten(sum(m_nice_ssp1_nomig_xim1[:migration,:receive][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp2_nomig_xim1[:migration,:receive][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp3_nomig_xim1[:migration,:receive][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp4_nomig_xim1[:migration,:receive][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp5_nomig_xim1[:migration,:receive][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1]))
)
income[:,:receive_xim1] = receive_xim1

send_xi1 = vcat(
    collect(Iterators.flatten(sum(m_nice_ssp1_nomig[:migration,:send][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp2_nomig[:migration,:send][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp3_nomig[:migration,:send][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp4_nomig[:migration,:send][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp5_nomig[:migration,:send][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1]))
)
income[:,:send_xi1] = send_xi1
send_xi0 = vcat(
    collect(Iterators.flatten(sum(m_nice_ssp1_nomig_xi0[:migration,:send][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp2_nomig_xi0[:migration,:send][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp3_nomig_xi0[:migration,:send][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp4_nomig_xi0[:migration,:send][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp5_nomig_xi0[:migration,:send][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1]))
)
income[:,:send_xi0] = send_xi0
send_xim1 = vcat(
    collect(Iterators.flatten(sum(m_nice_ssp1_nomig_xim1[:migration,:send][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp2_nomig_xim1[:migration,:send][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp3_nomig_xim1[:migration,:send][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp4_nomig_xim1[:migration,:send][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1])),
    collect(Iterators.flatten(sum(m_nice_ssp5_nomig_xim1[:migration,:send][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:],dims=3)[:,:,1]))
)
income[:,:send_xim1] = send_xim1

rem = innerjoin(
    rem, 
    rename(
        income, 
        :fundregion => :origin, 
        :receive_xi1 => :receive_or_xi1, 
        :gdp_migNICEFUND => :gdp_or_xi1, 
        :receive_xi0 => :receive_or_xi0, 
        :gdp_migNICEFUND_xi0 => :gdp_or_xi0, 
        :receive_xim1 => :receive_or_xim1, 
        :gdp_migNICEFUND_xim1 => :gdp_or_xim1, 
    )[:,Not([:send_xi1,:send_xi0,:send_xim1])],
    on = [:year,:scen,:origin]
)
rem = innerjoin(
    rem, 
    rename(
        income, 
        :fundregion => :destination, 
        :send_xi1 => :send_dest_xi1, 
        :gdp_migNICEFUND => :gdp_dest_xi1, 
        :send_xi0 => :send_dest_xi0, 
        :gdp_migNICEFUND_xi0 => :gdp_dest_xi0, 
        :send_xim1 => :send_dest_xim1, 
        :gdp_migNICEFUND_xim1 => :gdp_dest_xim1, 
    )[:,Not([:receive_xi1,:receive_xi0,:receive_xim1,:gdp_sspNICEFUND, :gdp_origFUND, :ypc_migNICEFUND, :ypc_sspNICEFUND, :ypc_origFUND, :ypc_migNICEFUND_xi0, :ypc_migNICEFUND_xim1])],
    on = [:year,:scen,:destination]
)
rem[:,:remshare_or_xi1] = rem[:,:rem_xi1] ./ rem[:,:receive_or_xi1]
rem[:,:remshare_or_xi0] = rem[:,:rem_xi0] ./ rem[:,:receive_or_xi0]
rem[:,:remshare_or_xim1] = rem[:,:rem_xim1] ./ rem[:,:receive_or_xim1]
rem[:,:remshare_dest_xi1] = rem[:,:rem_xi1] ./ rem[:,:send_dest_xi1]
rem[:,:remshare_dest_xi0] = rem[:,:rem_xi0] ./ rem[:,:send_dest_xi0]
rem[:,:remshare_dest_xim1] = rem[:,:rem_xim1] ./ rem[:,:send_dest_xim1]
for i in 1:size(rem,1)
    if rem[i,:receive_or_xi1] == 0 ; rem[i,:remshare_or_xi1] = 0 end
    if rem[i,:receive_or_xi0] == 0 ; rem[i,:remshare_or_xi0] = 0 end
    if rem[i,:receive_or_xim1] == 0 ; rem[i,:remshare_or_xim1] = 0 end
    if rem[i,:send_dest_xi1] == 0 ; rem[i,:remshare_dest_xi1] = 0 end
    if rem[i,:send_dest_xi0] == 0 ; rem[i,:remshare_dest_xi0] = 0 end
    if rem[i,:send_dest_xim1] == 0 ; rem[i,:remshare_dest_xim1] = 0 end
end

rem |> @filter(_.year == 2100) |> @vlplot(
    :rect, y=:origin, x=:destination, column = {"scen:o", axis={labelFontSize=16}, title=nothing},
    color={"rem_xi1:q"},title = string("damages proportional to income, ", 2100)
) |> save(joinpath(@__DIR__, "../results/income_ineq/", string("remflow_", 2100,"_xi1_v5.png")))
rem |> @filter(_.year == 2100) |> @vlplot(
    :rect, y=:origin, x=:destination, column = {"scen:o", axis={labelFontSize=16}, title=nothing},
    color={"remshare_or_xi1:q", scale={domain=[0,1]}},title = string("damages proportional to income, ", 2100)
) |> save(joinpath(@__DIR__, "../results/income_ineq/", string("remflow_share_or", 2100,"_xi1_v5.png")))
rem |> @filter(_.year == 2100) |> @vlplot(
    :rect, y=:origin, x=:destination, column = {"scen:o", axis={labelFontSize=16}, title=nothing},
    color={"remshare_dest_xi1:q", scale={domain=[0,1]}},title = string("damages proportional to income, ", 2100)
) |> save(joinpath(@__DIR__, "../results/income_ineq/", string("remflow_share_dest", 2100,"_xi1_v5.png")))
rem |> @filter(_.year == 2100) |> @vlplot(
    :rect, y=:origin, x=:destination, column = {"scen:o", axis={labelFontSize=16}, title=nothing},
    color={"rem_xi0:q"},title = string("damages independent of income, ", 2100)
) |> save(joinpath(@__DIR__, "../results/income_ineq/", string("remflow_", 2100,"_xi0_v5.png")))
rem |> @filter(_.year == 2100) |> @vlplot(
    :rect, y=:origin, x=:destination, column = {"scen:o", axis={labelFontSize=16}, title=nothing},
    color={"remshare_or_xi0:q", scale={domain=[0,1]}},title = string("damages independent of income, ", 2100)
) |> save(joinpath(@__DIR__, "../results/income_ineq/", string("remflow_share_or", 2100,"_xi0_v5.png")))
rem |> @filter(_.year == 2100) |> @vlplot(
    :rect, y=:origin, x=:destination, column = {"scen:o", axis={labelFontSize=16}, title=nothing},
    color={"remshare_dest_xi0:q", scale={domain=[0,1]}},title = string("damages independent of income, ", 2100)
) |> save(joinpath(@__DIR__, "../results/income_ineq/", string("remflow_share_dest", 2100,"_xi0_v5.png")))
rem |> @filter(_.year == 2100) |> @vlplot(
    :rect, y=:origin, x=:destination, column = {"scen:o", axis={labelFontSize=16}, title=nothing},
    color={"rem_xim1:q"},title = string("damages inversely proportional to income, ", 2100)
) |> save(joinpath(@__DIR__, "../results/income_ineq/", string("remflow_", 2100,"_xim1_v5.png")))
rem |> @filter(_.year == 2100) |> @vlplot(
    :rect, y=:origin, x=:destination, column = {"scen:o", axis={labelFontSize=16}, title=nothing},
    color={"remshare_or_xim1:q", scale={domain=[0,1]}},title = string("damages inversely proportional to income, ", 2100)
) |> save(joinpath(@__DIR__, "../results/income_ineq/", string("remflow_share_or", 2100,"_xim1_v5.png")))
rem |> @filter(_.year == 2100) |> @vlplot(
    :rect, y=:origin, x=:destination, column = {"scen:o", axis={labelFontSize=16}, title=nothing},
    color={"remshare_dest_xim1:q", scale={domain=[0,1]}},title = string("damages inversely proportional to income, ", 2100)
) |> save(joinpath(@__DIR__, "../results/income_ineq/", string("remflow_share_dest", 2100,"_xim1_v5.png")))


###################################### Plot geographical maps #####################################
world110m = dataset("world-110m")

isonum_fundregion = CSV.read(joinpath(@__DIR__,"../input_data/isonum_fundregion.csv"),DataFrame)
income_maps = leftjoin(income, isonum_fundregion, on = :fundregion)
income_maps[!,:ypcdiff_xi0] = (income_maps[!,:ypc_migNICEFUND_xi0] ./ income_maps[!,:ypc_migNICEFUND] .- 1) .* 100
income_maps[!,:ypcdiff_xim1] = (income_maps[!,:ypc_migNICEFUND_xim1] ./ income_maps[!,:ypc_migNICEFUND] .- 1) .* 100

for s in ssps
    @vlplot(width=800, height=600) + @vlplot(mark={:geoshape, stroke = :lightgray}, 
        data={values=world110m, format={type=:topojson, feature=:countries}}, 
        transform = [{lookup=:id, from={data=filter(row -> row[:scen] == s && row[:year] == 2100, income_maps), key=:isonum, fields=[string(:ypc_migNICEFUND)]}}],
        projection={type=:naturalEarth1}, title = {text=string("GDP per capita levels by 2100 for damages proportional to income, ", s),fontSize=24}, 
        color = {"ypc_migNICEFUND:q", scale={scheme=:greens}, legend={title=string("USD2005/cap"), titleFontSize=20, titleLimit=220, symbolSize=60, labelFontSize=24, labelLimit=220, offset=2}}
    ) |> save(joinpath(@__DIR__, "../results/world_maps_ineq/", string("ypc_xi1_", s, "_v5.png")))
end
for s in ssps
    @vlplot(width=800, height=600) + @vlplot(mark={:geoshape, stroke = :lightgray}, 
        data={values=world110m, format={type=:topojson, feature=:countries}}, 
        transform = [{lookup=:id, from={data=filter(row -> row[:scen] == s && row[:year] == 2100, income_maps), key=:isonum, fields=[string(:ypcdiff,:_xi0)]}}],
        projection={type=:naturalEarth1}, title = {text=string("damages independent of income, 2100, ", s),fontSize=24}, 
        color = {Symbol(string(:ypcdiff,:_xi0)), type=:quantitative, scale={domain=[-2,2], scheme=:redblue}, legend={title="% vs proportional", titleFontSize=20, symbolSize=60, labelFontSize=24}}
    ) |> save(joinpath(@__DIR__, "../results/world_maps_ineq/", string("ypcdiff",:_xi0,"_", s, "_v5.png")))
end
for s in ssps
    @vlplot(width=800, height=600) + @vlplot(mark={:geoshape, stroke = :lightgray}, 
        data={values=world110m, format={type=:topojson, feature=:countries}}, 
        transform = [{lookup=:id, from={data=filter(row -> row[:scen] == s && row[:year] == 2100, income_maps), key=:isonum, fields=[string(:ypcdiff,:_xim1)]}}],
        projection={type=:naturalEarth1}, title = {text=string("damages inversely proportional to income, 2100, ", s),fontSize=24}, 
        color = {Symbol(string(:ypcdiff,:_xim1)), type=:quantitative, scale={domain=[-2,2], scheme=:redblue}, legend={title="% vs proportional", titleFontSize=20, symbolSize=60, labelFontSize=24}}
    ) |> save(joinpath(@__DIR__, "../results/world_maps_ineq/", string("ypcdiff",:_xim1,"_", s, "_v5.png")))
end


###################################### Look at net remittances flows for different income elasticities of damages ############################################
income[!,:netrem_damprop] = income[!,:receive_xi1] .- income[!,:send_xi1]
income[!,:netrem_damindep] = income[!,:receive_xi0] .- income[!,:send_xi0]
income[!,:netrem_daminvprop] = income[!,:receive_xim1] .- income[!,:send_xim1]

netrem_all = stack(
    income, 
    [:netrem_damprop,:netrem_damindep,:netrem_daminvprop], 
    [:scen, :fundregion, :year]
)
rename!(netrem_all, :variable => :netrem_type, :value => :netrem)
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
netrem_all = innerjoin(netrem_all,regions_fullname, on=:fundregion)
for s in ssps
    netrem_all |> @filter(_.year >= 2015 && _.year <= 2100 && _.scen == s) |> @vlplot(
        mark={:line, strokeWidth = 4}, width=300, height=250, columns=4, wrap={"regionname:o", title=nothing, header={labelFontSize=24}}, 
        x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
        y={"netrem:q", title = nothing, axis={labelFontSize=16}},
        color={"netrem_type:o",scale={scheme=:darkmulti},legend={title=string("Net remittances, ",s), titleFontSize=20, titleLimit=240, symbolSize=60, labelFontSize=24, labelLimit=280, offset=2}},
        resolve = {scale={y=:independent}}
    ) |> save(joinpath(@__DIR__, "../results/income_ineq/", string("netrem_",s,"_v5.png")))
end
netrem_all[!,:scen_netrem_type] = [string(netrem_all[i,:scen],"_",SubString(string(netrem_all[i,:netrem_type]),8)) for i in 1:size(netrem_all,1)]
netrem_all |> @filter(_.year >= 2015 && _.year <= 2100) |> @vlplot(
    mark={:line, strokeWidth = 4}, width=300, height=250, columns=4, wrap="fundregion:o", 
    x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
    y={"netrem:q", title = nothing, axis={labelFontSize=16}},
    title = "Net remittances flow for world regions, SSP narratives and various income elasticities of damages",
    color={"scen_netrem_type:o",scale={scheme=:category20c},legend={titleFontSize=16, symbolSize=40, labelFontSize=16}},
    resolve = {scale={y=:independent}}
) |> save(joinpath(@__DIR__, "../results/income_ineq/", string("netrem_v5.png")))

rem_all = stack(
    rename(income, :receive_xi1 => :receive_damprop, :receive_xi0 => :receive_damindep, :receive_xim1 => :receive_daminvprop, :send_xi1 => :send_damprop, :send_xi0 => :send_damindep, :send_xim1 => :send_daminvprop), 
    [:receive_damprop, :receive_damindep, :receive_daminvprop, :send_damprop, :send_damindep, :send_daminvprop], 
    [:scen, :fundregion, :year]
)
rename!(rem_all, :variable => :rem_type, :value => :rem)
rem_all[!,:rem] = [in(rem_all[i,:rem_type], [:send_damprop,:send_damindep,:send_daminvprop]) ? rem_all[i,:rem] * (-1) : rem_all[i,:rem] for i in 1:size(rem_all,1)]
for s in ssps
    rem_all |> @filter(_.year >= 2015 && _.year <= 2100 && _.scen == s) |> @vlplot(
        mark={:line, strokeWidth = 4}, width=300, height=250, columns=4, wrap="fundregion:o", 
        x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
        y={"rem:q", title = nothing, axis={labelFontSize=16}},
        color={"rem_type:o",scale={scheme="category20c"},legend={titleFontSize=16, symbolSize=40, labelFontSize=16}},
        resolve = {scale={y=:independent}}
    ) |> save(joinpath(@__DIR__, "../results/income_ineq/", string("rem_",s,"_v5.png")))
end


################################################### Plot share of income sent as remittances #################################################
remshare_xi1 = vcat(
    collect(Iterators.flatten(m_nice_ssp1_nomig[:migration,:remshare][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp2_nomig[:migration,:remshare][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp3_nomig[:migration,:remshare][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp4_nomig[:migration,:remshare][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp5_nomig[:migration,:remshare][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))
)
rem[!,:remshare_damprop] = remshare_xi1
remshare_xi0 = vcat(
    collect(Iterators.flatten(m_nice_ssp1_nomig_xi0[:migration,:remshare][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp2_nomig_xi0[:migration,:remshare][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp3_nomig_xi0[:migration,:remshare][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp4_nomig_xi0[:migration,:remshare][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp5_nomig_xi0[:migration,:remshare][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))
)
rem[!,:remshare_damindep] = remshare_xi0
remshare_xim1 = vcat(
    collect(Iterators.flatten(m_nice_ssp1_nomig_xim1[:migration,:remshare][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp2_nomig_xim1[:migration,:remshare][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp3_nomig_xim1[:migration,:remshare][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp4_nomig_xim1[:migration,:remshare][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp5_nomig_xim1[:migration,:remshare][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))
)
rem[!,:remshare_daminvprop] = remshare_xim1

remshare_all = stack(
    rem, 
    [:remshare_damprop,:remshare_damindep,:remshare_daminvprop], 
    [:scen, :origin, :destination, :year]
)
rename!(remshare_all, :variable => :remshare_type, :value => :remshare)
remshare_all = innerjoin(remshare_all,rename(regions_fullname,:fundregion=>:origin,:regionname=>:originname), on=:origin)
remshare_all = innerjoin(remshare_all,rename(regions_fullname,:fundregion=>:destination,:regionname=>:destinationname), on=:destination)

remshare_all |> @filter(_.year >= 2015 && _.year <= 2100 && _.remshare_type == Symbol("remshare_damprop")) |> @vlplot(
    mark={:errorband, extent=:ci}, width=300, height=250, columns=4, wrap={"destinationname:o", title=nothing, header={labelFontSize=24, titleFontSize=20}}, 
    x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
    y={"remshare:q", title = "Share of migrant income", axis={labelFontSize=16,titleFontSize=20,}},
    color={"scen:o",scale={scheme=:category10},legend={title=string("Remshare"), titleFontSize=20, titleLimit=240, symbolSize=80, labelFontSize=24, labelLimit=280, offset=2}},
    resolve = {scale={y=:independent}}
) |> save(joinpath(@__DIR__, "../results/income_ineq/", string("remshare_xi1_v5.png")))


###################################### Plot remittances per quintile #########################################
income_quint = DataFrame(
    year = repeat(years, outer = length(ssps)*length(regions)*5),
    scen = repeat(ssps,inner = length(regions)*length(years)*5),
    fundregion = repeat(regions, outer = length(ssps)*5, inner=length(years)),
    quintile = repeat(1:5, outer = length(ssps), inner=length(years)*length(regions))
)

receive_quint_xi1 = vcat(
    collect(Iterators.flatten(m_nice_ssp1_nomig[:migration,:receive][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp2_nomig[:migration,:receive][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp3_nomig[:migration,:receive][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp4_nomig[:migration,:receive][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp5_nomig[:migration,:receive][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))
)
income_quint[:,:receive_quint_xi1] = receive_quint_xi1
receive_quint_xi0 = vcat(
    collect(Iterators.flatten(m_nice_ssp1_nomig_xi0[:migration,:receive][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp2_nomig_xi0[:migration,:receive][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp3_nomig_xi0[:migration,:receive][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp4_nomig_xi0[:migration,:receive][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp5_nomig_xi0[:migration,:receive][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))
)
income_quint[:,:receive_quint_xi0] = receive_quint_xi0
receive_quint_xim1 = vcat(
    collect(Iterators.flatten(m_nice_ssp1_nomig_xim1[:migration,:receive][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp2_nomig_xim1[:migration,:receive][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp3_nomig_xim1[:migration,:receive][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp4_nomig_xim1[:migration,:receive][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp5_nomig_xim1[:migration,:receive][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))
)
income_quint[:,:receive_quint_xim1] = receive_quint_xim1

send_quint_xi1 = vcat(
    collect(Iterators.flatten(m_nice_ssp1_nomig[:migration,:send][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp2_nomig[:migration,:send][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp3_nomig[:migration,:send][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp4_nomig[:migration,:send][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp5_nomig[:migration,:send][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))
)
income_quint[:,:send_quint_xi1] = send_quint_xi1
send_quint_xi0 = vcat(
    collect(Iterators.flatten(m_nice_ssp1_nomig_xi0[:migration,:send][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp2_nomig_xi0[:migration,:send][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp3_nomig_xi0[:migration,:send][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp4_nomig_xi0[:migration,:send][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp5_nomig_xi0[:migration,:send][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))
)
income_quint[:,:send_quint_xi0] = send_quint_xi0
send_quint_xim1 = vcat(
    collect(Iterators.flatten(m_nice_ssp1_nomig_xim1[:migration,:send][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp2_nomig_xim1[:migration,:send][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp3_nomig_xim1[:migration,:send][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp4_nomig_xim1[:migration,:send][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp5_nomig_xim1[:migration,:send][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))
)
income_quint[:,:send_quint_xim1] = send_quint_xim1

rem_quint_all = stack(
    rename(income_quint, :receive_quint_xi1 => :receive_quint_damprop, :receive_quint_xi0 => :receive_quint_damindep, :receive_quint_xim1 => :receive_quint_daminvprop, :send_quint_xi1 => :send_quint_damprop, :send_quint_xi0 => :send_quint_damindep, :send_quint_xim1 => :send_quint_daminvprop), 
    [:receive_quint_damprop, :receive_quint_damindep, :receive_quint_daminvprop, :send_quint_damprop, :send_quint_damindep, :send_quint_daminvprop], 
    [:scen, :quintile, :fundregion, :year]
)
rename!(rem_quint_all, :variable => :rem_type, :value => :rem)
rem_quint_all[!,:rem_quint] = [in(rem_quint_all[i,:rem_type], [:send_quint_damprop,:send_quint_damindep,:send_quint_daminvprop]) ? rem_quint_all[i,:rem] * (-1) : rem_quint_all[i,:rem] for i in 1:size(rem_quint_all,1)]
for s in ssps
    rem_quint_all |> @filter(_.year >= 2015 && _.year <= 2100 && _.scen == s) |> @vlplot(
        mark={:point,size=60}, width=300, height=250, columns=4, wrap="fundregion:o", 
        x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
        y={"rem_quint:q", title = nothing, axis={labelFontSize=16}},
        color={"quintile:o",scale={scheme=:darkmulti},legend={titleFontSize=16, symbolSize=40, labelFontSize=16}},
        shape={"rem_type:o",legend={titleFontSize=16, symbolSize=40, labelFontSize=16}},
        resolve = {scale={y=:independent}}
    ) |> save(joinpath(@__DIR__, "../results/income_ineq/", string("rem_quint_",s,"_v5.png")))
end


income_quint[!,:netrem_quint_damprop] = income_quint[!,:receive_quint_xi1] .- income_quint[!,:send_quint_xi1]
income_quint[!,:netrem_quint_damindep] = income_quint[!,:receive_quint_xi0] .- income_quint[!,:send_quint_xi0]
income_quint[!,:netrem_quint_daminvprop] = income_quint[!,:receive_quint_xim1] .- income_quint[!,:send_quint_xim1]

netrem_quint_all = stack(
    income_quint, 
    [:netrem_quint_damprop,:netrem_quint_damindep,:netrem_quint_daminvprop], 
    [:scen, :quintile, :fundregion, :year]
)
rename!(netrem_quint_all, :variable => :netrem_type, :value => :netrem_quint)
netrem_quint_all = innerjoin(netrem_quint_all,regions_fullname, on=:fundregion)
netrem_quint_all_p = netrem_quint_all[(map(x->mod(x,10)==0,netrem_quint_all[:,:year])),:]
netrem_quint_all_p[!,:netrem_type] = map(x->SubString(String(x), 14), netrem_quint_all_p[:,:netrem_type])
netrem_quint_all_p[!,:type_name] = [netrem_quint_all_p[i,:netrem_type]=="damprop" ? "proportional" : (netrem_quint_all_p[i,:netrem_type]=="damindep" ? "independent" : "inversely prop.") for i in 1:size(netrem_quint_all_p,1)]

for s in ssps
    netrem_quint_all_p |> @filter(_.year >= 2015 && _.year <= 2100 && _.scen == s) |> @vlplot(
        mark={:point,size=60}, width=300, height=250, columns=4, wrap={"regionname:o", title=nothing, header={labelFontSize=24}}, 
        x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
        y={"netrem_quint:q", title = "Net remittances, billion USD", axis={labelFontSize=16,titleFontSize=16}},
        color={"quintile:o",scale={scheme=:darkmulti},legend={title=string("Quintile, ",s), titleFontSize=20, titleLimit=220, symbolSize=80, labelFontSize=20}},
        shape={"type_name:o",scale={range=["circle","triangle-up","square"],domain=["proportional","independent","inversely prop."]},legend={title = "Damages elasticity", titleFontSize=20, titleLimit=260, symbolSize=80, labelFontSize=20}},
        resolve = {scale={y=:independent}}
    ) |> save(joinpath(@__DIR__, "../results/income_ineq/", string("netrem_quint_",s,"_v5.png")))
end


############################################## Plot income per capita per quintile #########################################################
gdp_quint_xi1 = vcat(
    collect(Iterators.flatten(m_nice_ssp1_nomig[:migration,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp2_nomig[:migration,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp3_nomig[:migration,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp4_nomig[:migration,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp5_nomig[:migration,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))
)
income_quint[:,:gdp_quint_xi1] = gdp_quint_xi1
gdp_quint_xi0 = vcat(
    collect(Iterators.flatten(m_nice_ssp1_nomig_xi0[:migration,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp2_nomig_xi0[:migration,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp3_nomig_xi0[:migration,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp4_nomig_xi0[:migration,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp5_nomig_xi0[:migration,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))
)
income_quint[:,:gdp_quint_xi0] = gdp_quint_xi0
gdp_quint_xim1 = vcat(
    collect(Iterators.flatten(m_nice_ssp1_nomig_xim1[:migration,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp2_nomig_xim1[:migration,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp3_nomig_xim1[:migration,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp4_nomig_xim1[:migration,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp5_nomig_xim1[:migration,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))
)
income_quint[:,:gdp_quint_xim1] = gdp_quint_xim1
pop_quint_xi1 = vcat(
    collect(Iterators.flatten(m_nice_ssp1_nomig[:migration,:pop][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp2_nomig[:migration,:pop][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp3_nomig[:migration,:pop][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp4_nomig[:migration,:pop][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp5_nomig[:migration,:pop][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))
)
income_quint[:,:pop_quint_xi1] = pop_quint_xi1
pop_quint_xi0 = vcat(
    collect(Iterators.flatten(m_nice_ssp1_nomig_xi0[:migration,:pop][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp2_nomig_xi0[:migration,:pop][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp3_nomig_xi0[:migration,:pop][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp4_nomig_xi0[:migration,:pop][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp5_nomig_xi0[:migration,:pop][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))
)
income_quint[:,:pop_quint_xi0] = pop_quint_xi0
pop_quint_xim1 = vcat(
    collect(Iterators.flatten(m_nice_ssp1_nomig_xim1[:migration,:pop][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp2_nomig_xim1[:migration,:pop][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp3_nomig_xim1[:migration,:pop][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp4_nomig_xim1[:migration,:pop][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_nice_ssp5_nomig_xim1[:migration,:pop][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))
)
income_quint[:,:pop_quint_xim1] = pop_quint_xim1

income_quint[:,:ypc_quint_xi1] = income_quint[:,:gdp_quint_xi1] ./ income_quint[:,:pop_quint_xi1] .* 1000
income_quint[:,:ypc_quint_xi0] = income_quint[:,:gdp_quint_xi0] ./ income_quint[:,:pop_quint_xi0] .* 1000
income_quint[:,:ypc_quint_xim1] = income_quint[:,:gdp_quint_xim1] ./ income_quint[:,:pop_quint_xim1] .* 1000

ypc_quint_all = stack(
    rename(income_quint, :ypc_quint_xi1 => :ypc_quint_damprop, :ypc_quint_xi0 => :ypc_quint_damindep, :ypc_quint_xim1 => :ypc_quint_daminvprop), 
    [:ypc_quint_damprop,:ypc_quint_damindep,:ypc_quint_daminvprop], 
    [:scen, :quintile, :fundregion, :year]
)
rename!(ypc_quint_all, :variable => :ypc_type, :value => :ypc_quint)
ypc_quint_all = innerjoin(ypc_quint_all,regions_fullname, on=:fundregion)
ypc_quint_all_p = ypc_quint_all[(map(x->mod(x,10)==0,ypc_quint_all[:,:year])),:]
ypc_quint_all_p[!,:ypc_type] = map(x->SubString(String(x), 14), ypc_quint_all_p[:,:ypc_type])

for s in ssps
    ypc_quint_all_p |> @filter(_.year >= 2015 && _.year <= 2100 && _.scen == s) |> @vlplot(
        mark={:point,size=60}, width=300, height=250, columns=4, wrap={"regionname:o", title=nothing, header={labelFontSize=24}}, 
        x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
        y={"ypc_quint:q", title = "GDP per capita, USD2005", axis={labelFontSize=16,titleFontSize=16}},
        color={"quintile:o",scale={scheme=:darkmulti},legend={title=string("Quintile, ",s), titleFontSize=20, titleLimit=220, symbolSize=80, labelFontSize=20}},
        shape={"ypc_type:o",legend={title = "Damages elasticity", titleFontSize=20, titleLimit=260, symbolSize=80, labelFontSize=20}},
        resolve = {scale={y=:independent}}
    ) |> save(joinpath(@__DIR__, "../results/income_ineq/", string("ypc_quint_",s,"_v5.png")))
end


############################################################## Plot remittances as percentage of total income per quintile ##############################
# Net remittances
income_quint[:,:netremgdp_quint_damprop] = income_quint[:,:netrem_quint_damprop] ./ income_quint[:,:gdp_quint_xi1]
income_quint[:,:netremgdp_quint_damindep] = income_quint[:,:netrem_quint_damindep] ./ income_quint[:,:gdp_quint_xi0]
income_quint[:,:netremgdp_quint_daminvprop] = income_quint[:,:netrem_quint_daminvprop] ./ income_quint[:,:gdp_quint_xim1]

income_quint_s = stack(
    income_quint, 
    [:netremgdp_quint_damprop,:netremgdp_quint_damindep,:netremgdp_quint_daminvprop], 
    [:scen, :quintile ,:fundregion, :year]
)
rename!(income_quint_s, :variable => :netremgdp_quint_type, :value => :netremgdp_quint)
income_quint_s[!,:damage_elasticity] = map(x->SubString(String(x),17), income_quint_s[:,:netremgdp_quint_type])
income_quint_s[!,:type_name] = [income_quint_s[i,:damage_elasticity]=="damprop" ? "proportional" : (income_quint_s[i,:damage_elasticity]=="damindep" ? "independent" : "inversely prop.") for i in 1:size(income_quint_s,1)]
income_quint_s = innerjoin(income_quint_s, regions_fullname, on =:fundregion)
for s in ssps
    income_quint_s |> @filter(_.year >= 2015 && _.year <= 2100 && _.scen == s) |> @vlplot(
        mark={:point,size=60}, width=300, height=250, columns=4, wrap={"regionname:o", title=nothing, header={labelFontSize=24}}, 
        x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
        y={"netremgdp_quint:q", title = "Net remittances as share of income", axis={labelFontSize=20,titleFontSize=20}},
        color={"quintile:o",scale={scheme=:darkmulti},legend={title = "Quintile", titleFontSize=20, symbolSize=80, labelFontSize=20}},
        shape={"type_name:o",scale={range=["circle","triangle-up","square"],domain=["proportional","independent","inversely prop."]},legend={title = "Damages elasticity", titleFontSize=20, titleLimit=260, symbolSize=80, labelFontSize=20}},
        resolve = {scale={y=:independent}}
    ) |> save(joinpath(@__DIR__, "../results/damages_ineq/", string("netremgdp_quint_",s,"_v5.png")))
end


# Remittances received
income_quint[:,:remgdp_quint_damprop] = income_quint[:,:receive_quint_xi1] ./ income_quint[:,:gdp_quint_xi1]
income_quint[:,:remgdp_quint_damindep] = income_quint[:,:receive_quint_xi0] ./ income_quint[:,:gdp_quint_xi0]
income_quint[:,:remgdp_quint_daminvprop] = income_quint[:,:receive_quint_xim1] ./ income_quint[:,:gdp_quint_xim1]

income_quint_s = stack(
    income_quint, 
    [:remgdp_quint_damprop,:remgdp_quint_damindep,:remgdp_quint_daminvprop], 
    [:scen, :quintile ,:fundregion, :year]
)
rename!(income_quint_s, :variable => :remgdp_quint_type, :value => :remgdp_quint)
income_quint_s[!,:damage_elasticity] = map(x->SubString(String(x),14), income_quint_s[:,:remgdp_quint_type])
income_quint_s[!,:type_name] = [income_quint_s[i,:damage_elasticity]=="damprop" ? "proportional" : (income_quint_s[i,:damage_elasticity]=="damindep" ? "independent" : "inversely prop.") for i in 1:size(income_quint_s,1)]
income_quint_s = innerjoin(income_quint_s, regions_fullname, on =:fundregion)
for s in ssps
    income_quint_s |> @filter(_.year >= 2015 && _.year <= 2100 && _.scen == s) |> @vlplot(
        mark={:point,size=60}, width=300, height=250, columns=4, wrap={"regionname:o", title=nothing, header={labelFontSize=24}}, 
        x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
        y={"remgdp_quint:q", title = "Remittances received / GDP", axis={labelFontSize=20,titleFontSize=20}},
        color={"quintile:o",scale={scheme=:darkmulti},legend={title = "Quintile", titleFontSize=20, symbolSize=80, labelFontSize=20}},
        shape={"type_name:o",scale={range=["circle","triangle-up","square"],domain=["proportional","independent","inversely prop."]},legend={title = "Damages elasticity", titleFontSize=20, titleLimit=260, symbolSize=80, labelFontSize=20}},
        resolve = {scale={y=:independent}}
    ) |> save(joinpath(@__DIR__, "../results/damages_ineq/", string("remgdp_quint_",s,"_v5.png")))
end

income_quint_maps = leftjoin(income_quint_s, isonum_fundregion, on = :fundregion)
for s in ssps
    for d in ["damprop","damindep","daminvprop"]
        @vlplot(width=800, height=600) + @vlplot(mark={:geoshape, stroke = :lightgray}, 
            data={values=world110m, format={type=:topojson, feature=:countries}}, 
            transform = [{lookup=:id, from={data=filter(row -> row[:scen] == s && row[:year] == 2100 && row[:damage_elasticity] == d && row[:quintile] == 1, income_quint_maps), key=:isonum, fields=[string(:remgdp_quint)]}}],
            projection={type=:naturalEarth1}, title = {text=string("SSP2-RCP4.5"),fontSize=24}, 
            color = {:remgdp_quint, type=:quantitative, scale={domain=[-0.5,0.5], scheme=:blueorange}, legend={title="Share of income", titleFontSize=20, titleLimit=260, symbolSize=60, labelFontSize=20, labelLimit=220}}
        ) |> save(joinpath(@__DIR__, "../results/world_maps_ineq/", string("remgdp_quint_q1_", s, "_", d, "_v5.png")))
    end
end

for s in ssps
    for d in ["damprop","damindep","daminvprop"]
        @vlplot(width=800, height=600) + @vlplot(mark={:geoshape, stroke = :lightgray}, 
            data={values=world110m, format={type=:topojson, feature=:countries}}, 
            transform = [{lookup=:id, from={data=filter(row -> row[:scen] == s && row[:year] == 2100 && row[:damage_elasticity] == d && row[:quintile] == 5, income_quint_maps), key=:isonum, fields=[string(:remgdp_quint)]}}],
            projection={type=:naturalEarth1}, title = {text=string("SSP2-RCP4.5"),fontSize=24}, 
            color = {:remgdp_quint, type=:quantitative, scale={domain=[-0.5,0.5], scheme=:blueorange}, legend={title="Share of income", titleFontSize=20, titleLimit=260, symbolSize=60, labelFontSize=20, labelLimit=220}}
        ) |> save(joinpath(@__DIR__, "../results/world_maps_ineq/", string("remgdp_quint_q5_", s, "_", d, "_v5.png")))
    end
end


########################################## Compare effect of remittances vs damages on income ####################################3
income_quint = innerjoin(income_quint, income_shock[:,[:year,:scen,:fundregion,:quintile,:income_shock_damprop,:income_shock_damindep,:income_shock_daminvprop]], on=[:year,:scen,:fundregion,:quintile])
income_quint[:,:remdam_quint_damprop] = income_quint[:,:remgdp_quint_damprop] .- income_quint[:,:income_shock_damprop]
income_quint[:,:remdam_quint_damindep] = income_quint[:,:remgdp_quint_damindep] .- income_quint[:,:income_shock_damindep]
income_quint[:,:remdam_quint_daminvprop] = income_quint[:,:remgdp_quint_daminvprop] .- income_quint[:,:income_shock_daminvprop]

remdam_quint_s = stack(
    income_quint, 
    [:remdam_quint_damprop,:remdam_quint_damindep,:remdam_quint_daminvprop], 
    [:scen, :quintile ,:fundregion, :year]
)
rename!(remdam_quint_s, :variable => :remdam_quint_type, :value => :remdam_quint)
remdam_quint_s[!,:damage_elasticity] = map(x->SubString(String(x),14), remdam_quint_s[:,:remdam_quint_type])
remdam_quint_s[!,:type_name] = [remdam_quint_s[i,:damage_elasticity]=="damprop" ? "proportional" : (remdam_quint_s[i,:damage_elasticity]=="damindep" ? "independent" : "inversely prop.") for i in 1:size(remdam_quint_s,1)]
remdam_quint_s = innerjoin(remdam_quint_s, regions_fullname, on =:fundregion)
for s in ssps
    remdam_quint_s |> @filter(_.year >= 2015 && _.year <= 2100 && _.scen == s) |> @vlplot(
        mark={:point,size=60}, width=300, height=250, columns=4, wrap={"regionname:o", title=nothing, header={labelFontSize=24}}, 
        x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
        y={"remdam_quint:q", title = "(Remittances-Damages)/GDP", axis={labelFontSize=20,titleFontSize=20}},
        color={"quintile:o",scale={scheme=:darkmulti},legend={title = "Quintile", titleFontSize=20, symbolSize=80, labelFontSize=20}},
        shape={"type_name:o",scale={range=["circle","triangle-up","square"],domain=["proportional","independent","inversely prop."]},legend={title = "Damages elasticity", titleFontSize=20, titleLimit=260, symbolSize=80, labelFontSize=20}},
        resolve = {scale={y=:independent}}
    ) |> save(joinpath(@__DIR__, "../results/damages_ineq/", string("remdam_quint_",s,"_v5.png")))
end
remdam_quint_p = remdam_quint_s[(map(x->mod(x,10)==0,remdam_quint_s[:,:year])),:]
remdam_quint_p[!,:scenario] = [remdam_quint_p[i,:scen]=="SSP1" ? "SSP1-RCP1.9" : (remdam_quint_p[i,:scen]=="SSP2" ? "SSP2-RCP4.5" : (remdam_quint_p[i,:scen]=="SSP3" ? "SSP3-RCP7.0" : (remdam_quint_p[i,:scen]=="SSP4" ? "SSP4-RCP6.0" : "SSP5-RCP8.5"))) for i in 1:size(remdam_quint_p,1)]
remdam_quint_p |> @filter(_.year >= 2015 && _.year <= 2100 && _.quintile == 1 && _.damage_elasticity == "daminvprop") |> @vlplot(
    mark={:line,point={filled=true,size=80}}, width=300, height=250, columns=4, wrap={"regionname:o", title=nothing, header={labelFontSize=24}}, 
    x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
    y={"remdam_quint:q", title = "(Remittances-Damages)/GDP", axis={labelFontSize=20,titleFontSize=20}},
    color={"scenario:o",scale={scheme=:category10,reverse=true},legend={title = "Scenario", titleFontSize=20, symbolSize=80, labelFontSize=20}},
    resolve = {scale={y=:independent}}
) |> save(joinpath(@__DIR__, "../results/damages_ineq/", string("remdam_quint_q1_daminvprop_v5.pdf")))

remdam_quint_maps = leftjoin(remdam_quint_s, isonum_fundregion, on = :fundregion)
for s in ssps
    for d in ["damprop","damindep","daminvprop"]
        for y in [2020, 2050, 2100]
            @vlplot(width=800, height=600) + @vlplot(mark={:geoshape, stroke = :lightgray}, 
                data={values=world110m, format={type=:topojson, feature=:countries}}, 
                transform = [{lookup=:id, from={data=filter(row -> row[:scen] == s && row[:year] == y && row[:damage_elasticity] == d && row[:quintile] == 1, remdam_quint_maps), key=:isonum, fields=[string(:remdam_quint)]}}],
                projection={type=:naturalEarth1}, title = {text=string("SSP3-RCP7.0, ", y),fontSize=24}, 
                color = {:remdam_quint, type=:quantitative, scale={domain=[-0.5,0.5], scheme=:purplegreen}, legend={title="Share of income", titleFontSize=20, titleLimit=260, symbolSize=60, labelFontSize=20, labelLimit=220}}
            ) |> save(joinpath(@__DIR__, "../results/world_maps_ineq/", string("remdam_quint_q1_", s, "_", d, "_",y ,"_v5.png")))
        end
    end
end

for s in ssps
    for d in ["damprop","damindep","daminvprop"]
        @vlplot(width=800, height=600) + @vlplot(mark={:geoshape, stroke = :lightgray}, 
            data={values=world110m, format={type=:topojson, feature=:countries}}, 
            transform = [{lookup=:id, from={data=filter(row -> row[:scen] == s && row[:year] == 2100 && row[:damage_elasticity] == d && row[:quintile] == 5, remdam_quint_maps), key=:isonum, fields=[string(:remdam_quint)]}}],
            projection={type=:naturalEarth1}, title = {text=string("SSP2-RCP4.5"),fontSize=24}, 
            color = {:remdam_quint, type=:quantitative, scale={domain=[-0.5,0.5], scheme=:purplegreen}, legend={title="Share of income", titleFontSize=20, titleLimit=260, symbolSize=60, labelFontSize=20, labelLimit=220}}
        ) |> save(joinpath(@__DIR__, "../results/world_maps_ineq/", string("remdam_quint_q5_", s, "_", d, "_v5.png")))
    end
end
