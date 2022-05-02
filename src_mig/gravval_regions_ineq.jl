using CSV, DataFrames, DelimitedFiles, ExcelFiles
using Plots, VegaLite, FileIO, VegaDatasets, FilePaths
using Statistics, Query


############################################ Obtain residuals from gravity model at FUND regions level #####################################

############################################ Using specification with remshare endogenous, Gini in levels, no fixed effects ###################################
# Read data on gravity-derived migration 
# We use the migration flow data from Azose and Raftery (2018) as presented in Abel and Cohen (2019)
gravity_ineq = CSV.read(joinpath(@__DIR__,"../results/gravity/gravity_ineq.csv"), DataFrame)
fe_ineq_yfe = CSV.read(joinpath(@__DIR__,"../results/gravity/fe_ineq_yfe.csv"), DataFrame)
fe_ineq_odyfe = CSV.read(joinpath(@__DIR__,"../results/gravity/fe_ineq_odyfe.csv"), DataFrame)
beta_ineq = CSV.read(joinpath(@__DIR__,"../results/gravity/beta_ineq.csv"), DataFrame)

# gravity_ineq has data in log. We transform it back.
data_ineq = gravity_ineq[:,[:year,:orig,:dest,:flow_AzoseRaftery,:distance,:pop_orig,:pop_dest,:ypc_orig,:ypc_dest,:gini_orig,:gini_dest,:exp_residual,:remcost,:comofflang]]
for name in [:flow_AzoseRaftery,:distance,:pop_orig,:pop_dest,:ypc_orig,:ypc_dest,:exp_residual,:remcost,:comofflang,:gini_orig,:gini_dest]
    data_ineq[!,name] = [exp(data_ineq[!,name][i]) for i in 1:size(data_ineq, 1)]
end

# First with only year fixed effects, as in our main specification
ireg = findfirst(beta_ineq[!,:regtype].=="reg_ineq_yfe")
gravval_ineq = innerjoin(data_ineq, unique(fe_ineq_yfe[!,[:year,:fe_YearCategorical]]), on = :year)
rename!(gravval_ineq, :flow_AzoseRaftery => :flowmig, :fe_YearCategorical => :fe_year_only)

# No need for the constant beta0 which is an average of year fixed effects
gravval_ineq[!,:flowmig_grav] = gravval_ineq[:,:pop_orig].^beta_ineq[ireg,:b1] .* gravval_ineq[:,:pop_dest].^beta_ineq[ireg,:b2] .* gravval_ineq[:,:ypc_orig].^beta_ineq[ireg,:b4] .* gravval_ineq[:,:ypc_dest].^beta_ineq[ireg,:b5] .* gravval_ineq[:,:gini_orig].^beta_ineq[ireg,:b11] .* gravval_ineq[:,:gini_dest].^beta_ineq[ireg,:b12] .* gravval_ineq[:,:distance].^beta_ineq[ireg,:b7] .* gravval_ineq[:,:exp_residual].^beta_ineq[ireg,:b8] .* gravval_ineq[:,:remcost].^beta_ineq[ireg,:b9] .* gravval_ineq[:,:comofflang].^beta_ineq[ireg,:b10] .* exp(beta_ineq[ireg,:b0])
for i in 1:size(gravval_ineq,1)
    if gravval_ineq[i,:orig] == gravval_ineq[i,:dest]
        gravval_ineq[i,:flowmig_grav] = 0.0
    end
end

gravval_ineq[!,:diff_flowmig] = gravval_ineq[!,:flowmig] .- gravval_ineq[!,:flowmig_grav]

# Transpose to FUND region * region level. 
iso3c_fundregion = CSV.read("../input_data/iso3c_fundregion.csv", DataFrame)
gravval_ineq = innerjoin(gravval_ineq, rename(iso3c_fundregion, :fundregion => :originregion, :iso3c => :orig), on =:orig)
gravval_ineq = innerjoin(gravval_ineq, rename(iso3c_fundregion, :fundregion => :destinationregion, :iso3c => :dest), on =:dest)

