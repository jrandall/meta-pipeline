#######################################################################################
# Copyright 2008, 2009 Joshua Randall
#
# Joshua Randall <jcrandall@alum.mit.edu>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#######################################################################################

################################################################################
# Automatically generate makefile from internal variables.
# This makefile will set variables like:
# $(paramdefs_sort_header_values), $(paramdefs_top_header_values), and $(paramdefs_top_numtop_values)
# as well as
# $(paramdefs_special_sort_base_values) 
################################################################################
.SILENT: generated-paramdefs.stamp generated-paramdefs.mk
generated-paramdefs.stamp: 
	touch $@
generated-paramdefs.mk: generated-paramdefs.stamp
	$(GENERATE_PARAMDEFS_MAKEFILE_SCRIPT) --varprefix="paramdefs_" --varsuffix="_values" --cmdgoals="$(MAKECMDGOALS)" --mappings="$(PARAMDEF_MAPPINGS)" --params="$(PARAMDEFS)" --out="$@" 

include generated-paramdefs.mk 

