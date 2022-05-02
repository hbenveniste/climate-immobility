using CSV, DataFrames, DelimitedFiles

ssps = ["SSP1","SSP2","SSP3","SSP4","SSP5"]

elosscatapar = DataFrame(
    scen = ssps,
    elosscata = [1.63,2.47,0.27,0.73,1.31]
)

for s in ssps
    CSV.write(joinpath(@__DIR__, string("../scen_ineq_cata/elosscatapar_", s, ".csv")), elosscatapar[(elosscatapar[:,:scen].==s),[:elosscata]]; writeheader=false)
end