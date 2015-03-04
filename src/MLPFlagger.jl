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

flag!(ms::Table) = flag!([ms])

function flag!(ms_list::Vector{Table})
    corrs = getcorrs(ms_list)
    antenna_flags = flag_antennas(corrs)
    channel_flags = flag_channels(autos,antenna_flags)
    apply_antenna_flags!(ms,antenna_flags)
    apply_channel_flags!(ms,channel_flags)
    nothing
end

@doc """
Derive a list of antennas to flag.
""" ->
function flag_antennas(corrs)
    reduction = squeeze(median(abs2(corrs),(1,2)),(1,2))
    λ,g = eigs(reduction,nev=1,which=:LM,ritzvec=true)
    antenna_amplitude = sqrt(λ[1])*abs(g)
    m0 = median(antenna_amplitude)
    m2 = median((antenna_amplitude-m0).^2)
    σ = sqrt(m2)
    flags = squeeze(abs(antenna_amplitude-m0) .> 4σ,2)

    figure(1); clf()
    plot(antenna_amplitude,"ko")
    axhline(m0,color="r")
    axhline(m0+σ,color="r",linestyle="--")
    axhline(m0-σ,color="r",linestyle="--")

    flags
end

function flag_channels(corrs,antenna_flags)
    af = !antenna_flags
    chans = convert(Vector{Float64},squeeze(median(abs(corrs[:,:,af,af]),(1,3,4)),(1,3,4)))
    x = linspace(0,1,length(chans))

    # Flag the really strong stuff first
    m0 = median(chans)
    m2 = median((chans-m0).^2)
    σ = sqrt(m2)
    flags = (chans-m0) .> 5σ

    # Now fit a splines
    k_schedule = [1,1,1,1,1,3,3,3,3,3]
    s_schedule = logspace(-1,-3,10)
    Niter = length(k_schedule)
    for i = 1:Niter
        k = k_schedule[i]
        s = s_schedule[i]
        spline = Spline1D(x[!flags],chans[!flags],k=k,s=s*sum(chans[!flags].^2))
        smoothed = evaluate(spline,x)

        m2 = median((chans-smoothed).^2)
        σ = sqrt(m2)
        flags = (chans-smoothed) .> 5σ
    end
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

function getcorrs(ms_list::Vector{Table})
    Nms   = length(ms_list)
    Nbase = numrows(ms_list[1])
    Nant  = div(isqrt(1+8Nbase)-1,2)
    Nchan = length(Table(ms_list[1][kw"SPECTRAL_WINDOW"])["CHAN_FREQ"])

    corrs = zeros(Complex64,4,Nms*Nchan,Nant,Nant)
    for (β,ms) in enumerate(ms_list)
        ant1 = ms["ANTENNA1"] + 1
        ant2 = ms["ANTENNA2"] + 1
        data = ms["DATA"]

        for α = 1:Nbase
            abs(ant1[α] - ant2[α]) ≤ 0 && continue
            corrs[:,(β-1)*Nchan+1:β*Nchan,ant1[α],ant2[α]] = data[:,:,α]
            corrs[:,(β-1)*Nchan+1:β*Nchan,ant2[α],ant1[α]] = conj(data[:,:,α])
        end
    end
    corrs
end

end