gravval_ineq_reg = combine(df -> (flowmig_reg= sum(skipmissing(df[:,:flowmig])), flowmig_grav_reg=sum(skipmissing(df[:,:flowmig_grav])), diff_flowmig_reg=sum(skipmissing(df[:,:diff_flowmig]))), groupby(gravval_ineq, [:year,:originregion,:destinationregion]))
gravval_ineq_reg[!,:diff_flowmig_reg_btw] = [gravval_ineq_reg[i,:originregion] == gravval_ineq_reg[i,:destinationregion] ? 0 : gravval_ineq_reg[i,:diff_flowmig_reg] for i in 1:size(gravval_ineq_reg,1)]

# Use average of period 2000-2015 for projecting residuals in gravity model
res_ineq = combine(df -> mean(df[:,:diff_flowmig_reg_btw]), groupby(gravval_ineq_reg[(gravval_ineq_reg[:,:year].>=2000),:], [:originregion,:destinationregion]))
push!(res_ineq,["CAN","CAN",0.0])
push!(res_ineq,["USA","USA",0.0])
# No data for ANZ-ANZ, ANZ-JPK, JPK-ANZ
push!(res_ineq,["ANZ","ANZ",0.0])
push!(res_ineq,["ANZ","JPK",0.0])
push!(res_ineq,["JPK","ANZ",0.0])

rename!(res_ineq,:x1 => :residuals)
regions = ["USA", "CAN", "WEU", "JPK", "ANZ", "EEU", "FSU", "MDE", "CAM", "LAM", "SAS", "SEA", "CHI", "MAF", "SSA", "SIS"]
regionsdf = DataFrame(originregion = repeat(regions, inner = length(regions)), indexo = repeat(1:16, inner = length(regions)), destinationregion = repeat(regions, outer = length(regions)), indexd = repeat(1:16, outer = length(regions)))
res_ineq = outerjoin(res_ineq, regionsdf, on = [:originregion, :destinationregion])
sort!(res_ineq, (:indexo, :indexd))
select!(res_ineq, Not([:indexo, :indexd]))
CSV.write(joinpath(@__DIR__,"../data_mig/gravres_ineq.csv"), res_ineq; writeheader=false)

# Plot: distribution of residuals across corridors, for all 5 periods
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
gravval_ineq_reg = innerjoin(gravval_ineq_reg, rename(regions_fullname,:fundregion=>:originregion,:regionname=>:originname), on =:originregion)
gravval_ineq_reg = innerjoin(gravval_ineq_reg, rename(regions_fullname,:fundregion=>:destinationregion,:regionname=>:destinationname), on =:destinationregion)
sort!(gravval_ineq_reg, [:year,:originname,:destinationname])

# Plot residuals for each destination region
gravval_ineq_reg |> @vlplot(
    mark={:line, point=true}, width=220, columns=4, wrap={"destinationname:o", title=nothing, header={labelFontSize=24}}, 
    y={"diff_flowmig_reg_btw:q", axis={labelFontSize=16, titleFontSize=16}, title="Residuals from gravity"},
    x={"year:o", title = nothing, axis={labelFontSize=16}},
    color={"originname:o",scale={scheme=:tableau20},legend={title=string("Origin region"), titleFontSize=20, titleLimit=240, symbolSize=80, labelFontSize=24, labelLimit=280, offset=2}},
    resolve = {scale={y=:independent}},
    #title = "Residuals for each destination region"
) |> save(joinpath(@__DIR__, "../results/gravity/", "residuals_ineq_nofe_btw_dest.png"))


############################################ Using specification with remshare endogenous, no fixed effects, for all quintiles ###################################
# Read data on gravity-derived migration 
# We use the migration flow data from Azose and Raftery (2018) as presented in Abel and Cohen (2019)
gravity_quint = CSV.read(joinpath(@__DIR__,"../../Documents/WorkInProgress/migrations-Esteban-FUND/results/gravity_quint.csv"), DataFrame)
fe_quint_ratio_tot_yfe = CSV.read(joinpath(@__DIR__,"../results/gravity/fe_quint_ratio_tot_yfe.csv"), DataFrame)
beta_quint_ratio = CSV.read(joinpath(@__DIR__,"../results/gravity/beta_quint_ratio.csv"), DataFrame)

