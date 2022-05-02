using CSV, DataFrames, Statistics, DelimitedFiles, FileIO


regions = ["USA", "CAN", "WEU", "JPK", "ANZ", "EEU", "FSU", "MDE", "CAM", "LAM", "SAS", "SEA", "CHI", "MAF", "SSA", "SIS"]
ssps = ["SSP1","SSP2","SSP3","SSP4","SSP5"]

sspall = CSV.read(joinpath(@__DIR__, "../input_data/sspall_10.csv"))

countries = unique(sspall[:,:country])


########################## Extend SSP GDP scenarios with and without migration ######################################
gdp_ssp = sspall[:,[:period, :scen, :country, :gdp_mig, :gdp_nomig, :ypc_mig, :ypc_nomig]]

# Linearizing GDP from 5-year periods to yearly values. Note: a value for year x actually represents GDP at the beginning of the five year period                                                
gdp_allyr = DataFrame(
    period = repeat(2015:2100, outer = length(ssps)*length(countries)),
    scen = repeat(ssps, inner = length(2015:2100)*length(countries)),
    country = repeat(countries, inner = length(2015:2100), outer = length(ssps))
)
gdp_ssp = join(gdp_ssp, gdp_allyr, on = [:period, :scen, :country], kind = :outer)
sort!(gdp_ssp, [:scen, :country, :period])
for i in 1:size(gdp_ssp,1)
    if mod(gdp_ssp[i,:period], 5) != 0
        ind = i - mod(gdp_ssp[i,:period], 5)
        for name in [:gdp_mig, :gdp_nomig, :ypc_mig, :ypc_nomig]
            floor = gdp_ssp[ind,name] ; ceiling = gdp_ssp[ind+5,name]
            a = floor + (ceiling - floor) / 5 * mod(gdp_ssp[i,:period], 5)
            gdp_ssp[i, name] = a
        end
    end
end

# For 1950-2015: use GDP growth in % from WDI (WB), when the data is available
# When not, use the default FUND scenario scenypcgrowth for the corresponding FUND region
gdpgrowth_unstacked = load(joinpath(@__DIR__,"../input_data/gdpgrowth_WDI.xlsx"), "gdpgrowth!A1:BK218") |> DataFrame
select!(gdpgrowth_unstacked, Not([Symbol("Series Name"),Symbol("Series Code"),Symbol("Country Name")]))
gdpgrowth = stack(gdpgrowth_unstacked, 2:size(gdpgrowth_unstacked,2))
rename!(gdpgrowth, :variable => :year, :value => :gdpgrowth, Symbol("Country Code") => :country)
gdpgrowth[!,:year] = map( x -> parse(Int, SubString(String(x), 1:4)), gdpgrowth[!,:year])
for i in 1:size(gdpgrowth,1)
    if gdpgrowth[i,:gdpgrowth] == ".."
        gdpgrowth[i,:gdpgrowth] = 0.0
    end
end

g0 = DataFrame(
    year = repeat(1950:1959, inner=length(unique(gdpgrowth[:,:country]))),
    gdpgrowth = zeros(length(1950:1959)*length(unique(gdpgrowth[:,:country]))),
    country = repeat(unique(gdpgrowth[:,:country]), outer=length(1950:1959))
)
gdpgrowth = vcat(gdpgrowth, g0)
sort!(gdpgrowth, [:year, :country])

scenpgrowth = CSV.read(joinpath(@__DIR__, "../input_data/scenpgrowth.csv"), header=false, datarow=2, delim = ",")
rename!(scenpgrowth, :Column1 => :year, :Column2 => :fundregion, :Column3 => :pgrowth)
scenypcgrowth = CSV.read(joinpath(@__DIR__, "../input_data/scenypcgrowth.csv"), header=false, datarow=2, delim = ",")
rename!(scenypcgrowth, :Column1 => :year, :Column2 => :fundregion, :Column3 => :ypcgrowth)
scengdpgrowth = join(scenpgrowth, scenypcgrowth, on = [:year, :fundregion])
scengdpgrowth[!,:gdpgrowth_f] = ((1 .+ scengdpgrowth[:,:ypcgrowth] ./ 100) .* (1 .+ scengdpgrowth[:,:pgrowth] ./ 100) .- 1) .* 100

