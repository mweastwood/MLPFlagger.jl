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
    clearflags!(ms::MeasurementSet)

Clear all of the flags in the measurement set.
"""
function clearflags!(ms::MeasurementSet)
    flags = zeros(Bool,4,ms.Nfreq,ms.Nbase)
    row_flags = zeros(Bool,ms.Nbase)
    ms.table["FLAG"] = flags
    ms.table["FLAG_ROW"] = row_flags
    flags
end

"""
    clearflags!(mslist::Vector{MeasurementSet})

Clear all of the flags in the list of measurement sets.
"""
function clearflags!(mslist::Vector{MeasurementSet})
    for ms in mslist
        clearflags!(ms)
    end
end