# gravity_quint has data in log. We transform it back.
data_quint = gravity_quint[:,[:year,:orig,:dest,:quint_orig,:quint_dest,:flow_quint,:distance,:pop_quint_orig,:pop_quint_dest,:ypc_quint_orig,:ypcratio_avsp,:exp_residual,:remcost,:comofflang]]
for name in [:flow_quint,:distance,:pop_quint_orig,:pop_quint_dest,:ypc_quint_orig,:ypcratio_avsp,:exp_residual,:remcost,:comofflang]
    data_quint[!,name] = [exp(data_quint[!,name][i]) for i in 1:size(data_quint, 1)]
end

# First with all quintiles at once
ireg = findfirst(beta_quint_ratio[!,:regtype].=="reg_quint_ratioavsp_tot_yfe")
gravval_quint = innerjoin(data_quint, unique(fe_quint_ratio_tot_yfe[!,[:year,:fe_YearCategorical]]), on = :year)
rename!(gravval_quint, :flow_quint => :flowmig, :fe_YearCategorical => :fe_year_only)

# No need for the constant beta0 which is an average of year fixed effects
gravval_quint[!,:flowmig_grav] = gravval_quint[:,:pop_quint_orig].^beta_quint_ratio[ireg,:beta1] .* gravval_quint[:,:pop_quint_dest].^beta_quint_ratio[ireg,:beta2] .* gravval_quint[:,:ypc_quint_orig].^beta_quint_ratio[ireg,:beta4] .* gravval_quint[:,:ypcratio_avsp].^beta_quint_ratio[ireg,:beta5] .* gravval_quint[:,:distance].^beta_quint_ratio[ireg,:beta7] .* gravval_quint[:,:exp_residual].^beta_quint_ratio[ireg,:beta8] .* gravval_quint[:,:remcost].^beta_quint_ratio[ireg,:beta9] .* gravval_quint[:,:comofflang].^beta_quint_ratio[ireg,:beta10] .* exp(beta_quint_ratio[ireg,:beta0])
for i in 1:size(gravval_quint,1)
    if gravval_quint[i,:orig] == gravval_quint[i,:dest]
        gravval_quint[i,:flowmig_grav] = 0.0
    end
end

gravval_quint[!,:diff_flowmig] = gravval_quint[!,:flowmig] .- gravval_quint[!,:flowmig_grav]

# Transpose to FUND region * region level. 
iso3c_fundregion = CSV.read("../input_data/iso3c_fundregion.csv", DataFrame)
gravval_quint = innerjoin(gravval_quint, rename(iso3c_fundregion, :fundregion => :originregion, :iso3c => :orig), on =:orig)
gravval_quint = innerjoin(gravval_quint, rename(iso3c_fundregion, :fundregion => :destinationregion, :iso3c => :dest), on =:dest)

gravval_quint_reg = combine(df -> (flowmig_reg= sum(skipmissing(df[:,:flowmig])), flowmig_grav_reg=sum(skipmissing(df[:,:flowmig_grav])), diff_flowmig_reg=sum(skipmissing(df[:,:diff_flowmig]))), groupby(gravval_quint, [:year,:originregion,:destinationregion,:quint_orig,:quint_dest]))
gravval_quint_reg[!,:diff_flowmig_reg_btw] = [gravval_quint_reg[i,:originregion] == gravval_quint_reg[i,:destinationregion] ? 0 : gravval_quint_reg[i,:diff_flowmig_reg] for i in 1:size(gravval_quint_reg,1)]

