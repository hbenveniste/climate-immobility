using CSV, DataFrames, Statistics, Query


regions = ["USA", "CAN", "WEU", "JPK", "ANZ", "EEU", "FSU", "MDE", "CAM", "LAM", "SAS", "SEA", "CHI", "MAF", "SSA", "SIS"]

emtot = CSV.File(joinpath(@__DIR__, "../input_data/emtot_10.csv")) |> DataFrame

countries = unique(emtot[:,:country])
ssps = unique(emtot[:,:scenario])


########################## Extend SSP GHG emissions scenarios with and without migration ######################################
em_ssp = @from i in emtot begin
    @where i.gas == "Emissions|CO2"
    @select {i.scenario, i.period, i.country, i.scen, i.em_mig, i.em_nomig}
    @collect DataFrame
end

# Linearizing emissions from 5- or 10-year periods to yearly values                                               
em_allyr = DataFrame(
    period = repeat(2015:2100, outer = length(ssps)*length(countries)),
    scenario = repeat(ssps, inner = length(2015:2100)*length(countries)),
    country = repeat(countries, inner = length(2015:2100), outer = length(ssps))
)
em_ssp = join(em_ssp, em_allyr, on = [:period, :scenario, :country], kind = :outer)
sort!(em_ssp, [:scenario, :country, :period])
for i in 1:size(em_ssp,1)
    if em_ssp[i,:period]>= 2020
        if mod(em_ssp[i,:period], 10) != 0
            ind = i - mod(em_ssp[i,:period], 10)
            for name in [:em_mig, :em_nomig]
                floor = em_ssp[ind,name] ; ceiling = em_ssp[ind+10,name]
                a = floor + (ceiling - floor) / 10 * mod(em_ssp[i,:period], 10)
                em_ssp[i, name] = a
            end
        end
    else
        if mod(em_ssp[i,:period], 5) != 0
            ind = i - mod(em_ssp[i,:period], 5)
            for name in [:em_mig, :em_nomig]
                floor = em_ssp[ind,name] ; ceiling = em_ssp[ind+5,name]
                a = floor + (ceiling - floor) / 5 * mod(em_ssp[i,:period], 5)
                em_ssp[i, name] = a
            end
        end
    end
end
em_ssp[:,:scen] = map(x -> SubString(x, 1:4), em_ssp[:,:scenario])

# For 1990-2015: use CMIP6 historical projection 
em_hist_all = CSV.File(joinpath(@__DIR__, "../input_data/emhist_10.csv")) |> DataFrame
em_hist_sect = @from i in em_hist_all begin
    @where i.gas == "Emissions|CO2"
    @select {i.period, i.country, i.type, i.em_hist}
    @collect DataFrame
end
em_hist = by(em_hist_sect, [:period, :country], d -> sum(d.em_hist))
sort!(em_hist, [:country,:period])
countries_hist = unique(em_hist[:,:country])
em_past = DataFrame(
    scenario = repeat(ssps, inner=length(countries_hist)*length(1990:2014)),
    period = repeat(1990:2014, outer=length(countries_hist)*length(ssps)),
    country = repeat(countries_hist, outer=length(ssps), inner=length(1990:2014)),
    scen = map(x -> SubString(x, 1:4), repeat(ssps, inner=length(countries_hist)*length(1990:2014))),
    em_mig = repeat(em_hist[:,:x1], outer=length(ssps)),
    em_nomig = repeat(em_hist[:,:x1], outer=length(ssps))
)
em_ssp = vcat(em_ssp, em_past)
sort!(em_ssp, [:scenario, :country, :period])

# For 1950-1990: use default FUND scenario acei (growth rate of emissions per energy consumption)
scenaeei = CSV.File(joinpath(@__DIR__, "../input_data/scenaeei.csv"), header=false, datarow=2, delim = ",") |> DataFrame
rename!(scenaeei, :Column1 => :year, :Column2 => :fundregion, :Column3 => :aeei)
scenacei = CSV.File(joinpath(@__DIR__, "../input_data/scenacei.csv"), header=false, datarow=2, delim = ",") |> DataFrame
rename!(scenacei, :Column1 => :year, :Column2 => :fundregion, :Column3 => :acei)
scenemgrowth = join(scenaeei, scenacei, on = [:year, :fundregion])
rename!(scenemgrowth, :year => :period)

