using DelimitedFiles, CSV, VegaLite, FileIO, VegaDatasets, FilePaths
using Statistics, DataFrames, Query, Distributions

using Mimi, MimiFUND

include("main_mig_nice.jl")


ssps = ["SSP1","SSP2","SSP3","SSP4","SSP5"]
regions = ["USA", "CAN", "WEU", "JPK", "ANZ", "EEU", "FSU", "MDE", "CAM", "LAM", "SAS", "SEA", "CHI", "MAF", "SSA", "SIS"]
years = 1951:2100

world110m = dataset("world-110m")
isonum_fundregion = CSV.read(joinpath(@__DIR__,"../input_data/isonum_fundregion.csv"),DataFrame)

# Run models
# Damages within a given region proportional to income (xi=1)
m_nice_ssp1_nomig = getmigrationnicemodel(scen="SSP1",migyesno="nomig",xi=1.0,omega=1.0)
m_nice_ssp2_nomig = getmigrationnicemodel(scen="SSP2",migyesno="nomig",xi=1.0,omega=1.0)
m_nice_ssp3_nomig = getmigrationnicemodel(scen="SSP3",migyesno="nomig",xi=1.0,omega=1.0)
m_nice_ssp4_nomig = getmigrationnicemodel(scen="SSP4",migyesno="nomig",xi=1.0,omega=1.0)
m_nice_ssp5_nomig = getmigrationnicemodel(scen="SSP5",migyesno="nomig",xi=1.0,omega=1.0)
m_fund = getfund()

run(m_nice_ssp1_nomig;ntimesteps=151)
run(m_nice_ssp2_nomig;ntimesteps=151)
run(m_nice_ssp3_nomig;ntimesteps=151)
run(m_nice_ssp4_nomig;ntimesteps=151)
run(m_nice_ssp5_nomig;ntimesteps=151)
run(m_fund)

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
leave_quint[!,:type_name] = [leave_quint[i,:leave_type]=="damageprop" ? "proportional" : (leave_quint[i,:leave_type]=="damageindep" ? "independent" : "inversely prop.") for i in eachindex(leave_quint[:,1])]
regions_fullname = DataFrame(
    fundregion=regions,
    regionname = ["United States","Canada","Western Europe", "Japan & South Korea","Australia & New Zealand","Central & Eastern Europe","Former Soviet Union", "Middle East", "Central America", "South America","South Asia","Southeast Asia","China plus", "North Africa","Sub-Saharan Africa","Small Island States"]
)
leave_quint = innerjoin(leave_quint, regions_fullname, on =:fundregion)

# For SSP2, this gives Fig.1a
for s in ssps
    leave_quint |> @filter(_.year >= 2015 && _.year <= 2100 && _.scen == s && _.leave_type == "damageinvprop") |> @vlplot(
        mark={:line,point={filled=true,size=80}}, width=300, height=250, columns=4, wrap={"regionname:o", title=nothing, header={labelFontSize=24}}, 
        x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
        y={"leave_quint:q", title = "Total emigrants", axis={labelFontSize=20,titleFontSize=20}},
        color={"quintile:o",scale={scheme=:darkmulti},legend={title = "Quintile", titleFontSize=20, symbolSize=80, labelFontSize=20, offset=40}},
        resolve = {scale={y=:independent}}
    ) |> save(joinpath(@__DIR__, "../results/migflow_ineq/", string("leave_quint_daminvprop_",s,"_v5_update.png")))
end

enter_quint = stack(
    rename(migration_quint_p, :enter_quint_xi1 => :enter_quint_damageprop, :enter_quint_xi0 => :enter_quint_damageindep, :enter_quint_xim1 => :enter_quint_damageinvprop), 
    [:enter_quint_damageprop,:enter_quint_damageindep,:enter_quint_damageinvprop], 
    [:scen, :quintile ,:fundregion, :year]
)
rename!(enter_quint, :variable => :enter_type, :value => :enter_quint)
enter_quint[!,:enter_type] = map(x->SubString(String(x), 13), enter_quint[:,:enter_type])
enter_quint = innerjoin(enter_quint, regions_fullname, on =:fundregion)

