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

function run_clearflags(args)
    clearflags!(Table(args["--input"]))
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

@doc """
Clear all of the flags in the measurement set.
""" ->
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

function clearflags!(ms_list::Vector{Table})
    for ms in ms_list
        clearflags!(ms)
    end
end

flag!(ms::Table) = flag!([ms])

function flag!(ms_list::Vector{Table};
               bad_antennas::Vector{Int}=Int[],
               bad_channels::Vector{Int}=Int[])
    channel_flags = flag_channels(ms_list,bad_antennas)
    channel_flags[bad_channels] = true
    apply_flags!(ms_list,channel_flags,bad_antennas)
    find(channel_flags)
end

function flag_channels(ms_list::Vector{Table},bad_antennas=Int[])
    spec = getspec(ms_list,bad_antennas) # (this dominates the run time)
    x = linspace(0,1,length(spec))

    # Flag the really strong stuff first
    m0 = median(spec)
    m2 = median((spec-m0).^2)
    σ = sqrt(m2)
    flags = (spec-m0) .> 5σ

    # Now fit a splines
    k_schedule = [1,1,1,1,1,3,3,3,3,3]
    s_schedule = logspace(-1,-3,10)
    Niter = length(k_schedule)
    for i = 1:Niter
        k = k_schedule[i]
        s = s_schedule[i]
        spline = Spline1D(x[!flags],spec[!flags],k=k,s=s*sum(spec[!flags].^2))
        smoothed = evaluate(spline,x)

        m2 = median((spec-smoothed).^2)
        σ = sqrt(m2)
        flags = (spec-smoothed) .> 5σ
    end
    flags
end

function getspec(ms_list::Vector{Table},bad_antennas)
    Nms   = length(ms_list)
    Nbase = numrows(ms_list[1])
    Nant  = div(isqrt(1+8Nbase)-1,2)
    Nchan = length(Table(ms_list[1][kw"SPECTRAL_WINDOW"])["CHAN_FREQ"])

    spec = zeros(Float64,Nms*Nchan)
    for (β,ms) in enumerate(ms_list)
        ant1 = ms["ANTENNA1"] + 1
        ant2 = ms["ANTENNA2"] + 1
        data = abs(permutedims(ms["DATA"],(2,1,3)))
        for α = 1:Nbase
            (ant1[α] in bad_antennas || ant2[α] in bad_antennas) && continue
            spec[(β-1)*Nchan+1:β*Nchan] += sum(slice(data,:,:,α),2)
        end
    end
    spec
end

################################################################################
# Apply flags

function apply_flags!(ms::Table,channel_flags,bad_antennas)
    ant1 = ms["ANTENNA1"] + 1
    ant2 = ms["ANTENNA2"] + 1
    flags = ms["FLAG"]
    apply_antenna_flags!(flags,ant1,ant2,bad_antennas)
    apply_channel_flags!(flags,channel_flags)
    ms["FLAG"] = flags
end

function apply_flags!(ms_list::Vector{Table},channel_flags,bad_antennas)
    N = div(length(channel_flags),length(ms_list))
    for i = 1:length(ms_list)
        apply_flags!(ms_list[i],sub(channel_flags,(i-1)*N+1:i*N),bad_antennas)
    end
end

function apply_antenna_flags!(flags,ant1,ant2,bad_antennas)
    for α = 1:size(flags,3)
        if ant1[α] in bad_antennas || ant2[α] in bad_antennas
            flags[:,:,α] = true
        end
    end
end

function apply_channel_flags!(flags,channel_flags)
    for β = 1:size(flags,2)
        if channel_flags[β]
            flags[:,β,:] = true
        end
    end
end

end

