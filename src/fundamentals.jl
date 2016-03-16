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
    Nfreq(ms::CasaCore.Tables.Table)

Returns the number of frequency channels in the measurement set.
"""
function Nfreq(ms::Table)
    spw = Table(ms[kw"SPECTRAL_WINDOW"])
    ν = spw["CHAN_FREQ",1]
    unlock(spw)
    length(ν)
end

"""
    Nant(ms::CasaCore.Tables.Table)

Returns the number of antennas in the measurement set.
"""
function Nant(ms::Table)
    antenna = Table(ms[kw"ANTENNA"])
    N = Tables.numrows(antenna)
    unlock(antenna)
    Int(N)
end

"""
    Nbase(ms::CasaCore.Tables.Table)

Returns the number of baselines in the measurement set.
"""
function Nbase(ms::Table)
    Int(Tables.numrows(ms))
end

function autos(ms::Table)
    ant1 = ms["ANTENNA1"] + 1
    ant2 = ms["ANTENNA2"] + 1
    out = zeros(Nfreq(ms), Nant(ms), 2)
    for α = 1:Nbase(ms)
        ant1[α] == ant2[α] || continue
        data = ms["DATA",α]
        for β = 1:size(out, 1)
            out[β,ant1[α],1] = real(data[1,β]) # xx
            out[β,ant1[α],2] = real(data[4,β]) # yy
        end
    end
    out
end

function autoflags(ms::Table)
    ant1 = ms["ANTENNA1"] + 1
    ant2 = ms["ANTENNA2"] + 1
    out = fill(false, Nfreq(ms), Nant(ms), 2)
    for α = 1:Nbase(ms)
        ant1[α] == ant2[α] || continue
        rowflag = ms["FLAG_ROW",α]
        if rowflag
            out[:,ant1[α],:] = true
            continue
        end
        flags = ms["FLAG",α]
        for β = 1:size(out, 1)
            out[β,ms.ant1[α],1] = flags[1,β] # xx
            out[β,ms.ant1[α],2] = flags[4,β] # yy
        end
    end
    out
end

