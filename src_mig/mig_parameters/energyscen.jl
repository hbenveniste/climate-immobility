using CSV, DataFrames, Statistics, Query


regions = ["USA", "CAN", "WEU", "JPK", "ANZ", "EEU", "FSU", "MDE", "CAM", "LAM", "SAS", "SEA", "CHI", "MAF", "SSA", "SIS"]

energytot = CSV.read(joinpath(@__DIR__, "../input_data/energytot_10.csv"))

countries = unique(energytot[:,:country])
ssps = unique(energytot[:,:scenario])


########################## Extend SSP final energy consumption scenarios with and without migration ######################################
en_ssp = energytot[:,[:scenario, :period, :country, :en_mig, :en_nomig]]
# Consider that energy consumption in 2010 for no migration is the same as with migration
ind2010 = findall(energytot[:,:period].==2010)
for i in ind2010
    en_ssp[i,:en_nomig] = en_ssp[i,:en_mig]
end

# Linearizing energy from 10-year periods to yearly values                                               
en_allyr = DataFrame(
    period = repeat(2010:2100, outer = length(ssps)*length(countries)),
    scenario = repeat(ssps, inner = length(2010:2100)*length(countries)),
    country = repeat(countries, inner = length(2010:2100), outer = length(ssps))
)
en_ssp = join(en_ssp, en_allyr, on = [:period, :scenario, :country], kind = :outer)
sort!(en_ssp, [:scenario, :country, :period])
for i in 1:size(en_ssp,1)
    if mod(en_ssp[i,:period], 10) != 0
        ind = i - mod(en_ssp[i,:period], 10)
        for name in [:en_mig, :en_nomig]
            floor = en_ssp[ind,name] ; ceiling = en_ssp[ind+10,name]
            a = floor + (ceiling - floor) / 10 * mod(en_ssp[i,:period], 10)
            en_ssp[i, name] = a
        end
    end
end

# For 1950-2010: use default FUND scenario aeei (growth rate of energy intensity of GDP)
scenpgrowth = CSV.read(joinpath(@__DIR__, "../input_data/scenpgrowth.csv"), header=false, datarow=2, delim = ",")
rename!(scenpgrowth, :Column1 => :year, :Column2 => :fundregion, :Column3 => :pgrowth)
scenypcgrowth = CSV.read(joinpath(@__DIR__, "../input_data/scenypcgrowth.csv"), header=false, datarow=2, delim = ",")
rename!(scenypcgrowth, :Column1 => :year, :Column2 => :fundregion, :Column3 => :ypcgrowth)
scenaeei = CSV.read(joinpath(@__DIR__, "../input_data/scenaeei.csv"), header=false, datarow=2, delim = ",")
rename!(scenaeei, :Column1 => :year, :Column2 => :fundregion, :Column3 => :aeei)
scenengrowth = join(scenaeei, join(scenpgrowth, scenypcgrowth, on = [:year, :fundregion]), on = [:year, :fundregion])
scenengrowth[!,:engrowth_f] = ((1 .+ scenengrowth[:,:aeei] ./ 100) .* (1 .+ scenengrowth[:,:ypcgrowth] ./ 100) .* (1 .+ scenengrowth[:,:pgrowth] ./ 100) .- 1) .* 100

iso3c_fundregion = CSV.read("../input_data/iso3c_fundregion.csv")
rename!(iso3c_fundregion, :iso3c => :country)
en_ssp = join(en_ssp, iso3c_fundregion, on = :country)

for s in ssps
    for c in countries
        f = en_ssp[.&(en_ssp[:,:scenario].==s, en_ssp[:,:country].==c),:fundregion][1]
        for t in 2009:-1:1950
            gt = scenengrowth[.&(scenengrowth[:,:fundregion].==f,scenengrowth[:,:year].==t),:engrowth_f][1] / 100
            e_mig = en_ssp[.&(en_ssp[:,:scenario].==s,en_ssp[:,:country].==c,en_ssp[:,:period].==t+1),:en_mig][1] / (1 + gt)
            e_nomig = en_ssp[.&(en_ssp[:,:scenario].==s,en_ssp[:,:country].==c,en_ssp[:,:period].==t+1),:en_nomig][1] / (1 + gt)
            push!(en_ssp, [s, t, c, e_mig, e_nomig, f])
        end
        print(s," ", c, " ")
    end
end
sort!(en_ssp, [:scenario, :country, :period])