gdp_ssp = CSV.File(joinpath(@__DIR__,"../../../results/gdp_ssp.csv")) |> DataFrame
em_ssp = join(em_ssp, gdp_ssp[(gdp_ssp[:,:period].<=2100),:], on = [:period, :scen, :country], kind = :outer)
em_ssp = join(em_ssp, scenemgrowth[(scenemgrowth[:,:period].<=2100),:], on = [:period, :fundregion], kind = :outer)
for i in 1:size(em_ssp,1)
    if ismissing(em_ssp[i,:scenario])
        em_ssp[i,:scenario] = em_ssp[i,:scen]=="SSP1" ? em_ssp[i,:scenario]=ssps[1] : (em_ssp[i,:scen]=="SSP2" ? em_ssp[i,:scenario]=ssps[2] : (em_ssp[i,:scen]=="SSP3" ? em_ssp[i,:scenario]=ssps[3] : (em_ssp[i,:scen]=="SSP4" ? em_ssp[i,:scenario]=ssps[4] : em_ssp[i,:scenario]=ssps[5])))
    end
end
sort!(em_ssp, [:scenario, :country, :period])

for s in ssps
    for c in unique(gdp_ssp[(gdp_ssp[:,:period].<=1990),:country])
        for t in 1989:-1:1950
            indt = intersect(findall(em_ssp[:,:scenario].==s),findall(em_ssp[:,:country].==c),findall(em_ssp[:,:period].==t))[1]
            em_ssp[indt,:em_mig] = em_ssp[indt+1,:em_mig] / (1 + em_ssp[indt,:acei]/100) / (1 + em_ssp[indt,:aeei]/100) * em_ssp[indt,:gdp_mig] / em_ssp[indt+1,:gdp_mig]
            em_ssp[indt,:em_nomig] = em_ssp[indt+1,:em_nomig] / (1 + em_ssp[indt,:acei]/100) / (1 + em_ssp[indt,:aeei]/100) * em_ssp[indt,:gdp_nomig] / em_ssp[indt+1,:gdp_nomig]
        end
        print(s," ", c, " ")
    end
end
sort!(em_ssp, [:scenario, :country, :period])

# For 2100-2300: 
# Remove CO2 LULUCF net: linear decline in emissions reaching 0 in 2200
em_ds = CSV.File(joinpath(@__DIR__, "../input_data/em_downscaled.csv")) |> DataFrame
rename!(em_ds, :variable => :type)
select!(em_ds, Not(6:30))        # remove historical years
emissions = stack(em_ds, 6:size(em_ds,2))
rename!(emissions, :variable => :year)
permutecols!(emissions, [3,4,6,7,1,5,2])
sort!(emissions, [:model, :scenario, :year, :region, :type])
indhist = findall(emissions[!,:model] .== "History")
deleterows!(emissions, indhist)     # remove historical model
em_lu = @from i in emissions begin
    @where (i.type == "Emissions|CO2|Agricultural Waste Burning" || i.type == "Emissions|CO2|Agriculture" || i.type == "Emissions|CO2|Forest Burning" || i.type == "Emissions|CO2|Grassland Burning" || i.type == "Emissions|CO2|Peat Burning") 
    @select {i.scenario, i.year, i.region, i.value}
    @collect DataFrame
end
describe(em_lu)

# For CO2 emissions from fossil fuels and industry: fixed growth rate of emissions per GDP at 2090-2100 rate (as done in IWG SCC, source by Kevin Rennert RFF)
# If growth rate >0 in 2100, declining growth rate of emissions per GDP until 0 in 2300
gs2300 = @from i in gdp_ssp begin
    @where i.period <= 2300 && i.period >= 2100
    @select {i.period, i.scen, i.country, i.gdp_mig, i.gdp_nomig, i.fundregion}
    @collect DataFrame
