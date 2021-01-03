#!/usr/bin/julia
module MakeBackend
include("structs.jl")
include("parser.jl")
include("scheduler.jl")

using Distributed

function exec(task::MakeTask)::Array{String}
    # Put Makefile directory in PATH
    println("Making $(task.name) on worker $(myid())")
    contentDirBefore = readdir()

    env = copy(ENV)
    env["PATH"] = "$(pwd()):$(env["PATH"])"
    cmd = Cmd(`sh -c $(task.command)`, env=env)
    run(cmd)

    contentDirAfter = readdir()
    files_created = setdiff(contentDirAfter, contentDirBefore)

    files_created
end

function exec_task_on_worker(
        worker_id,
        todoTask,
        done_stack,
    )

    # Copie des fichiers utiles sur l'esclave
    # TODO: faire un diff avec les fichiers déjà présents sur l'esclave
    if !isempty(todoTask.dependenciesStatic)
        ## run(`scp $(todoTask.dependenciesStatic) gautier@192.168.0.17:/home/gautier/sysd`)
    end 

    files_created = remotecall_fetch(exec, worker_id, todoTask)
    
    # Copie des fichiers créés
    if !isempty(files_created)
        ## run(`scp gautier@192.168.0.17:/home/gautier/sysd/$files_created .`)
    end
    todoTask.done = true
    
    # Put task to be put in done
    put!(done_stack, todoTask)

    # Make worker available again
    put!(default_worker_pool(), worker_id)

end

# TODO à revoir avec le machine file et/ou au début de make.jl
function clusterStart()
    # TODO: sshkey dédiée
    # workersTab = [("gautier@192.168.0.17:22",1)] 
    # addprocs(workersTab ; sshflags=`-i /home/gautier/.ssh/id_rsa`, dir="/home/gautier/sysd", tunnel=true, exename=`/usr/bin/julia`)

    ## run(`scp -r $(pwd()) gautier@192.168.0.17:/home/gautier/sysd`)
end

end