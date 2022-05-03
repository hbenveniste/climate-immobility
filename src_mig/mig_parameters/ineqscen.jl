using CSV, DataFrames, Statistics, DelimitedFiles
using Plots, VegaLite, FileIO, VegaDatasets, FilePaths, ImageIO, ImageMagick


regions = ["USA", "CAN", "WEU", "JPK", "ANZ", "EEU", "FSU", "MDE", "CAM", "LAM", "SAS", "SEA", "CHI", "MAF", "SSA", "SIS"]
ssps = ["SSP1","SSP2","SSP3","SSP4","SSP5"]

gini_edu = CSV.File(joinpath(@__DIR__, "../input_data/gini_edu.csv")) |> DataFrame

countries = unique(gini_edu[.&(gini_edu[:,:period].==2100, map(x->!ismissing(x),gini_edu[:,:gini_nomig])),:country])


########################## Extend SSP gini scenarios with and without migration ######################################
gini_ssp = gini_edu[(map(x->x in countries, gini_edu[:,:country])),[:period, :scen, :country, :gini, :gini_nomig]]
rename!(gini_ssp,:gini=>:gini_mig)

# Linearizing gini from 5-year periods to yearly values. Note: a value for year x actually represents gini at the beginning of the five year period                                                
gini_allyr = DataFrame(
    period = repeat(2010:2100, outer = length(ssps)*length(countries)),
    scen = repeat(ssps, inner = length(2010:2100)*length(countries)),
    country = repeat(countries, inner = length(2010:2100), outer = length(ssps))
)
gini_ssp = outerjoin(gini_ssp, gini_allyr, on = [:period, :scen, :country])
sort!(gini_ssp, [:scen, :country, :period])
for i in 1:size(gini_ssp,1)
    if mod(gini_ssp[i,:period], 5) != 0
        ind = i - mod(gini_ssp[i,:period], 5)
        for name in [:gini_mig, :gini_nomig]
            floor = gini_ssp[ind,name] ; ceiling = gini_ssp[ind+5,name]
            a = floor + (ceiling - floor) / 5 * mod(gini_ssp[i,:period], 5)
            gini_ssp[i, name] = a
        end
    end
end

# For 1950-2010: use data on within-country Gini from World Bank. 
# Interpolate Gini values for each country when missing data
# Prior to first year of data available, assume constant Gini
data_gini = load(joinpath(@__DIR__, "../input_data/Gini_WB_all.xlsx"), "Data!A1:BL265") |> DataFrame
gini_hist = stack(data_gini[:,4:end], 2:61)
rename!(gini_hist, Symbol("Country Code")=>:country, :variable => :year, :value=>:gini)
gini_hist[!,:year] = map(x->parse(Int,SubString(String(x), 1:4)), gini_hist[:,:year])
gini_hist[!,:gini] = [typeof(gini_hist[i,:gini]) == Float64 ? gini_hist[i,:gini] /100 : missing for i in 1:size(gini_hist,1)]

gini_past = DataFrame(
    period = repeat(1950:2009,outer=length(ssps)*length(countries)),
    scen = repeat(ssps,inner=length(1950:2009)*length(countries)),
    country = repeat(countries,outer=length(ssps),inner=length(1950:2009))
)
gini_past = leftjoin(gini_past, rename(gini_hist[(gini_hist[:,:year].<2010),:],:year=>:period,:gini=>:gini_mig),on=[:period,:country])
gini_past = leftjoin(gini_past, rename(gini_hist[(gini_hist[:,:year].<2010),:],:year=>:period,:gini=>:gini_nomig),on=[:period,:country])
gini2010 = gini_ssp[(gini_ssp[:,:period].==2010),:]
gini_past = vcat(gini_past,gini2010)
sort!(gini_past, [:scen,:country,:period])

for s in ssps
    for c in countries
        indb = intersect(findall(gini_past[:,:scen].==s),findall(gini_past[:,:country].==c))
        indf = findall(!ismissing,gini_past[indb,:gini_mig])
        for i in indb[1]:indb[1]+indf[1]-2
            gini_past[i,:gini_mig] = gini_past[indb[1]+indf[1]-1,:gini_mig]
            gini_past[i,:gini_nomig] = gini_past[indb[1]+indf[1]-1,:gini_nomig]
        end
        for p in 1:length(indf)-1
            for i in indb[1]+indf[p]:indb[1]+indf[p+1]-2
                gini_past[i,:gini_mig] = gini_past[indb[1]+indf[p]-1,:gini_mig] + (gini_past[indb[1]+indf[p+1]-1,:gini_mig] - gini_past[indb[1]+indf[p]-1,:gini_mig]) / (indb[1]+indf[p+1]-1 - (indb[1]+indf[p]-1)) * (i - (indb[1]+indf[p]-1))
                gini_past[i,:gini_nomig] = gini_past[indb[1]+indf[p]-1,:gini_nomig] + (gini_past[indb[1]+indf[p+1]-1,:gini_nomig] - gini_past[indb[1]+indf[p]-1,:gini_nomig]) / (indb[1]+indf[p+1]-1 - (indb[1]+indf[p]-1)) * (i - (indb[1]+indf[p]-1))
            end
        end
    end
