using DelimitedFiles, CSV, VegaLite, VegaDatasets, FileIO, FilePaths
using Statistics, DataFrames, Query

using MimiFUND

include("main_mig_nice.jl")

ssps = ["SSP1","SSP2","SSP3","SSP4","SSP5"]
regions = ["USA", "CAN", "WEU", "JPK", "ANZ", "EEU", "FSU", "MDE", "CAM", "LAM", "SAS", "SEA", "CHI", "MAF", "SSA", "SIS"]
years = 1951:2100
world110m = dataset("world-110m")

isonum_fundregion = CSV.read(joinpath(@__DIR__,"../input_data/isonum_fundregion.csv"),DataFrame)
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


# Run models
m_nice_ssp1_nomig = getmigrationnicemodel(scen="SSP1",migyesno="nomig",xi=1.0,omega=1.0)
m_nice_ssp2_nomig = getmigrationnicemodel(scen="SSP2",migyesno="nomig",xi=1.0,omega=1.0)
m_nice_ssp3_nomig = getmigrationnicemodel(scen="SSP3",migyesno="nomig",xi=1.0,omega=1.0)
m_nice_ssp4_nomig = getmigrationnicemodel(scen="SSP4",migyesno="nomig",xi=1.0,omega=1.0)
m_nice_ssp5_nomig = getmigrationnicemodel(scen="SSP5",migyesno="nomig",xi=1.0,omega=1.0)

run(m_nice_ssp1_nomig)
run(m_nice_ssp2_nomig)
run(m_nice_ssp3_nomig)
run(m_nice_ssp4_nomig)
run(m_nice_ssp5_nomig)

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
netrem_quint_all_p[!,:type_name] = [netrem_quint_all_p[i,:netrem_type]=="damprop" ? "proportional" : (netrem_quint_all_p[i,:netrem_type]=="damindep" ? "independent" : "inversely prop.") for i in eachindex(netrem_quint_all_p[:,1])]

# For SSP2, this gives Fig.B3
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


########################################## Compare effect of remittances vs damages on income ####################################3
# Remittances received
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
income_quint[:,:remgdp_quint_damprop] = income_quint[:,:receive_quint_xi1] ./ income_quint[:,:gdp_quint_xi1]
income_quint[:,:remgdp_quint_damindep] = income_quint[:,:receive_quint_xi0] ./ income_quint[:,:gdp_quint_xi0]
income_quint[:,:remgdp_quint_daminvprop] = income_quint[:,:receive_quint_xim1] ./ income_quint[:,:gdp_quint_xim1]

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
remdam_quint_s[!,:type_name] = [remdam_quint_s[i,:damage_elasticity]=="damprop" ? "proportional" : (remdam_quint_s[i,:damage_elasticity]=="damindep" ? "independent" : "inversely prop.") for i in eachindex(remdam_quint_s[:,1])]
remdam_quint_s = innerjoin(remdam_quint_s, regions_fullname, on =:fundregion)
remdam_quint_p = remdam_quint_s[(map(x->mod(x,10)==0,remdam_quint_s[:,:year])),:]
remdam_quint_p[!,:scenario] = [remdam_quint_p[i,:scen]=="SSP1" ? "SSP1-RCP1.9" : (remdam_quint_p[i,:scen]=="SSP2" ? "SSP2-RCP4.5" : (remdam_quint_p[i,:scen]=="SSP3" ? "SSP3-RCP7.0" : (remdam_quint_p[i,:scen]=="SSP4" ? "SSP4-RCP6.0" : "SSP5-RCP8.5"))) for i in eachindex(remdam_quint_p[:,1])]

remdam_quint_p |> @filter(_.year >= 2015 && _.year <= 2100 && _.quintile == 1 && _.damage_elasticity == "daminvprop") |> @vlplot(
    mark={:line,point={filled=true,size=80}}, width=300, height=250, columns=4, wrap={"regionname:o", title=nothing, header={labelFontSize=24}}, 
    x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
    y={"remdam_quint:q", title = "(Remittances-Damages)/GDP", axis={labelFontSize=20,titleFontSize=20}},
    color={"scenario:o",scale={scheme=:category10,reverse=true},legend={title = "Scenario", titleFontSize=20, symbolSize=80, labelFontSize=20}},
    resolve = {scale={y=:independent}}
) |> save(joinpath(@__DIR__, "../results/damages_ineq/", string("Fig3.png")))

remdam_quint_p |> @filter(_.year >= 2015 && _.year <= 2100 && _.quintile == 1 && _.damage_elasticity == "damindep") |> @vlplot(
    mark={:line,point={filled=true,size=80}}, width=300, height=250, columns=4, wrap={"regionname:o", title=nothing, header={labelFontSize=24}}, 
    x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
    y={"remdam_quint:q", title = "(Remittances-Damages)/GDP", axis={labelFontSize=20,titleFontSize=20}},
    color={"scenario:o",scale={scheme=:category10,reverse=true},legend={title = "Scenario", titleFontSize=20, symbolSize=80, labelFontSize=20}},
    resolve = {scale={y=:independent}}
) |> save(joinpath(@__DIR__, "../results/damages_ineq/", string("FigB8.png")))
