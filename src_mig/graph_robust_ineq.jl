using DelimitedFiles, CSV, VegaLite, FileIO, VegaDatasets, FilePaths
using Statistics, DataFrames, Query, Distributions

using Mimi, MimiFUND

include("main_mig_nice.jl")


ssps = ["SSP1","SSP2","SSP3","SSP4","SSP5"]
regions = ["USA", "CAN", "WEU", "JPK", "ANZ", "EEU", "FSU", "MDE", "CAM", "LAM", "SAS", "SEA", "CHI", "MAF", "SSA", "SIS"]
regions_fullname = DataFrame(
    fundregion=regions,
    regionname = ["United States","Canada","Western Europe", "Japan & South Korea","Australia & New Zealand","Central & Eastern Europe","Former Soviet Union", "Middle East", "Central America", "South America","South Asia","Southeast Asia","China plus", "North Africa","Sub-Saharan Africa","Small Island States"]
)
years = 1951:2100

world110m = dataset("world-110m")
isonum_fundregion = CSV.read(joinpath(@__DIR__,"../input_data/isonum_fundregion.csv"),DataFrame)


########################################## Run models with zero CO2 fertilization ####################################################
# Test for when we divide the CO2 fertilization effect by 10, and multiply all other damages by 10.
m_nice_ssp2_nofert_xim1 = getmigrationnicemodel(scen="SSP2",migyesno="nomig",xi=-1.0,omega=1.0)
update_param!(m_nice_ssp2_nofert_xim1, :agcbm, map(x->x/10,m_nice_ssp2_nomig[:impactagriculture,:agcbm]))
set_param!(m_nice_ssp2_nofert_xim1, :consleak, 2.5)
run(m_nice_ssp2_nofert_xim1;ntimesteps=151)

