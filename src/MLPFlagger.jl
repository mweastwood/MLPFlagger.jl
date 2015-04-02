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
using Dierckx
using JSON

include("clearflags.jl")
include("flag.jl")

function run_clearflags(args)
    for file in args["--input"]
        clearflags!(Table(ascii(file)))
    end
    nothing
end

function run_flag(args)
    ms_list = [Table(ascii(file)) for file in args["--input"]]
    bad_antennas = Int[]
    bad_channels = Int[]
    if haskey(args,"--antennas")
        bad_antennas = args["--antennas"]
    end
    if haskey(args,"--oldflags")
        # Add the bad antennas to the list
        dict = JSON.parsefile(args["--oldflags"])
        old_bad_antennas = Vector{Int}(dict["bad_antennas"])
        bad_antennas = unique([bad_antennas;old_bad_antennas])
        old_bad_channels = Vector{Int}(dict["bad_channels"])
        bad_channels = unique([bad_channels;old_bad_channels])
    end
    bad_channels = flag!(ms_list,bad_antennas=bad_antennas,bad_channels=bad_channels)
    if haskey(args,"--output")
        output = Dict("bad_antennas" => bad_antennas,
                      "bad_channels" => bad_channels)
        open(args["--output"],"w") do file
            JSON.print(file,output)
        end
    end
    nothing
end

end

