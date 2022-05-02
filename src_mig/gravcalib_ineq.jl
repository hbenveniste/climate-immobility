using CSV, DataFrames, DelimitedFiles, ExcelFiles
using Plots, VegaLite, FileIO, VegaDatasets, FilePaths, ImageIO, ImageMagick
using Statistics, Query, Distributions, StatsPlots
using FixedEffectModels, RegressionTables
using GLM


######################################### Prepare data ###########################################################################
gravity_endo = CSV.File(joinpath(@__DIR__,"../results/gravity/gravity_endo.csv")) |> DataFrame
gravity_endo_abel = CSV.File(joinpath(@__DIR__,"../results/gravity/gravity_endo_abel.csv")) |> DataFrame

# For 1950-2010: use data on within-country Gini from World Bank. Data only available sporadicly over time and across countries
data_gini = load(joinpath(@__DIR__, "../input_data/Gini_WB_all.xlsx"), "Data!A1:BL265") |> DataFrame
gini_hist = stack(data_gini[:,4:end], 2:61)
rename!(gini_hist, Symbol("Country Code")=>:country, :variable => :year, :value=>:gini)
gini_hist[!,:year] = map(x->parse(Int,SubString(String(x), 1:4)), gini_hist[:,:year])
gini_hist[!,:gini] = [typeof(gini_hist[i,:gini]) == Float64 ? gini_hist[i,:gini] : missing for i in 1:size(gini_hist,1)]
# In order to have enough data for gravres, attribute for Australia the Gini of 2001 to 2000, and of 2004 to 2005
ind0 = intersect(findall(gini_hist[:,:year].==2000),findall(gini_hist[:,:country].=="AUS"))
ind1 = intersect(findall(gini_hist[:,:year].==2001),findall(gini_hist[:,:country].=="AUS"))
ind5 = intersect(findall(gini_hist[:,:year].==2005),findall(gini_hist[:,:country].=="AUS"))
ind4 = intersect(findall(gini_hist[:,:year].==2004),findall(gini_hist[:,:country].=="AUS"))
gini_hist[ind0,:gini] = gini_hist[ind1,:gini]
gini_hist[ind5,:gini] = gini_hist[ind4,:gini]

gravity_ineq = innerjoin(gravity_endo, rename(gini_hist[(map(x->!ismissing(x),gini_hist[:,:gini])),:],:country=>:orig,:gini=>:gini_orig), on=[:year,:orig])
gravity_ineq = innerjoin(gravity_ineq, rename(gini_hist[(map(x->!ismissing(x),gini_hist[:,:gini])),:],:country=>:dest,:gini=>:gini_dest), on=[:year,:dest])
gravity_ineq_abel = innerjoin(gravity_endo_abel, rename(gini_hist[(map(x->!ismissing(x),gini_hist[:,:gini])),:],:country=>:orig,:gini=>:gini_orig), on=[:year,:orig])
gravity_ineq_abel = innerjoin(gravity_ineq_abel, rename(gini_hist[(map(x->!ismissing(x),gini_hist[:,:gini])),:],:country=>:dest,:gini=>:gini_dest), on=[:year,:dest])

gravity_ineq_abel[!,:gini_ratio] = gravity_ineq_abel[:,:gini_dest] ./ gravity_ineq_abel[:,:gini_orig]

# Convert Gini to number between 0 and 1 instead of percentage, then take log for regression
for name in [:gini_orig,:gini_dest]
    gravity_ineq[!,name] = gravity_ineq[:,name] ./ 100
    gravity_ineq_abel[!,name] = gravity_ineq_abel[:,name] ./ 100
    gravity_ineq[!,Symbol(:log,name)] = [log(gravity_ineq[i,name]/100) for i in 1:size(gravity_ineq, 1)]
    gravity_ineq_abel[!,Symbol(:log,name)] = [log(gravity_ineq_abel[i,name]/100) for i in 1:size(gravity_ineq_abel, 1)]
end

edu_bil = CSV.File(joinpath(@__DIR__,"../../../results/edu_bil.csv")) |> DataFrame

edu_bil[!,:flow_quint_share] = edu_bil[:,:flow_quint] ./ edu_bil[:,:flow]
for i in 1:size(edu_bil,1) ; if edu_bil[i,:flow_quint] == 0.0 && edu_bil[i,:flow] == 0.0 ; edu_bil[i,:flow_quint_share] = 0 end end

gravity_quint = innerjoin(gravity_ineq[.&(gravity_ineq[:,:year].==2010),:], edu_bil[:,union(1:2,4,6,7,9,11)], on = [:orig, :dest])
gravity_quint[!,:flow_quint] = map(x->log(x),map(x->exp(x), gravity_quint[:,:flow_AzoseRaftery]) .* gravity_quint[:,:flow_quint_share])
gravity_quint[!,:ypc_quint_orig] = map(x->log(x), gravity_quint[:,:ypc_quint_orig])
gravity_quint[!,:ypc_quint_dest] = map(x->log(x), gravity_quint[:,:ypc_quint_dest])
gravity_quint[!,:pop_quint_orig] = map(x->log(exp(x)/5), gravity_quint[:,:pop_orig])
gravity_quint[!,:pop_quint_dest] = map(x->log(exp(x)/5), gravity_quint[:,:pop_dest])

gravity_quint_abel = innerjoin(gravity_ineq_abel[.&(gravity_ineq_abel[:,:year].==2010),:], edu_bil[:,union(1:2,4,6,7,9,11)], on = [:orig, :dest])
gravity_quint_abel[!,:flow_quint] = map(x->log(x),map(x->exp(x), gravity_quint_abel[:,:flow_Abel]) .* gravity_quint_abel[:,:flow_quint_share])
gravity_quint_abel[!,:ypc_quint_orig] = map(x->log(x), gravity_quint_abel[:,:ypc_quint_orig])
gravity_quint_abel[!,:ypc_quint_dest] = map(x->log(x), gravity_quint_abel[:,:ypc_quint_dest])
gravity_quint_abel[!,:pop_quint_orig] = map(x->log(exp(x)/5), gravity_quint_abel[:,:pop_orig])
gravity_quint_abel[!,:pop_quint_dest] = map(x->log(exp(x)/5), gravity_quint_abel[:,:pop_dest])


######################################### Calibrate gravity equation, separately on origin #############################################################
# Compute ratios of income per capita at destination and origin
gravity_quint[!,:ypcratio_avav] = map(x->log(x), map(x->exp(x), gravity_quint[:,:ypc_dest]) ./ map(x->exp(x), gravity_quint[:,:ypc_orig]))
gravity_quint[!,:ypcratio_avsp] = map(x->log(x), map(x->exp(x), gravity_quint[:,:ypc_dest]) ./ map(x->exp(x), gravity_quint[:,:ypc_quint_orig]))
gravity_quint[!,:ypcratio_spav] = map(x->log(x), map(x->exp(x), gravity_quint[:,:ypc_quint_dest]) ./ map(x->exp(x), gravity_quint[:,:ypc_orig]))
gravity_quint[!,:ypcratio_spsp] = map(x->log(x), map(x->exp(x), gravity_quint[:,:ypc_quint_dest]) ./ map(x->exp(x), gravity_quint[:,:ypc_quint_orig]))
# Compute squared and cube terms for income per capita at origin
gravity_quint[!,:ypc_quint_orig_sq] = gravity_quint[:,:ypc_quint_orig].^2
gravity_quint[!,:ypc_quint_orig_cu] = gravity_quint[:,:ypc_quint_orig].^3

# Estimate for each origin quintile