end
em_ssp = join(em_ssp, gs2300, on=[:scen,:period,:country, :gdp_mig, :gdp_nomig, :fundregion], kind=:outer)
for i in 1:size(em_ssp,1)
    if ismissing(em_ssp[i,:scenario])
        em_ssp[i,:scenario] = em_ssp[i,:scen]=="SSP1" ? em_ssp[i,:scenario]=ssps[1] : (em_ssp[i,:scen]=="SSP2" ? em_ssp[i,:scenario]=ssps[2] : (em_ssp[i,:scen]=="SSP3" ? em_ssp[i,:scenario]=ssps[3] : (em_ssp[i,:scen]=="SSP4" ? em_ssp[i,:scenario]=ssps[4] : em_ssp[i,:scenario]=ssps[5])))
    end
end
sort!(em_ssp, [:scenario,:country,:period])
for s in ssps
    for c in unique(gdp_ssp[:,:country])
        ind2100 = intersect(findall(em_ssp[:,:scenario].==s),findall(em_ssp[:,:country].==c),findall(em_ssp[:,:period].==2100))
        ind2090 = intersect(findall(em_ssp[:,:scenario].==s),findall(em_ssp[:,:country].==c),findall(em_ssp[:,:period].==2090))
        # Limit growth rate of emissions to +/-50% per decade
        g2100_mig = min(0.05, max(-0.05, 1 / 10 * ((em_ssp[ind2100,:em_mig][1] / em_ssp[ind2100,:gdp_mig][1]) / (em_ssp[ind2090,:em_mig][1] / em_ssp[ind2090,:gdp_mig][1]) - 1)))
        g2100_nomig = min(0.05, max(-0.05, 1 / 10 * ((em_ssp[ind2100,:em_nomig][1] / em_ssp[ind2100,:gdp_nomig][1]) / (em_ssp[ind2090,:em_nomig][1] / em_ssp[ind2090,:gdp_nomig][1]) - 1)))
        for t in 2101:2300
            indt = intersect(findall(em_ssp[:,:scenario].==s),findall(em_ssp[:,:country].==c),findall(em_ssp[:,:period].==t))
            if g2100_mig > 0.1
                em_ssp[indt[1], :em_mig] = (1 - g2100_mig ) * em_ssp[indt[1]-1,:em_mig] * em_ssp[indt[1],:gdp_mig] / em_ssp[indt[1]-1,:gdp_mig]
            elseif g2100_mig > 0 && em_ssp[ind2100,:em_mig][1] < 0
                em_ssp[indt[1], :em_mig] = (1 - g2100_mig * (1 - 1 / 200 * (t-2100))) * em_ssp[indt[1]-1,:em_mig] * em_ssp[indt[1],:gdp_mig] / em_ssp[indt[1]-1,:gdp_mig]
            elseif g2100_mig > 0
                em_ssp[indt[1], :em_mig] = (1 + g2100_mig * (1 - 1 / 200 * (t-2100))) * em_ssp[indt[1]-1,:em_mig] * em_ssp[indt[1],:gdp_mig] / em_ssp[indt[1]-1,:gdp_mig]
            else
                em_ssp[indt[1], :em_mig] = (1 + g2100_mig) * em_ssp[indt[1]-1,:em_mig] * em_ssp[indt[1],:gdp_mig] / em_ssp[indt[1]-1,:gdp_mig]
            end
            if g2100_nomig > 0.1 
                em_ssp[indt[1], :em_nomig] = (1 - g2100_nomig ) * em_ssp[indt[1]-1,:em_nomig] * em_ssp[indt[1],:gdp_nomig] / em_ssp[indt[1]-1,:gdp_nomig]
            elseif g2100_nomig > 0 && em_ssp[ind2100,:em_nomig][1] < 0 
                em_ssp[indt[1], :em_nomig] = (1 - g2100_nomig * (1 - 1 / 200 * (t-2100))) * em_ssp[indt[1]-1,:em_nomig] * em_ssp[indt[1],:gdp_nomig] / em_ssp[indt[1]-1,:gdp_nomig]
            elseif g2100_nomig > 0
                em_ssp[indt[1], :em_nomig] = (1 + g2100_nomig * (1 - 1 / 200 * (t-2100))) * em_ssp[indt[1]-1,:em_nomig] * em_ssp[indt[1],:gdp_nomig] / em_ssp[indt[1]-1,:gdp_nomig]
            else
                em_ssp[indt[1], :em_nomig] = (1 + g2100_nomig) * em_ssp[indt[1]-1,:em_nomig] * em_ssp[indt[1],:gdp_nomig] / em_ssp[indt[1]-1,:gdp_nomig]
            end
        end
        print(s," ", c, " ")
    end
