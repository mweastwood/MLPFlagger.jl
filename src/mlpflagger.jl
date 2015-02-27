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

CLI.set_name("ttcal.jl")
CLI.set_banner("""
     MLPFlagger
    ============
    A flagging routine developed for the OVRO LWA.
    Written by Michael Eastwood (mweastwood@astro.caltech.edu).
    """)

CLI.print_banner()

push!(CLI.commands,Command("clear","Clear all flags from the given measurement set."))
push!(CLI.commands,Command("flag","Flag antennas and channels with anomalous autocorrelation power."))

CLI.options["clear"] = [
    Option("--input","""
        The measurement set that will have its flags cleared.""",
        UTF8String,true,1,1)]
CLI.options["flagantennas"] = [
    Option("--input","""
        The measurement set that will be flagged.""",
        UTF8String,true,1,1)]

import MLPFlagger

# Catch exceptions to hide the verbose Julia output that is
# not especially helpful to users.
try
    command,args = CLI.parse_args(ARGS)
    if     command == "clear"
        MLPFlagger.run_clear(args)
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

