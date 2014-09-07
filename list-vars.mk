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
# Targets to list the value of variables
################################################################################
.PHONY: list-vpath
list-vpath:
	$(info VPATH is:)$(foreach dir,$(VPATH),$(info $(dir)))

.PHONY: list-analyses
list-analyses:
	$(info Analyses available are:)$(foreach analysis,$(ANALYSES),$(info $(analysis)))

.PHONY: list-cohorts
list-cohorts:
	$(info Cohorts available are:)$(foreach cohort,$(COHORTS),$(info $(cohort)))


define phony-targets_list-ANALYSIS-cohorts # ANALYSIS
.PHONY: list-$(1)-cohorts
list-$(1)-cohorts:
	$$(info Cohorts available in $(1) are:)$$(foreach cohort,$$($(1)_COHORTS),$$(info $$(cohort)))
endef
$(foreach analysis,$(ANALYSES),$(eval $(call phony-targets_list-ANALYSIS-cohorts,$(analysis))))

define phony-targets_list-COHORT-analyses # COHORT
.PHONY: list-$(1)-analyses
list-$(1)-analyses:
	$$(info $(1) available for analysis of:)$$(foreach analysis,$$($(1)_ANALYSES),$$(info $$(analysis)))
endef
$(foreach cohort,$(COHORTS),$(eval $(call phony-targets_list-COHORT-analyses,$(cohort))))