end

# For 2300-3000: keep emissions per GDP constant (different from the default FUND scenarios, which keep it constantly growing at 0.1%)
# Because GDP is constant after 2300, means keep emissions constant
em_ssp[!,:emgdp_mig] = em_ssp[!,:em_mig] ./ em_ssp[!,:gdp_mig]
em_ssp[!,:emgdp_nomig] = em_ssp[!,:em_nomig] ./ em_ssp[!,:gdp_nomig]
emgdp2300 = em_ssp[(em_ssp[:,:period].==2300),[:scen,:country,:emgdp_mig,:emgdp_nomig]]
gs3000 = @from i in gdp_ssp begin
    @where i.period > 2300 
    @select {i.period, i.scen, i.country, i.gdp_mig, i.gdp_nomig, i.fundregion}
    @collect DataFrame
end
gs3000 = join(gs3000, emgdp2300, on =[:scen,:country], kind = :left)
em_ssp = join(em_ssp, gs3000, on = [:scen, :period, :country, :fundregion, :gdp_mig, :gdp_nomig, :emgdp_mig, :emgdp_nomig], kind = :outer)
for i in 1:size(em_ssp,1)
    if ismissing(em_ssp[i,:scenario])
        em_ssp[i,:scenario] = em_ssp[i,:scen]=="SSP1" ? em_ssp[i,:scenario]=ssps[1] : (em_ssp[i,:scen]=="SSP2" ? em_ssp[i,:scenario]=ssps[2] : (em_ssp[i,:scen]=="SSP3" ? em_ssp[i,:scenario]=ssps[3] : (em_ssp[i,:scen]=="SSP4" ? em_ssp[i,:scenario]=ssps[4] : em_ssp[i,:scenario]=ssps[5])))
    end
end
sort!(em_ssp, [:scenario, :country, :period])

for i in 1:size(em_ssp,1)
    if em_ssp[i,:period] > 2300
        em_ssp[i,:em_mig] = em_ssp[i,:emgdp_mig] * em_ssp[i,:gdp_mig]
        em_ssp[i,:em_nomig] = em_ssp[i,:emgdp_nomig] * em_ssp[i,:gdp_nomig]
    end
end

# Convert to FUND regions
em_ssp_f = by(em_ssp, [:period, :scenario, :scen, :fundregion], d -> (em_mig = sum(skipmissing(d.em_mig)), em_nomig = sum(skipmissing(d.em_nomig))))
# Remove data from small countries that don't have a corresponding FUND region: "ASM", "ATG", "BMU", "COK", "CUW", "CYM", "DMA", "ESH", "FLK", "FRO", "FSM", "GIB", "GLP", "GRD", "GRL", "GUF", "GUM", "KIR", "KNA", "LIE", "MHL", "MSR","MTQ", "NIU", "PLW", "PRK", "REU", "SPM", "SRB (KOSOVO)", "SSD", "SXM", "SYC", "TCA", "TKL", "VGB", "VIR", "WLF"
indmissing = findall(map(x->ismissing(x),em_ssp_f[:,:fundregion]))
deleterows!(em_ssp_f, indmissing)

# Sorting the data
regionsdf = DataFrame(fundregion = regions, index = 1:16)
em_ssp_f = join(em_ssp_f, regionsdf, on = :fundregion)
sort!(em_ssp_f, [:scenario, :period, :index])

# Write for each SSP and mig/nomig separately
ssps= unique(em_ssp[:,:scen])
for s in ssps
    CSV.write(joinpath(@__DIR__, string("../scen/em_mig_", s, ".csv")), em_ssp_f[(em_ssp_f[:,:scen].==s),[:period, :fundregion, :em_mig]]; writeheader=false)
    CSV.write(joinpath(@__DIR__, string("../scen/em_nomig_", s, ".csv")), em_ssp_f[(em_ssp_f[:,:scen].==s),[:period, :fundregion, :em_nomig]]; writeheader=false)
end
CSV.write(joinpath(@__DIR__, "../../../results/em_ssp.csv"), em_ssp)