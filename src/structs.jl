#!/usr/bin/julia

mutable struct MakeTask
    name::String
    command::String
    done::Bool
    dependenciesStatic::Set{String}
    dependencies::Set{String}
    needed_by::Set{String}
end
