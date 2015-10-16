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
    immutable ChannelFlags

A container that holds a length $N$ vector of flags where
$N$ is the number of frequency channels.
"""
immutable ChannelFlags
    flags::Vector{Bool}
end

Base.getindex(flags::ChannelFlags,I...) = flags.flags[I...]
Base.setindex!(flags::ChannelFlags,x,I...) = flags.flags[I...] = x

function Base.show(io::IO,flags::ChannelFlags)
    print(io,"Flagged channels: [")
    channels = UTF8String[]
    for β = 1:length(flags.flags)
        flags[β] || continue
        push!(channels,string(β))
    end
    print(io,join(channels,", "))
    print(io,"]")
end

"""
    bright_narrow_rfi(ms)

Find RFI that is narrowband and very bright.
This is the kind of RFI that is likely to make a frequency channel
completely useless.
"""
function bright_narrow_rfi(ms)
    data  = MLPFlagger.autos(ms)
    flags = MLPFlagger.autoflags(ms)
    Nfreq = size(data,1)
    Nant  = size(data,2)

    # Compute an array averaged sky spectrum after doing
    # a very rough gain calibration
    count = zeros(Int,Nfreq)
    spectrum = zeros(Nfreq)
    for pol = 1:2, ant = 1:Nant
        f = slice(flags,:,ant,pol) # flags
        g = all(f)? 0.0 : median(data[!f,ant,pol]) # rough gain
        for β = 1:Nfreq
            f[β] && continue
            count[β] += 1
            spectrum[β] += data[β,ant,pol] / g
        end
    end
    spectrum = spectrum ./ count

    # Find the outliers on the combined spectrum
    channel_flags = zeros(Bool,Nfreq)
    schedule = [11,21,31] # steadily increase the smoothing length
    for i = 1:length(schedule)
        smoothed = MLPFlagger.smooth_1d(spectrum,channel_flags,schedule[i])
        MLPFlagger.flag_1d!(spectrum-smoothed,channel_flags,5)
    end
    ChannelFlags(channel_flags)
end

doc"""
    applyflags!(ms::MeasurementSet, flags::ChannelFlags)

Apply the channel flags to the measurement set.

The flags are written to the "FLAG" column of the
measurement set.
"""
function applyflags!(ms::MeasurementSet,flags::ChannelFlags)
    msflags = ms.table["FLAG"]
    for β = 1:ms.Nfreq
        flags[β] || continue
        msflags[:,β,:] = true
    end
    ms.table["FLAG"] = msflags
    msflags
end

