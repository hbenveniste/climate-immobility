using Mimi

@defcomp addimpact_nice begin
    regions     = Index()
    quintiles   = Index()

    elossall   = Variable(index=[time,regions])
    slossall   = Variable(index=[time,regions])
    loss    = Variable(index=[time,regions])

    eloss       = Parameter(index=[time,regions])
    sloss       = Parameter(index=[time,regions])
    entercost   = Parameter(index=[time,regions])
    leavecost   = Parameter(index=[time,regions])
    otherconsloss   = Parameter(index=[time,regions,quintiles])
    income      = Parameter(index=[time,regions])

    function run_timestep(p,v,d,t)
        if is_first(t)
            for r in d.regions
                v.elossall[t, r] = 0.0
                v.slossall[t, r] = 0.0
            end
        else
            for r in d.regions
                v.elossall[t, r] = min(p.eloss[t, r] - p.entercost[t, r], p.income[t, r])          # remove entercost: remove migration in SLR component
                v.slossall[t, r] = p.sloss[t, r] - p.leavecost[t, r] + sum(p.otherconsloss[t, r, :])       # remove leavecost: remove migration in SLR component + add otherconsloss: add lives lost while attempting to migrate
                v.loss[t, r] = (v.elossall[t, r] + v.slossall[t, r]) * 1000000000.0
            end
        end
    end
end