iso3c_fundregion = CSV.read("../input_data/iso3c_fundregion.csv")
rename!(iso3c_fundregion, :iso3c => :country)
gdpgrowth = join(gdpgrowth, iso3c_fundregion, on = :country)

gdpgrowth = join(gdpgrowth, scengdpgrowth[(scengdpgrowth[:,:year].<2019),[:year,:fundregion,:gdpgrowth_f]], on = [:year, :fundregion])

for s in ssps
    for c in intersect(countries, unique(gdpgrowth[:,:country]))        # only Taiwan has no growth data
        for t in 2014:-1:1950
            indg = intersect(findall(gdpgrowth[:,:country].==c),findall(gdpgrowth[:,:year].==t))
            gt = gdpgrowth[indg,:gdpgrowth][1] / 100
            gtf = gdpgrowth[indg,:gdpgrowth_f][1] / 100
            inds = intersect(findall(gdp_ssp[:,:scen].==s),findall(gdp_ssp[:,:country].==c),findall(gdp_ssp[:,:period].==t+1))
            g_mig = gdp_ssp[inds,:gdp_mig][1] / (gt != 0.0 ? (1 + gt) : (1 + gtf))
            g_nomig = gdp_ssp[inds,:gdp_nomig][1] / (gt != 0.0 ? (1 + gt) : (1 + gtf))
            push!(gdp_ssp, [t, s, c, g_mig, g_nomig,missing,missing])
        end
        print(s," ", c, " ")
    end
end
sort!(gdp_ssp, [:scen, :country, :period])

# For 2100-2300: linear decline in GDP per capita growth rate reaching 0 (as done in IWG SCC, source by Kevin Rennert RFF)
pop_ssp = CSV.read(joinpath(@__DIR__, "../input_data/pop_ssp.csv"))
iso3c_isonum = CSV.read("../input_data/iso3c_isonum.csv")
pop_ssp = join(pop_ssp, rename(iso3c_isonum, :iso3c => :country, :isonum => :region), on = :region)
ps2300 = @from i in pop_ssp begin
    @where i.period <= 2300 && i.country in countries
    @select {i.period, i.scen, i.country, i.pop_mig, i.pop_nomig, i.fundregion}
    @collect DataFrame
end
gdp_ssp = join(gdp_ssp, ps2300, on = [:scen, :period, :country], kind = :right)
sort!(gdp_ssp, [:scen,:country,:period])
for s in ssps
    for c in countries
        indg = intersect(findall(gdp_ssp[:,:scen].==s),findall(gdp_ssp[:,:country].==c),findall(gdp_ssp[:,:period].==2100))
        g2100_mig = gdp_ssp[indg,:ypc_mig][1] / gdp_ssp[indg[1]-1,:ypc_mig] - 1
        g2100_nomig = gdp_ssp[indg,:ypc_nomig][1] / gdp_ssp[indg[1]-1,:ypc_nomig] - 1
        for t in 2101:2300
            indt = intersect(findall(gdp_ssp[:,:scen].==s),findall(gdp_ssp[:,:country].==c),findall(gdp_ssp[:,:period].==t))
            gdp_ssp[indt[1],:gdp_mig] = (1 +g2100_mig * (1 - 1 / 200 * (t-2100))) * gdp_ssp[indt[1]-1,:gdp_mig] * gdp_ssp[indt[1],:pop_mig] / gdp_ssp[indt[1]-1,:pop_mig]
            gdp_ssp[indt[1],:gdp_nomig] = (1 +g2100_nomig * (1 - 1 / 200 * (t-2100))) * gdp_ssp[indt[1]-1,:gdp_nomig] * gdp_ssp[indt[1],:pop_nomig] / gdp_ssp[indt[1]-1,:pop_nomig]
        end
        print(s," ", c, " ")
    end