# With origin quintile-specific income levels (also for ratio) and population sizes, and destination average income levels
regirq1avspnog = reg(rename(gravity_quint[(gravity_quint[:,:quint_orig].=="q1"),:],:flow_quint=>:flow_q1), @formula(flow_q1 ~ pop_quint_orig + pop_quint_dest + ypc_quint_orig + ypcratio_avsp + distance + exp_residual + remcost + comofflang + fe(YearCategorical)), Vcov.cluster(:OrigCategorical, :DestCategorical), save=true)
regirq2avspnog = reg(rename(gravity_quint[(gravity_quint[:,:quint_orig].=="q2"),:],:flow_quint=>:flow_q2), @formula(flow_q2 ~ pop_quint_orig + pop_quint_dest + ypc_quint_orig + ypcratio_avsp + distance + exp_residual + remcost + comofflang + fe(YearCategorical)), Vcov.cluster(:OrigCategorical, :DestCategorical), save=true)
regirq3avspnog = reg(rename(gravity_quint[(gravity_quint[:,:quint_orig].=="q3"),:],:flow_quint=>:flow_q3), @formula(flow_q3 ~ pop_quint_orig + pop_quint_dest + ypc_quint_orig + ypcratio_avsp + distance + exp_residual + remcost + comofflang + fe(YearCategorical)), Vcov.cluster(:OrigCategorical, :DestCategorical), save=true)
regirq4avspnog = reg(rename(gravity_quint[(gravity_quint[:,:quint_orig].=="q4"),:],:flow_quint=>:flow_q4), @formula(flow_q4 ~ pop_quint_orig + pop_quint_dest + ypc_quint_orig + ypcratio_avsp + distance + exp_residual + remcost + comofflang + fe(YearCategorical)), Vcov.cluster(:OrigCategorical, :DestCategorical), save=true)
regirq5avspnog = reg(rename(gravity_quint[(gravity_quint[:,:quint_orig].=="q5"),:],:flow_quint=>:flow_q5), @formula(flow_q5 ~ pop_quint_orig + pop_quint_dest + ypc_quint_orig + ypcratio_avsp + distance + exp_residual + remcost + comofflang + fe(YearCategorical)), Vcov.cluster(:OrigCategorical, :DestCategorical), save=true)

regtable(regirq1avspnog,regirq2avspnog,regirq3avspnog,regirq4avspnog,regirq5avspnog; renderSettings = asciiOutput(),regression_statistics=[:nobs, :r2 ])      

# Estimation with data from Abel (2018)
gravity_quint_abel[!,:ypcratio_avsp] = map(x->log(x), map(x->exp(x), gravity_quint_abel[:,:ypc_dest]) ./ map(x->exp(x), gravity_quint_abel[:,:ypc_quint_orig]))
regirq1avspnogabel = reg(rename(gravity_quint_abel[.&(gravity_quint_abel[:,:quint_orig].=="q1",gravity_quint_abel[:,:flow_quint].>-Inf),:],:flow_quint=>:flow_q1), @formula(flow_q1 ~ pop_quint_orig + pop_quint_dest + ypc_quint_orig + ypcratio_avsp + distance + exp_residual + remcost + comofflang + fe(YearCategorical)), Vcov.cluster(:OrigCategorical, :DestCategorical), save=true)
regirq2avspnogabel = reg(rename(gravity_quint_abel[.&(gravity_quint_abel[:,:quint_orig].=="q2",gravity_quint_abel[:,:flow_quint].>-Inf),:],:flow_quint=>:flow_q2), @formula(flow_q2 ~ pop_quint_orig + pop_quint_dest + ypc_quint_orig + ypcratio_avsp + distance + exp_residual + remcost + comofflang + fe(YearCategorical)), Vcov.cluster(:OrigCategorical, :DestCategorical), save=true)
regirq3avspnogabel = reg(rename(gravity_quint_abel[.&(gravity_quint_abel[:,:quint_orig].=="q3",gravity_quint_abel[:,:flow_quint].>-Inf),:],:flow_quint=>:flow_q3), @formula(flow_q3 ~ pop_quint_orig + pop_quint_dest + ypc_quint_orig + ypcratio_avsp + distance + exp_residual + remcost + comofflang + fe(YearCategorical)), Vcov.cluster(:OrigCategorical, :DestCategorical), save=true)
regirq4avspnogabel = reg(rename(gravity_quint_abel[.&(gravity_quint_abel[:,:quint_orig].=="q4",gravity_quint_abel[:,:flow_quint].>-Inf),:],:flow_quint=>:flow_q4), @formula(flow_q4 ~ pop_quint_orig + pop_quint_dest + ypc_quint_orig + ypcratio_avsp + distance + exp_residual + remcost + comofflang + fe(YearCategorical)), Vcov.cluster(:OrigCategorical, :DestCategorical), save=true)
regirq5avspnogabel = reg(rename(gravity_quint_abel[.&(gravity_quint_abel[:,:quint_orig].=="q5",gravity_quint_abel[:,:flow_quint].>-Inf),:],:flow_quint=>:flow_q5), @formula(flow_q5 ~ pop_quint_orig + pop_quint_dest + ypc_quint_orig + ypcratio_avsp + distance + exp_residual + remcost + comofflang + fe(YearCategorical)), Vcov.cluster(:OrigCategorical, :DestCategorical), save=true)

regtable(regirq1avspnogabel,regirq2avspnogabel,regirq3avspnogabel,regirq4avspnogabel,regirq5avspnogabel; renderSettings = asciiOutput(),regression_statistics=[:nobs, :r2 ])      

# With income at origin without remittances
gravity_quint[!,:ypc_quint_orig_nor] = map(x->log(x), (map(x->exp(x), gravity_quint[:,:pop_quint_orig]) .* map(x->exp(x), gravity_quint[:,:ypc_quint_orig]) .- gravity_quint[:,:remshare] .* map(x->exp(x), gravity_quint[:,:flow_quint]) .* map(x->exp(x), gravity_quint[:,:ypc_quint_dest])) ./ map(x->exp(x), gravity_quint[:,:pop_quint_orig]))

regirq1avspnognor = reg(rename(gravity_quint[(gravity_quint[:,:quint_orig].=="q1"),:],:flow_quint=>:flow_q1), @formula(flow_q1 ~ pop_quint_orig + pop_quint_dest + ypc_quint_orig_nor + ypcratio_avsp + distance + exp_residual + remcost + comofflang + fe(YearCategorical)), Vcov.cluster(:OrigCategorical, :DestCategorical), save=true)
regirq2avspnognor = reg(rename(gravity_quint[(gravity_quint[:,:quint_orig].=="q2"),:],:flow_quint=>:flow_q2), @formula(flow_q2 ~ pop_quint_orig + pop_quint_dest + ypc_quint_orig_nor + ypcratio_avsp + distance + exp_residual + remcost + comofflang + fe(YearCategorical)), Vcov.cluster(:OrigCategorical, :DestCategorical), save=true)
regirq3avspnognor = reg(rename(gravity_quint[(gravity_quint[:,:quint_orig].=="q3"),:],:flow_quint=>:flow_q3), @formula(flow_q3 ~ pop_quint_orig + pop_quint_dest + ypc_quint_orig_nor + ypcratio_avsp + distance + exp_residual + remcost + comofflang + fe(YearCategorical)), Vcov.cluster(:OrigCategorical, :DestCategorical), save=true)
regirq4avspnognor = reg(rename(gravity_quint[(gravity_quint[:,:quint_orig].=="q4"),:],:flow_quint=>:flow_q4), @formula(flow_q4 ~ pop_quint_orig + pop_quint_dest + ypc_quint_orig_nor + ypcratio_avsp + distance + exp_residual + remcost + comofflang + fe(YearCategorical)), Vcov.cluster(:OrigCategorical, :DestCategorical), save=true)
regirq5avspnognor = reg(rename(gravity_quint[(gravity_quint[:,:quint_orig].=="q5"),:],:flow_quint=>:flow_q5), @formula(flow_q5 ~ pop_quint_orig + pop_quint_dest + ypc_quint_orig_nor + ypcratio_avsp + distance + exp_residual + remcost + comofflang + fe(YearCategorical)), Vcov.cluster(:OrigCategorical, :DestCategorical), save=true)

