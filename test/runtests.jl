using MLPFlagger
if VERSION >= v"0.5-"
    using Base.Test
else
    using BaseTestNext
    const Test = BaseTestNext
end
using CasaCore.Measures
using CasaCore.Tables

include("setup.jl")

srand(123)
@testset "MLPFlagger Tests" begin
    include("clearflags.jl")
    include("antennas.jl")
    include("channels.jl")
end

