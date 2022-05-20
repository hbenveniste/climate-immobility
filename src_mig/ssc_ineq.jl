using DelimitedFiles, CSV, VegaLite, FileIO, VegaDatasets, FilePaths
using Statistics, DataFrames, Query, Distributions

using MimiFUND

include("main_mig_nice.jl")
include("fund_ssp_ineq.jl")


################################################################################################################################################################################
################# Compare SCC for original FUND model with original scenarios, NICE-FUND with SSP scenarios, and Mig-NICE-FUND with SSP scenarios zero migration #################
################################################################################################################################################################################

################################## Prepare models #########################################################################################################################
# Define models
m_nice_ssp1_nomig = getmigrationnicemodel(scen="SSP1",migyesno="nomig",xi=1.0,omega=1.0)
m_nice_ssp2_nomig = getmigrationnicemodel(scen="SSP2",migyesno="nomig",xi=1.0,omega=1.0)
m_nice_ssp3_nomig = getmigrationnicemodel(scen="SSP3",migyesno="nomig",xi=1.0,omega=1.0)
m_nice_ssp4_nomig = getmigrationnicemodel(scen="SSP4",migyesno="nomig",xi=1.0,omega=1.0)
m_nice_ssp5_nomig = getmigrationnicemodel(scen="SSP5",migyesno="nomig",xi=1.0,omega=1.0)

m_fundnicessp1 = getsspnicemodel(scen="SSP1",migyesno="mig",xi=1.0,omega=1.0)
m_fundnicessp2 = getsspnicemodel(scen="SSP2",migyesno="mig",xi=1.0,omega=1.0)
m_fundnicessp3 = getsspnicemodel(scen="SSP3",migyesno="mig",xi=1.0,omega=1.0)
m_fundnicessp4 = getsspnicemodel(scen="SSP4",migyesno="mig",xi=1.0,omega=1.0)
m_fundnicessp5 = getsspnicemodel(scen="SSP5",migyesno="mig",xi=1.0,omega=1.0)

m_fund = getfund()

# Damages within a given region independent of income (xi=0)
m_nice_ssp1_nomig_xi0 = getmigrationnicemodel(scen="SSP1",migyesno="nomig",xi=0.0,omega=1.0)
m_nice_ssp2_nomig_xi0 = getmigrationnicemodel(scen="SSP2",migyesno="nomig",xi=0.0,omega=1.0)
m_nice_ssp3_nomig_xi0 = getmigrationnicemodel(scen="SSP3",migyesno="nomig",xi=0.0,omega=1.0)
m_nice_ssp4_nomig_xi0 = getmigrationnicemodel(scen="SSP4",migyesno="nomig",xi=0.0,omega=1.0)
m_nice_ssp5_nomig_xi0 = getmigrationnicemodel(scen="SSP5",migyesno="nomig",xi=0.0,omega=1.0)

m_fundnicessp1_xi0 = getsspnicemodel(scen="SSP1",migyesno="mig",xi=0.0,omega=1.0)
m_fundnicessp2_xi0 = getsspnicemodel(scen="SSP2",migyesno="mig",xi=0.0,omega=1.0)
m_fundnicessp3_xi0 = getsspnicemodel(scen="SSP3",migyesno="mig",xi=0.0,omega=1.0)
m_fundnicessp4_xi0 = getsspnicemodel(scen="SSP4",migyesno="mig",xi=0.0,omega=1.0)
m_fundnicessp5_xi0 = getsspnicemodel(scen="SSP5",migyesno="mig",xi=0.0,omega=1.0)

# Damages within a given region inversely proportional to income (xi=-1)
m_nice_ssp1_nomig_xim1 = getmigrationnicemodel(scen="SSP1",migyesno="nomig",xi=-1.0,omega=1.0)
m_nice_ssp2_nomig_xim1 = getmigrationnicemodel(scen="SSP2",migyesno="nomig",xi=-1.0,omega=1.0)
m_nice_ssp3_nomig_xim1 = getmigrationnicemodel(scen="SSP3",migyesno="nomig",xi=-1.0,omega=1.0)
m_nice_ssp4_nomig_xim1 = getmigrationnicemodel(scen="SSP4",migyesno="nomig",xi=-1.0,omega=1.0)
m_nice_ssp5_nomig_xim1 = getmigrationnicemodel(scen="SSP5",migyesno="nomig",xi=-1.0,omega=1.0)

