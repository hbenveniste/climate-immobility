using DelimitedFiles, CSV, VegaLite, FileIO, VegaDatasets, FilePaths
using Statistics, DataFrames, Query, Distributions

using MimiFUND


# Look at catastrophic damages: add term in (T^7) so that global GDP loss = 50% when T=6C 

include("main_mig_nice_cata.jl")


ssps = ["SSP1","SSP2","SSP3","SSP4","SSP5"]
regions = ["USA", "CAN", "WEU", "JPK", "ANZ", "EEU", "FSU", "MDE", "CAM", "LAM", "SAS", "SEA", "CHI", "MAF", "SSA", "SIS"]
years = 1951:2100

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
world110m = dataset("world-110m")
isonum_fundregion = CSV.read(joinpath(@__DIR__,"../input_data/isonum_fundregion.csv"), DataFrame)


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


################################################ Compare to without climate change ##################################
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

