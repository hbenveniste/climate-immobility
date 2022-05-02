using Mimi

@defcomp addimpact_nice_cata begin
    regions     = Index()
    quintiles   = Index()

    elossall   = Variable(index=[time,regions])
    slossall   = Variable(index=[time,regions])
    loss    = Variable(index=[time,regions])
    eloss_otherall = Variable(index=[time,regions])

    eloss       = Parameter(index=[time,regions])
    sloss       = Parameter(index=[time,regions])
    entercost   = Parameter(index=[time,regions])
    leavecost   = Parameter(index=[time,regions])
    otherconsloss   = Parameter(index=[time,regions,quintiles])
    income      = Parameter(index=[time,regions])   
    eloss_other = Parameter(index=[time,regions])
    globalincome = Parameter(index=[time])
    temp        = Parameter(index=[time])
    elosscatapar = Parameter()

    function run_timestep(p,v,d,t)
        if is_first(t)
            for r in d.regions
                v.elossall[t, r] = 0.0
                v.slossall[t, r] = 0.0
                v.eloss_otherall[t, r] = 0.0
            end
        else
            for r in d.regions
                v.eloss_otherall[t, r] = p.eloss_other[t, r] + p.elosscatapar * p.temp[t]^7 * p.income[t, r] / p.globalincome[t]       # add catastrophic damages (T^7) so that global GDP loss = 50% when T=6C
                v.elossall[t, r] = min(p.eloss[t, r] + v.eloss_otherall[t, r] - p.entercost[t, r], p.income[t, r])          # remove entercost: remove migration in SLR component
                v.slossall[t, r] = p.sloss[t, r] - p.leavecost[t, r] + sum(p.otherconsloss[t, r, :])       # remove leavecost: remove migration in SLR component + add otherconsloss: add lives lost while attempting to migrate
                v.loss[t, r] = (v.elossall[t, r] + v.slossall[t, r]) * 1000000000.0
            end
        end
    end
end