# For 2100-2300: fixed growth rate of energy consumption per GDP at 2090-2100 rate (as done in IWG SCC, source by Kevin Rennert RFF)
gdp_ssp = CSV.read(joinpath(@__DIR__,"../../Documents/WorkInProgress/migrations-Esteban-FUND/results/gdp_ssp.csv"))
en_ssp[:,:scen] = map(x -> SubString(x, 1:4), en_ssp[:,:scenario])
gs2300 = @from i in gdp_ssp begin
    @where i.period <= 2300 && i.country in countries
    @select {i.period, i.scen, i.country, i.gdp_mig, i.gdp_nomig, i.fundregion}
    @collect DataFrame
end
en_ssp = join(en_ssp, gs2300, on=[:scen,:period,:country, :fundregion], kind=:right)
for i in 1:size(en_ssp,1)
    if ismissing(en_ssp[i,:scenario])
        en_ssp[i,:scenario] = en_ssp[i,:scen]=="SSP1" ? en_ssp[i,:scenario]=ssps[1] : (en_ssp[i,:scen]=="SSP2" ? en_ssp[i,:scenario]=ssps[2] : (en_ssp[i,:scen]=="SSP3" ? en_ssp[i,:scenario]=ssps[3] : (en_ssp[i,:scen]=="SSP4" ? en_ssp[i,:scenario]=ssps[4] : en_ssp[i,:scenario]=ssps[5])))
    end
end
# If growth rate >0 in 2100, declining growth rate of energy per GDP until 0 in 2300 (otherwise crazy amount of energy)
sort!(en_ssp, [:scenario,:country,:period])
for s in ssps
    for c in countries
        ind2100 = intersect(findall(en_ssp[:,:scenario].==s),findall(en_ssp[:,:country].==c),findall(en_ssp[:,:period].==2100))
        ind2090 = intersect(findall(en_ssp[:,:scenario].==s),findall(en_ssp[:,:country].==c),findall(en_ssp[:,:period].==2090))
        g2100_mig = min(0.05, 1 / 10 * ((en_ssp[ind2100,:en_mig][1] / en_ssp[ind2100,:gdp_mig][1]) / (en_ssp[ind2090,:en_mig][1] / en_ssp[ind2090,:gdp_mig][1]) - 1))
        g2100_nomig = min(0.05, 1 / 10 * ((en_ssp[ind2100,:en_nomig][1] / en_ssp[ind2100,:gdp_nomig][1]) / (en_ssp[ind2090,:en_nomig][1] / en_ssp[ind2090,:gdp_nomig][1]) - 1))
        for t in 2101:2300
            indt = intersect(findall(en_ssp[:,:scenario].==s),findall(en_ssp[:,:country].==c),findall(en_ssp[:,:period].==t))
            if g2100_mig > 0.1
                en_ssp[indt[1], :en_mig] = (1 - g2100_mig ) * en_ssp[indt[1]-1,:en_mig] * en_ssp[indt[1],:gdp_mig] / en_ssp[indt[1]-1,:gdp_mig]
            elseif g2100_mig > 0
                en_ssp[indt[1], :en_mig] = (1 + g2100_mig * (1 - 1 / 200 * (t-2100))) * en_ssp[indt[1]-1,:en_mig] * en_ssp[indt[1],:gdp_mig] / en_ssp[indt[1]-1,:gdp_mig]
            else
                en_ssp[indt[1], :en_mig] = (1 + g2100_mig) * en_ssp[indt[1]-1,:en_mig] * en_ssp[indt[1],:gdp_mig] / en_ssp[indt[1]-1,:gdp_mig]
            end
            if g2100_nomig > 0.1
                en_ssp[indt[1], :en_nomig] = (1 - g2100_nomig ) * en_ssp[indt[1]-1,:en_nomig] * en_ssp[indt[1],:gdp_nomig] / en_ssp[indt[1]-1,:gdp_nomig]
            elseif g2100_nomig > 0
                en_ssp[indt[1], :en_nomig] = (1 + g2100_nomig * (1 - 1 / 200 * (t-2100))) * en_ssp[indt[1]-1,:en_nomig] * en_ssp[indt[1],:gdp_nomig] / en_ssp[indt[1]-1,:gdp_nomig]
            else
                en_ssp[indt[1], :en_nomig] = (1 + g2100_nomig) * en_ssp[indt[1]-1,:en_nomig] * en_ssp[indt[1],:gdp_nomig] / en_ssp[indt[1]-1,:gdp_nomig]
            end
        end
        print(s," ", c, " ")
    end