regtable(regirq1avspnognor,regirq2avspnognor,regirq3avspnognor,regirq4avspnognor,regirq5avspnognor; renderSettings = asciiOutput(),regression_statistics=[:nobs, :r2 ])      

# With squared term for ypc at origin
regirq1avspnogsq = reg(rename(gravity_quint[(gravity_quint[:,:quint_orig].=="q1"),:],:flow_quint=>:flow_q1), @formula(flow_q1 ~ pop_quint_orig + pop_quint_dest + ypc_quint_orig + ypc_quint_orig_sq + ypcratio_avsp + distance + exp_residual + remcost + comofflang + fe(YearCategorical)), Vcov.cluster(:OrigCategorical, :DestCategorical), save=true)
regirq2avspnogsq = reg(rename(gravity_quint[(gravity_quint[:,:quint_orig].=="q2"),:],:flow_quint=>:flow_q2), @formula(flow_q2 ~ pop_quint_orig + pop_quint_dest + ypc_quint_orig + ypc_quint_orig_sq + ypcratio_avsp + distance + exp_residual + remcost + comofflang + fe(YearCategorical)), Vcov.cluster(:OrigCategorical, :DestCategorical), save=true)
regirq3avspnogsq = reg(rename(gravity_quint[(gravity_quint[:,:quint_orig].=="q3"),:],:flow_quint=>:flow_q3), @formula(flow_q3 ~ pop_quint_orig + pop_quint_dest + ypc_quint_orig + ypc_quint_orig_sq + ypcratio_avsp + distance + exp_residual + remcost + comofflang + fe(YearCategorical)), Vcov.cluster(:OrigCategorical, :DestCategorical), save=true)
regirq4avspnogsq = reg(rename(gravity_quint[(gravity_quint[:,:quint_orig].=="q4"),:],:flow_quint=>:flow_q4), @formula(flow_q4 ~ pop_quint_orig + pop_quint_dest + ypc_quint_orig + ypc_quint_orig_sq + ypcratio_avsp + distance + exp_residual + remcost + comofflang + fe(YearCategorical)), Vcov.cluster(:OrigCategorical, :DestCategorical), save=true)
regirq5avspnogsq = reg(rename(gravity_quint[(gravity_quint[:,:quint_orig].=="q5"),:],:flow_quint=>:flow_q5), @formula(flow_q5 ~ pop_quint_orig + pop_quint_dest + ypc_quint_orig + ypc_quint_orig_sq + ypcratio_avsp + distance + exp_residual + remcost + comofflang + fe(YearCategorical)), Vcov.cluster(:OrigCategorical, :DestCategorical), save=true)

regtable(regirq1avspnogsq,regirq2avspnogsq,regirq3avspnogsq,regirq4avspnogsq,regirq5avspnogsq; renderSettings = asciiOutput(),regression_statistics=[:nobs, :r2 ])      

# With squared and cube terms for ypc at origin
regirq1avspnogsqcu = reg(rename(gravity_quint[(gravity_quint[:,:quint_orig].=="q1"),:],:flow_quint=>:flow_q1), @formula(flow_q1 ~ pop_quint_orig + pop_quint_dest + ypc_quint_orig + ypc_quint_orig_sq + ypc_quint_orig_cu + ypcratio_avsp + distance + exp_residual + remcost + comofflang + fe(YearCategorical)), Vcov.cluster(:OrigCategorical, :DestCategorical), save=true)
regirq2avspnogsqcu = reg(rename(gravity_quint[(gravity_quint[:,:quint_orig].=="q2"),:],:flow_quint=>:flow_q2), @formula(flow_q2 ~ pop_quint_orig + pop_quint_dest + ypc_quint_orig + ypc_quint_orig_sq + ypc_quint_orig_cu + ypcratio_avsp + distance + exp_residual + remcost + comofflang + fe(YearCategorical)), Vcov.cluster(:OrigCategorical, :DestCategorical), save=true)
regirq3avspnogsqcu = reg(rename(gravity_quint[(gravity_quint[:,:quint_orig].=="q3"),:],:flow_quint=>:flow_q3), @formula(flow_q3 ~ pop_quint_orig + pop_quint_dest + ypc_quint_orig + ypc_quint_orig_sq + ypc_quint_orig_cu + ypcratio_avsp + distance + exp_residual + remcost + comofflang + fe(YearCategorical)), Vcov.cluster(:OrigCategorical, :DestCategorical), save=true)
regirq4avspnogsqcu = reg(rename(gravity_quint[(gravity_quint[:,:quint_orig].=="q4"),:],:flow_quint=>:flow_q4), @formula(flow_q4 ~ pop_quint_orig + pop_quint_dest + ypc_quint_orig + ypc_quint_orig_sq + ypc_quint_orig_cu + ypcratio_avsp + distance + exp_residual + remcost + comofflang + fe(YearCategorical)), Vcov.cluster(:OrigCategorical, :DestCategorical), save=true)
regirq5avspnogsqcu = reg(rename(gravity_quint[(gravity_quint[:,:quint_orig].=="q5"),:],:flow_quint=>:flow_q5), @formula(flow_q5 ~ pop_quint_orig + pop_quint_dest + ypc_quint_orig + ypc_quint_orig_sq + ypc_quint_orig_cu + ypcratio_avsp + distance + exp_residual + remcost + comofflang + fe(YearCategorical)), Vcov.cluster(:OrigCategorical, :DestCategorical), save=true)

regtable(regirq1avspnogsqcu,regirq2avspnogsqcu,regirq3avspnogsqcu,regirq4avspnogsqcu,regirq5avspnogsqcu; renderSettings = asciiOutput(),regression_statistics=[:nobs, :r2 ])  

# With origin quintile-specific income levels and population sizes, and average income levels for ratio (both origin and destination)
regirq1avavnog = reg(rename(gravity_quint[(gravity_quint[:,:quint_orig].=="q1"),:],:flow_quint=>:flow_q1), @formula(flow_q1 ~ pop_quint_orig + pop_quint_dest + ypc_quint_orig + ypcratio_avav + distance + exp_residual + remcost + comofflang + fe(YearCategorical)), Vcov.cluster(:OrigCategorical, :DestCategorical), save=true)
regirq2avavnog = reg(rename(gravity_quint[(gravity_quint[:,:quint_orig].=="q2"),:],:flow_quint=>:flow_q2), @formula(flow_q2 ~ pop_quint_orig + pop_quint_dest + ypc_quint_orig + ypcratio_avav + distance + exp_residual + remcost + comofflang + fe(YearCategorical)), Vcov.cluster(:OrigCategorical, :DestCategorical), save=true)
regirq3avavnog = reg(rename(gravity_quint[(gravity_quint[:,:quint_orig].=="q3"),:],:flow_quint=>:flow_q3), @formula(flow_q3 ~ pop_quint_orig + pop_quint_dest + ypc_quint_orig + ypcratio_avav + distance + exp_residual + remcost + comofflang + fe(YearCategorical)), Vcov.cluster(:OrigCategorical, :DestCategorical), save=true)
regirq4avavnog = reg(rename(gravity_quint[(gravity_quint[:,:quint_orig].=="q4"),:],:flow_quint=>:flow_q4), @formula(flow_q4 ~ pop_quint_orig + pop_quint_dest + ypc_quint_orig + ypcratio_avav + distance + exp_residual + remcost + comofflang + fe(YearCategorical)), Vcov.cluster(:OrigCategorical, :DestCategorical), save=true)
regirq5avavnog = reg(rename(gravity_quint[(gravity_quint[:,:quint_orig].=="q5"),:],:flow_quint=>:flow_q5), @formula(flow_q5 ~ pop_quint_orig + pop_quint_dest + ypc_quint_orig + ypcratio_avav + distance + exp_residual + remcost + comofflang + fe(YearCategorical)), Vcov.cluster(:OrigCategorical, :DestCategorical), save=true)

