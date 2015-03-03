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

module MLPFlagger

export clearflags!, flag!

using CasaCore.Tables

function run_clearflags(args)
    clearflags!(Table(args["--input"]))
    nothing
end

function run_flag(args)
    flag!(Table(args["--input"]))
    nothing
end

@doc """
Clear all of the flags in the measurement set.
""" ->
function clearflags!(ms::Table)
    N = numrows(ms)
    spw = Table(ms[kw"SPECTRAL_WINDOW"])
    freq  = spw["CHAN_FREQ",1]
    Nfreq = length(freq)
    flags = zeros(Bool,4,Nfreq,N)
    ms["FLAG"] = flags
    flags
end

function flag!(ms::Table)
    autos = getautos(ms)
    antenna_flags = flag_antennas(autos)
    channel_flags = flag_channels(autos,antenna_flags)
    apply_antenna_flags!(ms,antenna_flags)
    apply_channel_flags!(ms,channel_flags)
    nothing
end

@doc """
Derive a list of antennas to flag.
""" ->
function flag_antennas(autos)
    # Flag the antennas with too much power
    xx_power = log10(abs(squeeze(median(squeeze(autos[1,:,:],1),1),1)))
    xy_power = log10(abs(squeeze(median(squeeze(autos[2,:,:],1),1),1)))
    yy_power = log10(abs(squeeze(median(squeeze(autos[4,:,:],1),1),1)))

    xx_flags = flag(xx_power,Niter=2)
    xy_flags = flag(xy_power,Niter=2)
    yy_flags = flag(yy_power,Niter=2)

    # Flag the antenna if it appears in at least 2 of 3 cases
    votes = xx_flags + xy_flags + yy_flags
    flags = votes .>= 2
    flags
end

function apply_antenna_flags!(ms::Table,antenna_flags)
    N = numrows(ms)
    ant1 = ms["ANTENNA1"] + 1
    ant2 = ms["ANTENNA2"] + 1
    flags = ms["FLAG"]
    for α = 1:N
        if antenna_flags[ant1[α]] || antenna_flags[ant2[α]]
            flags[:,:,α] = true
        end
    end
    ms["FLAG"] = flags
    flags
end

function flag_channels(autos,antenna_flags)
    Nfreq = size(autos,2)
    Nant  = size(autos,3)
    votes = zeros(Int,Nfreq)
    for ant = 1:Nant
        antenna_flags[ant] && continue

        xx_spectrum = abs(squeeze(autos[1,:,ant],1))
        xy_spectrum = abs(squeeze(autos[2,:,ant],1))
        yy_spectrum = abs(squeeze(autos[4,:,ant],1))

        xx_flags = flag(xx_spectrum,Niter=2)
        xy_flags = flag(xy_spectrum,Niter=2)
        yy_flags = flag(yy_spectrum,Niter=2)

        votes += xx_flags + xy_flags + yy_flags
    end
    
    # Flag the antenna if it receives at least 10 votes
    flags = votes .>= 10
    flags
end

function apply_channel_flags!(ms::Table,channel_flags)
    N = length(channel_flags)
    flags = ms["FLAG"]
    for β = 1:N
        if channel_flags[β]
            flags[:,β,:] = true
        end
    end
    ms["FLAG"] = flags
    flags
end

function getautos(ms)
    ant1 = ms["ANTENNA1"] + 1
    ant2 = ms["ANTENNA2"] + 1
    data = ms["DATA"]

    Nant  = length(unique(ant1))
    Nfreq = size(data,2)
    Nbase = size(data,3)

    autos = zeros(4,Nfreq,Nant)
    count = 1
    for α = 1:Nbase
        if ant1[α] == ant2[α]
            autos[:,:,count] = real(data[:,:,α])
            count += 1
        end
    end
    autos
end

function flag(vector;Niter::Int=1)
    flags = zeros(Bool,length(vector))
    for i = 1:Niter
        flag!(flags,vector)
    end
    flags
end

function flag!(flags,vector)
    m0 = median(vector[!flags])
    m2 = median((vector[!flags]-m0).^2)
    stddev   = sqrt(m2)
    flags[:] = abs(vector-m0) .> 5stddev
    flags
end

end

