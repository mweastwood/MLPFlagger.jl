@testset "antennas.jl" begin
    let
        flags = AntennaFlags(10)
        @test repr(flags) == "Flagged antennas: []"
        flags[1,1] = true
        @test repr(flags) == "Flagged antennas: [1x]"
        flags[5,2] = true
        @test repr(flags) == "Flagged antennas: [1x, 5y]"
    end

    let Nant = 5, Nfreq = 5
        name, ms = createms(Nant, Nfreq)
        ant1 = ms["ANTENNA1"] + 1
        ant2 = ms["ANTENNA2"] + 1
        Nbase = Tables.numrows(ms)
        # Generate the bad data
        bad_antennas = [2,4]
        data = zeros(Complex64, 4, Nfreq, Nbase)
        for α = 1:Nbase, β = 1:Nfreq
            if ant1[α] in bad_antennas || ant2[α] in bad_antennas
                data[1,β,α] = abs(randn())
                data[4,β,α] = abs(randn())
            else
                data[1,β,α] = 500 + randn()
                data[4,β,α] = 500 + randn()
            end
        end
        ms["DATA"] = data
        # Test that the bad antennas are flagged
        flags = AntennaFlags(fill(false, Nant, 2))
        flags[bad_antennas,:] = true
        myflags = low_power_antennas(ms, 1e-2)
        @test flags == myflags
    end
end

