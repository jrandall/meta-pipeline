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

#######################################################################################
# Generated Variables based on files listed in .analysisfiles.list for each analysis
#######################################################################################
%-vars.mk: %.analysisfiles.list
	(echo "$*_INPUT=\\" && (cat $< | perl -pi -e 's/\n/\\\n/g')) > $@

$(foreach analysis,$(ANALYSES),$(eval include $(analysis)-vars.mk))

define ANALYSISINPUT_lists # analysis
#$(1)_COHORTS = $$(patsubst %.$(1),%,$$($(1)_INPUT))
$(1)_COHORTS = $$(foreach infile,$$($(1)_INPUT),$$(word 1,$$(subst ., ,$$(infile))))
$$(foreach cohort,$$($(1)_COHORTS),$$(eval $$(cohort)_ANALYSES += $(1)))
endef
$(foreach analysis,$(ANALYSES),$(eval $(call ANALYSISINPUT_lists,$(analysis))))

COHORTS = $(sort $(foreach analysis,$(ANALYSES),$($(analysis)_COHORTS)))

define COHORTINPUT_lists # cohort
$(1)_INPUT = $$(foreach analysis,$$($(1)_ANALYSES),$(1).$$(analysis))
endef
$(foreach cohort,$(COHORTS),$(eval $(call COHORTINPUT_lists,$(cohort))))

INPUTS = $(foreach analysis,$(ANALYSES),$($(analysis)_INPUT))


MENWOMENANALYSES = $(filter MEN% WOMEN%,$(ANALYSES))
MENWOMENANALYSES_SUFFIXES = $(sort $(patsubst WOMEN%,%,$(patsubst MEN%,%,$(MENWOMENANALYSES))))