# For SSP2, this gives Fig.B1
for s in ssps
    enter_quint |> @filter(_.year >= 2015 && _.year <= 2100 && _.scen == s && _.enter_type == "damageinvprop") |> @vlplot(
        mark={:line,point={filled=true,size=80}}, width=300, height=250, columns=4, wrap={"regionname:o", title=nothing, header={labelFontSize=24}}, 
        x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
        y={"enter_quint:q", title = "Total immigrants", axis={labelFontSize=20,titleFontSize=20}},
        color={"quintile:o",scale={scheme=:darkmulti},legend={title = "Quintile", titleFontSize=20, symbolSize=80, labelFontSize=20,offset=20}},
        resolve = {scale={y=:independent}}
    ) |> save(joinpath(@__DIR__, "../results/migflow_ineq/", string("enter_quint_daminvprop_",s,"_v5_update.png")))
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
netmig_quint_all_p[!,:type_name] = [netmig_quint_all_p[i,:netmig_quint_type]=="damageprop" ? "proportional" : (netmig_quint_all_p[i,:netmig_quint_type]=="damageindep" ? "independent" : "inversely prop.") for i in eachindex(netmig_quint_all_p[:,1])]

# For SSP2, this gives Fig.B2
for s in ssps
    netmig_quint_all_p |> @filter(_.year >= 2015 && _.year <= 2100 && _.scen == s) |> @vlplot(
        mark={:point,size=60}, width=300, height=250, columns=4, wrap={"regionname:o", title=nothing, header={labelFontSize=24}}, 
        x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
        y={"netmig_quint:q", title = "Net migrants", axis={labelFontSize=16,titleFontSize=16}},
        color={"quintile:o",scale={scheme=:darkmulti},legend={title=string("Quintile, ",s), titleFontSize=20, titleLimit=220, symbolSize=80, labelFontSize=20}},
        shape={"type_name:o",scale={range=["circle","triangle-up","square"],domain=["proportional","independent","inversely prop."]},legend={title = "Damages elasticity", titleFontSize=20, titleLimit=260, symbolSize=80, labelFontSize=20}},
        resolve = {scale={y=:independent}}
    ) |> save(joinpath(@__DIR__, "../results/migflow_ineq/", string("netmig_quint_",s,"_v5_update.png")))
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
migstock_quint[!,:type_name] = [migstock_quint[i,:migstock_type]=="damageprop" ? "proportional" : (migstock_quint[i,:migstock_type]=="damageindep" ? "independent" : "inversely prop.") for i in eachindex(migstock_quint[:,1])]
migstock_quint = innerjoin(migstock_quint, regions_fullname, on =:fundregion)

# For SSP2, this gives Fig.B1
for s in ssps
    migstock_quint |> @filter(_.year >= 2015 && _.year <= 2100 && _.scen == s) |> @vlplot(
        mark={:point,size=60}, width=300, height=250, columns=4, wrap={"regionname:o", title=nothing, header={labelFontSize=24}}, 
        x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
        y={"migstock:q", title = "Immigrants stock", axis={labelFontSize=20,titleFontSize=20}},
        color={"quintile:o",scale={scheme=:darkmulti},legend={title = "Quintile", titleFontSize=20, symbolSize=80, labelFontSize=20}},
        shape={"type_name:o",scale={range=["circle","triangle-up","square"],domain=["proportional","independent","inversely prop."]},legend={title = "Damages elasticity", titleFontSize=20, titleLimit=260, symbolSize=80, labelFontSize=20}},
        resolve = {scale={y=:independent}}
    ) |> save(joinpath(@__DIR__, "../results/migflow_ineq/", string("migstock_quint_",s,"_v5_update.png")))
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
leave_quint_ccshare[!,:type_name] = [leave_quint_ccshare[i,:damage_elasticity]=="damageprop" ? "proportional" : (leave_quint_ccshare[i,:damage_elasticity]=="damageindep" ? "independent" : "inversely prop.") for i in eachindex(leave_quint_ccshare[:,1])]
leave_quint_ccshare = innerjoin(leave_quint_ccshare, regions_fullname, on=:fundregion)

