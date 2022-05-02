using DelimitedFiles, CSV, VegaLite, FileIO, VegaDatasets, FilePaths
using Statistics, DataFrames, Query

using MimiFUND

include("main_mig_nice.jl")
include("fund_ssp_ineq.jl")

################################# Compare NICE-FUND with SSP scenarios, and Mig-NICE-FUND with SSP scenarios zero migration ###############################

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

# Try to understand whether discrepancies between Mig-NICE-FUND and SSP are due to input Gini scenarios with zero migration
m_fundnicessp1_nomig = getsspnicemodel(scen="SSP1",migyesno="nomig",xi=1.0,omega=1.0)
m_fundnicessp2_nomig = getsspnicemodel(scen="SSP2",migyesno="nomig",xi=1.0,omega=1.0)
m_fundnicessp3_nomig = getsspnicemodel(scen="SSP3",migyesno="nomig",xi=1.0,omega=1.0)
m_fundnicessp4_nomig = getsspnicemodel(scen="SSP4",migyesno="nomig",xi=1.0,omega=1.0)
m_fundnicessp5_nomig = getsspnicemodel(scen="SSP5",migyesno="nomig",xi=1.0,omega=1.0)

run(m_fundnicessp1_nomig)
run(m_fundnicessp2_nomig)
run(m_fundnicessp3_nomig)
run(m_fundnicessp4_nomig)
run(m_fundnicessp5_nomig)


################################ Compare inequality (Gini) in Mig-NICE-FUND and in NICE-FUND with SSP #######################3
ssps = ["SSP1","SSP2","SSP3","SSP4","SSP5"]
regions = ["USA", "CAN", "WEU", "JPK", "ANZ", "EEU", "FSU", "MDE", "CAM", "LAM", "SAS", "SEA", "CHI", "MAF", "SSA", "SIS"]
years = 1950:2100

ssp_gini = CSV.read(joinpath(@__DIR__, "../../yssp/data/gini_rao/ssp_ginis.csv"),DataFrame)

gini = DataFrame(
    year = repeat(years, outer = length(ssps)*length(regions)),
    scen = repeat(ssps,inner = length(regions)*length(years)),
    fundregion = repeat(regions, outer = length(ssps), inner=length(years))
)