m_fundnicessp1_xim1 = getsspnicemodel(scen="SSP1",migyesno="mig",xi=-1.0,omega=1.0)
m_fundnicessp2_xim1 = getsspnicemodel(scen="SSP2",migyesno="mig",xi=-1.0,omega=1.0)
m_fundnicessp3_xim1 = getsspnicemodel(scen="SSP3",migyesno="mig",xi=-1.0,omega=1.0)
m_fundnicessp4_xim1 = getsspnicemodel(scen="SSP4",migyesno="mig",xi=-1.0,omega=1.0)
m_fundnicessp5_xim1 = getsspnicemodel(scen="SSP5",migyesno="mig",xi=-1.0,omega=1.0)


###################################### Compute Social Cost of Carbon using the embedded function #################################################
# Use default discounting parameters and equity weights. Calculate for CO2 using 3000 as last year of run. 
# Provide results for the 5 SSP-RCP combinations, for the 3 values of xi, and for years 2020, 2050, and 2100.
scc_fund = MimiFUND.compute_scco2(m_fund, year = 2020)

ssps = ["SSP1","SSP2","SSP3","SSP4","SSP5"]
years = [2020,2050,2100]

sccres = DataFrame(
    scen = repeat(ssps,outer=3*3),
    xi = repeat([1,0,-1],inner=5,outer=3),
    year = repeat(years,inner=3*5)
)
scc_fn = [] ; scc_mfn = []
for y in years
    sfnx1s1 = MimiFUND.compute_scco2(m_fundnicessp1, year = y)
    sfnx1s2 = MimiFUND.compute_scco2(m_fundnicessp2, year = y)
    sfnx1s3 = MimiFUND.compute_scco2(m_fundnicessp3, year = y)
    sfnx1s4 = MimiFUND.compute_scco2(m_fundnicessp4, year = y)
    sfnx1s5 = MimiFUND.compute_scco2(m_fundnicessp5, year = y)
    sfnx0s1 = MimiFUND.compute_scco2(m_fundnicessp1_xi0, year = y)
    sfnx0s2 = MimiFUND.compute_scco2(m_fundnicessp2_xi0, year = y)
    sfnx0s3 = MimiFUND.compute_scco2(m_fundnicessp3_xi0, year = y)
    sfnx0s4 = MimiFUND.compute_scco2(m_fundnicessp4_xi0, year = y)
    sfnx0s5 = MimiFUND.compute_scco2(m_fundnicessp5_xi0, year = y)
    sfnxm1s1 = MimiFUND.compute_scco2(m_fundnicessp1_xim1, year = y)
    sfnxm1s2 = MimiFUND.compute_scco2(m_fundnicessp2_xim1, year = y)
    sfnxm1s3 = MimiFUND.compute_scco2(m_fundnicessp3_xim1, year = y)
    sfnxm1s4 = MimiFUND.compute_scco2(m_fundnicessp4_xim1, year = y)
    sfnxm1s5 = MimiFUND.compute_scco2(m_fundnicessp5_xim1, year = y)
    scc_fn = vcat(scc_fn, [sfnx1s1,sfnx1s2,sfnx1s3,sfnx1s4,sfnx1s5,sfnx0s1,sfnx0s2,sfnx0s3,sfnx0s4,sfnx0s5,sfnxm1s1,sfnxm1s2,sfnxm1s3,sfnxm1s4,sfnxm1s5])
    print("sfn ",y,"  ")
    smfnx1s1 = MimiFUND.compute_scco2(m_nice_ssp1_nomig, year = y)
    smfnx1s2 = MimiFUND.compute_scco2(m_nice_ssp2_nomig, year = y)
    smfnx1s3 = MimiFUND.compute_scco2(m_nice_ssp3_nomig, year = y)
    smfnx1s4 = MimiFUND.compute_scco2(m_nice_ssp4_nomig, year = y)
    smfnx1s5 = MimiFUND.compute_scco2(m_nice_ssp5_nomig, year = y)
    print("smfn xi=1 ",y,"  ")
    smfnx0s1 = MimiFUND.compute_scco2(m_nice_ssp1_nomig_xi0, year = y)
    smfnx0s2 = MimiFUND.compute_scco2(m_nice_ssp2_nomig_xi0, year = y)
    smfnx0s3 = MimiFUND.compute_scco2(m_nice_ssp3_nomig_xi0, year = y)
    smfnx0s4 = MimiFUND.compute_scco2(m_nice_ssp4_nomig_xi0, year = y)
    smfnx0s5 = MimiFUND.compute_scco2(m_nice_ssp5_nomig_xi0, year = y)
    print("smfn xi=0 ",y,"  ")
    smfnxm1s1 = MimiFUND.compute_scco2(m_nice_ssp1_nomig_xim1, year = y)
    smfnxm1s2 = MimiFUND.compute_scco2(m_nice_ssp2_nomig_xim1, year = y)
    smfnxm1s3 = MimiFUND.compute_scco2(m_nice_ssp3_nomig_xim1, year = y)
    smfnxm1s4 = MimiFUND.compute_scco2(m_nice_ssp4_nomig_xim1, year = y)
    smfnxm1s5 = MimiFUND.compute_scco2(m_nice_ssp5_nomig_xim1, year = y)
    print("smfn xi=-1 ",y,"  ")
    scc_mfn = vcat(scc_mfn, [smfnx1s1,smfnx1s2,smfnx1s3,smfnx1s4,smfnx1s5,smfnx0s1,smfnx0s2,smfnx0s3,smfnx0s4,smfnx0s5,smfnxm1s1,smfnxm1s2,smfnxm1s3,smfnxm1s4,smfnxm1s5])
