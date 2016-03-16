# Copyright (c) 2015 Michael Eastwood
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

doc"""
    AntennaFlags

A container that holds a list of antenna flags.

    AntennaFlags(Nant)

Create an empty set of antenna flags for `Nant` antennas.
"""
immutable AntennaFlags
    flags::Array{Bool,2}
    function AntennaFlags(flags)
        size(flags, 2) == 2 || error("second dimension must correspond to 2 polarizations")
        new(flags)
    end
end

function AntennaFlags(Nant::Int)
    flags = fill(false, Nant, 2)
    AntennaFlags(flags)
end

==(lhs::AntennaFlags, rhs::AntennaFlags) = lhs.flags == rhs.flags

getindex(flags::AntennaFlags,I...) = flags.flags[I...]
setindex!(flags::AntennaFlags,x,I...) = flags.flags[I...] = x

function Base.show(io::IO, flags::AntennaFlags)
    print(io,"Flagged antennas: [")
    ants = UTF8String[]
    for ant = 1:size(flags.flags, 1), pol = 1:2
        flags[ant,pol] || continue
        xy = pol == 1? "x" : "y"
        push!(ants,"$ant$xy")
    end
    print(io,join(ants,", "))
    print(io,"]")
end

"""
    low_power_antennas(ms::CasaCore.Tables.Table, threshold)

Search for antennas that appear to have low power.

The criterion for an antenna to be flagged is
`power < threshold * median(power)`, where `power` is the
integrated power in the antenna's autocorrelation spectrum.
"""
function low_power_antennas(ms::Table, threshold)
    data  = autos(ms)
    power = squeeze(sum(data, 1), 1)
    flags = power .< threshold * median(power)
    AntennaFlags(flags)
end

"""
    applyflags!(ms::CasaCore.Tables.Table, flags::AntennaFlags)

Apply the antenna flags to the measurement set.

The flags are written to the "FLAG" column of the
measurement set.
"""
function applyflags!(ms::Table, flags::AntennaFlags)
    msflags = ms["FLAG"]
    ant1 = ms["ANTENNA1"] + 1
    ant2 = ms["ANTENNA2"] + 1
    @inbounds for α = 1:size(msflags, 3)
        if flags[ant1[α],1]
            # flag xx and xy
            msflags[1,:,α] = true
            msflags[2,:,α] = true
        end
        if flags[ant1[α],2]
            # flag yx and yy
            msflags[3,:,α] = true
            msflags[4,:,α] = true
        end
        if flags[ant2[α],1]
            # flag xx and yx
            msflags[1,:,α] = true
            msflags[3,:,α] = true
        end
        if flags[ant2[α],2]
            # flag xy and yy
            msflags[2,:,α] = true
            msflags[4,:,α] = true
        end
    end
    ms["FLAG"] = msflags
    msflags
end

