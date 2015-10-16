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
    clearflags!(ms::Table)

Clear all of the flags in the measurement set.
"""
function clearflags!(ms::Table)
    N = numrows(ms)
    spw = Table(ms[kw"SPECTRAL_WINDOW"])
    freq  = spw["CHAN_FREQ",1]
    Nfreq = length(freq)
    flags = zeros(Bool,4,Nfreq,N)
    row_flags = zeros(Bool,N)
    ms["FLAG"] = flags
    ms["FLAG_ROW"] = row_flags
    flags
end

"""
    clearflags!(mslist::Vector{Table})

Clear all of the flags in the list of measurement sets.
"""
function clearflags!(mslist::Vector{Table})
    for ms in mslist
        clearflags!(ms)
    end
end