# Use average of period 2000-2015 for projecting residuals in gravity model
res_quint = combine(df -> mean(df[:,:diff_flowmig_reg_btw]), groupby(gravval_quint_reg[(gravval_quint_reg[:,:year].>=2000),:], [:originregion,:destinationregion,:quint_orig,:quint_dest]))

rename!(res_quint,:x1 => :residuals)
regionsdfq = DataFrame(
    originregion = repeat(regions, inner = length(regions)*5*5), 
    indexo = repeat(1:16, inner = length(regions)*5*5), 
    destinationregion = repeat(regions, outer = length(regions), inner=5*5), 
    indexd = repeat(1:16, outer = length(regions), inner=5*5),
    quint_or = repeat(1:5, outer = length(regions)*length(regions), inner=5),
    quint_de = repeat(1:5, outer = length(regions)*length(regions)*5)
)
quintiles = DataFrame(name=unique(res_quint[:,:quint_orig]),number=1:5)
res_quint = innerjoin(res_quint, rename(quintiles,:name=>:quint_orig,:number=>:quint_or), on = :quint_orig)
res_quint = innerjoin(res_quint, rename(quintiles,:name=>:quint_dest,:number=>:quint_de), on = :quint_dest)
res_quint = outerjoin(res_quint, regionsdfq, on = [:originregion, :destinationregion,:quint_or,:quint_de])

# Missing data for 900 out of 6400 corridors: all corridors including ANZ, CAN-CAN, USA-USA, SIS-SIS, MAF-SIS, SIS-MAF
# Assume that residuals equal zero for those
for i in 1:size(res_quint,1) 
    if ismissing(res_quint[i,:residuals]) || ismissing(res_quint[i,:quint_orig])
        res_quint[i, :residuals] = 0.0 
        res_quint[i,:quint_orig] = string("q",res_quint[i,:quint_or]) 
        res_quint[i,:quint_dest] = string("q",res_quint[i,:quint_de]) 
    end 
end

sort!(res_quint, (:indexo, :indexd,:quint_or,:quint_de))
CSV.write(joinpath(@__DIR__,"../data_mig_3d/gravres_quint.csv"), res_quint[:,union(1:2,6:7,5)]; writeheader=false)

# Plot: distribution of residuals across corridors, for all 5 periods
res_quint = innerjoin(res_quint, rename(regions_fullname,:fundregion=>:originregion,:regionname=>:originname), on =:originregion)
res_quint = innerjoin(res_quint, rename(regions_fullname,:fundregion=>:destinationregion,:regionname=>:destinationname), on =:destinationregion)

# Plot residuals for each destination region and quintile
res_quint |> @vlplot(
    mark={:point}, width=220, columns=4, wrap={"destinationname:o", title=nothing, header={labelFontSize=24}}, 
    y={"residuals:q", axis={labelFontSize=16, titleFontSize=16}, title="Residuals from gravity"},
    x={"quint_dest:o", title = nothing, axis={labelFontSize=16}},
    color={"originname:o",scale={scheme=:tableau20},legend={title=string("Origin region"), titleFontSize=20, titleLimit=240, symbolSize=80, labelFontSize=24, labelLimit=280, offset=2}},
    shape={"quint_orig:o",legend={title=string("Origin quintile"), titleFontSize=20, titleLimit=240, symbolSize=80, labelFontSize=24, labelLimit=280, offset=2}},
    resolve = {scale={y=:independent}},
    #title = "Residuals for each destination region"
) |> save(joinpath(@__DIR__, "../results/gravity/", "residuals_quint_tot_nofe_dest.png"))


############################################ Using specification with remshare endogenous, no fixed effects, for each quintile ###################################
# Read data on gravity-derived migration 
# We use the migration flow data from Azose and Raftery (2018) as presented in Abel and Cohen (2019)
fe_quint_ratio_q1 = CSV.read(joinpath(@__DIR__,"../results/gravity/fe_quint_ratio_q1.csv"), DataFrame)
fe_quint_ratio_q2 = CSV.read(joinpath(@__DIR__,"../results/gravity/fe_quint_ratio_q2.csv"), DataFrame)
fe_quint_ratio_q3 = CSV.read(joinpath(@__DIR__,"../results/gravity/fe_quint_ratio_q3.csv"), DataFrame)
fe_quint_ratio_q4 = CSV.read(joinpath(@__DIR__,"../results/gravity/fe_quint_ratio_q4.csv"), DataFrame)
fe_quint_ratio_q5 = CSV.read(joinpath(@__DIR__,"../results/gravity/fe_quint_ratio_q5.csv"), DataFrame)