end
sccres[!,:scc_fundnice] = scc_fn
sccres[!,:scc_migfundnice] = scc_mfn
sccres[!,:scc_diff] = sccres[!,:scc_migfundnice] .- sccres[!,:scc_fundnice]

# Results for FUND-NICE only
sccres_fundnice = DataFrame(
    scen = repeat(ssps,outer=3*3),
    xi = repeat([1,0,-1],inner=5,outer=3),
    year = repeat(years,inner=3*5)
)
scc_fundnice = [] 
for y in years
    sfnx1s1 = MimiFUND.compute_scco2(m_fundnicessp1, year = y)
    sfnx1s2 = MimiFUND.compute_scco2(m_fundnicessp2, year = y)
    sfnx1s3 = MimiFUND.compute_scco2(m_fundnicessp3, year = y)
    sfnx1s4 = MimiFUND.compute_scco2(m_fundnicessp4, year = y)
    sfnx1s5 = MimiFUND.compute_scco2(m_fundnicessp5, year = y)
    sfnx0s1 = MimiFUND.compute_scco2(m_fundnicessp1_xi0, year = y)
    sfnx0s2 = MimiFUND.compute_scco2(m_fundnicessp2_xi0, year = y)
    sfnx0s3 = MimiFUND.compute_scco2(m_fundnicessp3_xi0, year = y)
    sfnx0s4 = MimiFUND.compute_scco2(m_fundnicessp4_xi0, year = y)
    sfnx0s5 = MimiFUND.compute_scco2(m_fundnicessp5_xi0, year = y)
    sfnxm1s1 = MimiFUND.compute_scco2(m_fundnicessp1_xim1, year = y)
    sfnxm1s2 = MimiFUND.compute_scco2(m_fundnicessp2_xim1, year = y)
    sfnxm1s3 = MimiFUND.compute_scco2(m_fundnicessp3_xim1, year = y)
    sfnxm1s4 = MimiFUND.compute_scco2(m_fundnicessp4_xim1, year = y)
    sfnxm1s5 = MimiFUND.compute_scco2(m_fundnicessp5_xim1, year = y)
    scc_fundnice = vcat(scc_fundnice, [sfnx1s1,sfnx1s2,sfnx1s3,sfnx1s4,sfnx1s5,sfnx0s1,sfnx0s2,sfnx0s3,sfnx0s4,sfnx0s5,sfnxm1s1,sfnxm1s2,sfnxm1s3,sfnxm1s4,sfnxm1s5])
