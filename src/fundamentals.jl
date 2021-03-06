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

function smooth_1d(signal,flags,width = 11)
    isodd(width) || error("width must be odd")
    chop = div(width-1,2)

    σ = width/3
    x = linspace(-width/2,width/2,width)
    kernel = zeros(length(x))
    for i in eachindex(x,kernel)
        kernel[i] = exp(-x[i]^2/σ^2) * (width/2-x[i]) * (x[i]+width/2)
    end

    window = !flags
    convolved = conv(window.*signal,kernel)
    convolved = convolved[1+chop:end-chop]
    normalization = conv(window,kernel)
    normalization = normalization[1+chop:end-chop]
    convolved = convolved ./ normalization
    convolved
end

function flag_1d!(signal,flags,sigmas = 20)
    x = signal[!flags]
    μ = median(x)
    σ = max(abs2(x-μ) |> median |> sqrt,1e-5)
    threshold = μ+sigmas*σ
    idx = signal .> threshold
    flags[idx] = true
end

function autos(ms::MeasurementSet)
    out = zeros(ms.Nfreq,ms.Nant,2)
    for α = 1:ms.Nbase
        ms.ant1[α] == ms.ant2[α] || continue
        data = ms.table["DATA",α]
        for β = 1:ms.Nfreq
            out[β,ms.ant1[α],1] = real(data[1,β]) # xx
            out[β,ms.ant1[α],2] = real(data[4,β]) # yy
        end
    end
    out
end

function autoflags(ms::MeasurementSet)
    out = zeros(Bool,ms.Nfreq,ms.Nant,2)
    for α = 1:ms.Nbase
        ms.ant1[α] == ms.ant2[α] || continue
        rowflag = ms.table["FLAG_ROW",α]
        if rowflag
            out[:,ms.ant1[α],:] = true
            continue
        end
        flags = ms.table["FLAG",α]
        for β = 1:ms.Nfreq
            out[β,ms.ant1[α],1] = flags[1,β] # xx
            out[β,ms.ant1[α],2] = flags[4,β] # yy
        end
    end
    out
end

