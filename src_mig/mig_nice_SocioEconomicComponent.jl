using Mimi, Distributions

@defcomp mig_nice_socioeconomic begin
    
    regions = Index()
    quintiles = Index()

    income              = Variable(index=[time,regions])
    consumption         = Variable(index=[time,regions])
    ypc                 = Variable(index=[time,regions])
    ygrowth             = Variable(index=[time,regions])
    pgrowth_mig         = Variable(index=[time,regions])
    inequality          = Variable(index=[time,regions])
    plus                = Variable(index=[time,regions])
    urbpop              = Variable(index=[time,regions])
    popdens             = Variable(index=[time,regions])
    pc_consumption      = Variable(index=[time,regions])

    globalconsumption   = Variable(index=[time])
    globalypc           = Variable(index=[time])
    globalincome        = Variable(index=[time])
    ypc90               = Variable(index=[regions])

    quintile_pop            = Variable(index=[time, regions, quintiles])
    quintile_old_income     = Variable(index=[time, regions, quintiles])
    quintile_consumption    = Variable(index=[time, regions, quintiles])
    quintile_income         = Variable(index=[time, regions, quintiles])
    quintile_pc_consumption = Variable(index=[time, regions, quintiles])
    income_distribution     = Variable(index=[time, regions, quintiles])
    mitigation_distribution = Variable(index=[time, regions, quintiles])
    damage_distribution     = Variable(index=[time, regions, quintiles])

    entermig            = Parameter(index=[time,regions,quintiles])
    leavemig            = Parameter(index=[time,regions,quintiles])
    deadmig             = Parameter(index=[time,regions,quintiles])
    transfer            = Parameter(index=[time,regions,quintiles])

    pgrowth             = Parameter(index=[time,regions])
    ypcgrowth           = Parameter(index=[time,regions])
    eloss               = Parameter(index=[time,regions])
    sloss               = Parameter(index=[time,regions])
    mitigationcost      = Parameter(index=[time,regions])
    area                = Parameter(index=[time,regions])
    population          = Parameter(index=[time,regions])
    populationin1       = Parameter(index=[time,regions])
    ineqgrowth          = Parameter(index=[time,regions])
    dead                = Parameter(index=[time,regions])

    globalpopulation    = Parameter(index=[time])
    plus90              = Parameter(index=[regions])
    gdp90               = Parameter(index=[regions])
    pop90               = Parameter(index=[regions])
    urbcorr             = Parameter(index=[regions])
    gdp0                = Parameter(index=[regions])
    ineq0               = Parameter(index=[regions])

    runwithoutdamage    = Parameter{Bool}(default = false)
    omega               = Parameter()
    xi                  = Parameter()
	consleak            = Parameter(default = 0.25)
	plusel              = Parameter(default = 0.25)
    savingsrate         = Parameter(default = 0.2)

    function run_timestep(p,v,d,t)

        if is_first(t)
            for r in d.regions
                # Set initial income distribution
                v.inequality[t, r] = p.ineq0[r]
                for q in d.quintiles
                    # Calculate quintile populations (20% of regional population)
                    v.quintile_pop[t,r,q] = p.population[t,r] / 5

                    # Set initial "old_income" per quintile to 0.0
                    v.quintile_old_income[t,r,q] = 0.0
                                
                    # Calculate initial quintile income
                    v.income_distribution[t,r,q] = cdf.(Normal(), quantile.(Normal(), q/5) .- sqrt(2) .* quantile.(Normal(), (v.inequality[t,r] + 1)/2)) - cdf.(Normal(), quantile.(Normal(), (q-1)/5) .- sqrt(2) .* quantile.(Normal(), (v.inequality[t,r] + 1)/2))
                    v.quintile_income[t,r,q] = p.gdp0[r] * v.income_distribution[t, r, q]

                    # Calculate initial quintile level consumption
                    v.quintile_consumption[t,r,q] = v.quintile_income[t,r,q] * 1000000000.0 * (1.0 - p.savingsrate)

                    # Calculate initial per capita quintile consumption levels.
                    v.quintile_pc_consumption[t,r,q] = v.quintile_consumption[t,r,q] / v.quintile_pop[t,r,q] / 1000000.0
                end

                v.income[t, r] = p.gdp0[r]
                v.ypc[t, r] = v.income[t, r] / p.population[t, r] * 1000.0
                v.consumption[t, r] = v.income[t, r] * 1000000000.0 * (1.0 - p.savingsrate)
            end

            v.globalincome[t] = sum(v.income[t,:])
            v.globalypc[t] = sum(v.income[t,:] .* 1000000000.0) / sum(p.populationin1[t,:])
            v.globalconsumption[t] = sum(v.consumption[t,:])

            for r in d.regions
                v.ypc90[r] = p.gdp90[r] / p.pop90[r] * 1000
            end
            
            # Calculate initial mitigation and damage distributions.
            v.mitigation_distribution[t,:,:] = quintile_dist(p.omega, v.income_distribution[t,:,:])
            v.damage_distribution[t,:,:]     = quintile_dist(p.xi, v.income_distribution[t,:,:])

        else
            for r in d.regions
                # Recalculate population growth rate including migration
                # Steady state after 2300
                if t <= TimestepValue(2300)
                    v.pgrowth_mig[t - 1, r] = (p.population[t, r] / p.population[t - 1, r] - 1.) * 100.
                else
                    v.pgrowth_mig[t - 1, r] = v.pgrowth_mig[t - 2, r]
                end

                # Calculate income growth rate 
                v.ygrowth[t, r] = (1 + 0.01 * v.pgrowth_mig[t - 1, r]) * (1 + 0.01 * p.ypcgrowth[t - 1, r]) - 1

                # Calculate inequality as described by Gini coefficient
                v.inequality[t, r] = max(0.01,min(0.99,(1 + 0.01 * p.ineqgrowth[t - 1, r]) * v.inequality[t - 1, r]))

                for q in d.quintiles
                    # Calculate quintile populations (20% of regional population)
                    v.quintile_pop[t,r,q] = p.population[t,r] / 5

                    # Calculate how each income quintile would evolve with input inequality scenario
                    v.income_distribution[t,r,q] = cdf.(Normal(), quantile.(Normal(), q/5) .- sqrt(2) .* quantile.(Normal(), (v.inequality[t,r] + 1)/2)) - cdf.(Normal(), quantile.(Normal(), (q-1)/5) .- sqrt(2) .* quantile.(Normal(), (v.inequality[t,r] + 1)/2))
                    quintginigrowth = (v.income_distribution[t,r,q] / v.income_distribution[t-1,r,q] - 1.) * 100.

                    # Calculate quintile income levels
                    v.quintile_old_income[t, r, q] = v.quintile_income[t-1, r, q] - (t >= TimestepValue(1990) && !p.runwithoutdamage ? p.consleak * p.eloss[t - 1, r] * v.damage_distribution[t-1,r,q] / 10.0 : 0) - (t >= TimestepValue(2015) ? p.transfer[t - 2, r,q] : 0.0)
                    v.quintile_income[t, r, q]     = (1 + v.ygrowth[t, r]) * (1 + 0.01 * quintginigrowth) * v.quintile_old_income[t,r,q] - p.mitigationcost[t-1,r] * v.mitigation_distribution[t-1,r,q] + p.transfer[t-1,r,q]

                    # Calculate quintile consumption for each region
                    v.quintile_consumption[t,r,q] = max(v.quintile_income[t,r,q] * 1000000000.0 * (1.0 - p.savingsrate) - (p.runwithoutdamage ? 0.0 :   (p.eloss[t - 1, r] + p.sloss[t - 1, r]) * v.damage_distribution[t-1,r,q] * 1000000000.0), 0.0)
                end

                # Rescale income and consumption quintiles based on changes in population distribution.
                if t >= TimestepValue(2015)
                    nbpeople = []
                    for q in d.quintiles                # Assume deaths not related to migration are equiproportionnal across quintiles
                        append!(nbpeople, (v.quintile_pop[t-1,r,q] - (p.dead[t-1,r] - sum(p.deadmig[t-1,r,:]))/1000000 / 5 + (p.entermig[t-1,r,q] - p.leavemig[t-1,r,q] - p.deadmig[t-1,r,q])/1000000) * (1.0 + 0.01 * p.pgrowth[t - 1, r]))
                    end
                    restpeople = nbpeople .- v.quintile_pop[t,r,:]
                    qiold = v.quintile_income[t,r,:]
                    qcold = v.quintile_consumption[t,r,:]
                    for q in d.quintiles
                        v.quintile_income[t,r,q] = max(0.1 * v.quintile_pop[t, r, q], qiold[q] * (v.quintile_pop[t,r,q] - (sum(restpeople[1:q-1]) > 0 ? sum(restpeople[1:q-1]) : 0.0) + (sum(restpeople[1:q]) < 0 ? sum(restpeople[1:q]) : 0.0)) / nbpeople[q] + (sum(restpeople[1:q-1]) > 0 ? sum(restpeople[1:q-1]) * qiold[q-1] / nbpeople[q-1] : 0.0) - (sum(restpeople[1:q]) < 0 && q<5 ? sum(restpeople[1:q]) * qiold[q+1] / nbpeople[q+1] : 0.0))
                        v.quintile_consumption[t,r,q] = max(0.00001, qcold[q] * (v.quintile_pop[t,r,q] - (sum(restpeople[1:q-1]) > 0 ? sum(restpeople[1:q-1]) : 0.0) + (sum(restpeople[1:q]) < 0 ? sum(restpeople[1:q]) : 0.0)) / nbpeople[q] + (sum(restpeople[1:q-1]) > 0 ? sum(restpeople[1:q-1]) * qcold[q-1] / nbpeople[q-1] : 0.0) - (sum(restpeople[1:q]) < 0 && q<5 ? sum(restpeople[1:q]) * qcold[q+1] / nbpeople[q+1] : 0.0))
                    end
                    for q in d.quintiles
                        if q<5 && v.quintile_income[t,r,q] >v.quintile_income[t,r,q+1]
                            diffqi = v.quintile_income[t,r,q] - v.quintile_income[t,r,q+1]
                            v.quintile_income[t,r,q] -= diffqi
                            v.quintile_income[t,r,q+1] += diffqi
                        end
                        if q<5 && v.quintile_consumption[t,r,q] >v.quintile_consumption[t,r,q+1]
                            diffqc = v.quintile_consumption[t,r,q] - v.quintile_consumption[t,r,q+1]
                            v.quintile_consumption[t,r,q] -= diffqc
                            v.quintile_consumption[t,r,q+1] += diffqc
                        end
                    end
                end
        
                # Check for unrealistic values
                for q in d.quintiles
                    if v.quintile_income[t, r, q] < 0.0001 * v.quintile_pop[t, r, q]
                        v.quintile_income[t, r, q] = 0.0001 * v.quintile_pop[t, r, q]
                    end
                end
        
                # Steady state after 2300
                if t > TimestepValue(2300)
                    for q in d.quintiles
                        v.quintile_income[t, r, q] = v.quintile_income[t-1, r, q]
                        v.quintile_consumption[t, r, q] = v.quintile_consumption[t-1, r, q]
                    end
                end

                # Calculate regional income (as the sum of quintile incomes within a region)
                v.income[t,r] = sum(v.quintile_income[t,r,:])

                # Calculate per capita quintile consumption levels.
                for q in d.quintiles
                    v.quintile_pc_consumption[t,r,q] = v.quintile_consumption[t,r,q] / v.quintile_pop[t,r,q] / 1000000.0
                end

                # Calculate regional consumption (as the sum of quintile consumptions within a region).
                v.consumption[t,r] = sum(v.quintile_consumption[t,r,:])

                # Calculate the error of calculating Gini from quintiles compared to Gini from lognormal
                ineq = 1 + 1/5 - 2/5 * (5 * v.income_distribution[t,r,1] + 4 * v.income_distribution[t,r,2] + 3 * v.income_distribution[t,r,3] + 2 * v.income_distribution[t,r,4] + v.income_distribution[t,r,5])
                ineqerr = ineq / v.inequality[t, r] - 1

                # Recalculate the new income distribution.
                for q in d.quintiles
                    v.income_distribution[t,r,q] = v.quintile_income[t,r,q] / v.income[t,r]
                end

                # Recalculate the new inequality, i.e. Gini coefficient
                # We use the Lorenz curve: Gini coefficient = 1 - 2*area under Lorenz curve
                # For quintiles, Gini can be approximated by G = 1 + 1/5 - 2/5 * (5*q1 + 4*q2 + 3*q3 + 2*q4 + q5) 
                # To ensure consistency with the lognormal transformation, we correct with the error defined above                
                v.inequality[t, r] = max(0.01,min(0.99, 1 / (1 + ineqerr) * (1 + 1/5 - 2/5 * (5 * v.income_distribution[t,r,1] + 4 * v.income_distribution[t,r,2] + 3 * v.income_distribution[t,r,3] + 2 * v.income_distribution[t,r,4] + v.income_distribution[t,r,5]))))
            end

            # Recalculate the new mitigation and damage distributions.
            v.mitigation_distribution[t,:,:] = quintile_dist(p.omega, v.income_distribution[t,:,:])
            v.damage_distribution[t,:,:]     = quintile_dist(p.xi, v.income_distribution[t,:,:])

            # Check for unrealistic values
            for r in d.regions
                if v.income[t, r] < 0.01 * p.population[t, r]
                    v.income[t, r] = 0.01 * p.population[t, r]
                end
            end

            for r in d.regions
                v.ypc[t, r] = v.income[t, r] / p.population[t, r] * 1000.0
            end

            v.globalconsumption[t] = sum(v.consumption[t,:])

            for r in d.regions
                v.plus[t, r] = p.plus90[r] * (v.ypc[t, r] / v.ypc90[r])^p.plusel

                if v.plus[t, r] > 1
                    v.plus[t, r] = 1.0
                end
            end

            for r in d.regions
                v.popdens[t, r] = p.population[t, r] / p.area[t, r] * 1000000.0
            end

            for r in d.regions
                v.urbpop[t, r] = (0.031 * sqrt(v.ypc[t, r]) - 0.011 * sqrt(v.popdens[t, r])) / (1.0 + 0.031 * sqrt(v.ypc[t, r]) - 0.011 * sqrt(v.popdens[t, r])) / (1 + p.urbcorr[r] / (1 + 0.001 * (t.t - MimiFUND.getindexfromyear(1990))^2.))
            end

            v.globalincome[t] = sum(v.income[t,:])

            v.globalypc[t] = sum(v.income[t,:] .* 1000000000.0) / sum(p.populationin1[t,:])
        end
    end
end