end
sccres_fundnice[!,:scc_fundnice] = scc_fundnice


###################################### Compute Social Cost of Carbon using a modified function accounting for within-region inequality #################################################
# Use default discounting parameters and equity weights. Calculate for CO2 using 2020 as last year of run. 
# Provide results for the 5 SSP-RCP combinations, for the 3 values of xi, and for years 2020, 2050, and 2100.

# Helper function for computing SC from a MarginalModel that's already been run, not to be exported
function compute_sc_from_mnice(m::Model=get_model(); year::Union{Int, Nothing} = nothing, gas::Symbol = :CO2, last_year::Int = 3000, equity_weights::Bool = false, equity_weights_normalization_region::Int = 0, eta::Float64 = 1.45, prtp::Float64 = 0.015, pulse_size::Float64 = 1e7)
    mm = MimiFUND.get_marginal_model(m; year = year, gas = gas, pulse_size = pulse_size)
    ntimesteps = getindexfromyear(last_year)
    # Run the "best guess" social cost calculation
    run(mm; ntimesteps = ntimesteps)
    
    # Calculate the marginal damage between run 1 and 2 for each year/region
    marginaldamage = mm[:impactaggregation, :loss] .* mm.base[:socioeconomic, :damage_distribution]
    ypcq = mm.base[:socioeconomic, :quintile_income]

    # Compute discount factor with or without equityweights
    df = zeros(ntimesteps, 16, 5)
    if !equity_weights
        for r = 1:16
            for q = 1:5
                x = 1.
                for t = getindexfromyear(year):ntimesteps
                    df[t, r, q] = x
                    gr = (ypcq[t, r, q] - ypcq[t - 1, r, q]) / ypcq[t - 1, r, q]
                    x = x / (1. + prtp + eta * gr)
                end
            end
        end
    else
        normalization_ypc = equity_weights_normalization_region==0 ? mm.base[:socioeconomic, :globalypc][getindexfromyear(year)] : mm.base[:socioeconomic, :ypc][getindexfromyear(year), equity_weights_normalization_region]
        df = Float64[t >= getindexfromyear(year) ? (normalization_ypc / ypcq[t, r, q]) ^ eta / (1.0 + prtp) ^ (t - getindexfromyear(year)) : 0.0 for t = 1:ntimesteps, r = 1:16, q = 1:5]
    end 

    # Compute global social cost
    sc = sum(marginaldamage[2:ntimesteps, :, :] .* df[2:ntimesteps, :, :])   # need to start from second value because first value is missing
    return sc
end

