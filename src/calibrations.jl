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

doc"""
    immutable GainCalibrationFlags

A container that holds a $N_{\rm ant} \times N_{\rm freq} \times 2$
array of flags where $N_{\rm ant}$ is the number of antennas, and
$N_{\rm freq}$ is the number of frequency channels. The third
dimension corresponds to the $x$ and $y$ polarizations.
"""
immutable GainCalibrationFlags
    flags::Array{Bool,3}
end

Base.getindex(flags::GainCalibrationFlags,I...) = flags.flags[I...]
Base.setindex!(flags::GainCalibrationFlags,x,I...) = flags.flags[I...] = x

"""
    nonlinear_phase(cal::GainCalibration)

Look for gain solutions where the phase does not
vary linearly with frequency.
"""
function nonlinear_phase(cal::GainCalibration)
    flags = copy(cal.flags)
    linear_fit_matrix = [1:TTCal.Nfreq(cal) ones(TTCal.Nfreq(cal))]
    for pol = 1:2, ant = 1:TTCal.Nant(cal)
        f = slice(    flags,ant,:,pol)
        g = slice(cal.gains,ant,:,pol)
        ϕ = angle(g)
        unwrap!(ϕ,f)
        schedule = [6,5,4]
        for i = 1:length(schedule)
            param = linear_fit_matrix[!f,:]\ϕ[!f]
            fit   = linear_fit_matrix*param
            flag_1d!(abs(ϕ-fit),f,schedule[i])
        end
    end
    flags
end

doc"""
    unwrap!(phase,flags)

Attempt to unwrap the phase.

Add and subtract multiples of $2\pi$ to remove
discontinuities.
"""
function unwrap!(phase,flags)
    N = length(phase)
    for i = 2:N
        flags[i] && continue
        j = previous(i,flags)
        j == 0 && continue
        if phase[i] - phase[j] < -π/2
            for k = i:N
                phase[k] += 2π
            end
        elseif phase[i] - phase[j] > π/2
            for k = i:N
                phase[k] -= 2π
            end
        end
    end
    phase
end

"""
    previous(index,flags)

Return the index of the nearest unflagged
entry prior to `index`. Returns 0 if there
are no unflagged entries.
"""
function previous(index,flags)
    out = index - 1
    while out > 0 && flags[out]
        out -= 1
    end
    out
end

doc"""
    applyflags!(cal::GainCalibration, flags::GainCalibrationFlags)

Apply the set of flags to the gain calibration.
"""
function applyflags!(cal::GainCalibration,flags::GainCalibrationFlags)
    for pol = 1:2, β = 1:TTCal.Nfreq(cal), ant = 1:TTCal.Nant(cal)
        if flags[ant,β,pol]
            cal.flags[ant,β,pol] = true
        end
    end
    GainCalibrationFlags(cal.flags)
end