end

# For 2300-3000: keep energy intensity of GDP constant.
en_ssp[!,:engdp_mig] = en_ssp[!,:en_mig] ./ en_ssp[!,:gdp_mig]
en_ssp[!,:engdp_nomig] = en_ssp[!,:en_nomig] ./ en_ssp[!,:gdp_nomig]
engdp2300 = en_ssp[(en_ssp[:,:period].==2300),[:scen,:country,:engdp_mig,:engdp_nomig]]
gs3000 = @from i in gdp_ssp begin
    @where i.period > 2300 && i.country in countries
    @select {i.period, i.scen, i.country, i.gdp_mig, i.gdp_nomig, i.fundregion}
    @collect DataFrame
end
gs3000 = join(gs3000, engdp2300, on =[:scen,:country], kind = :left)
en_ssp = join(en_ssp, gs3000, on = [:scen, :period, :country, :fundregion, :gdp_mig, :gdp_nomig, :engdp_mig, :engdp_nomig], kind = :outer)
for i in 1:size(en_ssp,1)
    if ismissing(en_ssp[i,:scenario])
        en_ssp[i,:scenario] = en_ssp[i,:scen]=="SSP1" ? en_ssp[i,:scenario]=ssps[1] : (en_ssp[i,:scen]=="SSP2" ? en_ssp[i,:scenario]=ssps[2] : (en_ssp[i,:scen]=="SSP3" ? en_ssp[i,:scenario]=ssps[3] : (en_ssp[i,:scen]=="SSP4" ? en_ssp[i,:scenario]=ssps[4] : en_ssp[i,:scenario]=ssps[5])))
    end
end
sort!(en_ssp, [:scenario, :country, :period])

for i in 1:size(en_ssp,1)
    if en_ssp[i,:period] > 2300
        en_ssp[i,:en_mig] = en_ssp[i,:engdp_mig] * en_ssp[i,:gdp_mig]
        en_ssp[i,:en_nomig] = en_ssp[i,:engdp_nomig] * en_ssp[i,:gdp_nomig]
    end
end

#en_fut = DataFrame(
#    scenario = repeat(ssps, inner = length(2301:3000)*length(countries)),
#    period = repeat(2301:3000, outer = length(ssps)*length(countries)),
#    country = repeat(countries, inner = length(2301:3000), outer = length(ssps)),
#    en_mig = repeat(en2300[:,:en_mig], inner=length(2301:3000)),
#    en_nomig = repeat(en2300[:,:en_nomig], inner=length(2301:3000))
#)
#en_fut[:,:scen] = map(x -> SubString(x, 1:4), en_fut[:,:scenario])
#en_fut = join(en_fut, gs3000, on=[:scen,:period,:country], kind=:outer)
#permutecols!(en_fut, [1,2,3,4,5,9,6,7,8])
#en_ssp = vcat(en_ssp, en_fut)
#sort!(en_ssp, [:scenario, :country, :period])

# Convert to FUND regions
en_ssp_f = by(en_ssp, [:period, :scenario, :fundregion, :scen], d -> (en_mig = sum(skipmissing(d.en_mig)), en_nomig = sum(skipmissing(d.en_nomig))))

# Sorting the data
regionsdf = DataFrame(fundregion = regions, index = 1:16)
en_ssp_f = join(en_ssp_f, regionsdf, on = :fundregion)
sort!(en_ssp_f, [:scenario, :period, :index])

# Convert from EJ to TWh for FUND. 1 EJ = 277.778 TWh
en_ssp_f[!,:en_mig] .*= 277.778
en_ssp_f[!,:en_nomig] .*= 277.778

# Write for each SSP and mig/nomig separately
ssps= unique(en_ssp[:,:scen])
for s in ssps
    CSV.write(joinpath(@__DIR__, string("../scen/en_mig_", s, ".csv")), en_ssp_f[(en_ssp_f[:,:scen].==s),[:period, :fundregion, :en_mig]]; writeheader=false)
    CSV.write(joinpath(@__DIR__, string("../scen/en_nomig_", s, ".csv")), en_ssp_f[(en_ssp_f[:,:scen].==s),[:period, :fundregion, :en_nomig]]; writeheader=false)
end
CSV.write(joinpath(@__DIR__, "../../Documents/WorkInProgress/migrations-Esteban-FUND/results/en_ssp.csv"), en_ssp)