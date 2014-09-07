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

define clean-report_ANALYSIS_rules # ANALYSIS 

################################################################################
# Rules to generate per-analysis cleaning reports
################################################################################
$(1).cleaning-report.txt: $$(foreach result,$$($(1)_INPUT),$$(word 1,$$(subst .cleaned., ,$$(result))).cleaned.report.txt)
	(head -n 1 $$(word 1,$$+) && tail -q -n +2 $$+) > $$@

$(1).cleaning-warnings.txt: $$(foreach result,$$($(1)_INPUT),$$(word 1,$$(subst .cleaned., ,$$(result))).cleaned.warnings.txt.gz)
	((zcat $$(word 1,$$+) | head -n 1)  $$(foreach file,$$+, && (zcat $$(file) | tail -q -n +2)) ) > $$@

$(1).cleaning-excluded.txt: $$(foreach result,$$($(1)_INPUT),$$(word 1,$$(subst .cleaned., ,$$(result))).cleaned.excluded.txt.gz)
	((zcat $$(word 1,$$+) | head -n 1)  $$(foreach file,$$+, && (zcat $$(file) | tail -q -n +2)) ) > $$@

endef # clean-report_ANALYSIS_rules


################################################################################
# Evaluate above rules for each analysis
################################################################################
$(foreach analysis,$(ANALYSES),$(eval $(call clean-report_ANALYSIS_rules,$(analysis))))
