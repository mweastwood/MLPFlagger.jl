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

"""
    ChannelFlags

A container that holds a list of frequency channel flags.
Each antenna receives its own set of associated flags.

    ChannelFlags(Nfreq, Nant)

Create an empty set of channel flags for `Nfreq` frequency channels
and `Nant` antennas.
"""
immutable ChannelFlags
    flags::Array{Bool,3}
    function ChannelFlags(flags)
        size(flags, 3) == 2 || error("third dimension must correspond to 2 polarizations")
        new(flags)
    end
end

function ChannelFlags(Nfreq::Int, Nant::Int)
    flags = fill(false, Nfreq, Nant , 2)
    ChannelFlags(flags)
end

==(lhs::ChannelFlags, rhs::ChannelFlags) = lhs.flags == rhs.flags

getindex(flags::ChannelFlags, I...) = flags.flags[I...]
setindex!(flags::ChannelFlags, x, I...) = flags.flags[I...] = x

function Base.show(io::IO, flags::ChannelFlags)
    fraction_flagged = sum(flags.flags, (2, 3)) / (size(flags.flags, 2) * size(flags.flags, 3))
    channels = find(fraction_flagged .≥ 0.25)
    print(io, "Flagged channels: [")
    for β = 1:length(channels)
        color = :white
        fraction_flagged[channels[β]]  ≥ 0.5 && (color = :red)
        fraction_flagged[channels[β]] == 1.0 && (color = :blue)
        print_with_color(color, io, string(channels[β]))
        β == length(channels) || print(io, ", ")
    end
    print(io, "]\n")
    print(io, "          Legend: ")
    print_with_color(:white, io, ">25% flagged"); print(io, ", ")
    print_with_color(  :red, io, ">50% flagged"); print(io, ", ")
    print_with_color( :blue, io, "100% flagged"); print(io, "\n")
end

"""
    bright_narrow_rfi(ms::CasaCore.Tables.Table)

Find RFI that is narrowband and very bright.
This is the kind of RFI that is likely to make a frequency channel
completely useless.

The criterion for a channel to be flagged is
`power > threshold * mad(power)`, where `power` is the power in
a sincle frequency channel and `mad` is the mean absolute deviation.
"""
function bright_narrow_rfi(ms, threshold)
    data  = autos(ms)
    flags = ChannelFlags(Nfreq(ms), Nant(ms))
    for ant = 1:Nant(ms), pol = 1:2
        flags[:, ant, pol] = bright_narrow_rfi_one_antenna(slice(data, :, ant, pol), threshold)
    end
    println(flags)
    flags
end

function bright_narrow_rfi_one_antenna(data, threshold)
    Nfreq = length(data)
    ν = collect(1:Nfreq)
    flags = fill(false, Nfreq)
    # The width parameter here defines the spacing of the knots in the smoothing
    # spline. If the knots are more finely spaced the smoothing spline will trace
    # the data more closely but it will not smooth out the RFI. Therefore we
    # define a schedule where the knots are spaced further and further apart to
    # make sure we capture as much RFI as possible. On the final iteration we
    # use a very fine spacing to help avoid errors where legitimate parts of the
    # band are flagged just because the smoothing spline does not model that part
    # of the band very well.
    for width in (2, 4, 8, 16, 32, 2)
        spline = Spline1D(ν[!flags], data[!flags], ν[!flags][2:width:end-1], k=1)
        model  = spline(ν) |> abs
        # In comparing the difference of the data to the model, we normalize by the
        # square root of the model to flatten the noise characteristics as a function
        # of frequency.
        δ = (data - model) ./ sqrt(model)
        # Calculate the mean absolute deviation of the data from the model. Note that
        # this is less sensitive to outliers (ie. RFI) than the standard deviation.
        # Hence we prefer the mean absolute deviation to the standard devation here.
        mad = mean(abs(δ[!flags]))
        # Now we flag all the data that falls above the threshold. Note that we don't
        # flag data that deviates from the model in the negative direction because RFI
        # should be a positive deviation. We also update all of the flags at each
        # iteration because the model should improve on each iteration and we may have
        # made a mistake on a previous iteration.
        flags = δ .> threshold * mad
    end
    flags
end

"""
    applyflags!(ms::CasaCore.Tables.Table, flags::ChannelFlags)

Apply the channel flags to the measurement set.

The flags are written to the "FLAG" column of the
measurement set.
"""
function applyflags!(ms::Table, flags::ChannelFlags)
    msflags = ms["FLAG"]
    ant1 = ms["ANTENNA1"] + 1
    ant2 = ms["ANTENNA2"] + 1
    @inbounds for α = 1:size(msflags, 3), β = 1:size(msflags, 2)
        if flags[β,ant1[α],1]
            # flag xx and xy
            msflags[1,β,α] = true
            msflags[2,β,α] = true
        end
        if flags[β,ant1[α],2]
            # flag yx and yy
            msflags[3,β,α] = true
            msflags[4,β,α] = true
        end
        if flags[β,ant2[α],1]
            # flag xx and yx
            msflags[1,β,α] = true
            msflags[3,β,α] = true
        end
        if flags[β,ant2[α],2]
            # flag xy and yy
            msflags[2,β,α] = true
            msflags[4,β,α] = true
        end
    end
    ms["FLAG"] = msflags
    msflags
end