regtable(regirq1avavnog,regirq2avavnog,regirq3avavnog,regirq4avavnog,regirq5avavnog; renderSettings = asciiOutput(),regression_statistics=[:nobs, :r2 ])     

# With origin and destination quintile-specific income levels and population sizes
regirq1spspnog = reg(rename(gravity_quint[(gravity_quint[:,:quint_orig].=="q1"),:],:flow_quint=>:flow_q1), @formula(flow_q1 ~ pop_quint_orig + pop_quint_dest + ypc_quint_orig + ypcratio_spsp + distance + exp_residual + remcost + comofflang + fe(YearCategorical)), Vcov.cluster(:OrigCategorical, :DestCategorical), save=true)
regirq2spspnog = reg(rename(gravity_quint[(gravity_quint[:,:quint_orig].=="q2"),:],:flow_quint=>:flow_q2), @formula(flow_q2 ~ pop_quint_orig + pop_quint_dest + ypc_quint_orig + ypcratio_spsp + distance + exp_residual + remcost + comofflang + fe(YearCategorical)), Vcov.cluster(:OrigCategorical, :DestCategorical), save=true)
regirq3spspnog = reg(rename(gravity_quint[(gravity_quint[:,:quint_orig].=="q3"),:],:flow_quint=>:flow_q3), @formula(flow_q3 ~ pop_quint_orig + pop_quint_dest + ypc_quint_orig + ypcratio_spsp + distance + exp_residual + remcost + comofflang + fe(YearCategorical)), Vcov.cluster(:OrigCategorical, :DestCategorical), save=true)
regirq4spspnog = reg(rename(gravity_quint[(gravity_quint[:,:quint_orig].=="q4"),:],:flow_quint=>:flow_q4), @formula(flow_q4 ~ pop_quint_orig + pop_quint_dest + ypc_quint_orig + ypcratio_spsp + distance + exp_residual + remcost + comofflang + fe(YearCategorical)), Vcov.cluster(:OrigCategorical, :DestCategorical), save=true)
regirq5spspnog = reg(rename(gravity_quint[(gravity_quint[:,:quint_orig].=="q5"),:],:flow_quint=>:flow_q5), @formula(flow_q5 ~ pop_quint_orig + pop_quint_dest + ypc_quint_orig + ypcratio_spsp + distance + exp_residual + remcost + comofflang + fe(YearCategorical)), Vcov.cluster(:OrigCategorical, :DestCategorical), save=true)

regtable(regirq1spspnog,regirq2spspnog,regirq3spspnog,regirq4spspnog,regirq5spspnog; renderSettings = asciiOutput(),regression_statistics=[:nobs, :r2 ]) 

# With Gini
regirq1avsp = reg(rename(gravity_quint[(gravity_quint[:,:quint_orig].=="q1"),:],:flow_quint=>:flow_q1), @formula(flow_q1 ~ pop_quint_orig + pop_quint_dest + ypc_quint_orig + ypcratio_avsp + gini_orig + gini_dest + distance + exp_residual + remcost + comofflang + fe(YearCategorical)), Vcov.cluster(:OrigCategorical, :DestCategorical), save=true)
regirq2avsp = reg(rename(gravity_quint[(gravity_quint[:,:quint_orig].=="q2"),:],:flow_quint=>:flow_q2), @formula(flow_q2 ~ pop_quint_orig + pop_quint_dest + ypc_quint_orig + ypcratio_avsp + gini_orig + gini_dest + distance + exp_residual + remcost + comofflang + fe(YearCategorical)), Vcov.cluster(:OrigCategorical, :DestCategorical), save=true)
regirq3avsp = reg(rename(gravity_quint[(gravity_quint[:,:quint_orig].=="q3"),:],:flow_quint=>:flow_q3), @formula(flow_q3 ~ pop_quint_orig + pop_quint_dest + ypc_quint_orig + ypcratio_avsp + gini_orig + gini_dest + distance + exp_residual + remcost + comofflang + fe(YearCategorical)), Vcov.cluster(:OrigCategorical, :DestCategorical), save=true)
regirq4avsp = reg(rename(gravity_quint[(gravity_quint[:,:quint_orig].=="q4"),:],:flow_quint=>:flow_q4), @formula(flow_q4 ~ pop_quint_orig + pop_quint_dest + ypc_quint_orig + ypcratio_avsp + gini_orig + gini_dest + distance + exp_residual + remcost + comofflang + fe(YearCategorical)), Vcov.cluster(:OrigCategorical, :DestCategorical), save=true)
regirq5avsp = reg(rename(gravity_quint[(gravity_quint[:,:quint_orig].=="q5"),:],:flow_quint=>:flow_q5), @formula(flow_q5 ~ pop_quint_orig + pop_quint_dest + ypc_quint_orig + ypcratio_avsp + gini_orig + gini_dest + distance + exp_residual + remcost + comofflang + fe(YearCategorical)), Vcov.cluster(:OrigCategorical, :DestCategorical), save=true)

regtable(regirq1avsp,regirq2avsp,regirq3avsp,regirq4avsp,regirq5avsp; renderSettings = asciiOutput(),regression_statistics=[:nobs, :r2 ])     

# Estimation adding the ratio of Gini coefficients
gravity_quint[!,:gini_ratio] = gravity_quint[:,:gini_dest] ./ gravity_quint[:,:gini_orig]
regirq1avspgr = reg(rename(gravity_quint[(gravity_quint[:,:quint_orig].=="q1"),:],:flow_quint=>:flow_q1), @formula(flow_q1 ~ pop_quint_orig + pop_quint_dest + ypc_quint_orig + ypcratio_avsp + gini_ratio + distance + exp_residual + remcost + comofflang + fe(YearCategorical)), Vcov.cluster(:OrigCategorical, :DestCategorical), save=true)
regirq2avspgr = reg(rename(gravity_quint[(gravity_quint[:,:quint_orig].=="q2"),:],:flow_quint=>:flow_q2), @formula(flow_q2 ~ pop_quint_orig + pop_quint_dest + ypc_quint_orig + ypcratio_avsp + gini_ratio + distance + exp_residual + remcost + comofflang + fe(YearCategorical)), Vcov.cluster(:OrigCategorical, :DestCategorical), save=true)
regirq3avspgr = reg(rename(gravity_quint[(gravity_quint[:,:quint_orig].=="q3"),:],:flow_quint=>:flow_q3), @formula(flow_q3 ~ pop_quint_orig + pop_quint_dest + ypc_quint_orig + ypcratio_avsp + gini_ratio + distance + exp_residual + remcost + comofflang + fe(YearCategorical)), Vcov.cluster(:OrigCategorical, :DestCategorical), save=true)
regirq4avspgr = reg(rename(gravity_quint[(gravity_quint[:,:quint_orig].=="q4"),:],:flow_quint=>:flow_q4), @formula(flow_q4 ~ pop_quint_orig + pop_quint_dest + ypc_quint_orig + ypcratio_avsp + gini_ratio + distance + exp_residual + remcost + comofflang + fe(YearCategorical)), Vcov.cluster(:OrigCategorical, :DestCategorical), save=true)
regirq5avspgr = reg(rename(gravity_quint[(gravity_quint[:,:quint_orig].=="q5"),:],:flow_quint=>:flow_q5), @formula(flow_q5 ~ pop_quint_orig + pop_quint_dest + ypc_quint_orig + ypcratio_avsp + gini_ratio + distance + exp_residual + remcost + comofflang + fe(YearCategorical)), Vcov.cluster(:OrigCategorical, :DestCategorical), save=true)

