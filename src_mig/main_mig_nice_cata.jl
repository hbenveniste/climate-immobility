using DelimitedFiles, CSV
using Statistics

using MimiFUND

include("helper_mig.jl")
include("mig_nice_SocioEconomicComponent.jl")
include("Migration_nice_Component.jl")
include("Addpop_nice_Component.jl")
include("Addimpact_nice_cata_Component.jl")
include("scenconverter_ineq.jl")

# Run FUND with added migration dynamics, using as input SSP scenarios transformed for zero migration to ensure consistency

const path_datamigdir = joinpath(@__DIR__, "../data_mig")

function getmigrationnicecatamodel(;datamigdir=path_datamigdir,scen="SSP2",migyesno="mig",xi=1.0,omega=1.0)
    # first get original fund
    m = getfund()

    # load migration parameters
    param_mig = MimiFUND.load_default_parameters(datamigdir)

    # load migration parameters with 3 dimensions
    param_mig_3 = load_parameters_mig(joinpath(datamigdir,"../data_mig_3d"))

    # load input scenarios
    param_scen = MimiFUND.load_default_parameters(joinpath(datamigdir, "../scen"))
    param_scen_ineq = MimiFUND.load_default_parameters(joinpath(datamigdir, "../scen_ineq"))

    # load scenario-dependent parameters
    param_scen_ineq_cata = MimiFUND.load_default_parameters(joinpath(datamigdir,"../scen_ineq_cata/"))

    # add dimensions for age groups and quintiles
    set_dimension!(m, :agegroups, 0:120)
    set_dimension!(m, :quintiles, 1:5)

    # delete base FUND socioeconomic component
    delete!(m, :socioeconomic)

    # add mig_socioeconomic and migration components
    add_comp!(m, scenconverter_ineq, :scenconverter, before=:scenariouncertainty)
    add_comp!(m, mig_nice_socioeconomic, :socioeconomic, after=:geography)
    add_comp!(m, migration_nice, :migration, after=:impactaggregation)
    add_comp!(m, addimpact_nice_cata, :addimpact, after=:migration)
    add_comp!(m, addpop_nice, :addpop, after=:migration)

    # set input scenarios
    set_param!(m, :scenconverter, :population, param_scen[Symbol("pop_",migyesno,"_",scen,"_update")])
    set_param!(m, :scenconverter, :income, param_scen[Symbol("gdp_",migyesno,"_",scen,"_update")])
    set_param!(m, :scenconverter, :energuse, param_scen[Symbol("en_",migyesno,"_",scen,"_update")])
    set_param!(m, :scenconverter, :emission, param_scen[Symbol("em_",migyesno,"_",scen,"_update")])
    set_param!(m, :scenconverter, :inequality, param_scen_ineq[Symbol("ineq_",migyesno,"_",scen,"_update")])

    # Set parameters corresponding to input scenarios
    update_param!(m, :currtax, param_scen[Symbol("cp_",scen)])
    set_param!(m, :addimpact, :elosscatapar, param_scen_ineq_cata[Symbol("elosscatapar_",scen)])

    # set parameters for migration component
    set_param!(m, :migration, :lifeexp, param_scen[Symbol("lifeexp_",scen)])
    set_param!(m, :migration, :distance, param_mig[:distance])
    set_param!(m, :migration, :migdeathrisk, param_mig[:migdeathrisk])
    set_param!(m, :migration, :ageshare, param_mig_3["ageshare_ineq_update"])
    set_param!(m, :migration, :agegroupinit, param_mig_3["agegroupinit_ineq_update"])
    set_param!(m, :migration, :remres, param_mig[:remres_update])
    set_param!(m, :migration, :remcost, param_mig[:remcost_update])
    set_param!(m, :migration, :comofflang, param_mig[:comofflang])
    set_param!(m, :migration, :policy, param_mig[:policy])
    set_param!(m, :migration, :migstockinit, param_mig_3["migstockinit_ineq_update"])
    set_param!(m, :migration, :gravres_qi, param_mig_3["gravres_qi_update"])       
    set_param!(m, :migration, :beta0_quint, param_mig[:beta0_update])       
    set_param!(m, :migration, :beta1_quint, param_mig[:beta1_update])       
    set_param!(m, :migration, :beta2_quint, param_mig[:beta2_update])       
    set_param!(m, :migration, :beta4_quint, param_mig[:beta4_update])       
    set_param!(m, :migration, :beta5_quint, param_mig[:beta5_update])       
    set_param!(m, :migration, :beta7_quint, param_mig[:beta7_update])       
    set_param!(m, :migration, :beta8_quint, param_mig[:beta8_update])       
    set_param!(m, :migration, :beta9_quint, param_mig[:beta9_update])       
    set_param!(m, :migration, :beta10_quint, param_mig[:beta10_update])       
    set_param!(m, :migration, :gamma0_quint, param_mig[:gamma0_update])
    set_param!(m, :migration, :gamma1_quint, param_mig[:gamma1_update])

    # Set parameters for mig_nice socioeconomic components
    set_param!(m, :socioeconomic, :xi, xi)
    set_param!(m, :socioeconomic, :omega, omega)

    # scenconverter component connections
    connect_param!(m, :scenariouncertainty, :scenpgrowth, :scenconverter, :scenpgrowth)
    connect_param!(m, :scenariouncertainty, :scenypcgrowth, :scenconverter, :scenypcgrowth)
    connect_param!(m, :scenariouncertainty, :scenaeei, :scenconverter, :scenaeei)
    connect_param!(m, :scenariouncertainty, :scenacei, :scenconverter, :scenacei)

    # scenconverter component connections to other components
    connect_param!(m, :socioeconomic, :ineq0, :scenconverter, :ineq0)

    # mig socioeconomic component connections
    connect_param!(m, :socioeconomic, :area, :geography, :area)
    connect_param!(m, :socioeconomic, :globalpopulation, :population, :globalpopulation)
    connect_param!(m, :socioeconomic, :populationin1, :population, :populationin1)
    connect_param!(m, :socioeconomic, :population, :population, :population)
    connect_param!(m, :socioeconomic, :pgrowth, :scenariouncertainty, :pgrowth)
    connect_param!(m, :socioeconomic, :ypcgrowth, :scenariouncertainty, :ypcgrowth)
    connect_param!(m, :socioeconomic, :mitigationcost, :emissions, :mitigationcost)
    connect_param!(m, :socioeconomic, :ineqgrowth, :scenconverter, :scenineqgrowth)    

    # migration component connections
    connect_param!(m, :migration, :pop, :socioeconomic, :quintile_pop)
    connect_param!(m, :migration, :income, :socioeconomic, :quintile_income)
    connect_param!(m, :migration, :popdens, :socioeconomic, :popdens)
    connect_param!(m, :migration, :vsl, :vslvmorb, :vsl)

    # impacts adder connections
    connect_param!(m, :addimpact, :eloss, :impactaggregation, :eloss)
    connect_param!(m, :addimpact, :sloss, :impactaggregation, :sloss)
    connect_param!(m, :addimpact, :entercost, :impactsealevelrise, :entercost)
    connect_param!(m, :addimpact, :leavecost, :impactsealevelrise, :leavecost)
    connect_param!(m, :addimpact, :otherconsloss, :migration, :deadmigcost)
    connect_param!(m, :addimpact, :income, :socioeconomic, :income)
    connect_param!(m, :addimpact, :globalincome, :socioeconomic, :globalincome)
    connect_param!(m, :addimpact, :temp, :climatedynamics, :temp)

    # population adder connections
    connect_param!(m, :addpop, :dead, :impactdeathmorbidity, :dead)
    connect_param!(m, :addpop, :entermig, :migration, :entermig)
    connect_param!(m, :addpop, :leavemig, :migration, :leavemig)
    connect_param!(m, :addpop, :deadmig, :migration, :deadmig)

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

    # FUND components that need a connection to the pop adder component
    connect_param!(m, :population, :enter, :addpop, :enter)
    connect_param!(m, :population, :leave, :addpop, :leave)
    connect_param!(m, :population, :dead, :addpop, :deadall)

    # mig socioeconomic component connections to migration component
    connect_param!(m, :socioeconomic, :transfer, :migration, :remittances)
    connect_param!(m, :socioeconomic, :entermig, :migration, :entermig)
    connect_param!(m, :socioeconomic, :leavemig, :migration, :leavemig)
    connect_param!(m, :socioeconomic, :deadmig, :migration, :deadmig)
    connect_param!(m, :socioeconomic, :dead, :addpop, :deadall)

    # mig socioeconomic component connections to impacts adder component
    connect_param!(m, :socioeconomic, :eloss, :addimpact, :elossall)
    connect_param!(m, :socioeconomic, :sloss, :addimpact, :slossall)

    set_leftover_params!(m, param_mig)

    return m
end