end

gini_ssp = vcat(gini_past[(gini_past[:,:period].<2010),:],gini_ssp)
sort!(gini_ssp, [:scen, :country, :period])

# For 2100-2300: linear decline in gini growth rate reaching 0
gini2123 = DataFrame(
    period=repeat(2101:2300,outer=length(ssps)*length(countries)),
    scen=repeat(ssps,inner=length(2101:2300)*length(countries)),
    country=repeat(countries,inner=length(2101:2300),outer=length(ssps)),
    gini_mig=zeros(length(ssps)*length(countries)*length(2101:2300)),
    gini_nomig=zeros(length(ssps)*length(countries)*length(2101:2300))
)
gini_ssp = vcat(gini_ssp,gini2123)
sort!(gini_ssp, [:scen, :country, :period])
for s in ssps
    for c in countries
        indg = intersect(findall(gini_ssp[:,:scen].==s),findall(gini_ssp[:,:country].==c),findall(gini_ssp[:,:period].==2100))[1]
        g2100_mig = gini_ssp[indg,:gini_mig] / gini_ssp[indg-1,:gini_mig] - 1
        g2100_nomig = gini_ssp[indg,:gini_nomig] / gini_ssp[indg-1,:gini_nomig] - 1
        for t in 2101:2300
            indt = intersect(findall(gini_ssp[:,:scen].==s),findall(gini_ssp[:,:country].==c),findall(gini_ssp[:,:period].==t))[1]
            gini_ssp[indt,:gini_mig] = min(0.75,(1 +g2100_mig * (1 - 1 / 200 * (t-2100))) * gini_ssp[indt-1,:gini_mig])
            gini_ssp[indt,:gini_nomig] = min(0.75,(1 +g2100_nomig * (1 - 1 / 200 * (t-2100))) * gini_ssp[indt-1,:gini_nomig])
        end
        print(s," ", c, " ")
    end
end

# For 2300-3000: keep gini constant. 
gini2300 = gini_ssp[(gini_ssp[:,:period].==2300),[:scen,:country,:gini_mig,:gini_nomig]]
gini3000 = DataFrame(
    period=repeat(2301:3000,outer=size(gini2300,1)),
    scen=repeat(gini2300[:,:scen],inner=length(2301:3000)),
    country=repeat(gini2300[:,:country],inner=length(2301:3000)),
    gini_mig=repeat(gini2300[:,:gini_mig],inner=length(2301:3000)),
    gini_nomig=repeat(gini2300[:,:gini_nomig],inner=length(2301:3000))
)
gini_ssp = vcat(gini_ssp,gini3000)
sort!(gini_ssp, [:scen,:country,:period])

# Convert to FUND regions: use weighted average based on population 
iso3c_isonum = CSV.File("../input_data/iso3c_isonum.csv") |> DataFrame
gini_ssp = leftjoin(gini_ssp, rename(iso3c_isonum,:iso3c=>:country,:isonum=>:region), on = :country)
pop_ssp = CSV.File(joinpath(@__DIR__, "../input_data/pop_ssp.csv")) |> DataFrame
gini_ssp = innerjoin(gini_ssp, pop_ssp, on = [:period,:scen,:region])
pop_ssp_f = combine(d -> (pop_mig_f = sum(d.pop_mig), pop_nomig_f = sum(d.pop_nomig)), groupby(gini_ssp, [:period, :scen, :fundregion]))
gini_ssp = innerjoin(gini_ssp, pop_ssp_f, on=[:period,:scen,:fundregion])
gini_ssp[!,:pop_mig_share] = gini_ssp[:,:pop_mig] ./ gini_ssp[:,:pop_mig_f]
gini_ssp[!,:pop_nomig_share] = gini_ssp[:,:pop_nomig] ./ gini_ssp[:,:pop_nomig_f]

gini_ssp_f = combine(d -> (gini_mig = sum(d.gini_mig .* d.pop_mig_share), gini_nomig = sum(d.gini_nomig .* d.pop_nomig_share)), groupby(gini_ssp, [:period, :scen, :fundregion]))

# Sorting the data
regionsdf = DataFrame(fundregion = regions, index = 1:16)
gini_ssp_f = innerjoin(gini_ssp_f, regionsdf, on = :fundregion)
sort!(gini_ssp_f, [:scen, :period, :index])

# Write for each SSP and mig/nomig separately
for s in ssps
    CSV.write(joinpath(@__DIR__, string("../scen_ineq/ineq_mig_", s, ".csv")), gini_ssp_f[(gini_ssp_f[:,:scen].==s),[:period, :fundregion, :gini_mig]]; writeheader=false)
    CSV.write(joinpath(@__DIR__, string("../scen_ineq/ineq_nomig_", s, ".csv")), gini_ssp_f[(gini_ssp_f[:,:scen].==s),[:period, :fundregion, :gini_nomig]]; writeheader=false)
end
CSV.write(joinpath(@__DIR__, "../../../results/gini_ssp.csv"), gini_ssp)