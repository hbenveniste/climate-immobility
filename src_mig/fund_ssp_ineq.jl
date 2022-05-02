using DelimitedFiles
using Statistics

using MimiFUND

include("helper_mig.jl")
include("nice_SocioEconomicComponent.jl")
include("scenconverter_ineq.jl")

# Run original FUND with SSP scenarios instead of default scenarios

const path_datascendir = joinpath(@__DIR__, "../scen/")

function getsspnicemodel(;datascendir=path_datascendir,scen="SSP2",migyesno="mig",xi=1.0,omega=1.0)
    # first get original fund
    m = getfund()
    
    # load input scenarios
    param_scen = MimiFUND.load_default_parameters(datascendir)
    param_scen_ineq = MimiFUND.load_default_parameters(joinpath(datascendir, "../scen_ineq"))

    # add dimension for income quintiles
    set_dimension!(m, :quintiles, 1:5)

    # delete base FUND socioeconomic component
    delete!(m, :socioeconomic)

    # add scen converter component
    add_comp!(m, scenconverter_ineq, :scenconverter, before=:scenariouncertainty)
    add_comp!(m, nice_socioeconomic, :socioeconomic, after=:geography)

    # set input scenarios
    set_param!(m, :scenconverter, :population, param_scen[Symbol("pop_",migyesno,"_",scen)])
    set_param!(m, :scenconverter, :income, param_scen[Symbol("gdp_",migyesno,"_",scen)])
    set_param!(m, :scenconverter, :energuse, param_scen[Symbol("en_",migyesno,"_",scen)])
    set_param!(m, :scenconverter, :emission, param_scen[Symbol("em_",migyesno,"_",scen)])
    set_param!(m, :scenconverter, :inequality, param_scen_ineq[Symbol("ineq_",migyesno,"_",scen)])

    # Set parameters for mig_nice socioeconomic components
    set_param!(m, :socioeconomic, :xi, xi)
    set_param!(m, :socioeconomic, :omega, omega)

    update_param!(m, :currtax, param_scen[Symbol("cp_",scen)])

    # scenconverter component connections
    connect_param!(m, :scenariouncertainty, :scenpgrowth, :scenconverter, :scenpgrowth)
    connect_param!(m, :scenariouncertainty, :scenypcgrowth, :scenconverter, :scenypcgrowth)
    connect_param!(m, :scenariouncertainty, :scenaeei, :scenconverter, :scenaeei)
    connect_param!(m, :scenariouncertainty, :scenacei, :scenconverter, :scenacei)

    # scenconverter component connections to other components
    connect_param!(m, :socioeconomic, :ineq0, :scenconverter, :ineq0)

    # nice socioeconomic component connections
    connect_param!(m, :socioeconomic, :area, :geography, :area)
    connect_param!(m, :socioeconomic, :globalpopulation, :population, :globalpopulation)
    connect_param!(m, :socioeconomic, :populationin1, :population, :populationin1)
    connect_param!(m, :socioeconomic, :population, :population, :population)
    connect_param!(m, :socioeconomic, :pgrowth, :scenariouncertainty, :pgrowth)
    connect_param!(m, :socioeconomic, :ypcgrowth, :scenariouncertainty, :ypcgrowth)
    connect_param!(m, :socioeconomic, :mitigationcost, :emissions, :mitigationcost)
    connect_param!(m, :socioeconomic, :ineqgrowth, :scenconverter, :scenineqgrowth)   

    # FUND components that need a connection to mig socioeconomic component
    connect_param!(m, :emissions, :income, :socioeconomic, :income)
    connect_param!(m, :impactagriculture, :income, :socioeconomic, :income)
    connect_param!(m, :impactbiodiversity, :income, :socioeconomic, :income)
    connect_param!(m, :impactcardiovascularrespiratory, :plus, :socioeconomic, :plus)
    connect_param!(m, :impactcardiovascularrespiratory, :urbpop, :socioeconomic, :urbpop)
    connect_param!(m, :impactcooling, :income, :socioeconomic, :income)
    connect_param!(m, :impactdiarrhoea, :income, :socioeconomic, :income)
    connect_param!(m, :impactextratropicalstorms, :income, :socioeconomic, :income)
    connect_param!(m, :impactforests, :income, :socioeconomic, :income)
    connect_param!(m, :impactheating, :income, :socioeconomic, :income)
    connect_param!(m, :impactvectorbornediseases, :income, :socioeconomic, :income)
    connect_param!(m, :impacttropicalstorms, :income, :socioeconomic, :income)
    connect_param!(m, :vslvmorb, :income, :socioeconomic, :income)
    connect_param!(m, :impactwaterresources, :income, :socioeconomic, :income)
    connect_param!(m, :impactsealevelrise, :income, :socioeconomic, :income)
    connect_param!(m, :impactaggregation, :income, :socioeconomic, :income)
    
    # mig socioeconomic component connections to impacts adder component
    connect_param!(m, :socioeconomic, :eloss, :impactaggregation, :eloss)
    connect_param!(m, :socioeconomic, :sloss, :impactaggregation, :sloss)

    set_leftover_params!(m, param_scen)

    return m
end

