#!/usr/bin/env julia

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

using CLI

CLI.set_name("mlpflagger.jl")
CLI.set_banner("""
     MLPFlagger
    ============
    A flagging routine developed for the OVRO LWA.
    Written by Michael Eastwood (mweastwood@astro.caltech.edu).
    """)

CLI.print_banner()

push!(CLI.commands,Command("clearflags","Clear all flags from the given measurement set."))
push!(CLI.commands,Command("flag","Flag bad antennas and channels with anomalous autocorrelation power."))

CLI.options["clearflags"] = [
    Option("--input","""
        A list of measurement sets that will have their flags cleared.""",
        T=UTF8String,
        required=true,
        min=1,
        max=Inf)]
CLI.options["flag"] = [
    Option("--input","""
        A list of measurement sets to flag. The measurement sets should represent
        different spectral windows from the same time integration.""",
        T=UTF8String,
        required=true,
        min=1,
        max=Inf),
    Option("--antennas","""
        A list of bad antennas that should be flagged. Antennas are numbered
        starting from 1.""",
        T=Int,
        min=1,
        max=Inf),
    Option("--output","""
        A JSON file that will be written to with a record of the antenna and channel
        flags applied to this list of measurement sets. This allows these flags
        to easily be applied elsewhere.""",
        T=UTF8String,
        min=1,
        max=1),
    Option("--oldflags","""
        This is the name of a file previously written to with the --output option.
        The antenna and channel flags contained within this file will be applied
        to the current list of measurement sets.""",
        T=UTF8String,
        min=1,
        max=1)]

import MLPFlagger

# Catch exceptions to hide the verbose Julia output that is
# not especially helpful to users.
try
    command,args = CLI.parse_args(ARGS)
    if     command == "clearflags"
        MLPFlagger.run_clearflags(args)
    elseif command == "flag"
        MLPFlagger.run_flag(args)
    end
catch err
    if isa(err, ErrorException)
        println(err.msg)
    else
        throw(err)
    end
end

