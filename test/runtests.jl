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

    Tables.addRows!(table,Nbase)
    table["ANTENNA1"] = ant1-1
    table["ANTENNA2"] = ant2-1

    name,table
end

# Antenna flags
function test_antenna_flags()
    name,ms = createms()

    # Generate bad data
    bad_antennas = [8:8:Nant;]
    data = Array{Complex64}(4,Nfreq,Nbase)
    rand!(data)
    for α = 1:Nbase
        if ant1[α] in bad_antennas || ant2[α] in bad_antennas
            data[:,:,α] += 100.0+100.0im
        end
    end
    ms["DATA"] = data

    # Test
    autos = MLPFlagger.getautos(ms)
    @test find(MLPFlagger.flag_antennas(autos)) == bad_antennas
end
test_antenna_flags()