regtable(regirq1avspgr,regirq2avspgr,regirq3avspgr,regirq4avspgr,regirq5avspgr; renderSettings = asciiOutput(),regression_statistics=[:nobs, :r2 ])     

# Estimation adding common borders
iso2c_iso3c = CSV.File(joinpath(@__DIR__,"../input_data/iso2c_iso3c.csv")) |> DataFrame
cborder = CSV.File(joinpath(@__DIR__,"../data_mig/border.csv")) |> DataFrame
dropmissing!(cborder)
cborder = innerjoin(cborder,rename(iso2c_iso3c,:iso2c=>:country_code,:iso3c=>:ctrycode),on=:country_code)
cborder = innerjoin(cborder,rename(iso2c_iso3c,:iso2c=>:country_border_code,:iso3c=>:ctrybordercode),on=:country_border_code)
cborder[!,:commonborder] = ones(size(cborder,1))        # code shared border as 1
gravity_quint = leftjoin(gravity_quint, rename(cborder[!,[:ctrycode,:ctrybordercode,:commonborder]], :ctrycode=>:orig,:ctrybordercode=>:dest),on=[:orig,:dest])
gravity_quint[!,:commonborder] = coalesce.(gravity_quint[!,:commonborder], 0)       # code no shared border as 0

regirq1avspnogcb = reg(rename(gravity_quint[(gravity_quint[:,:quint_orig].=="q1"),:],:flow_quint=>:flow_q1), @formula(flow_q1 ~ pop_quint_orig + pop_quint_dest + ypc_quint_orig + ypcratio_avsp + distance + exp_residual + remcost + comofflang + commonborder + fe(YearCategorical)), Vcov.cluster(:OrigCategorical, :DestCategorical), save=true)
regirq2avspnogcb = reg(rename(gravity_quint[(gravity_quint[:,:quint_orig].=="q2"),:],:flow_quint=>:flow_q2), @formula(flow_q2 ~ pop_quint_orig + pop_quint_dest + ypc_quint_orig + ypcratio_avsp + distance + exp_residual + remcost + comofflang + commonborder + fe(YearCategorical)), Vcov.cluster(:OrigCategorical, :DestCategorical), save=true)
regirq3avspnogcb = reg(rename(gravity_quint[(gravity_quint[:,:quint_orig].=="q3"),:],:flow_quint=>:flow_q3), @formula(flow_q3 ~ pop_quint_orig + pop_quint_dest + ypc_quint_orig + ypcratio_avsp + distance + exp_residual + remcost + comofflang + commonborder + fe(YearCategorical)), Vcov.cluster(:OrigCategorical, :DestCategorical), save=true)
regirq4avspnogcb = reg(rename(gravity_quint[(gravity_quint[:,:quint_orig].=="q4"),:],:flow_quint=>:flow_q4), @formula(flow_q4 ~ pop_quint_orig + pop_quint_dest + ypc_quint_orig + ypcratio_avsp + distance + exp_residual + remcost + comofflang + commonborder + fe(YearCategorical)), Vcov.cluster(:OrigCategorical, :DestCategorical), save=true)
regirq5avspnogcb = reg(rename(gravity_quint[(gravity_quint[:,:quint_orig].=="q5"),:],:flow_quint=>:flow_q5), @formula(flow_q5 ~ pop_quint_orig + pop_quint_dest + ypc_quint_orig + ypcratio_avsp + distance + exp_residual + remcost + comofflang + commonborder + fe(YearCategorical)), Vcov.cluster(:OrigCategorical, :DestCategorical), save=true)

regtable(regirq1avspnogcb,regirq2avspnogcb,regirq3avspnogcb,regirq4avspnogcb,regirq5avspnogcb; renderSettings = asciiOutput(),regression_statistics=[:nobs, :r2 ])      

# Specifications with origin and destination fixed effects
regirq1avspnogfe = reg(rename(gravity_quint[(gravity_quint[:,:quint_orig].=="q1"),:],:flow_quint=>:flow_q1), @formula(flow_q1 ~ pop_quint_orig + pop_quint_dest + ypc_quint_orig + ypcratio_avsp + distance + exp_residual + remcost + comofflang + fe(OrigCategorical) + fe(DestCategorical) + fe(YearCategorical)), Vcov.cluster(:OrigCategorical, :DestCategorical), save=true)
regirq2avspnogfe = reg(rename(gravity_quint[(gravity_quint[:,:quint_orig].=="q2"),:],:flow_quint=>:flow_q2), @formula(flow_q2 ~ pop_quint_orig + pop_quint_dest + ypc_quint_orig + ypcratio_avsp + distance + exp_residual + remcost + comofflang + fe(OrigCategorical) + fe(DestCategorical) + fe(YearCategorical)), Vcov.cluster(:OrigCategorical, :DestCategorical), save=true)
regirq3avspnogfe = reg(rename(gravity_quint[(gravity_quint[:,:quint_orig].=="q3"),:],:flow_quint=>:flow_q3), @formula(flow_q3 ~ pop_quint_orig + pop_quint_dest + ypc_quint_orig + ypcratio_avsp + distance + exp_residual + remcost + comofflang + fe(OrigCategorical) + fe(DestCategorical) + fe(YearCategorical)), Vcov.cluster(:OrigCategorical, :DestCategorical), save=true)
regirq4avspnogfe = reg(rename(gravity_quint[(gravity_quint[:,:quint_orig].=="q4"),:],:flow_quint=>:flow_q4), @formula(flow_q4 ~ pop_quint_orig + pop_quint_dest + ypc_quint_orig + ypcratio_avsp + distance + exp_residual + remcost + comofflang + fe(OrigCategorical) + fe(DestCategorical) + fe(YearCategorical)), Vcov.cluster(:OrigCategorical, :DestCategorical), save=true)
regirq5avspnogfe = reg(rename(gravity_quint[(gravity_quint[:,:quint_orig].=="q5"),:],:flow_quint=>:flow_q5), @formula(flow_q5 ~ pop_quint_orig + pop_quint_dest + ypc_quint_orig + ypcratio_avsp + distance + exp_residual + remcost + comofflang + fe(OrigCategorical) + fe(DestCategorical) + fe(YearCategorical)), Vcov.cluster(:OrigCategorical, :DestCategorical), save=true)

regtable(regirq1avspnogfe,regirq2avspnogfe,regirq3avspnogfe,regirq4avspnogfe,regirq5avspnogfe; renderSettings = asciiOutput(),regression_statistics=[:nobs, :r2 ])      


