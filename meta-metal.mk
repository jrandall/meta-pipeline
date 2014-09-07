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

# TODO change this to be auto-detected from the requested targets
FILTERSETS = _MAC_gte_10 _MAC_gte_3 _MAC_gt_3

define meta_metal_ANALYSIS_SCHEME_FILTERSET_rules # ANALYSIS SCHEME FILTERSET

################################################################################
# Rules to make scripts for meta-analyses
################################################################################
$(1).metal-$(2)$(3).script: $(MAKE_METAL_SCRIPT) $(1).analysisfiles.list $(foreach result,$($(1)_INPUT),$(result))
	$$(word 1,$$+) --scheme="$(2)" $$(if $(3),$$(foreach filter,$$(subst _and_, ,$(3)), --filter "$$(subst _, ,$$(filter))")) --out="$(1)" --outsuffix=".metal-$(2)$(3).out" $$(foreach infile,$$(wordlist 3,$$(words $$+),$$+), --in $$(infile)) > $$@

################################################################################
# Rules to perform meta-analyses
################################################################################
$(1).metal-$(2)$(3).out: $(METAL_BIN) $(1).metal-$(2)$(3).script $(foreach result,$($(1)_INPUT),$(result)) 
	(($$(word 1,$$+) < $$(word 2,$$+)) >& $(1).metal-$(2)$(3).out.log) && \
	mv $(1)1.metal-$(2)$(3).out $(1).metal-$(2)$(3).out && \
	mv $(1)1.metal-$(2)$(3).out.info $(1).metal-$(2)$(3).out.info

################################################################################
# Rules to make scripts for post-meta-analysis GC-correction
################################################################################
$(1).metal-$(2)$(3)-gcc.script: $(MAKE_METAL_SCRIPT) $(1).metal-$(2)$(3).out
	$$(word 1,$$+) --scheme="$(2)" --out="$(1)" --outsuffix=".metal-$(2)$(3)-gcc.out" --in $$(word 2,$$+) --markerlabel=MarkerName --ealabel=Allele1 --oalabel=Allele2 --effectlabel=$$(if $$(subst se,,$(2)),Zscore,Effect) --weightlabel=$$(if $$(subst se,,$(2)),Weight,N) --pvaluelabel=P-value --stderrlabel=StdErr --freqlabel=Freq1 > $$@

################################################################################
# Rules to perform post-meta-analysis GC-correction
################################################################################
$(1).metal-$(2)$(3)-gcc.out: $(1).metal-$(2)$(3)-gcc.script $(1).metal-$(2)$(3).out
	(($(METAL_BIN) < $$(word 1,$$+)) >& $(1).metal-$(2)$(3)-gcc.out.log) && \
	mv $(1)1.metal-$(2)$(3)-gcc.out $(1).metal-$(2)$(3)-gcc.out && \
	mv $(1)1.metal-$(2)$(3)-gcc.out.info $(1).metal-$(2)$(3)-gcc.out.info

################################################################################
# Rules to combine Uncorrected and GC-correction results
################################################################################
$(1).metal-$(2)$(3)-comb.out: $(MERGE_COL_SCRIPT) $(1).metal-$(2)$(3)-gcc.out $(1).metal-$(2)$(3).out
	$$(word 1,$$+)  --tmpdir="$(TMP_DIR)" --in $$(word 2,$$+) --colprefix "" --in $$(word 3,$$+) --colprefix "Uncorrected." --out $$@ --matchcolheaders $(MARKERLABEL):$(MARKERLABEL) --keepall 1 --missing $(MISSING)

endef # meta_metal_ANALYSIS_SCHEME_FILTERSET_rules



################################################################################
# Evaluate above rules for SampleSize (ss) and StdErr (se) schemes
################################################################################
$(foreach analysis,$(ANALYSES),$(eval $(call meta_metal_ANALYSIS_SCHEME_FILTERSET_rules,$(analysis),ss)))
$(foreach analysis,$(ANALYSES),$(eval $(call meta_metal_ANALYSIS_SCHEME_FILTERSET_rules,$(analysis),se)))

################################################################################
# And also with each filterset
################################################################################
$(foreach filterset,$(FILTERSETS),$(foreach analysis,$(ANALYSES),$(eval $(call meta_metal_ANALYSIS_SCHEME_FILTERSET_rules,$(analysis),ss,$(filterset)))))
$(foreach filterset,$(FILTERSETS),$(foreach analysis,$(ANALYSES),$(eval $(call meta_metal_ANALYSIS_SCHEME_FILTERSET_rules,$(analysis),se,$(filterset)))))


define meta_metal_FILTERSET_rules # FILTERSET

################################################################################
# Pattern rules to combine SampleSize and StdErr results
################################################################################
%.metal-comb$(1).out: $(MERGE_COL_SCRIPT) %.metal-se$(1)-comb.out %.metal-ss$(1)-comb.out
	$$(word 1,$$+)  --tmpdir="$(TMP_DIR)" --in $$(word 2,$$+) --colprefix "SE." --in $$(word 3,$$+) --colprefix "SS." --out $$@ --matchcolheaders $(MARKERLABEL):$(MARKERLABEL) --keepall 1 --missing $(MISSING)
endef # meta_metal_FILTERSET_rules 

$(foreach filterset,$(FILTERSETS),$(eval $(call meta_metal_FILTERSET_rules,$(filterset))))

# also run with no filterset!
$(eval $(call meta_metal_FILTERSET_rules))


################################################################################
# Pattern rule to process Metal log output
################################################################################
%.out.studyinfo: $.out.log $(METALLOG2STUDYINFO_SCRIPT)
	$(word 2,$+) --in $(word 1,$+) --out $@

