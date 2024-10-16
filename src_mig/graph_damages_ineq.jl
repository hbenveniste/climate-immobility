using DelimitedFiles, CSV, VegaLite, VegaDatasets, FileIO, FilePaths
using Statistics, DataFrames

using MimiFUND

include("main_mig_nice.jl")


ssps = ["SSP1","SSP2","SSP3","SSP4","SSP5"]
regions = ["USA", "CAN", "WEU", "JPK", "ANZ", "EEU", "FSU", "MDE", "CAM", "LAM", "SAS", "SEA", "CHI", "MAF", "SSA", "SIS"]
regions_fullname = DataFrame(
    fundregion=regions,
    regionname = ["United States","Canada","Western Europe", "Japan & South Korea","Australia & New Zealand","Central & Eastern Europe","Former Soviet Union", "Middle East", "Central America", "South America","South Asia","Southeast Asia","China plus", "North Africa","Sub-Saharan Africa","Small Island States"]
)
years = 1951:2100

world110m = dataset("world-110m")
isonum_fundregion = CSV.read(joinpath(@__DIR__,"../input_data/isonum_fundregion.csv"), DataFrame)

# Run models
m_nice_ssp1_nomig = getmigrationnicemodel(scen="SSP1",migyesno="nomig",xi=1.0,omega=1.0)
m_nice_ssp2_nomig = getmigrationnicemodel(scen="SSP2",migyesno="nomig",xi=1.0,omega=1.0)
m_nice_ssp3_nomig = getmigrationnicemodel(scen="SSP3",migyesno="nomig",xi=1.0,omega=1.0)
m_nice_ssp4_nomig = getmigrationnicemodel(scen="SSP4",migyesno="nomig",xi=1.0,omega=1.0)
m_nice_ssp5_nomig = getmigrationnicemodel(scen="SSP5",migyesno="nomig",xi=1.0,omega=1.0)
run(m_nice_ssp1_nomig;ntimesteps=151)
run(m_nice_ssp2_nomig;ntimesteps=151)
run(m_nice_ssp3_nomig;ntimesteps=151)
run(m_nice_ssp4_nomig;ntimesteps=151)
run(m_nice_ssp5_nomig;ntimesteps=151)

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


################################### Compare damages in absolute terms and in % of GDP in Mig-NICE-FUND and in NICE-FUND with SSP #####################
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
gdp_migNICEFUND = vcat(
    collect(Iterators.flatten(m_nice_ssp1_nomig[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp2_nomig[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp3_nomig[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp4_nomig[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp5_nomig[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
damages[:,:gdp_migNICEFUND] = gdp_migNICEFUND
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

damages[:,:damgdp_migNICEFUND] = damages[:,:damages_migNICEFUND] ./ (damages[:,:gdp_migNICEFUND] .* 10^9)
damages[:,:damgdp_migNICEFUND_xi0] = damages[:,:damages_migNICEFUND_xi0] ./ (damages[:,:gdp_migNICEFUND_xi0] .* 10^9)
damages[:,:damgdp_migNICEFUND_xim1] = damages[:,:damages_migNICEFUND_xim1] ./ (damages[:,:gdp_migNICEFUND_xim1] .* 10^9)
rename!(damages, :damgdp_migNICEFUND => :damgdp_damprop, :damgdp_migNICEFUND_xi0 => :damgdp_damindep, :damgdp_migNICEFUND_xim1 => :damgdp_daminvprop)


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
income_shock_s[!,:type_name] = [income_shock_s[i,:damage_elasticity]=="damprop" ? "proportional" : (income_shock_s[i,:damage_elasticity]=="damindep" ? "independent" : "inversely prop.") for i in eachindex(income_shock_s[:,1])]
income_shock_s = innerjoin(income_shock_s, regions_fullname, on =:fundregion)

# For SSP2, this gives Fig.B6
# For SSP3, this gives Fig.B7
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

# For SSP2 and SSP3 combined, this gives Fig.2
for s in ssps
    for d in ["damprop","damindep","daminvprop"]
        @vlplot(width=800, height=600) + @vlplot(mark={:geoshape, stroke = :lightgray}, 
            data={values=world110m, format={type=:topojson, feature=:countries}}, 
            transform = [{lookup=:id, from={data=filter(row -> row[:scen] == s && row[:year] == 2100 && row[:damage_elasticity] == d && row[:quintile] == 1, income_shock_maps), key=:isonum, fields=[string(:income_shock)]}}],
            projection={type=:naturalEarth1}, title = {text=string("SSP2-RCP4.5"),fontSize=24}, 
            color = {:income_shock, type=:quantitative, scale={domain=[-1.2,1.2], scheme=:blueorange}, legend={title="Share of income", titleFontSize=20, titleLimit=260, symbolSize=60, labelFontSize=20, labelLimit=220}}
        ) |> save(joinpath(@__DIR__, "../results/world_maps_ineq/", string("income_shock_q1_", s, "_", d, "_v5.png")))
    end
end