# Then with each quintile separately
gravval_qi = vcat(
    innerjoin(data_quint[(data_quint[:,:quint_orig].=="q1"),:], unique(fe_quint_ratio_q1[!,[:year,:fe_YearCategorical]]), on = :year),
    innerjoin(data_quint[(data_quint[:,:quint_orig].=="q2"),:], unique(fe_quint_ratio_q2[!,[:year,:fe_YearCategorical]]), on = :year),
    innerjoin(data_quint[(data_quint[:,:quint_orig].=="q3"),:], unique(fe_quint_ratio_q3[!,[:year,:fe_YearCategorical]]), on = :year),
    innerjoin(data_quint[(data_quint[:,:quint_orig].=="q4"),:], unique(fe_quint_ratio_q4[!,[:year,:fe_YearCategorical]]), on = :year),
    innerjoin(data_quint[(data_quint[:,:quint_orig].=="q5"),:], unique(fe_quint_ratio_q5[!,[:year,:fe_YearCategorical]]), on = :year),
)
rename!(gravval_qi, :flow_quint => :flowmig, :fe_YearCategorical => :fe_year_only)

# No need for the constant beta0 which is an average of year fixed effects
flowmig_grav = []
for i in 1:size(gravval_qi,1)
    iqi = findfirst(beta_quint_ratio[!,:regtype].==string("reg_quint_ratioavsp_",gravval_qi[i,:quint_orig]))
    fg = gravval_qi[i,:pop_quint_orig]^beta_quint_ratio[iqi,:beta1] * gravval_qi[i,:pop_quint_dest]^beta_quint_ratio[iqi,:beta2] * gravval_qi[i,:ypc_quint_orig]^beta_quint_ratio[iqi,:beta4] * gravval_qi[i,:ypcratio_avsp]^beta_quint_ratio[iqi,:beta5] * gravval_qi[i,:distance]^beta_quint_ratio[iqi,:beta7] * gravval_qi[i,:exp_residual]^beta_quint_ratio[iqi,:beta8] * gravval_qi[i,:remcost]^beta_quint_ratio[iqi,:beta9] * gravval_qi[i,:comofflang]^beta_quint_ratio[iqi,:beta10] * exp(beta_quint_ratio[iqi,:beta0])
    if gravval_qi[i,:orig] == gravval_qi[i,:dest]
        fg = 0.0
    end
    append!(flowmig_grav,fg)
end
gravval_qi[!,:flowmig_grav] = flowmig_grav
gravval_qi[!,:diff_flowmig] = gravval_qi[!,:flowmig] .- gravval_qi[!,:flowmig_grav]

# Transpose to FUND region * region level. 
gravval_qi = innerjoin(gravval_qi, rename(iso3c_fundregion, :fundregion => :originregion, :iso3c => :orig), on =:orig)
gravval_qi = innerjoin(gravval_qi, rename(iso3c_fundregion, :fundregion => :destinationregion, :iso3c => :dest), on =:dest)

gravval_qi_reg = combine(df -> (flowmig_reg= sum(skipmissing(df[:,:flowmig])), flowmig_grav_reg=sum(skipmissing(df[:,:flowmig_grav])), diff_flowmig_reg=sum(skipmissing(df[:,:diff_flowmig]))), groupby(gravval_qi, [:year,:originregion,:destinationregion,:quint_orig,:quint_dest]))
gravval_qi_reg[!,:diff_flowmig_reg_btw] = [gravval_qi_reg[i,:originregion] == gravval_qi_reg[i,:destinationregion] ? 0 : gravval_qi_reg[i,:diff_flowmig_reg] for i in 1:size(gravval_qi_reg,1)]