# Main specification: including ratio of average income at destination and specific income at origin, and linear effect of specific income at origin.
# Estimation for each origin quintile. Will be followed by estimation of repartition in each destination quintile.
beta_quint_ratio = DataFrame(
    regtype = ["reg_quint_ratioavsp_tot_yfe","reg_quint_ratioavsp_q1","reg_quint_ratioavsp_q2", "reg_quint_ratioavsp_q3","reg_quint_ratioavsp_q4", "reg_quint_ratioavsp_q5"],
    beta1 = [0.804,0.824,0.809,0.792,0.807,0.805],       # pop_quint_orig
    beta2 = [0.718,0.719,0.717,0.719,0.718,0.720],       # pop_quint_dest
    beta4 = [1.762,1.808,1.760,1.865,1.834,1.808],       # ypc_quint_orig
    beta5 = [1.157,1.166,1.174,1.170,1.166,1.153],       # ypcratio_avsp
    beta7 = [-1.105,-1.100,-1.081,-1.099,-1.086,-1.120],   # distance
    beta8 = [-0.001,-0.002,-0.002,-0.001,-0.000,0.001],       # exp_residual
    beta9 = [-24.521,-22.604,-25.734,-24.555,-24.231,-24.608],       # remcost
    beta10 = [1.402,1.433,1.490,1.422,1.436,1.320]       # comofflang
)

# Compute constant including year fixed effect as average of beta0 + yearFE
cst_quint_ratio_tot_yfe = hcat(gravity_quint[:,Not([:OrigCategorical,:DestCategorical,:YearCategorical])], fe(regirttavspnog))
cst_quint_ratio_tot_yfe[!,:constant] = cst_quint_ratio_tot_yfe[!,:flow_quint] .- beta_quint_ratio[1,:beta1] .* cst_quint_ratio_tot_yfe[!,:pop_quint_orig] .- beta_quint_ratio[1,:beta2] .* cst_quint_ratio_tot_yfe[!,:pop_quint_dest] .- beta_quint_ratio[1,:beta4] .* cst_quint_ratio_tot_yfe[!,:ypc_quint_orig] .- beta_quint_ratio[1,:beta5] .* cst_quint_ratio_tot_yfe[!,:ypcratio_avsp] .- beta_quint_ratio[1,:beta7] .* cst_quint_ratio_tot_yfe[!,:distance] .- beta_quint_ratio[1,:beta8] .* cst_quint_ratio_tot_yfe[!,:exp_residual] .- beta_quint_ratio[1,:beta9] .* cst_quint_ratio_tot_yfe[!,:remcost] .- beta_quint_ratio[1,:beta10] .* cst_quint_ratio_tot_yfe[!,:comofflang]
constant_quint_ratio_tot_yfe = mean(cst_quint_ratio_tot_yfe[!,:constant])

cst_quint_ratio_q1 = hcat(gravity_quint[(gravity_quint[:,:quint_orig].=="q1"),Not([:OrigCategorical,:DestCategorical,:YearCategorical])], fe(regirq1avspnog))
cst_quint_ratio_q1[!,:constant] = cst_quint_ratio_q1[!,:flow_quint] .- beta_quint_ratio[2,:beta1] .* cst_quint_ratio_q1[!,:pop_quint_orig] .- beta_quint_ratio[2,:beta2] .* cst_quint_ratio_q1[!,:pop_quint_dest] .- beta_quint_ratio[2,:beta4] .* cst_quint_ratio_q1[!,:ypc_quint_orig] .- beta_quint_ratio[2,:beta5] .* cst_quint_ratio_q1[!,:ypcratio_avsp] .- beta_quint_ratio[2,:beta7] .* cst_quint_ratio_q1[!,:distance] .- beta_quint_ratio[2,:beta8] .* cst_quint_ratio_q1[!,:exp_residual] .- beta_quint_ratio[2,:beta9] .* cst_quint_ratio_q1[!,:remcost] .- beta_quint_ratio[2,:beta10] .* cst_quint_ratio_q1[!,:comofflang]
constant_quint_ratio_q1 = mean(cst_quint_ratio_q1[!,:constant])

cst_quint_ratio_q2 = hcat(gravity_quint[(gravity_quint[:,:quint_orig].=="q2"),Not([:OrigCategorical,:DestCategorical,:YearCategorical])], fe(regirq2avspnog))
cst_quint_ratio_q2[!,:constant] = cst_quint_ratio_q2[!,:flow_quint] .- beta_quint_ratio[3,:beta1] .* cst_quint_ratio_q2[!,:pop_quint_orig] .- beta_quint_ratio[3,:beta2] .* cst_quint_ratio_q2[!,:pop_quint_dest] .- beta_quint_ratio[3,:beta4] .* cst_quint_ratio_q2[!,:ypc_quint_orig] .- beta_quint_ratio[3,:beta5] .* cst_quint_ratio_q2[!,:ypcratio_avsp] .- beta_quint_ratio[3,:beta7] .* cst_quint_ratio_q2[!,:distance] .- beta_quint_ratio[3,:beta8] .* cst_quint_ratio_q2[!,:exp_residual] .- beta_quint_ratio[3,:beta9] .* cst_quint_ratio_q2[!,:remcost] .- beta_quint_ratio[3,:beta10] .* cst_quint_ratio_q2[!,:comofflang]
constant_quint_ratio_q2 = mean(cst_quint_ratio_q2[!,:constant])

cst_quint_ratio_q3 = hcat(gravity_quint[(gravity_quint[:,:quint_orig].=="q3"),Not([:OrigCategorical,:DestCategorical,:YearCategorical])], fe(regirq3avspnog))
cst_quint_ratio_q3[!,:constant] = cst_quint_ratio_q3[!,:flow_quint] .- beta_quint_ratio[4,:beta1] .* cst_quint_ratio_q3[!,:pop_quint_orig] .- beta_quint_ratio[4,:beta2] .* cst_quint_ratio_q3[!,:pop_quint_dest] .- beta_quint_ratio[4,:beta4] .* cst_quint_ratio_q3[!,:ypc_quint_orig] .- beta_quint_ratio[4,:beta5] .* cst_quint_ratio_q3[!,:ypcratio_avsp] .- beta_quint_ratio[4,:beta7] .* cst_quint_ratio_q3[!,:distance] .- beta_quint_ratio[4,:beta8] .* cst_quint_ratio_q3[!,:exp_residual] .- beta_quint_ratio[4,:beta9] .* cst_quint_ratio_q3[!,:remcost] .- beta_quint_ratio[4,:beta10] .* cst_quint_ratio_q3[!,:comofflang]
constant_quint_ratio_q3 = mean(cst_quint_ratio_q3[!,:constant])

cst_quint_ratio_q4 = hcat(gravity_quint[(gravity_quint[:,:quint_orig].=="q4"),Not([:OrigCategorical,:DestCategorical,:YearCategorical])], fe(regirq4avspnog))
cst_quint_ratio_q4[!,:constant] = cst_quint_ratio_q4[!,:flow_quint] .- beta_quint_ratio[5,:beta1] .* cst_quint_ratio_q4[!,:pop_quint_orig] .- beta_quint_ratio[5,:beta2] .* cst_quint_ratio_q4[!,:pop_quint_dest] .- beta_quint_ratio[5,:beta4] .* cst_quint_ratio_q4[!,:ypc_quint_orig] .- beta_quint_ratio[5,:beta5] .* cst_quint_ratio_q4[!,:ypcratio_avsp] .- beta_quint_ratio[5,:beta7] .* cst_quint_ratio_q4[!,:distance] .- beta_quint_ratio[5,:beta8] .* cst_quint_ratio_q4[!,:exp_residual] .- beta_quint_ratio[5,:beta9] .* cst_quint_ratio_q4[!,:remcost] .- beta_quint_ratio[5,:beta10] .* cst_quint_ratio_q4[!,:comofflang]
constant_quint_ratio_q4 = mean(cst_quint_ratio_q4[!,:constant])