migration_quint_nofert = DataFrame(
    year = repeat(years, outer = length(regions)*5),
    fundregion = repeat(regions, outer = 5, inner=length(years)),
    quintile = repeat(1:5, inner=length(years)*length(regions))
)
leave_quint_nofert_xim1 = collect(Iterators.flatten(m_nice_ssp2_nofert_xim1[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))
migration_quint_nofert[:,:leave_quint_nofert_xim1] = leave_quint_nofert_xim1
leave_quint_nocc_xim1 = collect(Iterators.flatten(m_nice_ssp2_nocc_xim1[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))
migration_quint_nofert[:,:leave_quint_nocc_xim1] = leave_quint_nocc_xim1
migration_quint_nofert[!,:leave_quint_diff_xim1] = migration_quint_nofert[:,:leave_quint_nofert_xim1] .- migration_quint_nofert[:,:leave_quint_nocc_xim1]

# Look at emigrants without residual from gravity (residual same for all SSP, xi, CC or not)
migration_quint_nofert[!,:leave_quint_gravres] = repeat(collect(Iterators.flatten(sum(m_nice_ssp2_nocc_xim1[:migration,:gravres_qi],dims=[2,4])[:,1,:,1])),inner=length(1951:2100))

migration_quint_nofert[!,:leave_quint_ccshare_xim1] = (migration_quint_nofert[:,:leave_quint_nofert_xim1] .- migration_quint_nofert[:,:leave_quint_nocc_xim1]) ./ (migration_quint_nofert[:,:leave_quint_nocc_xim1] .- migration_quint_nofert[:,:leave_quint_gravres])

migration_quint_nofert_p = migration_quint_nofert[(map(x->mod(x,10)==0,migration_quint_nofert[:,:year])),:]

migration_quint_nofert_p = innerjoin(migration_quint_nofert_p, regions_fullname, on=:fundregion)

# Plot graph over time
migration_quint_nofert_p |> @filter(_.year >= 2015 && _.year <= 2100) |> @vlplot(
    mark={:point,filled=true,size=80}, width=300, height=250, columns=4, wrap={"regionname:o", title=nothing, header={labelFontSize=24}}, 
    x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
    y={"leave_quint_ccshare_xim1:q", title = "CC effect on total emigrants", axis={labelFontSize=20,titleFontSize=20}},
    color={"quintile:o",scale={scheme=:darkmulti},legend={title = "Quintile", titleFontSize=20, symbolSize=80, labelFontSize=20}},
    resolve = {scale={y=:independent}}
) |> save(joinpath(@__DIR__, "../results/migflow_ineq/", string("FigB12_update.png")))


########################################## Run models with original SSP quantifications ####################################################
# Run models for SSP2
# Damages within a given region proportional to income (xi=1)
m_nice_ssp2_orig = getmigrationnicemodel(scen="SSP2",migyesno="mig",xi=1.0,omega=1.0)
run(m_nice_ssp2_orig;ntimesteps=151)

# Damages within a given region independent of income (xi=0)
m_nice_ssp2_orig_xi0 = getmigrationnicemodel(scen="SSP2",migyesno="mig",xi=0.0,omega=1.0)
run(m_nice_ssp2_orig_xi0;ntimesteps=151)

# Damages within a given region inversely proportional to income (xi=-1)
m_nice_ssp2_orig_xim1 = getmigrationnicemodel(scen="SSP2",migyesno="mig",xi=-1.0,omega=1.0)
run(m_nice_ssp2_orig_xim1;ntimesteps=151)

# Compare to without climate change
m_fund = getfund()
run(m_fund)

# Damages proportional to income
m_nice_ssp2_orig_nocc = getmigrationnicemodel(scen="SSP2",migyesno="mig",xi=1.0,omega=1.0)
set_param!(m_nice_ssp2_orig_nocc,:runwithoutdamage, true)
update_param!(m_nice_ssp2_orig_nocc,:currtax, m_fund[:emissions,:currtax])
run(m_nice_ssp2_orig_nocc;ntimesteps=151)

# Damages independent of income between regions
m_nice_ssp2_orig_nocc_xi0 = getmigrationnicemodel(scen="SSP2",migyesno="mig",xi=0.0,omega=1.0)
set_param!(m_nice_ssp2_orig_nocc_xi0,:runwithoutdamage, true)
update_param!(m_nice_ssp2_orig_nocc_xi0,:currtax, m_fund[:emissions,:currtax])
run(m_nice_ssp2_orig_nocc_xi0;ntimesteps=151)

# Damages inversely proportional to income between regions
m_nice_ssp2_orig_nocc_xim1 = getmigrationnicemodel(scen="SSP2",migyesno="mig",xi=-1.0,omega=1.0)
set_param!(m_nice_ssp2_orig_nocc_xim1,:runwithoutdamage, true)
update_param!(m_nice_ssp2_orig_nocc_xim1,:currtax, m_fund[:emissions,:currtax])
run(m_nice_ssp2_orig_nocc_xim1;ntimesteps=151)

migration_quint_orig = DataFrame(
    year = repeat(years, outer = length(regions)*5),
    fundregion = repeat(regions, outer = 5, inner=length(years)),
    quintile = repeat(1:5, inner=length(years)*length(regions))
)

migration_quint_orig[:,:leave_quint_xi1] = collect(Iterators.flatten(m_nice_ssp2_orig[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))
migration_quint_orig[:,:leave_quint_xi0] = collect(Iterators.flatten(m_nice_ssp2_orig_xi0[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))
migration_quint_orig[:,:leave_quint_xim1] = collect(Iterators.flatten(m_nice_ssp2_orig_xim1[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))

# Look at emigrants without residual from gravity (residual same for all SSP, xi, CC or not)
migration_quint_orig[!,:leave_quint_gravres] = repeat(collect(Iterators.flatten(sum(m_nice_ssp2_orig[:migration,:gravres_qi],dims=[2,4])[:,1,:,1])),inner=length(1951:2100))

# Plot differences in migration with and without climate change for each quintile
migration_quint_orig[:,:leave_quint_nocc_xi1] = collect(Iterators.flatten(m_nice_ssp2_orig_nocc[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))
migration_quint_orig[:,:leave_quint_nocc_xi0] = collect(Iterators.flatten(m_nice_ssp2_orig_nocc_xi0[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))
migration_quint_orig[:,:leave_quint_nocc_xim1] = collect(Iterators.flatten(m_nice_ssp2_orig_nocc_xim1[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))

migration_quint_orig[!,:leave_quint_diff_xi1] = migration_quint_orig[:,:leave_quint_xi1] .- migration_quint_orig[:,:leave_quint_nocc_xi1]
migration_quint_orig[!,:leave_quint_diff_xi0] = migration_quint_orig[:,:leave_quint_xi0] .- migration_quint_orig[:,:leave_quint_nocc_xi0]
migration_quint_orig[!,:leave_quint_diff_xim1] = migration_quint_orig[:,:leave_quint_xim1] .- migration_quint_orig[:,:leave_quint_nocc_xim1]

migration_quint_orig[!,:leave_quint_ccshare_xi1] = (migration_quint_orig[:,:leave_quint_xi1] .- migration_quint_orig[:,:leave_quint_nocc_xi1]) ./ (migration_quint_orig[:,:leave_quint_nocc_xi1] .- migration_quint_orig[:,:leave_quint_gravres])
migration_quint_orig[!,:leave_quint_ccshare_xi0] = (migration_quint_orig[:,:leave_quint_xi0] .- migration_quint_orig[:,:leave_quint_nocc_xi0]) ./ (migration_quint_orig[:,:leave_quint_nocc_xi0] .- migration_quint_orig[:,:leave_quint_gravres])
migration_quint_orig[!,:leave_quint_ccshare_xim1] = (migration_quint_orig[:,:leave_quint_xim1] .- migration_quint_orig[:,:leave_quint_nocc_xim1]) ./ (migration_quint_orig[:,:leave_quint_nocc_xim1] .- migration_quint_orig[:,:leave_quint_gravres])

migration_quint_orig_p = migration_quint_orig[(map(x->mod(x,10)==0,migration_quint_orig[:,:year])),:]

leave_quint_ccshare_orig = stack(
    rename(migration_quint_orig_p, :leave_quint_ccshare_xi1 => :leave_quint_ccshare_damageprop, :leave_quint_ccshare_xi0 => :leave_quint_ccshare_damageindep, :leave_quint_ccshare_xim1 => :leave_quint_ccshare_damageinvprop), 
    [:leave_quint_ccshare_damageprop,:leave_quint_ccshare_damageindep,:leave_quint_ccshare_damageinvprop], 
    [:quintile ,:fundregion, :year]
)
rename!(leave_quint_ccshare_orig, :variable => :leave_type, :value => :leave_quint_ccshare_nocc)
leave_quint_ccshare_orig[!,:damage_elasticity] = map(x->SubString(string(x),21),leave_quint_ccshare_orig[:,:leave_type])
leave_quint_ccshare_orig[!,:type_name] = [leave_quint_ccshare_orig[i,:damage_elasticity]=="damageprop" ? "proportional" : (leave_quint_ccshare_orig[i,:damage_elasticity]=="damageindep" ? "independent" : "inversely prop.") for i in eachindex(leave_quint_ccshare_orig[:,1])]
leave_quint_ccshare_orig = innerjoin(leave_quint_ccshare_orig, regions_fullname, on=:fundregion)

# For SSP2 and original SSP quantifications, this gives Fig.B10
leave_quint_ccshare_orig |> @filter(_.year >= 2015 && _.year <= 2100) |> @vlplot(
    mark={:point,size=60}, width=300, height=250, columns=4, wrap={"regionname:o", title=nothing, header={labelFontSize=24}}, 
    x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
    y={"leave_quint_ccshare_nocc:q", title = "CC effect on total emigrants", axis={labelFontSize=20,titleFontSize=20}},
    color={"quintile:o",scale={scheme=:darkmulti},legend={title = "Quintile", titleFontSize=20, symbolSize=80, labelFontSize=20}},
    shape={"type_name:o",scale={range=["circle","triangle-up","square"],domain=["proportional","independent","inversely prop."]},legend={title = "Damages elasticity", titleFontSize=20, titleLimit=260, symbolSize=80, labelFontSize=20}},
    resolve = {scale={y=:independent}}
) |> save(joinpath(@__DIR__, "../results/migflow_ineq/", string("B10_update.png")))


########################################## Run models with remittances catching up with damages ####################################################
# Run models for SSP2
# Damages within a given region proportional to income (xi=1)
m_nice_ssp2_catch = getmigrationnicemodel(scen="SSP2",migyesno="nomig",xi=1.0,omega=1.0)
set_param!(m_nice_ssp2_catch,:runremcatchupdam, true)
run(m_nice_ssp2_catch;ntimesteps=151)

# Damages within a given region independent of income (xi=0)
m_nice_ssp2_catch_xi0 = getmigrationnicemodel(scen="SSP2",migyesno="nomig",xi=0.0,omega=1.0)
set_param!(m_nice_ssp2_catch_xi0,:runremcatchupdam, true)
run(m_nice_ssp2_catch_xi0;ntimesteps=151)

# Damages within a given region inversely proportional to income (xi=-1)
m_nice_ssp2_catch_xim1 = getmigrationnicemodel(scen="SSP2",migyesno="nomig",xi=-1.0,omega=1.0)
set_param!(m_nice_ssp2_catch_xim1,:runremcatchupdam, true)
run(m_nice_ssp2_catch_xim1;ntimesteps=151)

# Compare to without climate change
# Damages proportional to income
m_nice_ssp2_catch_nocc = getmigrationnicemodel(scen="SSP2",migyesno="nomig",xi=1.0,omega=1.0)
set_param!(m_nice_ssp2_catch_nocc,:runremcatchupdam, true)
set_param!(m_nice_ssp2_catch_nocc,:runwithoutdamage, true)
update_param!(m_nice_ssp2_catch_nocc,:currtax, m_fund[:emissions,:currtax])
run(m_nice_ssp2_catch_nocc;ntimesteps=151)

# Damages independent of income between regions
m_nice_ssp2_catch_nocc_xi0 = getmigrationnicemodel(scen="SSP2",migyesno="nomig",xi=0.0,omega=1.0)
set_param!(m_nice_ssp2_catch_nocc_xi0,:runremcatchupdam, true)
set_param!(m_nice_ssp2_catch_nocc_xi0,:runwithoutdamage, true)
update_param!(m_nice_ssp2_catch_nocc_xi0,:currtax, m_fund[:emissions,:currtax])
run(m_nice_ssp2_catch_nocc_xi0;ntimesteps=151)

# Damages inversely proportional to income between regions
m_nice_ssp2_catch_nocc_xim1 = getmigrationnicemodel(scen="SSP2",migyesno="nomig",xi=-1.0,omega=1.0)
set_param!(m_nice_ssp2_catch_nocc_xim1,:runremcatchupdam, true)
set_param!(m_nice_ssp2_catch_nocc_xim1,:runwithoutdamage, true)
update_param!(m_nice_ssp2_catch_nocc_xim1,:currtax, m_fund[:emissions,:currtax])
run(m_nice_ssp2_catch_nocc_xim1;ntimesteps=151)

migration_quint_catch = DataFrame(
    year = repeat(years, outer = length(regions)*5),
    fundregion = repeat(regions, outer = 5, inner=length(years)),
    quintile = repeat(1:5, inner=length(years)*length(regions))
)

migration_quint_catch[:,:leave_quint_xi1] = collect(Iterators.flatten(m_nice_ssp2_catch[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))
migration_quint_catch[:,:leave_quint_xi0] = collect(Iterators.flatten(m_nice_ssp2_catch_xi0[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))
migration_quint_catch[:,:leave_quint_xim1] = collect(Iterators.flatten(m_nice_ssp2_catch_xim1[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))

# Look at emigrants without residual from gravity (residual same for all SSP, xi, CC or not)
migration_quint_catch[!,:leave_quint_gravres] = repeat(collect(Iterators.flatten(sum(m_nice_ssp2_catch[:migration,:gravres_qi],dims=[2,4])[:,1,:,1])),inner=length(1951:2100))

# Plot differences in migration with and without climate change for each quintile
migration_quint_catch[:,:leave_quint_nocc_xi1] = collect(Iterators.flatten(m_nice_ssp2_catch_nocc[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))
migration_quint_catch[:,:leave_quint_nocc_xi0] = collect(Iterators.flatten(m_nice_ssp2_catch_nocc_xi0[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))
migration_quint_catch[:,:leave_quint_nocc_xim1] = collect(Iterators.flatten(m_nice_ssp2_catch_nocc_xim1[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))

migration_quint_catch[!,:leave_quint_diff_xi1] = migration_quint_catch[:,:leave_quint_xi1] .- migration_quint_catch[:,:leave_quint_nocc_xi1]
migration_quint_catch[!,:leave_quint_diff_xi0] = migration_quint_catch[:,:leave_quint_xi0] .- migration_quint_catch[:,:leave_quint_nocc_xi0]
migration_quint_catch[!,:leave_quint_diff_xim1] = migration_quint_catch[:,:leave_quint_xim1] .- migration_quint_catch[:,:leave_quint_nocc_xim1]

migration_quint_catch[!,:leave_quint_ccshare_xi1] = (migration_quint_catch[:,:leave_quint_xi1] .- migration_quint_catch[:,:leave_quint_nocc_xi1]) ./ (migration_quint_catch[:,:leave_quint_nocc_xi1] .- migration_quint_catch[:,:leave_quint_gravres])
migration_quint_catch[!,:leave_quint_ccshare_xi0] = (migration_quint_catch[:,:leave_quint_xi0] .- migration_quint_catch[:,:leave_quint_nocc_xi0]) ./ (migration_quint_catch[:,:leave_quint_nocc_xi0] .- migration_quint_catch[:,:leave_quint_gravres])
migration_quint_catch[!,:leave_quint_ccshare_xim1] = (migration_quint_catch[:,:leave_quint_xim1] .- migration_quint_catch[:,:leave_quint_nocc_xim1]) ./ (migration_quint_catch[:,:leave_quint_nocc_xim1] .- migration_quint_catch[:,:leave_quint_gravres])

migration_quint_catch_p = migration_quint_catch[(map(x->mod(x,10)==0,migration_quint_catch[:,:year])),:]

leave_quint_ccshare_catch = stack(
    rename(migration_quint_catch_p, :leave_quint_ccshare_xi1 => :leave_quint_ccshare_damageprop, :leave_quint_ccshare_xi0 => :leave_quint_ccshare_damageindep, :leave_quint_ccshare_xim1 => :leave_quint_ccshare_damageinvprop), 
    [:leave_quint_ccshare_damageprop,:leave_quint_ccshare_damageindep,:leave_quint_ccshare_damageinvprop], 
    [:quintile ,:fundregion, :year]
)
rename!(leave_quint_ccshare_catch, :variable => :leave_type, :value => :leave_quint_ccshare_nocc)
leave_quint_ccshare_catch[!,:damage_elasticity] = map(x->SubString(string(x),21),leave_quint_ccshare_catch[:,:leave_type])
leave_quint_ccshare_catch[!,:type_name] = [leave_quint_ccshare_catch[i,:damage_elasticity]=="damageprop" ? "proportional" : (leave_quint_ccshare_catch[i,:damage_elasticity]=="damageindep" ? "independent" : "inversely prop.") for i in eachindex(leave_quint_ccshare_catch[:,1])]
leave_quint_ccshare_catch = innerjoin(leave_quint_ccshare_catch, regions_fullname, on=:fundregion)

# For SSP2 and original SSP quantifications, this gives Fig.B11
leave_quint_ccshare_catch |> @filter(_.year >= 2015 && _.year <= 2100) |> @vlplot(
    mark={:point,size=60}, width=300, height=250, columns=4, wrap={"regionname:o", title=nothing, header={labelFontSize=24}}, 
    x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
    y={"leave_quint_ccshare_nocc:q", title = "CC effect on total emigrants", axis={labelFontSize=20,titleFontSize=20}},
    color={"quintile:o",scale={scheme=:darkmulti},legend={title = "Quintile", titleFontSize=20, symbolSize=80, labelFontSize=20}},
    shape={"type_name:o",scale={range=["circle","triangle-up","square"],domain=["proportional","independent","inversely prop."]},legend={title = "Damages elasticity", titleFontSize=20, titleLimit=260, symbolSize=80, labelFontSize=20}},
    resolve = {scale={y=:independent}}
) |> save(joinpath(@__DIR__, "../results/migflow_ineq/", string("B11_update.png")))