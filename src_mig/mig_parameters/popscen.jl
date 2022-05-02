using CSV, DataFrames, Statistics, Query, DelimitedFiles
using VegaLite, FileIO, VegaDatasets, FilePaths, Plots


regions = ["USA", "CAN", "WEU", "JPK", "ANZ", "EEU", "FSU", "MDE", "CAM", "LAM", "SAS", "SEA", "CHI", "MAF", "SSA", "SIS"]
ssps = ["SSP1","SSP2","SSP3","SSP4","SSP5"]

sspall = CSV.read(joinpath(@__DIR__, "../input_data/sspall_10.csv"))

countries = unique(sspall[:,:region])


########################## Extend SSP population scenarios with and without migration ######################################
pop_ssp = sspall[:,[:period, :scen, :region, :pop_mig, :pop_nomig]]

# Linearizing population sizes from 5-year periods to yearly values. Note: a value for year x actually represents population size at the beginning of the five year period                                                
pop_allyr = DataFrame(
    period = repeat(2015:2100, outer = length(ssps)*length(countries)),
    scen = repeat(ssps, inner = length(2015:2100)*length(countries)),
    region = repeat(countries, inner = length(2015:2100), outer = length(ssps))
)
pop_ssp = join(pop_ssp, pop_allyr, on = [:period, :scen, :region], kind = :outer)
sort!(pop_ssp, [:scen, :region, :period])
for i in 1:size(pop_ssp,1)
    if mod(pop_ssp[i,:period], 5) != 0
        ind = i - mod(pop_ssp[i,:period], 5)
        for name in [:pop_mig, :pop_nomig]
            floor = pop_ssp[ind,name] ; ceiling = pop_ssp[ind+5,name]
            a = floor + (ceiling - floor) / 5 * mod(pop_ssp[i,:period], 5)
            pop_ssp[i, name] = a
        end
    end
end

# For 1950-2015: use WPP2019. We use the Medium variant, the most commonly used. Unit: thousands
pop_allvariants = CSV.read(joinpath(@__DIR__, "../input_data/WPP2019.csv"))
pop_hist = @from i in pop_allvariants begin
    @where i.Variant == "Medium" && i.Time < 2015
    @select {i.LocID, i.Location, i.Time, i.PopTotal}
    @collect DataFrame
end
pop_hist_scen = DataFrame(
    period = repeat(pop_hist[:,:Time], outer = length(ssps)),
    scen = repeat(ssps, inner = size(pop_hist,1)),
    region = repeat(pop_hist[:,:LocID], outer = length(ssps)),
    pop_mig = repeat(pop_hist[:,:PopTotal], outer = length(ssps)),
    pop_nomig = repeat(pop_hist[:,:PopTotal], outer = length(ssps))
)
countries_supp = setdiff(unique(pop_hist_scen[:,:region]), countries)
for c in countries_supp
    ind = findall(pop_hist_scen[:,:region].==c)
    deleterows!(pop_hist_scen, ind)
end

pop_ssp = vcat(pop_ssp, pop_hist_scen)
sort!(pop_ssp, [:scen, :region, :period])

# For 2100-2200: linear decline in population growth rate reaching 0 (as done in IWG SCC, source by Kevin Rennert RFF)
for s in ssps
    for c in countries
        indg = intersect(findall(pop_ssp[:,:scen].==s),findall(pop_ssp[:,:region].==c),findall(pop_ssp[:,:period].==2100))
        g2100_mig = pop_ssp[indg,:pop_mig][1] / pop_ssp[indg[1]-1,:pop_mig] - 1
        g2100_nomig = pop_ssp[indg,:pop_nomig][1] / pop_ssp[indg[1]-1,:pop_nomig][1] - 1
        for t in 2101:2200
            indt = intersect(findall(pop_ssp[:,:scen].==s),findall(pop_ssp[:,:region].==c),findall(pop_ssp[:,:period].==t-1))
            val_mig = (1 +g2100_mig * (1 - 1 / 100 * (t-2100))) * pop_ssp[indt,:pop_mig][1]
            val_nomig = (1 +g2100_nomig * (1 - 1 / 100 * (t-2100))) * pop_ssp[indt,:pop_nomig][1]
            push!(pop_ssp, [t, s, c, val_mig, val_nomig])
        end
        print(s," ", c, " ")
    end