cst_quint_ratio_q5 = hcat(gravity_quint[(gravity_quint[:,:quint_orig].=="q5"),Not([:OrigCategorical,:DestCategorical,:YearCategorical])], fe(regirq5avspnog;))
cst_quint_ratio_q5[!,:constant] = cst_quint_ratio_q5[!,:flow_quint] .- beta_quint_ratio[6,:beta1] .* cst_quint_ratio_q5[!,:pop_quint_orig] .- beta_quint_ratio[6,:beta2] .* cst_quint_ratio_q5[!,:pop_quint_dest] .- beta_quint_ratio[6,:beta4] .* cst_quint_ratio_q5[!,:ypc_quint_orig] .- beta_quint_ratio[6,:beta5] .* cst_quint_ratio_q5[!,:ypcratio_avsp] .- beta_quint_ratio[6,:beta7] .* cst_quint_ratio_q5[!,:distance] .- beta_quint_ratio[6,:beta8] .* cst_quint_ratio_q5[!,:exp_residual] .- beta_quint_ratio[6,:beta9] .* cst_quint_ratio_q5[!,:remcost] .- beta_quint_ratio[6,:beta10] .* cst_quint_ratio_q5[!,:comofflang]
constant_quint_ratio_q5 = mean(cst_quint_ratio_q5[!,:constant])

beta_quint_ratio[!,:beta0] = [constant_quint_ratio_tot_yfe,constant_quint_ratio_q1,constant_quint_ratio_q2, constant_quint_ratio_q3,constant_quint_ratio_q4, constant_quint_ratio_q5]       # constant

# Gather FE values
fe_quint_ratio_tot_yfe = hcat(gravity_quint[:,[:year,:orig,:dest]], fe(regirttavspnog))
fe_quint_ratio_q1 = hcat(gravity_quint[(gravity_quint[:,:quint_orig].=="q1"),[:year,:orig,:dest]], fe(regirq1avspnog))
fe_quint_ratio_q2 = hcat(gravity_quint[(gravity_quint[:,:quint_orig].=="q2"),[:year,:orig,:dest]], fe(regirq2avspnog))
fe_quint_ratio_q3 = hcat(gravity_quint[(gravity_quint[:,:quint_orig].=="q3"),[:year,:orig,:dest]], fe(regirq3avspnog))
fe_quint_ratio_q4 = hcat(gravity_quint[(gravity_quint[:,:quint_orig].=="q4"),[:year,:orig,:dest]], fe(regirq4avspnog))
fe_quint_ratio_q5 = hcat(gravity_quint[(gravity_quint[:,:quint_orig].=="q5"),[:year,:orig,:dest]], fe(regirq5avspnog))

CSV.write(joinpath(@__DIR__,"../results/gravity/beta_quint_ratio.csv"), beta_quint_ratio)
for j in 2:size(beta_quint_ratio,2)
    CSV.write(joinpath(@__DIR__,string("../data_mig/",string(names(beta_quint_ratio)[j]),".csv")), DataFrame(quintiles=1:5,b=beta_quint_ratio[2:6,j]);writeheader=false)
end

CSV.write(joinpath(@__DIR__,"../results/gravity/fe_quint_ratio_tot_yfe.csv"), fe_quint_ratio_tot_yfe)
CSV.write(joinpath(@__DIR__,"../results/gravity/fe_quint_ratio_q1.csv"), fe_quint_ratio_q1)
CSV.write(joinpath(@__DIR__,"../results/gravity/fe_quint_ratio_q2.csv"), fe_quint_ratio_q2)
CSV.write(joinpath(@__DIR__,"../results/gravity/fe_quint_ratio_q3.csv"), fe_quint_ratio_q3)
CSV.write(joinpath(@__DIR__,"../results/gravity/fe_quint_ratio_q4.csv"), fe_quint_ratio_q4)
CSV.write(joinpath(@__DIR__,"../results/gravity/fe_quint_ratio_q5.csv"), fe_quint_ratio_q5)

CSV.write(joinpath(@__DIR__,"../../../results/gravity_quint.csv"), gravity_quint)
CSV.write(joinpath(@__DIR__,"../../../results/gravity_quint_abel.csv"), gravity_quint_abel)


#################################################################### Estimating the repartition of migrants in destination quintiles #####################################################
# Compute, for a given origin quintile, the share of migrants that move to each of the five destination quintiles
gravity_quint_or = combine(groupby(view(gravity_quint,:,:), [:orig,:dest,:quint_orig]), :flow_quint_share => sum)
gravity_quint = innerjoin(gravity_quint, gravity_quint_or, on = [:orig,:dest,:quint_orig])
gravity_quint[!,:flowshare_quintdest] = map(x -> log(x), gravity_quint[:,:flow_quint_share] ./ gravity_quint[:,:flow_quint_share_sum])     

# Compute, for a given origin quintile, the relative development level of origin and destination from the migrant's perspective: ypc_dest / ypc_quint_orig
gravity_quint[!,:ypc_rel_destqor] = log.(exp.(gravity_quint[:,:ypc_dest]) ./ exp.(gravity_quint[:,:ypc_quint_orig]))      

# Run regression of ypc_rel_destqor on flowshare_quintdest separately for each destination quintile
regsd1 = reg(rename(gravity_quint[(gravity_quint[:,:quint_dest].=="q1"),:],:flowshare_quintdest=>:flowshare_qdest1), @formula(flowshare_qdest1 ~ ypc_rel_destqor), Vcov.cluster(:OrigCategorical, :DestCategorical))
regsd2 = reg(rename(gravity_quint[(gravity_quint[:,:quint_dest].=="q2"),:],:flowshare_quintdest=>:flowshare_qdest2), @formula(flowshare_qdest2 ~ ypc_rel_destqor), Vcov.cluster(:OrigCategorical, :DestCategorical))
regsd3 = reg(rename(gravity_quint[(gravity_quint[:,:quint_dest].=="q3"),:],:flowshare_quintdest=>:flowshare_qdest3), @formula(flowshare_qdest3 ~ ypc_rel_destqor), Vcov.cluster(:OrigCategorical, :DestCategorical))
regsd4 = reg(rename(gravity_quint[(gravity_quint[:,:quint_dest].=="q4"),:],:flowshare_quintdest=>:flowshare_qdest4), @formula(flowshare_qdest4 ~ ypc_rel_destqor), Vcov.cluster(:OrigCategorical, :DestCategorical))
regsd5 = reg(rename(gravity_quint[(gravity_quint[:,:quint_dest].=="q5"),:],:flowshare_quintdest=>:flowshare_qdest5), @formula(flowshare_qdest5 ~ ypc_rel_destqor), Vcov.cluster(:OrigCategorical, :DestCategorical))

regtable(regsd1,regsd2,regsd3,regsd4,regsd5; renderSettings = asciiOutput(),regression_statistics=[:nobs, :r2 ])     

gamma_quint = DataFrame(
    regtype = ["reg_sharedest_q1","reg_sharedest_q2", "reg_sharedest_q3","reg_sharedest_q4", "reg_sharedest_q5"],
    gamma0 = [-1.464,-1.765,-2.292,-1.859,-1.450],       # intercept
    gamma1 = [0.142,0.073,0.027,0.023,-0.149],       # ypc_dest / ypc_quint_orig
)

CSV.write(joinpath(@__DIR__,"../results/gravity/gamma_quint.csv"), gamma_quint)
for j in 2:size(gamma_quint,2)
    CSV.write(joinpath(@__DIR__,string("../data_mig/",string(names(gamma_quint)[j]),".csv")), DataFrame(quintiles=1:5,b=gamma_quint[:,j]);writeheader=false)
