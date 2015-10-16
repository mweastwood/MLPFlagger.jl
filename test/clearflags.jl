let Nant = 5, Nfreq = 5
    name,ms = createms(Nant,Nfreq)
    flags     = ms.table["FLAG"]
    row_flags = ms.table["FLAG_ROW"]
    rand!(flags)
    rand!(row_flags)
    ms.table["FLAG"] = flags
    ms.table["FLAG_ROW"] = row_flags
    clearflags!(ms)
    @test !any(ms.table["FLAG"])
    @test !any(ms.table["FLAG_ROW"])
end

