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

using CasaCore.Tables

@doc """
Clear all of the flags in the measurement set.
""" ->
function clear!(ms::Table)
    N = numrows(ms)
    Nfreq = length(freq(ms))
    flags = zeros(Bool,4,Nfreq,N)
    ms["FLAG"] = flags
    flags
end

@doc """
Derive and apply antenna flags to the measurement set.
""" ->
function antennas(ms::Table)
    autos = getautos(ms)

    # Flag the antennas with too much power
    xx_power = log10(abs(squeeze(median(squeeze(autos[1,:,:],1),1),1)))
    xy_power = log10(abs(squeeze(median(squeeze(autos[2,:,:],1),1),1)))
    yy_power = log10(abs(squeeze(median(squeeze(autos[4,:,:],1),1),1)))

    xx_flags = flag(xx_power,Niter=2)
    xy_flags = flag(xy_power,Niter=2)
    yy_flags = flag(yy_power,Niter=2)

    # Flag the antenna if appears in at least 2 of 3 cases
    votes = xx_flags + xy_flags + yy_flags
    flagged = votes .>= 2

    # Apply the flags to the measurement set
    ant1 = ms["ANTENNA1"] + 1
    ant2 = ms["ANTENNA2"] + 1
    flags = ms["FLAG"]
    for α = 1:N
        if flagged[ant1[α]] || flagged[ant2[α]]
            flags[:,:,α] = true
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