end


# Run regressions using terciles 
gravity_ineq = CSV.File(joinpath(@__DIR__,"../results/gravity/gravity_ineq.csv")) |> DataFrame

edu_bil_terc = CSV.File(joinpath(@__DIR__,"../../../results/edu_bil_terc.csv")) |> DataFrame

edu_bil_terc[!,:flow_terc_share] = edu_bil_terc[:,:flow_terc] ./ edu_bil_terc[:,:flow]
for i in 1:size(edu_bil_terc,1) ; if edu_bil_terc[i,:flow_terc] == 0.0 && edu_bil_terc[i,:flow] == 0.0 ; edu_bil_terc[i,:flow_terc_share] = 0 end end

gravity_terc = innerjoin(gravity_ineq[.&(gravity_ineq[:,:year].==2010),:], edu_bil_terc[:,union(1:2,4,6,7,9,11)], on = [:orig, :dest])
gravity_terc[!,:flow_terc] = map(x->log(x),map(x->exp(x), gravity_terc[:,:flow_AzoseRaftery]) .* gravity_terc[:,:flow_terc_share])
gravity_terc[!,:ypc_terc_orig] = map(x->log(x), gravity_terc[:,:ypc_terc_orig])
gravity_terc[!,:ypc_terc_dest] = map(x->log(x), gravity_terc[:,:ypc_terc_dest])
gravity_terc[!,:pop_terc_orig] = map(x->log(exp(x)/5), gravity_terc[:,:pop_orig])
gravity_terc[!,:pop_terc_dest] = map(x->log(exp(x)/5), gravity_terc[:,:pop_dest])

gravity_terc[!,:ypcratio_avav] = map(x->log(x), map(x->exp(x), gravity_terc[:,:ypc_dest]) ./ map(x->exp(x), gravity_terc[:,:ypc_orig]))
gravity_terc[!,:ypcratio_avsp] = map(x->log(x), map(x->exp(x), gravity_terc[:,:ypc_dest]) ./ map(x->exp(x), gravity_terc[:,:ypc_terc_orig]))
gravity_terc[!,:ypcratio_spav] = map(x->log(x), map(x->exp(x), gravity_terc[:,:ypc_terc_dest]) ./ map(x->exp(x), gravity_terc[:,:ypc_orig]))
gravity_terc[!,:ypcratio_spsp] = map(x->log(x), map(x->exp(x), gravity_terc[:,:ypc_terc_dest]) ./ map(x->exp(x), gravity_terc[:,:ypc_terc_orig]))
gravity_terc[!,:ypc_terc_orig_sq] = gravity_terc[:,:ypc_terc_orig].^2
gravity_terc[!,:ypc_terc_orig_cu] = gravity_terc[:,:ypc_terc_orig].^3

gravity_terc_or = combine(groupby(view(gravity_terc,:,:), [:orig,:dest,:terc_orig]), :flow_terc_share => sum)
gravity_terc = innerjoin(gravity_terc, gravity_terc_or, on = [:orig,:dest,:terc_orig])
gravity_terc[!,:flowshare_tercdest] = map(x -> log(x), gravity_terc[:,:flow_terc_share] ./ gravity_terc[:,:flow_terc_share_sum])

gravity_terc[!,:ypc_rel_desttor] = log.(exp.(gravity_terc[:,:ypc_dest]) ./ exp.(gravity_terc[:,:ypc_terc_orig]))

regsdt1 = reg(rename(gravity_terc[(gravity_terc[:,:terc_dest].=="t1"),:],:flowshare_tercdest=>:flowshare_tdest1), @formula(flowshare_tdest1 ~ ypc_rel_desttor), Vcov.cluster(:OrigCategorical, :DestCategorical))
regsdt2 = reg(rename(gravity_terc[(gravity_terc[:,:terc_dest].=="t2"),:],:flowshare_tercdest=>:flowshare_tdest2), @formula(flowshare_tdest2 ~ ypc_rel_desttor), Vcov.cluster(:OrigCategorical, :DestCategorical))
regsdt3 = reg(rename(gravity_terc[(gravity_terc[:,:terc_dest].=="t3"),:],:flowshare_tercdest=>:flowshare_tdest3), @formula(flowshare_tdest3 ~ ypc_rel_desttor), Vcov.cluster(:OrigCategorical, :DestCategorical))

regtable(regsdt1,regsdt2,regsdt3; renderSettings = asciiOutput(),regression_statistics=[:nobs, :r2 ])     


#################################################################### Estimating the remittances share #####################################################
# Reading GDP per capita at country level; data for 2017 from World Bank(WDI), in current USD. 
ypc_2017 = readdlm(joinpath(@__DIR__,"../input_data/ypc2017.csv"), ';', comments = true)
ypc2017 = DataFrame(iso3c = ypc_2017[2:end,1], ypc = ypc_2017[2:end,2])
for i in 1:size(ypc2017, 1) ; if ypc2017[:ypc][i] == ".." ; ypc2017[:ypc][i] = missing end end      # replacing missing values by missing

data_17 = join(ypc2017, iso3c_isonum, on=:iso3c)
dropmissing!(data_17)       # remove rows with missing values in ypc

data_17 = join(data_17, rename(pop_allvariants[.&(pop_allvariants[:,:Variant].=="Medium", pop_allvariants[:,:Time].==2017),[:LocID,:PopTotal]], :LocID=>:isonum), on=:isonum)
data_17[!,:PopTotal] .*= 1000        # pop is in thousands

gravity_17 = join(rename(data_17, :iso3c => :orig, :ypc=>:ypc_orig,:PopTotal=>:pop_orig)[:,Not(:isonum)], remittances, on=:orig)
gravity_17 = join(rename(data_17,:iso3c=>:dest,:ypc=>:ypc_dest,:PopTotal=>:pop_dest)[:,Not(:isonum)], gravity_17, on=:dest)
gravity_17[!,:ypc_ratio] = gravity_17[!,:ypc_dest] ./ gravity_17[!,:ypc_orig]

# log transformation
for name in [:pop_orig, :pop_dest, :ypc_orig, :ypc_dest, :ypc_ratio]
    gravity_17[!,name] = [log(gravity_17[i,name]) for i in 1:size(gravity_17, 1)]
end
gravity_17[!,:log_remshare] = [log(gravity_17[i,:remshare]) for i in 1:size(gravity_17, 1)]

# Create country fixed effects
gravity_17.OrigCategorical = categorical(gravity_17.orig)
gravity_17.DestCategorical = categorical(gravity_17.dest)

r17anex1 = reg(gravity_17, @formula(remshare ~ ypc_orig + ypc_dest + remcost), Vcov.cluster(:OrigCategorical, :DestCategorical), save=true)
r17anex2 = reg(gravity_17, @formula(remshare ~ ypc_dest + ypc_ratio + remcost), Vcov.cluster(:OrigCategorical, :DestCategorical), save=true)
r17anex5 = reg(gravity_17[(gravity_17[:,:remshare] .!= 0.0),:], @formula(log_remshare ~ ypc_orig + ypc_dest + remcost), Vcov.cluster(:OrigCategorical, :DestCategorical), save=true)
r17anex6 = reg(gravity_17[(gravity_17[:,:remshare] .!= 0.0),:], @formula(log_remshare ~ ypc_dest + ypc_ratio + remcost), Vcov.cluster(:OrigCategorical, :DestCategorical), save=true)

regtable(r17anex1, r17anex2, r17anex5, r17anex6; renderSettings = latexOutput(),regression_statistics=[:nobs, :r2])     