# For SSP2, this gives Extended Data Fig.3
# For SSP3, this gives Extended Data Fig.4
for s in ssps
    leave_quint_ccshare |> @filter(_.year >= 2015 && _.year <= 2100 && _.scen == s) |> @vlplot(
        mark={:point,size=60}, width=300, height=250, columns=4, wrap={"regionname:o", title=nothing, header={labelFontSize=24}}, 
        x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
        y={"leave_quint_ccshare_nocc:q", title = "CC effect on total emigrants", axis={labelFontSize=20,titleFontSize=20}},
        color={"quintile:o",scale={scheme=:darkmulti},legend={title = "Quintile", titleFontSize=20, symbolSize=80, labelFontSize=20}},
        shape={"type_name:o",scale={range=["circle","triangle-up","square"],domain=["proportional","independent","inversely prop."]},legend={title = "Damages elasticity", titleFontSize=20, titleLimit=260, symbolSize=80, labelFontSize=20}},
        resolve = {scale={y=:independent}}
    ) |> save(joinpath(@__DIR__, "../results/migflow_ineq/", string("leave_quint_ccshare_",s,"_v5_update.png")))
end

# Plot associated maps
leave_maps = leftjoin(leave_quint_ccshare, isonum_fundregion, on = :fundregion)

# For SSP2 and SSP3 combined and damages inversely proportional, this gives Fig.4 (top)
# For SSP2 and SSP3 combined and damages proportional, this gives Extended Data Fig.5 (top)
# For SSP2 and SSP3 combined and damages independent, this gives Extended Data Fig.6 (top)
for s in ssps
    for d in ["damageprop","damageindep","damageinvprop"]
        @vlplot(width=800, height=600) + @vlplot(mark={:geoshape, stroke = :lightgray}, 
            data={values=world110m, format={type=:topojson, feature=:countries}}, 
            transform = [{lookup=:id, from={data=filter(row -> row[:scen] == s && row[:year] == 2100 && row[:damage_elasticity] == d && row[:quintile] == 1, leave_maps), key=:isonum, fields=[string(:leave_quint_ccshare_nocc)]}}],
            projection={type=:naturalEarth1}, title = {text=string("SSP2-RCP4.5"),fontSize=24}, 
            color = {:leave_quint_ccshare_nocc, type=:quantitative, scale={domain=[-0.4,0.4], scheme=:pinkyellowgreen}, legend={title="Change vs no CC", titleFontSize=20, titleLimit=260, symbolSize=60, labelFontSize=20, labelLimit=220}}
        ) |> save(joinpath(@__DIR__, "../results/world_maps_ineq/", string("leave_q1_ccshare_", s, "_", d, "_v5_update.png")))
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
leave_quint_dec_nocc[!,:type_name] = [leave_quint_dec_nocc[i,:leave_type]=="damageprop" ? "proportional" : (leave_quint_dec_nocc[i,:leave_type]=="damageindep" ? "independent" : "inversely prop.") for i in eachindex(leave_quint_dec_nocc[:,1])]
leave_quint_dec_nocc = innerjoin(leave_quint_dec_nocc, regions_fullname, on=:fundregion)

# For SSP2, this gives Fig.B9
for s in ssps
    leave_quint_dec_nocc |> @filter(_.decade >= 2010 && _.decade <= 2100 && _.scen == s) |> @vlplot(
        mark={:point,size=60}, width=300, height=250, columns=4, wrap={"regionname:o", title=nothing, header={labelFontSize=24}}, 
        x={"decade:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
        y={"leave_quint_diff_dec_nocc:q", title = "Change in emigrants", axis={labelFontSize=20,titleFontSize=20}},
        color={"quintile:o",scale={scheme=:darkmulti},legend={title = "Quintile", titleFontSize=20, symbolSize=80, labelFontSize=20}},
        shape={"type_name:o",scale={range=["circle","triangle-up","square"],domain=["proportional","independent","inversely prop."]},legend={title = "Damages elasticity", titleFontSize=20, titleLimit=260, symbolSize=80, labelFontSize=20}},
        resolve = {scale={y=:independent}}
    ) |> save(joinpath(@__DIR__, "../results/migflow_ineq/", string("leave_quint_dec_nocc_",s,"_v5_update.png")))
end