end

# For 2200-3000: keep population constant
sort!(pop_ssp, [:period, :scen, :region])
ind2200 = findfirst(pop_ssp[:,:period].==2200)
pop_fut = DataFrame(
    period=repeat(2201:3000,inner=size(pop_ssp[ind2200:end,:scen],1)),
    scen=repeat(pop_ssp[ind2200:end,:scen],outer=length(2201:3000)),
    region=repeat(pop_ssp[ind2200:end,:region],outer=length(2201:3000)),
    pop_mig=repeat(pop_ssp[ind2200:end,:pop_mig],outer=length(2201:3000)),
    pop_nomig=repeat(pop_ssp[ind2200:end,:pop_nomig],outer=length(2201:3000)),
)
pop_ssp = vcat(pop_ssp, pop_fut)
sort!(pop_ssp, [:scen, :region, :period])

# Convert to FUND regions
isonum_fundregion = CSV.read("../input_data/isonum_fundregion.csv")
rename!(isonum_fundregion, :isonum => :region)
pop_ssp = join(pop_ssp, isonum_fundregion, on = :region, kind = :left)
pop_ssp_f = by(pop_ssp, [:period, :scen, :fundregion], d -> (pop_mig = sum(d.pop_mig), pop_nomig = sum(d.pop_nomig)))

# Sorting the data
regionsdf = DataFrame(fundregion = regions, index = 1:16)
pop_ssp_f = join(pop_ssp_f, regionsdf, on = :fundregion)
sort!(pop_ssp_f, [:scen, :period, :index])

# Converting from thousands to million people
pop_ssp_f[!,:pop_mig] ./= 1000
pop_ssp_f[!,:pop_nomig] ./= 1000

# Write for each SSP and mig/nomig separately
for s in ssps
    CSV.write(joinpath(@__DIR__, string("../scen/pop_mig_", s, ".csv")), pop_ssp_f[(pop_ssp_f[:,:scen].==s),[:period, :fundregion, :pop_mig]]; writeheader=false)
    CSV.write(joinpath(@__DIR__, string("../scen/pop_nomig_", s, ".csv")), pop_ssp_f[(pop_ssp_f[:,:scen].==s),[:period, :fundregion, :pop_nomig]]; writeheader=false)
end
CSV.write(joinpath(@__DIR__, "../input_data/pop_ssp.csv"), pop_ssp)

# Determine number of emigrants and immigrants at FUND region level
mig = sspall[:,[:period,:scen,:country,:pop_mig,:inmigsum,:outmigsum]]
iso3c_fundregion = CSV.read("../input_data/iso3c_fundregion.csv")
rename!(iso3c_fundregion,:iso3c => :country)
mig = join(mig,iso3c_fundregion,on=:country)
mig_f = by(mig,[:period,:scen,:fundregion], d->(popmig=sum(d.pop_mig),inmig=sum(d.inmigsum),outmig=sum(d.outmigsum)))
mig_f=join(mig_f,regionsdf,on=:fundregion)
sort!(mig_f,[:scen,:period,:index])
CSV.write(joinpath(@__DIR__, "../input_data/sspmig_fundregions.csv"), mig_f)


# Plot FUND regions definition
world110m = dataset("world-110m")
isonum_fundregion = CSV.read(joinpath(@__DIR__,"../input_data/isonum_fundregion.csv"))
addterr = DataFrame(isonum=[10,-99],fundregion=["_other","_other"])         # Add codes for Antarctica and Somaliland
@vlplot(width=800, height=600) + @vlplot(mark={:geoshape, stroke = :lightgray}, 
    data={values=world110m, format={type=:topojson, feature=:countries}}, 
    transform = [{lookup=:id, from={data=vcat(isonum_fundregion,addterr), key=:isonum, fields=["fundregion"]}}],
    projection={type=:naturalEarth1}, title = {text="World regions in FUND",fontSize=20}, 
    color = {"fundregion:o", scale={scheme="tableau20"}, legend={title=nothing, symbolSize=40, labelFontSize=16}}
) |> save(joinpath(@__DIR__, "../results/migflow/", string("regions.png")))