# Perform runs
sccniceres = DataFrame(
    scen = repeat(ssps,outer=3),
    xi = repeat([1,0,-1],inner=5),
    year = repeat([2020],inner=3*5)
)
sccnice_fn = [] ; sccnice_mfn = []
for y in [2020]
    sfnx1s1 = compute_sc_from_mnice(m_fundnicessp1, year = y, last_year=2200)
    sfnx1s2 = compute_sc_from_mnice(m_fundnicessp2, year = y, last_year=2200)
    sfnx1s3 = compute_sc_from_mnice(m_fundnicessp3, year = y, last_year=2200)
    sfnx1s4 = compute_sc_from_mnice(m_fundnicessp4, year = y, last_year=2200)
    sfnx1s5 = compute_sc_from_mnice(m_fundnicessp5, year = y, last_year=2200)
    sfnx0s1 = compute_sc_from_mnice(m_fundnicessp1_xi0, year = y, last_year=2200)
    sfnx0s2 = compute_sc_from_mnice(m_fundnicessp2_xi0, year = y, last_year=2200)
    sfnx0s3 = compute_sc_from_mnice(m_fundnicessp3_xi0, year = y, last_year=2200)
    sfnx0s4 = compute_sc_from_mnice(m_fundnicessp4_xi0, year = y, last_year=2200)
    sfnx0s5 = compute_sc_from_mnice(m_fundnicessp5_xi0, year = y, last_year=2200)
    sfnxm1s1 = compute_sc_from_mnice(m_fundnicessp1_xim1, year = y, last_year=2200)
    sfnxm1s2 = compute_sc_from_mnice(m_fundnicessp2_xim1, year = y, last_year=2200)
    sfnxm1s3 = compute_sc_from_mnice(m_fundnicessp3_xim1, year = y, last_year=2200)
    sfnxm1s4 = compute_sc_from_mnice(m_fundnicessp4_xim1, year = y, last_year=2200)
    sfnxm1s5 = compute_sc_from_mnice(m_fundnicessp5_xim1, year = y, last_year=2200)
    sccnice_fn = vcat(sccnice_fn, [sfnx1s1,sfnx1s2,sfnx1s3,sfnx1s4,sfnx1s5,sfnx0s1,sfnx0s2,sfnx0s3,sfnx0s4,sfnx0s5,sfnxm1s1,sfnxm1s2,sfnxm1s3,sfnxm1s4,sfnxm1s5])
    print("snfn ",y,"  ")
    smfnx1s1 = compute_sc_from_mnice(m_nice_ssp1_nomig, year = y, last_year=2200)
    smfnx1s2 = compute_sc_from_mnice(m_nice_ssp2_nomig, year = y, last_year=2200)
    smfnx1s3 = compute_sc_from_mnice(m_nice_ssp3_nomig, year = y, last_year=2200)
    smfnx1s4 = compute_sc_from_mnice(m_nice_ssp4_nomig, year = y, last_year=2200)
    smfnx1s5 = compute_sc_from_mnice(m_nice_ssp5_nomig, year = y, last_year=2200)
    print("snmfn xi=1 ",y,"  ")
    smfnx0s1 = compute_sc_from_mnice(m_nice_ssp1_nomig_xi0, year = y, last_year=2200)
    smfnx0s2 = compute_sc_from_mnice(m_nice_ssp2_nomig_xi0, year = y, last_year=2200)
    smfnx0s3 = compute_sc_from_mnice(m_nice_ssp3_nomig_xi0, year = y, last_year=2200)
    smfnx0s4 = compute_sc_from_mnice(m_nice_ssp4_nomig_xi0, year = y, last_year=2200)
    smfnx0s5 = compute_sc_from_mnice(m_nice_ssp5_nomig_xi0, year = y, last_year=2200)
    print("snmfn xi=0 ",y,"  ")
    smfnxm1s1 = compute_sc_from_mnice(m_nice_ssp1_nomig_xim1, year = y, last_year=2200)
    smfnxm1s2 = compute_sc_from_mnice(m_nice_ssp2_nomig_xim1, year = y, last_year=2200)
    smfnxm1s3 = compute_sc_from_mnice(m_nice_ssp3_nomig_xim1, year = y, last_year=2200)
    smfnxm1s4 = compute_sc_from_mnice(m_nice_ssp4_nomig_xim1, year = y, last_year=2200)
    smfnxm1s5 = compute_sc_from_mnice(m_nice_ssp5_nomig_xim1, year = y, last_year=2200)
    print("snmfn xi=-1 ",y,"  ")
    sccnice_mfn = vcat(sccnice_mfn, [smfnx1s1,smfnx1s2,smfnx1s3,smfnx1s4,smfnx1s5,smfnx0s1,smfnx0s2,smfnx0s3,smfnx0s4,smfnx0s5,smfnxm1s1,smfnxm1s2,smfnxm1s3,smfnxm1s4,smfnxm1s5])
end
sccniceres[!,:sccnice_fundnice_2200] = sccnice_fn
sccniceres[!,:sccnice_migfundnice_2200] = sccnice_mfn
sccniceres[!,:sccnice_diff] = sccniceres[!,:sccnice_migfundnice] .- sccniceres[!,:sccnice_fundnice]
