using Mimi

@defcomp migration_nice begin
    regions       = Index()
    agegroups     = Index()
    quintiles     = Index()

    move          = Variable(index=[time,regions,regions,quintiles,quintiles])
    migstock      = Variable(index=[time,regions,regions,quintiles,quintiles])
    rem           = Variable(index=[time,regions,regions,quintiles,quintiles])
    entermig      = Variable(index=[time,regions,quintiles])
    leavemig      = Variable(index=[time,regions,quintiles])
    deadmig       = Variable(index=[time,regions,quintiles])
    deadmigcost   = Variable(index=[time,regions,quintiles])
    receive       = Variable(index=[time,regions,quintiles])
    send          = Variable(index=[time,regions,quintiles])
    remittances   = Variable(index=[time,regions,quintiles])
    remshare      = Variable(index=[time,regions,regions])

    pop           = Parameter(index=[time,regions,quintiles])
    income        = Parameter(index=[time,regions,quintiles])
    damage_distr  = Parameter(index=[time, regions, quintiles])
    eloss         = Parameter(index=[time,regions])
    popdens       = Parameter(index=[time,regions])
    vsl           = Parameter(index=[time,regions])
    lifeexp       = Parameter(index=[time,regions])

    migstockinit  = Parameter(index=[regions,regions,quintiles,quintiles])
    distance      = Parameter(index=[regions,regions])
    migdeathrisk  = Parameter(index=[regions,regions])
    remres        = Parameter(index=[regions,regions])            # residuals from estimation of remshare, used in gravity estimation
    remcost       = Parameter(index=[regions,regions])
    comofflang    = Parameter(index=[regions,regions])   
    policy        = Parameter(index=[regions,regions])            # 1 represents implicit current border policy. Can be decreased for stronger border policy, or increased for more open borders.
    gravres_qi    = Parameter(index=[regions,regions,quintiles,quintiles]) 


    ageshare      = Parameter(index=[regions,quintiles,agegroups])
    agegroupinit  = Parameter(index=[regions,regions,quintiles,quintiles,agegroups])

    beta0_quint   = Parameter(index=[quintiles])
    beta1_quint   = Parameter(index=[quintiles])
    beta2_quint   = Parameter(index=[quintiles])
    beta4_quint   = Parameter(index=[quintiles])
    beta5_quint   = Parameter(index=[quintiles])
    beta7_quint   = Parameter(index=[quintiles])
    beta8_quint   = Parameter(index=[quintiles])
    beta9_quint   = Parameter(index=[quintiles])
    beta10_quint  = Parameter(index=[quintiles])

    # Repartition of migrants in destination quintiles
    gamma0_quint  = Parameter(index=[quintiles])
    gamma1_quint  = Parameter(index=[quintiles])

    # Remittance shares
    delta0        = Parameter(default = 3.418)
    delta1        = Parameter(default = -0.241)
    delta2        = Parameter(default = -0.362)
    delta3        = Parameter(default = -5.953)

    runremcatchupdam    = Parameter{Bool}(default = false)
    runwithoutdamage    = Parameter{Bool}(default = false)
    consleak            = Parameter(default = 0.25)

    function run_timestep(p,v,d,t)
        if is_first(t)
            for r in d.regions
                for r1 in d.regions
                    v.remshare[t, r, r1] = 0.0
                    for qor in d.quintiles
                        for qdest in d.quintiles
                            v.move[t, r, r1, qor, qdest] = 0.0
                            v.migstock[t, r, r1, qor, qdest] = 0.0
                            v.rem[t, r, r1, qor, qdest] = 0.0
                        end
                    end
                end
                for q in d.quintiles
                    v.entermig[t, r, q] = 0.0
                    v.leavemig[t, r, q] = 0.0
                    v.deadmig[t, r, q] = 0.0
                    v.deadmigcost[t, r, q] = 0.0
                    v.receive[t, r, q] = 0.0
                    v.send[t, r, q] = 0.0
                    v.remittances[t, r, q] = 0.0
                end
            end
        else
            # Calculating the number of people migrating from one region to another, based on a gravity model including per capita income.
            # Population is expressed in millions, distance in km.

            # We apply the gravity model at the quintile level; estimation for each origin quintile separately
            for destination in d.regions
                for source in d.regions
                    ypc_dest = mean([sum(p.income[TimestepIndex(t10), destination, :]) / sum(p.pop[TimestepIndex(t10), destination, :]) * 1000.0 for t10 in max(1,t.t-10):t.t])
                    for qor in d.quintiles
                        ypc_source = mean([p.income[TimestepIndex(t10), source, qor] / p.pop[TimestepIndex(t10), source, qor] * 1000.0 for t10 in max(1,t.t-10):t.t])
                        ypc_ratio = ypc_dest / ypc_source
                        # Compute migrants leaving each quintile of a given origin and entering an average quintile of a given destination
                        if t >= TimestepValue(2015) && source != destination && t <= TimestepValue(2300)
                            move = exp(p.beta0_quint[qor]) * (p.pop[t, source, qor] * 1000000)^p.beta1_quint[qor] * (p.pop[t, destination, qor] * 1000000)^p.beta2_quint[qor] * ypc_source^p.beta4_quint[qor] * ypc_ratio^p.beta5_quint[qor] * p.distance[source, destination]^p.beta7_quint[qor] * exp(p.beta8_quint[qor]*p.remres[source, destination]) * exp(p.beta9_quint[qor]*p.remcost[source,destination]) * exp(p.beta10_quint[qor]*p.comofflang[source,destination])
                        else
                            move = 0.0
                        end
                        # Distribute migrants over destination quintiles
                        # Compute preliminary share of migrants going to a given destination quintile, based on estimation
                        fs = []
                        for qdest in d.quintiles
                            append!(fs, exp(p.gamma0_quint[qdest]) * ypc_ratio^p.gamma1_quint[qdest])
                        end
                        # Rescale share so that sum(shares)=1
                        for qdest in d.quintiles
                            flowshare = fs[qdest] / sum(fs)
                            v.move[t, source, destination, qor, qdest] = max(0.0, p.policy[source, destination] * (p.gravres_qi[source,destination,qor,qdest] + move * 5 * flowshare))
                        end
                    end
                end
            end

            for destination in d.regions
                for qdest in d.quintiles
                    entermig = 0.0
                    for source in d.regions
                        for qor in d.quintiles
                            leaveall = sum(v.move[t, source, :, qor, :])
                            if leaveall > p.pop[t, source, qor] * 1000000
                                entermig += v.move[t, source, destination, qor, qdest] / leaveall * p.pop[t, source, qor] * 1000000
                            else
                                entermig += v.move[t, source, destination, qor, qdest]
                            end
                        end
                    end
                    v.entermig[t, destination, qdest] = entermig
                end                        
                # Steady state after 2300
                if t > TimestepValue(2300)
                    for qdest in d.quintiles
                        v.entermig[t, destination, qdest] = v.entermig[t-1, destination, qdest]
                    end
                end
            end
         
            for source in d.regions
                for qor in d.quintiles
                    leavemig = 0.0
                    leaveall = sum(v.move[t, source, :, qor, :])
                    for destination in d.regions
                        for qdest in d.quintiles
                            if leaveall > p.pop[t, source, qor] * 1000000
                                leavemig += v.move[t, source, destination, qor, qdest] / leaveall * p.pop[t, source, qor] * 1000000
                            else
                                leavemig += v.move[t, source, destination, qor, qdest]
                            end
                        end
                    end
                    v.leavemig[t, source, qor] = leavemig
                end
                # Steady state after 2300
                if t > TimestepValue(2300)
                    for qor in d.quintiles
                        v.leavemig[t, source, qor] = v.leavemig[t-1, source, qor]
                    end
                end
            end

            # Calculating the risk of dying while attempting to migrate across borders: 
            # We use data on migration flows between regions in period 2005-2010 from Abel [2013], used in the SSP population scenarios
            # And data on missing migrants in period 2014-2018 from IOM (http://missingmigrants.iom.int/)
            for r in d.regions
                for q in d.quintiles
                    v.deadmig[t, r, q] = 0.0               # consider risk of dying based on origin region
                    v.deadmigcost[t, r, q] = 0.0           
                    # we consider that only quintiles 1-2-3 are at risk of dying
                    if q<=3
                        for destination in d.regions
                            # We do not differentiate risk or cost per income quintile
                            # We count all migrants perishing on the way
                            v.deadmig[t, r, q] += sum(p.migdeathrisk[r, destination] .* v.move[t, r, destination, q, :])
                            # We count as climate change damage only those attributed to differences in income resulting from climate change impacts
                            v.deadmigcost[t, r, q] += max(p.vsl[t, destination], p.vsl[t, r]) * sum(p.migdeathrisk[r, destination] .* v.move[t, r, destination, q, :]) / 1000000000.0
                        end
                        if v.deadmig[t, r, q] > p.pop[t, r, q] * 1000000
                            v.deadmig[t, r, q] = p.pop[t, r, q] * 1000000
                        end
                    end
                end
                # Steady state after 2300
                if t > TimestepValue(2300)
                    for q in d.quintiles
                        v.deadmig[t, r, q] = v.deadmig[t-1, r, q]
                        v.deadmigcost[t, r, q] = v.deadmigcost[t-1, r, q]
                    end
                end
            end

            # Adding a stock variable indicating how many immigrants from a region are in another region.
            # Shares of migrants per age group are based on SSP projections for 2015-2100. Linear interpolation for this period, then shares maintained constant until 3000.
            # We assume that migrants once arrived stay in the same income quintile over time
            for source in d.regions
                for destination in d.regions
                    for qor in d.quintiles
                        for qdest in d.quintiles
                            if t < TimestepValue(2015)
                                v.migstock[t, source, destination, qor, qdest] = 0.0
                            elseif t == TimestepValue(2015)
                                # Attribute initial migrant stock to ensure some remittances from migrants before 2015 even when borders closed after
                                v.migstock[t, source, destination, qor, qdest] = p.migstockinit[source, destination, qor, qdest] + v.move[t, source, destination, qor, qdest] - v.deadmig[t, source, qor] * (v.leavemig[t, source, qor] != 0.0 ? v.move[t, source, destination, qor, qdest] / v.leavemig[t, source, qor] : 0.0)
                            else
                                v.migstock[t, source, destination, qor, qdest] = v.migstock[t - 1, source, destination, qor, qdest] + v.move[t, source, destination, qor, qdest] - v.deadmig[t, source, qor] * (v.leavemig[t, source, qor] != 0.0 ? v.move[t, source, destination, qor, qdest] / v.leavemig[t, source, qor] : 0.0)
                            end
                            # We assume that migrants' age distribution is specific to each quintile and based on education levels by age group from the SSP projections
                            if t >= TimestepValue(2015)
                                # Remove from stock migrants who migrated after 2015, once they die
                                for ag in d.agegroups
                                    if t.t - (2015-1950+1) > p.lifeexp[t, destination] - ag
                                        t0 = ceil(Int, t.t - max(0, p.lifeexp[t, destination] - ag))
                                        v.migstock[t, source, destination, qor, qdest] -= v.move[TimestepIndex(t0), source, destination, qor, qdest] * p.ageshare[destination, qdest, ag] 
                                    end
                                end
                                if t == TimestepValue(2015 )
                                    # Remove from stock migrants who migrated prior to 2015 and, in 2015, are older than their destination's life expectancy
                                    a0 = ceil(Int, p.lifeexp[t, destination])
                                    for a in a0:120
                                        v.migstock[t, source, destination, qor, qdest] -= p.agegroupinit[source, destination, qor, qdest, a+1] 
                                    end
                                else
                                    # Remove from stock migrants who migrated prior to 2015 and over time get older than their destination's life expectancy
                                    a1 = ceil(Int, p.lifeexp[t, destination] - (t.t - (2015-1950+1)))
                                    if a1 >= 0 
                                        v.migstock[t, source, destination, qor, qdest] -= p.agegroupinit[source, destination, qor, qdest, a1+1] 
                                    end
                                end
                            end
                            if v.migstock[t, source, destination, qor, qdest] < 0
                                v.migstock[t, source, destination, qor, qdest] = 0
                            end
                        end
                    end
                end
            end

            # Calculating remshare endogenously, but not at the quintile level by lack of data. Instead assume all migrants from a given corridor send the same share of income. 
            for source in d.regions
                for destination in d.regions
                    ypc_d = sum(p.income[t, destination, :]) / sum(p.pop[t, destination, :]) * 1000.0
                    ypc_s = sum(p.income[t, source, :]) / sum(p.pop[t, source, :]) * 1000.0
                    v.remshare[t,source,destination] = exp(p.delta0) * ypc_s^p.delta1 * ypc_d^p.delta2 * exp(p.delta3*p.remcost[source,destination]) * p.remres[source,destination]
                end
            end

            # Calculating remittances sent by migrants to their origin communities.
            for source in d.regions
                for destination in d.regions
                    for qor in d.quintiles
                        for qdest in d.quintiles
                            ypc_d = p.income[t, destination, qdest] / p.pop[t, destination, qdest] * 1000.0
                            # If we keep remittances constant over the lifetime of the migrant at remshare:
                            rem = v.migstock[t, source, destination, qor, qdest] * v.remshare[t,source, destination] * (1.0 - p.remcost[source, destination]) * ypc_d / 1000000000
                            v.rem[t, source, destination, qor, qdest] = rem
                        end
                    end
                end
            end

            for source in d.regions
                for qor in d.quintiles
                    receive = 0.0
                    for destination in d.regions
                        for qdest in d.quintiles
                            sendall = sum(v.rem[t, :, destination, :, qdest])
                            if sendall > p.income[t, destination, qdest]
                                receive += v.rem[t, source, destination, qor, qdest] / sendall * p.income[t, destination, qdest]
                            else
                                receive += v.rem[t, source, destination, qor, qdest]
                            end
                        end
                    end
                    v.receive[t, source, qor] = receive
                end
            end
            
            for destination in d.regions
                for qdest in d.quintiles
                    send = 0.0
                    sendall = sum(v.rem[t, :, destination, :, qdest])
                    for source in d.regions
                        for qor in d.quintiles
                            if sendall > p.income[t, destination, qdest]
                                send += v.rem[t, source, destination, qor, qdest] / sendall * p.income[t, destination, qdest]
                            else
                                send += v.rem[t, source, destination, qor, qdest] 
                            end
                        end
                    end
                    v.send[t, destination, qdest] = send
                end
            end

            for r in d.regions
                for q in d.quintiles
                    v.remittances[t, r, q] = max(
                        v.receive[t, r, q] - v.send[t, r, q],
                        (p.runremcatchupdam && t >= TimestepValue(1990) && !p.runwithoutdamage ? p.consleak * p.eloss[t-1, r] * p.damage_distr[t-1, r, q] / 10.0 : 0)
                    )
                end
            end
        end
    end
end