using DelimitedFiles, CSV, VegaLite, Query
using Statistics, DataFrames

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


########################################## Compare temperature in Mig-NICE-FUND, in NICE-FUND with SSP and in FUND with original scenarios #######################
ssps = ["SSP1-RCP1.9","SSP2-RCP4.5","SSP3-RCP7.0","SSP4-RCP6.0","SSP5-RCP8.5"]
regions = ["USA", "CAN", "WEU", "JPK", "ANZ", "EEU", "FSU", "MDE", "CAM", "LAM", "SAS", "SEA", "CHI", "MAF", "SSA", "SIS"]
years = 1951:2100

temp = DataFrame(
    year = repeat(years, outer = length(ssps)),
    scen = repeat(ssps,inner = length(years)),
)

temp_migFUND = vcat(
    collect(Iterators.flatten(m_nice_ssp1_nomig[:climatedynamics,:temp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp2_nomig[:climatedynamics,:temp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp3_nomig[:climatedynamics,:temp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp4_nomig[:climatedynamics,:temp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp5_nomig[:climatedynamics,:temp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
temp[:,:temp_migFUND] = temp_migFUND
temp_sspFUND = vcat(
    collect(Iterators.flatten(m_fundnicessp1[:climatedynamics,:temp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_fundnicessp2[:climatedynamics,:temp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_fundnicessp3[:climatedynamics,:temp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_fundnicessp4[:climatedynamics,:temp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_fundnicessp5[:climatedynamics,:temp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
temp[:,:temp_sspFUND] = temp_sspFUND
temp_origFUND = vcat(collect(Iterators.flatten(m_fund[:climatedynamics,:temp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),missings(length(years)*4))
temp[:,:temp_origFUND] = temp_origFUND

temp_p = temp[(map(x->mod(x,10)==0,temp[:,:year])),:]

temp_all = stack(temp_p, [:temp_sspFUND,:temp_migFUND,:temp_origFUND], [:scen, :year])
rename!(temp_all, :variable => :temp_type, :value => :temp)
data_ssp = temp_all |> @filter(_.year <= 2100 && _.temp_type != :temp_origFUND) 
data_fund = temp_all[:,Not(:scen)] |> @filter(_.year <= 2100 && _.temp_type == :temp_origFUND) 
@vlplot() + @vlplot(
    width=300, height=250, data = data_ssp, mark={:point, size=50}, 
    x = {"year:o", axis={labelFontSize=16, values = 1950:10:2100}, title=nothing}, y = {"temp:q", title=nothing, axis={labelFontSize=16}}, 
    title = "Global temperature for FUND with original scenarios and SSP, and Mig-NICE-FUND", 
    color = {"scen:n", scale={scheme=:category10}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}, 
    shape = {"temp_type:o", scale={range=["circle", "triangle-up"]}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}
) + @vlplot(
    mark={:line, strokeDash=[1,2]}, data = data_ssp, 
    x = {"year:o", axis={labelFontSize=16, values = 1950:10:2100}, title=nothing}, y = {"temp:q", aggregate=:mean,typ=:quantitative,title=nothing, axis={labelFontSize=16}}, 
    color = {"scen:n", scale={scheme=:category10}},
    detail = "temp_type:o"
) + @vlplot(
    data = data_fund, mark={:line, strokeDash=[1,2], color = :black}, 
    x = {"year:o", axis={labelFontSize=16, values = 1950:10:2100}, title=nothing}, y = {"temp:q", aggregate=:mean,typ=:quantitative, title=nothing, axis={labelFontSize=16}}, 
    detail = "temp_type:o"
) |> save(joinpath(@__DIR__, "../results/temperature_ineq/", "temp_world_v5.png"))


########################################### Compare temperature in Mig-NICE-FUND for different income elasticities of damages (xi) #####################################
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


temp_migFUND_xi0 = vcat(
    collect(Iterators.flatten(m_nice_ssp1_nomig_xi0[:climatedynamics,:temp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp2_nomig_xi0[:climatedynamics,:temp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp3_nomig_xi0[:climatedynamics,:temp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp4_nomig_xi0[:climatedynamics,:temp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp5_nomig_xi0[:climatedynamics,:temp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
temp[:,:temp_migFUND_xi0] = temp_migFUND_xi0

temp_migFUND_xim1 = vcat(
    collect(Iterators.flatten(m_nice_ssp1_nomig_xim1[:climatedynamics,:temp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp2_nomig_xim1[:climatedynamics,:temp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp3_nomig_xim1[:climatedynamics,:temp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp4_nomig_xim1[:climatedynamics,:temp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_nice_ssp5_nomig_xim1[:climatedynamics,:temp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
temp[:,:temp_migFUND_xim1] = temp_migFUND_xim1

temp_p = temp[(map(x->mod(x,10)==0,temp[:,:year])),:]
rename!(temp_p, :temp_migFUND => :temp_damprop, :temp_migFUND_xi0 => :temp_damindep, :temp_migFUND_xim1 => :temp_daminvprop)

temp_all = stack(temp_p, [:temp_damprop,:temp_damindep,:temp_daminvprop], [:scen, :year])
rename!(temp_all, :variable => :temp_type, :value => :temp)
temp_all[!,:xi] = [SubString(String(temp_all[i,:temp_type]), 6) for i in 1:size(temp_all,1)]
temp_all |> @filter(_.year <= 2100) |> @vlplot(
    width=300, height=250, mark={:point, size=80}, 
    x = {"year:o", axis={labelFontSize=16, values = 1950:10:2100}, title=nothing}, y = {"temp:q", title="Temperature increase, degC", axis={labelFontSize=16,titleFontSize=16}}, 
    #title = "Global temperature for Mig-NICE-FUND with various income elasticities of damages", 
    color = {"scen:n", scale={scheme=:category10}, legend={title="Climate scenario", titleFontSize=20, titleLimit=220, symbolSize=60, labelFontSize=18, labelLimit=280}}, 
    shape = {"xi:o", scale={range=["circle", "triangle-up", "square","cross"]}, legend={title="income elasticity of damages", titleFontSize=20, titleLimit=220, symbolSize=60, labelFontSize=18, labelLimit=280}}
) + @vlplot(
    mark={:line, strokeDash=[1,2]}, 
    x = {"year:o", axis={labelFontSize=16, values = 1950:10:2100}, title=nothing}, y = {"temp:q", aggregate=:mean,typ=:quantitative,title="Temperature increase, degC", axis={labelFontSize=16,titleFontSize=16}}, 
    color = {"scen:n", scale={scheme=:category10}, legend={title="Climate scenario", titleFontSize=20, titleLimit=220, symbolSize=60, labelFontSize=18, labelLimit=280}},
    detail = "xi:o"
) |> save(joinpath(@__DIR__, "../results/temperature_ineq/", "temp_world_xi_v5.png"))
