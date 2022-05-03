using CSV, DataFrames, DelimitedFiles

regions = ["USA", "CAN", "WEU", "JPK", "ANZ", "EEU", "FSU", "MDE", "CAM", "LAM", "SAS", "SEA", "CHI", "MAF", "SSA", "SIS"]

# Current border policy
onepar = DataFrame(
    source = repeat(regions, inner = length(regions)), 
    destination = repeat(regions, outer = length(regions)), 
    borderpol = ones(length(regions) * length(regions))
)
CSV.write("../data_mig/policy.csv", onepar; writeheader=false)
