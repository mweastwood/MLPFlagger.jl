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
    immutable AntennaFlags

A container that holds a $N \times 2$ array of flags where $N$ is the
number of antennas. Each row of the array gives the flags for the
$x$ and $y$ polarizations respectively.
"""
immutable AntennaFlags
    flags::Matrix{Bool}
    function AntennaFlags(flags)
        size(flags,2) == 2 || error("second dimension must correspond to 2 polarizations")
        new(flags)
    end
end

"""
    AntennaFlags(Nant::Int)

Create an empty set of antenna flags for `Nant` antennas.
"""
function AntennaFlags(Nant::Int)
    flags = zeros(Bool,Nant,2)
    AntennaFlags(flags)
end

Base.getindex(flags::AntennaFlags,I...) = flags.flags[I...]
Base.setindex!(flags::AntennaFlags,x,I...) = flags.flags[I...] = x

function Base.show(io::IO,flags::AntennaFlags)
    print(io,"Flagged antennas: [")
    ants = UTF8String[]
    for ant = 1:size(flags.flags,1), pol = 1:2
        flags[ant,pol] || continue
        xy = pol == 1? "x" : "y"
        push!(ants,"$ant$xy")
    end
    print(io,join(ants,", "))
    print(io,"]")
end

"""
    low_power_antennas(ms::MeasurementSet)

Search for antennas that appear to have very low power.
"""
function low_power_antennas(ms::MeasurementSet)
    data  = autos(ms)
    power = median(data,1) |> log10
    power = squeeze(power,1)
    flags = zeros(Bool,size(power))
    flag_1d!(-power,flags,20)
    AntennaFlags(flags)
end

doc"""
    applyflags!(ms::MeasurementSet, flags::AntennaFlags)

Apply the flags to the measurement set.

The flags are written to the "FLAG" column of the
measurement set.
"""
function applyflags!(ms::MeasurementSet,flags::AntennaFlags)
    msflags = ms.table["FLAG"]
    for α = 1:ms.Nbase
        if flags[ms.ant1[α],1]
            # flag xx and xy
            msflags[1,:,α] = true
            msflags[2,:,α] = true
        end
        if flags[ms.ant1[α],2]
            # flag yx and yy
            msflags[3,:,α] = true
            msflags[4,:,α] = true
        end
        if flags[ms.ant2[α],1]
            # flag xx and yx
            msflags[1,:,α] = true
            msflags[3,:,α] = true
        end
        if flags[ms.ant2[α],2]
            # flag xy and yy
            msflags[2,:,α] = true
            msflags[4,:,α] = true
        end
    end
    ms.table["FLAG"] = msflags
    msflags
end

