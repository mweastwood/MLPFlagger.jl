let
    flags = AntennaFlags(10)
    @test repr(flags) == "Flagged antennas: []"
    flags[1,1] = true
    @test repr(flags) == "Flagged antennas: [1x]"
    flags[5,2] = true
    @test repr(flags) == "Flagged antennas: [1x, 5y]"
end

let Nant = 5, Nfreq = 5
    name,ms = createms(Nant,Nfreq)
    # Generate the bad data
    bad_antennas = [2,4]
    data = zeros(Complex64,4,Nfreq,ms.Nbase)
    for α = 1:ms.Nbase
        if ms.ant1[α] in bad_antennas || ms.ant2[α] in bad_antennas
            data[:,:,α] = 0.1*rand() + 1
        else
            data[:,:,α] = 0.1*rand() + 10
        end
    end
    ms.table["DATA"] = data
    # Test that the bad antennas are flagged
    flags = zeros(Nant,2)
    flags[bad_antennas,:] = true
    myflags = low_power_antennas(ms)
    @test flags == myflags.flags
end

