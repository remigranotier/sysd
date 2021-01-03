#!/usr/bin/julia

function init_task_lists(tasks::Dict{String, MakeTask})
    done::Dict{String, MakeTask} = filter(t->t.second.done, tasks)
    # Filter task already done from other tasks dependencies.
    for pair in done
        task = pair.second
        for t in task.needed_by 
            if t in keys(tasks)
                delete!(tasks[t].dependencies, task.name)
            end
        end
    end

    wait_for_dependencies::Dict{String, MakeTask} = filter(t->length(t.second.dependencies)>0, tasks)

    to_do::Dict{String, MakeTask} = filter(t->(length(t.second.dependencies) == 0 && !t.second.done), tasks)

    wait_for_dependencies, to_do, done
end


function update_after_task_completion!(
        task::MakeTask,
        wait_for_dependencies::Dict{String, MakeTask},
        to_do::Dict{String, MakeTask},
        done::Dict{String, MakeTask}
    )
    for t in task.needed_by 
        if t in keys(wait_for_dependencies)
            delete!(wait_for_dependencies[t].dependencies, task.name)
        end
    end
    
    update_task_lists!(wait_for_dependencies, to_do)
    push!(done, task.name => task)
end


function update_task_lists!(wait_for_dependencies::Dict{String, MakeTask}, to_do::Dict{String, MakeTask})
    for task in wait_for_dependencies
        if length(task.second.dependencies) == 0
            delete!(wait_for_dependencies, task.first)
            push!(to_do, task)
        end
    end
end


function schedule_tasks(tasks_to_do::Dict{String, MakeTask}, dirName::String)
    # Rend les fichiers julia disponibles sur les workers
    ## run(`scp $(readdir()) gautier@192.168.0.17:/home/gautier/sysd`)
    wait_for_dependencies, to_do, done = MakeBackend.init_task_lists(tasks_to_do)

    # Channel is used to communicate with functions run asynchronously
    done_stack::Channel{MakeTask} = Channel{MakeTask}(length(workers()) + 1)

    while length(done) != length(tasks_to_do)
        worker_id = take!(default_worker_pool())

        # Channel content is used to update state
        while isready(done_stack)
            task_done = take!(done_stack)
            update_after_task_completion!(task_done, wait_for_dependencies, to_do, done)
        end
        
        next_task = nothing
        if length(to_do) > 0
            next_task = pop!(to_do).second
        end

        if next_task !== nothing
            @async MakeBackend.exec_task_on_worker(worker_id, next_task, done_stack, dirName)
        end
    end
end