end

# For 2300-3000: keep GDP per capita constant. Note: different from the default FUND scenarios, which keep ypc constantly growing at 0.6%
for i in 1:size(gdp_ssp,1)
    if gdp_ssp[i,:period] == 2300
        gdp_ssp[i,:ypc_mig] = gdp_ssp[i,:gdp_mig] / gdp_ssp[i,:pop_mig]
        gdp_ssp[i,:ypc_nomig] = gdp_ssp[i,:gdp_nomig] / gdp_ssp[i,:pop_nomig]
    end
end
ypc2300 = gdp_ssp[(gdp_ssp[:,:period].==2300),[:scen,:country,:ypc_mig,:ypc_nomig]]
ps3000 = @from i in pop_ssp begin
    @where i.period > 2300 && i.country in countries
    @select {i.period, i.scen, i.country, i.pop_mig, i.pop_nomig, i.fundregion}
    @collect DataFrame
end
ps3000 = join(ps3000, ypc2300, on = [:scen,:country], kind = :left)
gdp_ssp = join(gdp_ssp, ps3000, on = [:scen, :period, :country, :fundregion, :pop_mig, :pop_nomig,:ypc_mig,:ypc_nomig], kind = :outer)
sort!(gdp_ssp, [:scen,:country,:period])

for i in 1:size(gdp_ssp,1)
    if gdp_ssp[i,:period] > 2300
        gdp_ssp[i,:gdp_mig] = gdp_ssp[i,:ypc_mig] * gdp_ssp[i,:pop_mig]
        gdp_ssp[i,:gdp_nomig] = gdp_ssp[i,:ypc_nomig] * gdp_ssp[i,:pop_nomig]
    end
end

# !! This is keeping GDP constant, not GDP per capita !!
#sort!(gdp_ssp, [:period, :scen, :country])
#ind2300 = findfirst(gdp_ssp[:,:period].==2300)
#gdp_fut = DataFrame(
    #period = repeat(2301:3000,inner=size(gdp_ssp[ind2300:end,:scen],1)),
    #scen = repeat(gdp_ssp[ind2300:end,:scen],outer=length(2301:3000)),
    #country = repeat(gdp_ssp[ind2300:end,:country],outer=length(2301:3000)),
    #gdp_mig = repeat(gdp_ssp[ind2300:end,:gdp_mig],outer=length(2301:3000)),
    #gdp_nomig = repeat(gdp_ssp[ind2300:end,:gdp_nomig],outer=length(2301:3000))
#)
#gdp_ssp = vcat(gdp_ssp, gdp_fut)
#sort!(gdp_ssp, [:scen, :country, :period])

# Convert to FUND regions
gdp_ssp = join(gdp_ssp, iso3c_fundregion, on = :country, kind = :left)
gdp_ssp_f = by(gdp_ssp, [:period, :scen, :fundregion], d -> (gdp_mig = sum(skipmissing(d.gdp_mig)), gdp_nomig = sum(skipmissing(d.gdp_nomig))))

# Sorting the data
regionsdf = DataFrame(fundregion = regions, index = 1:16)
gdp_ssp_f = join(gdp_ssp_f, regionsdf, on = :fundregion)
sort!(gdp_ssp_f, [:scen, :period, :index])

# Write for each SSP and mig/nomig separately
for s in ssps
    CSV.write(joinpath(@__DIR__, string("../scen/gdp_mig_", s, ".csv")), gdp_ssp_f[(gdp_ssp_f[:,:scen].==s),[:period, :fundregion, :gdp_mig]]; writeheader=false)
    CSV.write(joinpath(@__DIR__, string("../scen/gdp_nomig_", s, ".csv")), gdp_ssp_f[(gdp_ssp_f[:,:scen].==s),[:period, :fundregion, :gdp_nomig]]; writeheader=false)
end
CSV.write(joinpath(@__DIR__, "../../Documents/WorkInProgress/migrations-Esteban-FUND/results/gdp_ssp.csv"), gdp_ssp)