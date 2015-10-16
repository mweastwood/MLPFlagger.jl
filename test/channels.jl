let
    Nfreq = 10
    flags = ChannelFlags(zeros(Bool,Nfreq))
    @test repr(flags) == "Flagged channels: []"
    flags[5] = true
    flags[7] = true
    @test repr(flags) == "Flagged channels: [5, 7]"
end

let Nant = 5, Nfreq = 100
    name,ms = createms(Nant,Nfreq)
    # Generate the bad data
    bad_channels = [5,10,35,72]
    data = zeros(Complex64,4,Nfreq,ms.Nbase)
    for β = 1:Nfreq
        if β in bad_channels
            data[:,β,:] = 0.1*rand() + 100
        else
            data[:,β,:] = 0.1*rand() + 1
        end
    end
    ms.table["DATA"] = data
    # Test that the bad antennas are flagged
    flags = zeros(Nfreq)
    flags[bad_channels] = true
    myflags = bright_narrow_rfi(ms)
    @test flags == myflags.flags
end