gini_migNICEFUND = vcat(
    collect(Iterators.flatten(m_nice_ssp1_nomig[:socioeconomic,:inequality][MimiFUND.getindexfromyear(1950):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp2_nomig[:socioeconomic,:inequality][MimiFUND.getindexfromyear(1950):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp3_nomig[:socioeconomic,:inequality][MimiFUND.getindexfromyear(1950):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp4_nomig[:socioeconomic,:inequality][MimiFUND.getindexfromyear(1950):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp5_nomig[:socioeconomic,:inequality][MimiFUND.getindexfromyear(1950):MimiFUND.getindexfromyear(2100),:]))
)
gini[:,:gini_migNICEFUND] = gini_migNICEFUND
gini_sspNICEFUND = vcat(
    collect(Iterators.flatten(m_fundnicessp1[:socioeconomic,:inequality][MimiFUND.getindexfromyear(1950):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_fundnicessp2[:socioeconomic,:inequality][MimiFUND.getindexfromyear(1950):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_fundnicessp3[:socioeconomic,:inequality][MimiFUND.getindexfromyear(1950):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_fundnicessp4[:socioeconomic,:inequality][MimiFUND.getindexfromyear(1950):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_fundnicessp5[:socioeconomic,:inequality][MimiFUND.getindexfromyear(1950):MimiFUND.getindexfromyear(2100),:]))
)
gini[:,:gini_sspNICEFUND] = gini_sspNICEFUND
gini_ssp = vcat(
    collect(Iterators.flatten(m_fundnicessp1[:scenconverter,:inequality][MimiFUND.getindexfromyear(1950):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_fundnicessp2[:scenconverter,:inequality][MimiFUND.getindexfromyear(1950):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_fundnicessp3[:scenconverter,:inequality][MimiFUND.getindexfromyear(1950):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_fundnicessp4[:scenconverter,:inequality][MimiFUND.getindexfromyear(1950):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_fundnicessp5[:scenconverter,:inequality][MimiFUND.getindexfromyear(1950):MimiFUND.getindexfromyear(2100),:]))
)
gini[:,:gini_ssp] = gini_ssp
gini_sspNICEFUND_nomig = vcat(
    collect(Iterators.flatten(m_fundnicessp1_nomig[:socioeconomic,:inequality][MimiFUND.getindexfromyear(1950):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_fundnicessp2_nomig[:socioeconomic,:inequality][MimiFUND.getindexfromyear(1950):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_fundnicessp3_nomig[:socioeconomic,:inequality][MimiFUND.getindexfromyear(1950):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_fundnicessp4_nomig[:socioeconomic,:inequality][MimiFUND.getindexfromyear(1950):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_fundnicessp5_nomig[:socioeconomic,:inequality][MimiFUND.getindexfromyear(1950):MimiFUND.getindexfromyear(2100),:]))
)
gini[:,:gini_sspNICEFUND_nomig] = gini_sspNICEFUND_nomig
gini_nocc = vcat(
    collect(Iterators.flatten(m_nice_ssp1_nocc[:socioeconomic,:inequality][MimiFUND.getindexfromyear(1950):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp2_nocc[:socioeconomic,:inequality][MimiFUND.getindexfromyear(1950):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp3_nocc[:socioeconomic,:inequality][MimiFUND.getindexfromyear(1950):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp4_nocc[:socioeconomic,:inequality][MimiFUND.getindexfromyear(1950):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp5_nocc[:socioeconomic,:inequality][MimiFUND.getindexfromyear(1950):MimiFUND.getindexfromyear(2100),:]))
)
gini[:,:gini_nocc_migNICEFUND] = gini_nocc

gini_p = gini[(map(x->mod(x,10)==0,gini[:,:year])),:]

gini_all = stack(gini_p, [:gini_sspNICEFUND,:gini_migNICEFUND,:gini_ssp], [:scen, :fundregion, :year])
rename!(gini_all, :variable => :gini_type, :value => :gini)
for r in regions
    data_ssp = gini_all |> @filter(_.year <= 2100 && _.year >= 2015  && _.fundregion==r) 
    @vlplot() + @vlplot(
        width=300, height=250, data = data_ssp,
        mark={:point, size=30}, x = {"year:o", axis={labelFontSize=16}, title=nothing}, y = {"gini:q", title=nothing, axis={labelFontSize=16}}, 
        color = {"scen:n", scale={scheme=:category10}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}, 
        shape = {"gini_type:o", legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}
    ) + @vlplot(
        mark={:line, strokeDash=[1,2]}, data = data_ssp, x = {"year:o", axis={labelFontSize=16}, title=nothing}, y = {"gini:q", aggregate=:mean,type=:quantitative,title=nothing, axis={labelFontSize=16}}, 
        color = {"scen:n", scale={scheme=:category10}},
        detail = "gini_type:o"
    ) |> save(joinpath(@__DIR__, "../results/inequality/", string("gini_", r, "_v5.png")))
end

regions_fullname = DataFrame(
    fundregion=regions,
    regionname = ["United States","Canada","Western Europe", "Japan & South Korea","Australia & New Zealand","Central & Eastern Europe","Former Soviet Union", "Middle East", "Central America", "South America","South Asia","Southeast Asia","China plus", "North Africa","Sub-Saharan Africa","Small Island States"]
)
gini_all = innerjoin(gini_all, regions_fullname, on=:fundregion)
gini_all[:,:gini_type] = map(x->SubString(String(x),6), gini_all[:,:gini_type])
gini_all[!,:type_name] = [gini_all[i,:gini_type]=="ssp" ? "Original SSP" : (gini_all[i,:gini_type]=="sspNICEFUND" ? "FUND + income dist." : "FUND + income dist. + migration") for i in 1:size(gini_all,1)]

gini_all |> @filter(_.year <= 2100 && _.year >= 2015) |> @vlplot(
    width=300, height=250, columns=4, wrap={"regionname:o", title=nothing, header={labelFontSize=24}}, mark={:point, size=80}, 
    x = {"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing}, 
    y = {"gini:q", title="Gini coefficient", axis={labelFontSize=20,titleFontSize=20}}, 
    color = {"scen:n", scale={scheme=:category10}, legend={title="Scenario",titleFontSize=20, symbolSize=80, labelFontSize=20}}, 
    shape = {"type_name:o",scale={range=["circle","triangle-up","square"],domain=["Original SSP","FUND + income dist.","FUND + income dist. + migration"]}, legend={title="Model type",titleFontSize=20, symbolSize=80, labelFontSize=16, labelLimit = 240}}
) |> save(joinpath(@__DIR__, "../results/inequality/", string("gini_v5.png")))
# Not really a matter of input scenarios: does not cover the increase in Gini for destination regions

gini_nocc_all = stack(gini_p, [:gini_migNICEFUND,:gini_nocc_migNICEFUND], [:scen, :fundregion, :year])
rename!(gini_nocc_all, :variable => :gini_type, :value => :gini)
gini_nocc_all = innerjoin(gini_nocc_all, regions_fullname, on=:fundregion)
gini_nocc_all[:,:run_type] = map(x->SubString(String(x),6), gini_nocc_all[:,:gini_type])
gini_nocc_all |> @filter(_.year <= 2100 && _.year >= 2015) |> @vlplot(
    width=300, height=250, columns=4, wrap={"regionname:o", title=nothing, header={labelFontSize=24}}, mark={:point, size=60}, 
    x = {"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing}, 
    y = {"gini:q", title=nothing, axis={labelFontSize=16}}, 
    color = {"scen:n", scale={scheme=:category10}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}, 
    shape = {"run_type:o", legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}
) |> save(joinpath(@__DIR__, "../results/inequality/", string("gini_nocc_v5.png")))


######################################### Compare inequality in Mig-NICE-FUND for different income elasticities of damages (xi) #######################
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


gini_migNICEFUND_xi0 = vcat(
    collect(Iterators.flatten(m_nice_ssp1_nomig_xi0[:socioeconomic,:inequality][MimiFUND.getindexfromyear(1950):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp2_nomig_xi0[:socioeconomic,:inequality][MimiFUND.getindexfromyear(1950):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp3_nomig_xi0[:socioeconomic,:inequality][MimiFUND.getindexfromyear(1950):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp4_nomig_xi0[:socioeconomic,:inequality][MimiFUND.getindexfromyear(1950):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp5_nomig_xi0[:socioeconomic,:inequality][MimiFUND.getindexfromyear(1950):MimiFUND.getindexfromyear(2100),:]))
)
gini[:,:gini_migNICEFUND_xi0] = gini_migNICEFUND_xi0
gini_sspNICEFUND_xi0 = vcat(
    collect(Iterators.flatten(m_fundnicessp1_xi0[:socioeconomic,:inequality][MimiFUND.getindexfromyear(1950):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_fundnicessp2_xi0[:socioeconomic,:inequality][MimiFUND.getindexfromyear(1950):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_fundnicessp3_xi0[:socioeconomic,:inequality][MimiFUND.getindexfromyear(1950):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_fundnicessp4_xi0[:socioeconomic,:inequality][MimiFUND.getindexfromyear(1950):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_fundnicessp5_xi0[:socioeconomic,:inequality][MimiFUND.getindexfromyear(1950):MimiFUND.getindexfromyear(2100),:]))
)
gini[:,:gini_sspNICEFUND_xi0] = gini_sspNICEFUND_xi0

gini_migNICEFUND_xim1 = vcat(
    collect(Iterators.flatten(m_nice_ssp1_nomig_xim1[:socioeconomic,:inequality][MimiFUND.getindexfromyear(1950):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp2_nomig_xim1[:socioeconomic,:inequality][MimiFUND.getindexfromyear(1950):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp3_nomig_xim1[:socioeconomic,:inequality][MimiFUND.getindexfromyear(1950):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp4_nomig_xim1[:socioeconomic,:inequality][MimiFUND.getindexfromyear(1950):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp5_nomig_xim1[:socioeconomic,:inequality][MimiFUND.getindexfromyear(1950):MimiFUND.getindexfromyear(2100),:]))
)
gini[:,:gini_migNICEFUND_xim1] = gini_migNICEFUND_xim1
gini_sspNICEFUND_xim1 = vcat(
    collect(Iterators.flatten(m_fundnicessp1_xim1[:socioeconomic,:inequality][MimiFUND.getindexfromyear(1950):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_fundnicessp2_xim1[:socioeconomic,:inequality][MimiFUND.getindexfromyear(1950):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_fundnicessp3_xim1[:socioeconomic,:inequality][MimiFUND.getindexfromyear(1950):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_fundnicessp4_xim1[:socioeconomic,:inequality][MimiFUND.getindexfromyear(1950):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_fundnicessp5_xim1[:socioeconomic,:inequality][MimiFUND.getindexfromyear(1950):MimiFUND.getindexfromyear(2100),:]))
)
gini[:,:gini_sspNICEFUND_xim1] = gini_sspNICEFUND_xim1

gini_p = gini[(map(x->mod(x,10)==0,gini[:,:year])),:]

gini_xi_all = stack(gini_p, [:gini_sspNICEFUND,:gini_sspNICEFUND_xi0,:gini_sspNICEFUND_xim1], [:scen, :fundregion, :year])
rename!(gini_xi_all, :variable => :gini_type, :value => :gini)
for r in regions
    data_ssp = gini_xi_all |> @filter(_.year <= 2100 && _.year >= 2015  && _.fundregion==r) 
    @vlplot() + @vlplot(
        width=300, height=250, data = data_ssp,
        mark={:point, size=30}, x = {"year:o", axis={labelFontSize=16}, title=nothing}, y = {"gini:q", title=nothing, axis={labelFontSize=16}}, 
        title = string("Gini of region ",r," for SSP, NICE-FUND with SSP and Mig-NICE-FUND with SSP zero migration"), 
        color = {"scen:n", scale={scheme=:category10}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}, 
        shape = {"gini_type:o", legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}
    ) + @vlplot(
        mark={:line, strokeDash=[1,2]}, data = data_ssp, x = {"year:o", axis={labelFontSize=16}, title=nothing}, y = {"gini:q", aggregate=:mean,type=:quantitative,title=nothing, axis={labelFontSize=16}}, 
        color = {"scen:n", scale={scheme=:category10}},
        detail = "gini_type:o"
    ) |> save(joinpath(@__DIR__, "../results/inequality/", string("gini_fundnice_xi_", r, "_v5.png")))
end

gini_xi_all = stack(gini_p, [:gini_migNICEFUND,:gini_migNICEFUND_xi0,:gini_migNICEFUND_xim1], [:scen, :fundregion, :year])
rename!(gini_xi_all, :variable => :gini_type, :value => :gini)
gini_xi_all[!,:gini_type] = map(x->SubString(string(x),6), gini_xi_all[:,:gini_type])
gini_xi_all[!,:xi] = [gini_xi_all[i,:gini_type]=="migNICEFUND" ? "proportional" : (gini_xi_all[i,:gini_type]=="migNICEFUND_xi0" ? "independent" : "inversely prop.") for i in 1:size(gini_xi_all,1)]

gini_xi_all = innerjoin(gini_xi_all, regions_fullname, on=:fundregion)

for r in regions
    data_ssp = gini_xi_all |> @filter(_.year <= 2100 && _.year >= 2015  && _.fundregion==r) 
    @vlplot() + @vlplot(
        width=300, height=250, data = data_ssp,
        mark={:point, size=30}, x = {"year:o", axis={labelFontSize=16}, title=nothing}, y = {"gini:q", title=nothing, axis={labelFontSize=16}}, 
        title = string("Gini of region ",r), 
        color = {"scen:n", scale={scheme=:category10}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}, 
        shape = {"gini_type:o", legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}
    ) + @vlplot(
        mark={:line, strokeDash=[1,2]}, data = data_ssp, x = {"year:o", axis={labelFontSize=16}, title=nothing}, y = {"gini:q", aggregate=:mean,type=:quantitative,title=nothing, axis={labelFontSize=16}}, 
        color = {"scen:n", scale={scheme=:category10}},
        detail = "gini_type:o"
    ) |> save(joinpath(@__DIR__, "../results/inequality/", string("gini_mignice_xi_", r, "_v5.png")))
end

data_ssp = gini_xi_all |> @filter(_.year <= 2100 && _.year >= 2015) |> @vlplot(
    width=300, height=250, columns=4, wrap={"regionname:o", title=nothing, header={labelFontSize=24}}, mark={:point, size=80}, 
    x = {"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing}, 
    y = {"gini:q", title="Gini coefficient", axis={labelFontSize=20,titleFontSize=20}}, 
    color = {"scen:n", scale={scheme=:category10}, legend={title="Scenario",titleFontSize=20, symbolSize=80, labelFontSize=20}}, 
    shape = {"xi:o", scale={range=["circle","triangle-up","square"],domain=["proportional","independent","inversely prop."]}, legend={title="Damages elasticity",titleFontSize=20, titleLimit=260, symbolSize=80, labelFontSize=20}}
) |> save(joinpath(@__DIR__, "../results/inequality/", string("gini_mignice_xi_v5.png")))