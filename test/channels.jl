@testset "channels.jl" begin
    let Nant = 5, Nfreq = 100
        name, ms = createms(Nant, Nfreq)
        Nbase = Tables.numrows(ms)
        # Generate the bad data
        bad_channels = [5, 10, 35, 72]
        data = zeros(Complex64, 4, Nfreq, Nbase)
        for α = 1:Nbase, β = 1:Nfreq, p = 1:4
            if β in bad_channels
                data[p,β,α] = 0.1*rand() + 100
            else
                data[p,β,α] = 0.1*rand() + 1
            end
        end
        ms["DATA"] = data
        # Test that the bad antennas are flagged
        flags = ChannelFlags(zeros(Nfreq, Nant, 2))
        flags[bad_channels, :, :] = true
        myflags = bright_narrow_rfi(ms, 10)
        @test flags == myflags
    end
end

