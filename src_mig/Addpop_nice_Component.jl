using Mimi

@defcomp addpop_nice begin
    regions     = Index()
    quintiles   = Index()

    enter    = Variable(index=[time,regions])
    leave    = Variable(index=[time,regions])
    deadall     = Variable(index=[time,regions])

    dead     = Parameter(index=[time,regions])
    entermig = Parameter(index=[time,regions,quintiles])
    leavemig = Parameter(index=[time,regions,quintiles])
    deadmig  = Parameter(index=[time,regions,quintiles])

    function run_timestep(p,v,d,t)
        if !is_first(t)
            for r in d.regions
                v.leave[t, r] = sum(p.leavemig[t, r, :])
                v.enter[t, r] = sum(p.entermig[t, r, :])
                v.deadall[t, r] = p.dead[t, r] + sum(p.deadmig[t, r, :])
            end
        end
    end
end