#!/usr/bin/julia

using Distributed

#TODO: mettre dans machinefile
# Pour l'instant, les ips/username pour ssh sont en dur car on execute en local,
# ce sera changé pour grid5000

fileName = "/home/rgranotier/hosts.txt"
workersTab = []
open(fileName) do file
    for (i, line) in enumerate(eachline(file))
        push!(workersTab, (line, 1))
    end
end

# run(`scp $(readdir("/home/gautier/sysd_g3/src")) gautier@192.168.0.17:/home/gautier/sysd`)
# workersTab = [("gautier@192.168.0.17:22",2)] 
addprocs(   workersTab;
            sshflags=`-i /home/rgranotier/.ssh/id_rsa`,
            dir="/home/rgranotier/sysd/src",
            tunnel=true,
            exename=`/usr/bin/julia`)

include("execute.jl")
@everywhere include("execute.jl")
@everywhere using .MakeBackend

function main() 
    if length(ARGS) < 1 
        println("You need to put a directory")
        println("Aborting...")
        return nothing
    end

    if !isdir(ARGS[1])
        println("Invalid directory")
        println("Aborting...")
    elseif !isfile("$(ARGS[1])/Makefile")
        println("There is no Makefile in this directory")
        println("Aborting...")
    else
        # cd(ARGS[1])
        tasks = MakeBackend.parsing(ARGS[1])
        # display(tasks)
    end

    target::String = "all"
    if length(ARGS) >= 2
        target = ARGS[2]
    end

    if !haskey(tasks, target)
        println("There is no target named $target in $(pwd())")
        println("Aborting...")
        return
    end
    tasks_to_do = MakeBackend.targeted_tasks(target, tasks)

    # if target=="clean"
    #     @sync [@spawnat i MakeBackend.exec(tasks_to_do["clean"], ARGS[1]) for i in workers()]
    #     MakeBackend.exec(tasks_to_do["clean"], ARGS[1])
    #     return
    # end

    MakeBackend.schedule_tasks(tasks_to_do, ARGS[1])

end

main()