# Use average of period 2000-2015 for projecting residuals in gravity model
res_qi = combine(df -> mean(df[:,:diff_flowmig_reg_btw]), groupby(gravval_qi_reg[(gravval_qi_reg[:,:year].>=2000),:], [:originregion,:destinationregion,:quint_orig,:quint_dest]))

rename!(res_qi,:x1 => :residuals)
res_qi = innerjoin(res_qi, rename(quintiles,:name=>:quint_orig,:number=>:quint_or), on = :quint_orig)
res_qi = innerjoin(res_qi, rename(quintiles,:name=>:quint_dest,:number=>:quint_de), on = :quint_dest)
res_qi = outerjoin(res_qi, regionsdfq, on = [:originregion, :destinationregion,:quint_or,:quint_de])

# Missing data for 900 out of 6400 corridors: all corridors including ANZ, CAN-CAN, USA-USA, SIS-SIS, MAF-SIS, SIS-MAF
# Assume that residuals equal zero for those
for i in 1:size(res_qi,1) 
    if ismissing(res_qi[i,:residuals]) || ismissing(res_qi[i,:quint_orig])
        res_qi[i, :residuals] = 0.0 
        res_qi[i,:quint_orig] = string("q",res_qi[i,:quint_or]) 
        res_qi[i,:quint_dest] = string("q",res_qi[i,:quint_de]) 
    end 
end

sort!(res_qi, (:indexo, :indexd,:quint_or,:quint_de))
CSV.write(joinpath(@__DIR__,"../data_mig_3d/gravres_qi.csv"), res_qi[:,union(1:2,6:7,5)]; writeheader=false)

res_qi = innerjoin(res_qi, rename(regions_fullname,:fundregion=>:originregion,:regionname=>:originname), on =:originregion)
res_qi = innerjoin(res_qi, rename(regions_fullname,:fundregion=>:destinationregion,:regionname=>:destinationname), on =:destinationregion)

# Plot residuals for each destination region and quintile
res_qi |> @vlplot(
    mark={:point}, width=220, columns=4, wrap={"destinationname:o", title=nothing, header={labelFontSize=24}}, 
    y={"residuals:q", axis={labelFontSize=16, titleFontSize=16}, title="Residuals from gravity"},
    x={"quint_dest:o", title = nothing, axis={labelFontSize=16}},
    color={"originname:o",scale={scheme=:tableau20},legend={title=string("Origin region"), titleFontSize=20, titleLimit=240, symbolSize=80, labelFontSize=24, labelLimit=280, offset=2}},
    shape={"quint_orig:o",legend={title=string("Origin quintile"), titleFontSize=20, titleLimit=240, symbolSize=80, labelFontSize=24, labelLimit=280, offset=2}},
    resolve = {scale={y=:independent}}
) |> save(joinpath(@__DIR__, "../results/gravity/", "residuals_qi_tot_nofe_dest.png"))

# Plot residuals for each origin region and quintile
res_qi |> @vlplot(
    mark={:point}, width=220, columns=4, wrap={"originname:o", title=nothing, header={labelFontSize=24}}, 
    y={"residuals:q", axis={labelFontSize=16, titleFontSize=16}, title="Residuals from gravity"},
    x={"quint_orig:o", title = nothing, axis={labelFontSize=16}},
    color={"destinationname:o",scale={scheme=:tableau20},legend={title=string("Destination region"), titleFontSize=20, titleLimit=240, symbolSize=80, labelFontSize=24, labelLimit=280, offset=2}},
    shape={"quint_dest:o",legend={title=string("Destination quintile"), titleFontSize=20, titleLimit=240, symbolSize=80, labelFontSize=24, labelLimit=280, offset=2}},
    resolve = {scale={y=:independent}}
) |> save(joinpath(@__DIR__, "../results/gravity/", "residuals_qi_tot_nofe_orig.png"))
