using CSV, DataFrames, DelimitedFiles, ExcelFiles
using Plots, VegaLite, FileIO, VegaDatasets, FilePaths
using Statistics, Query


############################################ Obtain residuals from gravity model at FUND regions level #####################################
# Read data on gravity-derived migration 
# We use the migration flow data from Azose and Raftery (2018) as presented in Abel and Cohen (2019)
gravity_quint = CSV.read(joinpath(@__DIR__,"../../../results/gravity_quint.csv"), DataFrame)
beta_quint_ratio = CSV.read(joinpath(@__DIR__,"../results/gravity/beta_quint_ratio.csv"), DataFrame)
fe_quint_ratio_q1 = CSV.read(joinpath(@__DIR__,"../results/gravity/fe_quint_ratio_q1.csv"), DataFrame)
fe_quint_ratio_q2 = CSV.read(joinpath(@__DIR__,"../results/gravity/fe_quint_ratio_q2.csv"), DataFrame)
fe_quint_ratio_q3 = CSV.read(joinpath(@__DIR__,"../results/gravity/fe_quint_ratio_q3.csv"), DataFrame)
fe_quint_ratio_q4 = CSV.read(joinpath(@__DIR__,"../results/gravity/fe_quint_ratio_q4.csv"), DataFrame)
fe_quint_ratio_q5 = CSV.read(joinpath(@__DIR__,"../results/gravity/fe_quint_ratio_q5.csv"), DataFrame)

# gravity_quint has data in log. We transform it back.
data_quint = gravity_quint[:,[:year,:orig,:dest,:quint_orig,:quint_dest,:flow_quint,:distance,:pop_quint_orig,:pop_quint_dest,:ypc_quint_orig,:ypcratio_avsp,:exp_residual,:remcost,:comofflang]]
for name in [:flow_quint,:distance,:pop_quint_orig,:pop_quint_dest,:ypc_quint_orig,:ypcratio_avsp,:exp_residual,:remcost,:comofflang]
    data_quint[!,name] = [exp(data_quint[!,name][i]) for i in 1:size(data_quint, 1)]
end

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

# Missing data: assume that residuals equal zero
for i in 1:size(res_qi,1) 
    if ismissing(res_qi[i,:residuals]) || ismissing(res_qi[i,:quint_orig])
        res_qi[i, :residuals] = 0.0 
        res_qi[i,:quint_orig] = string("q",res_qi[i,:quint_or]) 
        res_qi[i,:quint_dest] = string("q",res_qi[i,:quint_de]) 
    end 
end

sort!(res_qi, (:indexo, :indexd,:quint_or,:quint_de))
CSV.write(joinpath(@__DIR__,"../data_mig_3d/gravres_qi.csv"), res_qi[:,union(1:2,6:7,5)]; writeheader=false)

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
res_qi = innerjoin(res_qi, rename(regions_fullname,:fundregion=>:originregion,:regionname=>:originname), on =:originregion)
res_qi = innerjoin(res_qi, rename(regions_fullname,:fundregion=>:destinationregion,:regionname=>:destinationname), on =:destinationregion)

# Plot residuals for each origin region and quintile
res_qi |> @vlplot(
    mark={:point}, width=220, columns=4, wrap={"originname:o", title=nothing, header={labelFontSize=24}}, 
    y={"residuals:q", axis={labelFontSize=16, titleFontSize=16}, title="Residuals from gravity"},
    x={"quint_orig:o", title = nothing, axis={labelFontSize=16}},
    color={"destinationname:o",scale={scheme=:tableau20},legend={title=string("Destination region"), titleFontSize=20, titleLimit=240, symbolSize=80, labelFontSize=24, labelLimit=280, offset=2}},
    shape={"quint_dest:o",legend={title=string("Destination quintile"), titleFontSize=20, titleLimit=240, symbolSize=80, labelFontSize=24, labelLimit=280, offset=2}},
    resolve = {scale={y=:independent}}
) |> save(joinpath(@__DIR__, "../results/gravity/", "residuals_qi_tot_nofe_orig.png"))
