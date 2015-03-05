using MLPFlagger
using Base.Test

using CasaCore.Tables

srand(123)

# Define the interferometer
Nant  = 256
Nfreq = 109
Nbase = div(Nant*(Nant-1),2) + Nant

ant1 = Array(Int32,Nbase)
ant2 = Array(Int32,Nbase)
α = 1
for i = 1:Nant, j = i:Nant
    ant1[α] = i
    ant2[α] = j
    α += 1
end

function createms()
    name  = tempname()*".ms"
    table = Table(name)

    subtable = Table("$name/SPECTRAL_WINDOW")
    Tables.addRows!(subtable,1)
    subtable["CHAN_FREQ"] = reshape(linspace(0,1,Nfreq),Nfreq,1)
    finalize(subtable)

    Tables.addRows!(table,Nbase)
    table[kw"SPECTRAL_WINDOW"] = "Table: $name/SPECTRAL_WINDOW"
    table["ANTENNA1"] = ant1-1
    table["ANTENNA2"] = ant2-1
    table["FLAG"] = zeros(Bool,4,Nfreq,Nbase)

    name,table
end

# clearflags
function test_clearflags()
    name,ms = createms()

    # Generate flags
    flags = rand(Bool,4,Nfreq,Nbase)
    ms["FLAG"] = flags

    # Test
    clearflags!(ms)
    @test ms["FLAG"] == zeros(Bool,4,Nfreq,Nbase)
end
test_clearflags()

# flag
function test_flags()
    name,ms = createms()

    # Generate bad data
    bad_antennas = 8:8:Nant
    bad_channels = 20:20:Nfreq

    data = Array{Complex64}(4,Nfreq,Nbase)
    rand!(data)
    data[:,bad_channels,:] *= 100.0
    ms["DATA"] = data

    # Test
    flag!([ms],bad_antennas=[bad_antennas...])
    flags = ms["FLAG"]
    for α = 1:Nbase
        if ant1[α] in bad_antennas || ant2[α] in bad_antennas
            @test all(flags[:,:,α])
        end
    end
    for β in bad_channels
        @test all(flags[:,β,:])
    end
end
test_flags()

