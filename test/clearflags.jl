@testset "clearflags.jl" begin
    Nant  = 5
    Nfreq = 5
    name, ms  = createms(Nant, Nfreq)
    flags     = ms["FLAG"]
    row_flags = ms["FLAG_ROW"]
    rand!(flags)
    rand!(row_flags)
    ms["FLAG"]     = flags
    ms["FLAG_ROW"] = row_flags
    clearflags!(ms)
    @test !any(ms["FLAG"])
    @test !any(ms["FLAG_ROW"])
end

