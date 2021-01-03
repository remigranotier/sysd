#!/usr/bin/julia

"""
Parses a Makefile and produces a dict of all the tasks present 
in the Makefile

# Arguments
- `filename::String`: path to a valid Makefile
"""
function parsing(dirname::String)::Dict{String, MakeTask}
    # Working directory must be the root directory of the Makefile
    cd(dirname)
    filename::String = "Makefile"

    tasks::Dict{String, MakeTask} = Dict([])
    open(filename) do file
        current::MakeTask = MakeTask("", "",  false, Set([]), Set([]), Set([]))
        building_task = false
        empty_line = r"^\s*#*\s*$"

        for (i, line) in enumerate(eachline(file))
            # if !(match(empty_line, line) === nothing)
            if occursin(empty_line, line)
                if building_task
                    push!(tasks, current.name => current)
                    current = MakeTask("", "", false, Set([]), Set([]), Set([]))
                    building_task = false
                end
                continue
            end;

            if !building_task
                current.name, dependencies = split(line, ":", limit=2)
                current.dependencies = Set(split(dependencies))
                current.dependenciesStatic = Set(split(dependencies)) #added for exec
                building_task = true
            elseif building_task
                current.command = strip(line)
                push!(tasks, current.name => current)
                current = MakeTask("", "", false, Set([]), Set([]), Set([]))
                building_task = false
            end
        end
        if building_task
            push!(tasks, current.name => current)
        end
    end

    # Files and directories present at the same place than the Makefile are valid dependencies,
    # i.e. tasks already done
    foreach(readdir()) do f
        current = MakeTask(f, "", true, Set([]), Set([]), Set([]))
        push!(tasks, current.name => current)
    end

    # Filling needed_by
    for (name, t) in tasks
        for dep in t.dependencies
            push!(tasks[dep].needed_by, name)
        end
    end

    tasks
end


function targeted_tasks(target::String, tasks::Dict{String, MakeTask})::Dict{String, MakeTask}
    targeted::Dict{String, MakeTask} = Dict([(target, tasks[target])])
    to_explore::Set{String} = Set([target])
    explored::Set{String} = Set()

    while !isempty(to_explore)
        current = pop!(to_explore)
        if current in explored
            continue
        end
        push!(explored, current)

        for t in tasks[current].dependencies
            push!(to_explore, t)
            push!(targeted, t => tasks[t])
        end
    end
    targeted
end
