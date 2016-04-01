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

__precompile__()

module MLPFlagger

export applyflags!, clearflags!

export AntennaFlags
export flag_antennas!, low_power_antennas

export ChannelFlags
export bright_narrow_rfi

importall Base.Operators
using CasaCore.Tables
using Dierckx

include("fundamentals.jl")
include("clearflags.jl")
include("antennas.jl")
include("channels.jl")

end

