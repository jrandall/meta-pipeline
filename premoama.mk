#######################################################################################
# Copyright 2008 Joshua Randall
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
# Real Target Rules
#######################################################################################
%.metalprep.txt: %.original.txt $(META_CHECK_WITHIN_SCRIPT)
	($(META_CHECK_WITHIN_SCRIPT) $(word 1,$+) > $*.metalprep.txt) >& $*.metalprep.log

%.metalish.txt: $(ORIGINAL2METALISH_SCRIPT) %.original.txt 
	($(word 1,$+) $(word 2,$+) > $*.metalish.txt) >& $*.metalish.log

%.metalprep.max_N.txt: %.metalprep.txt
	$(COL_MAX_SCRIPT) --in $< --out $@ --col N

define PHENOTYPE_rules # phenotype

$(1).metal-unfiltered-stderr.script: $(MAKEMETAL_STDERR_SCRIPT) $(foreach result,$($(1)_INPUT),$(result).metalish.txt)
	$(MAKEMETAL_STDERR_SCRIPT) 1 $(1) .metal-unfiltered-stderr-uncorrected.out $$(wordlist 2, $$(words $$+), $$+) > $$@
$(1).metal-unfiltered-stderr-uncorrected.out.info: $(1)1.metal-unfiltered-stderr-uncorrected.out.info 
	cp $$< $$@
$(1).metal-unfiltered-stderr-uncorrected.out: $(1)1.metal-unfiltered-stderr-uncorrected.out 
	cp $$< $$@
$(1)1%metal-unfiltered-stderr-uncorrected.out $(1)1%metal-unfiltered-stderr-uncorrected.out.info $(1)%metal-unfiltered-stderr-uncorrected.out.log: $(1)%metal-unfiltered-stderr.script $(foreach result,$($(1)_INPUT),$(result).metalish.txt) $(METALBIN)
	($(METALBIN) < $$(word 1,$$+)) >& $(1)$$*metal-unfiltered-stderr-uncorrected.out.log
$(1)1%metal-unfiltered-stderr.out: $(MERGE_COL_SCRIPT) $(1)1%metal-unfiltered-stderr-gcc.out $(1)1%metal-unfiltered-stderr-uncorrected.out
	$(MERGE_COL_SCRIPT) --in $$(word 2,$$+) --colprefix "" --in $$(word 3,$$+) --colprefix "Uncorrected." --out $$@ --matchcolheaders MarkerName:MarkerName --keepall 1 --missing "."
$(1).metal-unfiltered-stderr-metagccorrect.script: $(MAKEMETAL_STDERR_METAGCC_SCRIPT) $(1)1.metal-unfiltered-stderr-uncorrected.out
	$(MAKEMETAL_STDERR_METAGCC_SCRIPT) 0 $(1) .metal-unfiltered-stderr-gcc.out $$(word 2,$$+) > $$@
$(1)1%metal-unfiltered-stderr-gcc.out $(1)1%metal-unfiltered-stderr-gcc.out.info $(1)%metal-unfiltered-stderr-gcc.out.log: $(1)%metal-unfiltered-stderr-metagccorrect.script $(1)1.metal-unfiltered-stderr-uncorrected.out $(METALBIN)
	($(METALBIN) < $$(word 1,$$+)) >& $(1)$$*metal-unfiltered-stderr-gcc.out.log



$(1).metal.script: $(MAKEMETAL_SCRIPT) $(1).minweight $(foreach result,$($(1)_INPUT),$(result).metalprep.txt)
	$(MAKEMETAL_SCRIPT) `cat $$(word 2,$$+)` $(1) .metal-uncorrected.out $$(wordlist 3, $$(words $$+), $$+) > $$@
$(1)1%metal-uncorrected.out $(1)1%metal-uncorrected.out.info $(1)%metal-uncorrected.out.log: $(1)%metal.script $(foreach result,$($(1)_INPUT),$(result).metalprep.txt) $(METALBIN)
	($(METALBIN) < $$(word 1,$$+)) >& $(1)$$*metal-uncorrected.out.log

$(1).metal-stderr.script: $(MAKEMETAL_STDERR_SCRIPT) $(1).minweight $(foreach result,$($(1)_INPUT),$(result).metalprep.txt)
	$(MAKEMETAL_STDERR_SCRIPT) `cat $$(word 2,$$+)` $(1) .metal-stderr-uncorrected.out $$(wordlist 3, $$(words $$+), $$+) > $$@
$(1).metal-stderr-uncorrected.out.info: $(1)1.metal-stderr-uncorrected.out.info 
	cp $$< $$@
$(1).metal-stderr-uncorrected.out: $(1)1.metal-stderr-uncorrected.out 
	cp $$< $$@
$(1)1%metal-stderr-uncorrected.out $(1)1%metal-stderr-uncorrected.out.info $(1)%metal-stderr-uncorrected.out.log: $(1)%metal-stderr.script $(foreach result,$($(1)_INPUT),$(result).metalprep.txt) $(METALBIN)
	($(METALBIN) < $$(word 1,$$+)) >& $(1)$$*metal-stderr-uncorrected.out.log
$(1).metal-metagccorrect.script: $(MAKEMETAL_METAGCC_SCRIPT) $(1)1.metal-uncorrected.out
	$(MAKEMETAL_METAGCC_SCRIPT) 0 $(1) .metal-gcc.out $$(word 2,$$+) > $$@
$(1).metal-stderr-metagccorrect.script: $(MAKEMETAL_STDERR_METAGCC_SCRIPT) $(1)1.metal-stderr-uncorrected.out
	$(MAKEMETAL_STDERR_METAGCC_SCRIPT) 0 $(1) .metal-stderr-gcc.out $$(word 2,$$+) > $$@
$(1).%metal-gcc.out: $(1)1.metal-gcc.out
	cp $$< $$@
$(1).metal-gcc.out.info: $(1)1.metal-gcc.out.info
	cp $$< $$@
$(1)1%metal-gcc.out $(1)1%metal-gcc.out.info $(1)%metal-gcc.out.log: $(1)%metal-metagccorrect.script $(1)1.metal-uncorrected.out $(METALBIN)
	($(METALBIN) < $$(word 1,$$+)) >& $(1)$$*metal-gcc.out.log
$(1)1%metal-stderr-gcc.out $(1)1%metal-stderr-gcc.out.info $(1)%metal-stderr-gcc.out.log: $(1)%metal-stderr-metagccorrect.script $(1)1.metal-stderr-uncorrected.out $(METALBIN)
	($(METALBIN) < $$(word 1,$$+)) >& $(1)$$*metal-stderr-gcc.out.log
$(1).metal-stderr-gcc.out: $(1)1.metal-stderr-gcc.out
	cp $$< $$@
$(1).metal-stderr-gcc.out.info: $(1)1.metal-stderr-gcc.out.info
	cp $$< $$@
$(1).metal.out-info-log.tar.bz2: $(1).metal.out $(1).metal-gcc.out.info $(1).metal-gcc.out.log $(1).metal-uncorrected.out.info $(1).metal-uncorrected.out.log
	$(TARBIN) -cjf $$@ $$+
$(1).metal-stderr.out-info-log.tar.bz2: $(1).metal-stderr.out $(1).metal-stderr-gcc.out.info $(1).metal-stderr-gcc.out.log $(1).metal-stderr-uncorrected.out.info $(1).metal-stderr-uncorrected.out.log
	$(TARBIN) -cjf $$@ $$+
$(1)1%metal.out: $(MERGE_COL_SCRIPT) $(1)1%metal-gcc.out $(1)1%metal-uncorrected.out
	$(MERGE_COL_SCRIPT) --in $$(word 2,$$+) --colprefix "" --in $$(word 3,$$+) --colprefix "Uncorrected." --out $$@ --matchcolheaders MarkerName:MarkerName --keepall 1 --missing "."
$(1)1%metal-stderr.out: $(MERGE_COL_SCRIPT) $(1)1%metal-stderr-gcc.out $(1)1%metal-stderr-uncorrected.out
	$(MERGE_COL_SCRIPT) --in $$(word 2,$$+) --colprefix "" --in $$(word 3,$$+) --colprefix "Uncorrected." --out $$@ --matchcolheaders MarkerName:MarkerName --keepall 1 --missing "."
$(1).checkacrossstudies.log: $(META_CHECK_ACROSS_STUDIES_SCRIPT) $$(foreach result,$$($(1)_INPUT),$$(result).original.txt)
	$(META_CHECK_ACROSS_STUDIES_SCRIPT) $$(wordlist 2,$$(words $$+),$$+) > $$@
$(1).checkalleles.log: $(META_CHECK_ALLELES_SCRIPT) $$(foreach result,$$($(1)_INPUT),$$(result).metalprep.txt)
	$(META_CHECK_ALLELES_SCRIPT) $$(wordlist 2,$$(words $$+),$$+) > $$@
$(1).combined.%: $(MERGE_COL_SCRIPT) $(1).% $(foreach result,$($(1)_INPUT),$(result).metalprep.txt)
	$(MERGE_COL_SCRIPT) --in $$(word 2,$$+) --colprefix "" $$(foreach metalprep,$$(wordlist 3,$$(words $$+), $$+),--in $$(metalprep) --colprefix "$$(subst .metalprep.txt,,$$(metalprep)) " ) --out $$@ --matchcolheaders $(METAL_MARKER_H):SNP --keepall 1 --missing "."
$(1).rsid-totaln.tsv: $(CALC_TOTAL_N_SCRIPT) $(foreach result,$($(1)_INPUT),$(result).metalprep.txt)
	$$(word 1,$$+) $$(wordlist 2,$$(words $$+),$$+) > $$@
$(1).metal-stderr.annottotaln:  $(MERGE_COL_SCRIPT) $(1).metal-stderr.out $(1).rsid-totaln.tsv
	$(MERGE_COL_SCRIPT) --in $$(word 2,$$+) --in $$(word 3,$$+) --out $$@ --matchcolheaders $(METAL_MARKER_H):$(METAL_MARKER_H) --keepall 1 --missing "."
$(1).vs.%.metal-stderr.annottotaln: $(MERGE_COL_SCRIPT) $(1).metal-stderr.annottotaln %.metal-stderr.annottotaln
	$(MERGE_COL_SCRIPT) --in $$(word 2,$$+) --colprefix "$(1)." --in $$(word 3,$$+) --colprefix "$$*." --out $$@ --matchcolheaders $(METAL_MARKER_H):$(METAL_MARKER_H)
$(1).vs.%.ttest.out: $(PAIRWISE_T_TEST_R_SCRIPT) $(1).vs.%.metal-stderr.annottotaln
	$(RBIN) --args infile=$$(word 2,$$+) effect1header=$(1).Effect se1header=$(1).StdErr totaln1header=$(1).TOTAL.N effect2header=$$*.Effect se2header=$$*.StdErr totaln2header=$$*.TOTAL.N markerheader=$(1).$(METAL_MARKER_H) outfile=$$@ direction1header=$(1).Uncorrected.Direction direction2header=$$*.Uncorrected.Direction < $(PAIRWISE_T_TEST_R_SCRIPT) >& $$@.log
$(1).vs.%.uncorrected.ttest.out: $(PAIRWISE_T_TEST_R_SCRIPT) $(1).vs.%.metal-stderr.annottotaln
	$(RBIN) --args infile=$$(word 2,$$+) effect1header=$(1).Uncorrected.Effect se1header=$(1).Uncorrected.StdErr totaln1header=$(1).TOTAL.N effect2header=$$*.Uncorrected.Effect se2header=$$*.Uncorrected.StdErr totaln2header=$$*.TOTAL.N markerheader=$(1).$(METAL_MARKER_H) outfile=$$@ direction1header=$(1).Uncorrected.Direction direction2header=$$*.Uncorrected.Direction < $(PAIRWISE_T_TEST_R_SCRIPT)
%.annotin-$(subst .,_,$(1)): $(MERGE_COL_SCRIPT) % $(foreach result,$($(1)_INPUT),$(result).metalprep.txt)
	$(MERGE_COL_SCRIPT) --keepall 1 --missing "." --in $$(word 2,$$+) --colprefix "" $$(foreach metalprepfile,$$(wordlist 3, $$(words $$+), $$+), --in $$(metalprepfile) --colprefix $$(subst .metalprep.txt,,$$(metalprepfile)). ) --out $$@ --matchcolheaders $(METAL_MARKER_H):$(METALPREP_MARKER_H)
%.annotmetal-$(subst .,_,$(1)): $(MERGE_COL_SCRIPT) % $(1).metal.out
	$(MERGE_COL_SCRIPT) --in $$(word 2,$$+) --colprefix "" --in $$(word 3,$$+) --colprefix "$(1)." --out $$@ --matchcolheaders $(METAL_MARKER_H):$(METAL_MARKER_H) --keepall 1 --missing "."
%.annotmetal-stderr-$(subst .,_,$(1)): $(MERGE_COL_SCRIPT) % $(1).metal-stderr.out
	$(MERGE_COL_SCRIPT) --in $$(word 2,$$+) --colprefix "" --in $$(word 3,$$+) --colprefix "$(1)." --out $$@ --matchcolheaders $(METAL_MARKER_H):$(METAL_MARKER_H) --keepall 1 --missing "."
#$(1).metal.out.analysislabel: $(APPEND_CONSTANT_COL_SCRIPT) $(1).metal.out
#	$$(word 1,$$+) Phenotype $(1) < $$(word 2,$$+) > $$@
$(1).%.analysislabel: $(APPEND_CONSTANT_COL_SCRIPT) $(1).%
	$$(word 1,$$+) Analysis $(1) < $$(word 2,$$+) > $$@
$(1).%.phenolabel: $(APPEND_CONSTANT_COL_SCRIPT) $(1).%
	$$(word 1,$$+) Phenotype `echo $(1) | perl -pi -e 's/.*?\.//' | perl -pi -e 's/\..*//'` < $$(word 2,$$+) > $$@
$(1).%.phenostratlabel: $(APPEND_CONSTANT_COL_SCRIPT) $(1).%
	$$(word 1,$$+) Phenotype-Strat `echo $(1) | perl -pi -e 's/.*?\.//' | perl -pi -e 's/\..*//'`'-'`echo $(1) | perl -pi -e 's/\..*//' | perl -pi -e 's/.*WOM.*/women/' |perl -pi -e 's/.*MIXED.*/mixed/' |perl -pi -e 's/.*MEN.*/men/'   ` < $$(word 2,$$+) > $$@
$(1).%.forest.pdf $(1).%.hetero.txt: $(1).% $(GIANT_FOREST_PLOT_R_SCRIPT)
	$(RBIN) --args inputdata=$$(word 1,$$+) outfile=$(1).$$*.forest.pdf heterooutfile=$(1).$$*.hetero.txt pheno="$(1)" < $(GIANT_FOREST_PLOT_R_SCRIPT) >& $(1).$$*.forest.log
endef
$(foreach phenotype,$(PHENOTYPES),$(eval $(call PHENOTYPE_rules,$(phenotype))))

#define PHENOVSPHENO_rules # pheno1 pheno2
#%.annottt-$(subst .,_,$(1))_vs_$(subst .,_,$(2)): $(MERGE_COL_SCRIPT) % $(1).vs.$(2).ttest.out
#	$(MERGE_COL_SCRIPT) --in $$(word 2,$$+) --colprefix "" --in $$(word 3,$$+) --colprefix "$(subst .,_,$(1))_vs_$(subst .,_,$(2))." --out $$@ --matchcolheaders $(METAL_MARKER_H):MARKER --keepall 1 --missing "."
#%.annotutt-$(subst .,_,$(1))_vs_$(subst .,_,$(2)): $(MERGE_COL_SCRIPT) % $(1).vs.$(2).uncorrected.ttest.out
#	$(MERGE_COL_SCRIPT) --in $$(word 2,$$+) --colprefix "" --in $$(word 3,$$+) --colprefix "$(subst .,_,$(1))_vs_$(subst .,_,$(2)).Uncorrected." --out $$@ --matchcolheaders $(METAL_MARKER_H):MARKER --keepall 1 --missing "."
#merged-$(1)-$(2).metal.out.analysislabel: $(1).metal.out.analysislabel $(2).metal.out.analysislabel
#	(head -n 1 $$(word 1,$$+) && tail -n +2 $$(word 1,$$+) && tail -n +2 $$(word 2,$$+)) > $$@
#endef
#$(foreach phenotype1,$(PHENOTYPES),$(foreach phenotype2,$(PHENOTYPES),$(eval $(call PHENOVSPHENO_rules,$(phenotype1),$(phenotype2)))))

#MENrep.WEIGHT.UNIFORM.metal-stderr.out.threshold1e-4.annotutt-MENrep_WEIGHT_UNIFORM_vs_WOMENrep_WEIGHT_UNIFORM.filter_TTUUNP_lt_1e-3 MENrep.WEIGHT.UNIFORM.metal-stderr.out.threshold1e-5.annotutt-MENrep_WEIGHT_UNIFORM_vs_WOMENrep_WEIGHT_UNIFORM.filter_TTUUNP_lt_5e-2 WOMENrep.WEIGHT.UNIFORM.metal-stderr.out.threshold1e-4.annotutt-MENrep_WEIGHT_UNIFORM_vs_WOMENrep_WEIGHT_UNIFORM.filter_TTUUNP_lt_1e-3 WOMENrep.WEIGHT.UNIFORM.metal-stderr.out.threshold1e-5.annotutt-MENrep_WEIGHT_UNIFORM_vs_WOMENrep_WEIGHT_UNIFORM.filter_TTUUNP_lt_5e-2
#$(1).combined.%: $(MERGE_COL_SCRIPT) $(1).% $(foreach result,$($(1)_INPUT),$(result).metalprep.txt)
#	$(MERGE_COL_SCRIPT) --in $$(word 2,$$+) --colprefix "" $$(foreach metalprep,$$(wordlist 3,$$(words $$+), $$+),--in $$(metalprep) --colprefix "$$(subst .metalprep.txt,,$$(metalprep)) " ) --out $$@ --matchcolheaders $(METAL_MARKER_H):SNP --keepall 1 --missing "."

define MENWOMENPHENO_rules # phenosuffix
MENWOMEN$(1).filtered.tsv: $$(foreach filterset,$$(FILTERSETS),MEN$(1).metal-stderr.out.annotutt-MEN$$(subst .,_,$(1))_vs_WOMEN$$(subst .,_,$(1)).$$(filterset).filtersetlabel WOMEN$(1).metal-stderr.out.annotutt-MEN$$(subst .,_,$(1))_vs_WOMEN$$(subst .,_,$(1)).$$(filterset).filtersetlabel)
	(head -n 1 $$(word 1,$$+) && tail -q -n +2 $$+) > $$@
endef
$(foreach phenosuffix,$(MENWOMENPHENOS_SUFFIXES),$(eval $(call MENWOMENPHENO_rules,$(phenosuffix))))

define FILTERSET_rules # filterset
%.$(1).filtersetlabel: $(APPEND_CONSTANT_COL_SCRIPT) %.$(1)
	$$(word 1,$$+) GENDERFILTERSET $(1) < $$(word 2,$$+) > $$@
endef
$(foreach filterset,$(FILTERSETS),$(eval $(call FILTERSET_rules,$(filterset))))

#define PHENOPHENOPHENO_rules # pheno1 pheno2 pheno3
#merged-$(1)-$(2)-$(3).metal.out.analysislabel: $(1).metal.out.analysislabel $(2).metal.out.analysislabel $(3).metal.out.analysislabel
#	(head -n 1 $$(word 1,$$+) && tail -n +2 $$(word 1,$$+) && tail -n +2 $$(word 2,$$+) && tail -n +2 $$(word 3,$$+)) > $$@
#endef
#$(foreach phenotype1,$(PHENOTYPES),$(foreach phenotype2,$(PHENOTYPES),$(foreach phenotype3,$(PHENOTYPES),$(eval $(call PHENOPHENOPHENO_rules,$(phenotype1),$(phenotype2),$(phenotype3))))))
#

define COHORT_rules # cohort 
$(1).checkacrossanalyses.log: $(META_CHECK_ACROSS_ANALYSES_SCRIPT) $$(foreach input,$$($(1)_INPUT),$$(input).metalprep.txt)
	$(META_CHECK_ACROSS_ANALYSES_SCRIPT) $$(wordlist 2,$$(words $$+),$$+) > $$@
endef
$(foreach cohort,$(COHORTS),$(eval $(call COHORT_rules,$(cohort))))


%.metal.out: %1.metal.out
	cp $< $@
%.metal-stderr.out: %1.metal-stderr.out
	cp $< $@
%.metal-unfiltered-stderr.out: %1.metal-unfiltered-stderr.out
	cp $< $@

%.metal-uncorrected.out.info: %1.metal-uncorrected.out.info
	cp $< $@
%.metal-uncorrected.out.log: %1.metal-uncorrected.out.log
	cp $< $@

%.metal-stderr-uncorrected.out.info: %1.metal-stderr-uncorrected.out.info
	cp $< $@
%.metal-stderr-uncorrected.out.log: %1.metal-stderr-uncorrected.out.log
	cp $< $@

%.distind1MB %.distind1MB.log: $(DIST_INDEPENDENT_FILTER) %
	$(DIST_INDEPENDENT_FILTER) --metalfile $(word 2,$+) --distance=1000000 --outfile $*.distind1MB --verbose >& $*.distind1MB.log

%.ttpirank0.2 %.ttpirank0.2.log: $(RSQ_INDEPENDENT_RANK) %.pisortttp ld_ALL_CEU.rsid1-rsid2-rsq.filter_rsq_gt_0.2.txt
	$(RSQ_INDEPENDENT_RANK) --metalfile $(word 2,$+) --rsqfile $(word 3,$+) --cutoff=0.2 --outfile $*.ttpirank0.2 --verbose >& $*.ttpirank0.2.log

%.ttuunpirank0.2 %.ttuunpirank0.2.log: $(RSQ_INDEPENDENT_RANK) %.pisortttuunp ld_ALL_CEU.rsid1-rsid2-rsq.filter_rsq_gt_0.2.txt
	$(RSQ_INDEPENDENT_RANK) --metalfile $(word 2,$+) --rsqfile $(word 3,$+) --cutoff=0.2 --outfile $*.ttuunpirank0.2 --verbose >& $*.ttuunpirank0.2.log

%.ttuusnpirank0.2 %.ttuusnpirank0.2.log: $(RSQ_INDEPENDENT_RANK) %.pisortttuusnp ld_ALL_CEU.rsid1-rsid2-rsq.filter_rsq_gt_0.2.txt
	$(RSQ_INDEPENDENT_RANK) --metalfile $(word 2,$+) --rsqfile $(word 3,$+) --cutoff=0.2 --outfile $*.ttuusnpirank0.2 --verbose >& $*.ttuusnpirank0.2.log

%.pvalindrank0.2 %.pvalindrank0.2.log: $(RSQ_INDEPENDENT_RANK) %.preindpvalsort ld_ALL_CEU.rsid1-rsid2-rsq.filter_rsq_gt_0.2.txt
	$(RSQ_INDEPENDENT_RANK) --metalfile $(word 2,$+) --rsqfile $(word 3,$+) --cutoff=0.2 --outfile $*.pvalindrank0.2 --verbose >& $*.pvalindrank0.2.log

%.pvalindep0.2 %.pvalindep0.2.log: $(RSQ_INDEPENDENT_FILTER) %.preindpvalsort ld_ALL_CEU.rsid1-rsid2-rsq.filter_rsq_gt_0.2.txt
	$(RSQ_INDEPENDENT_FILTER) --metalfile $(word 2,$+) --rsqfile $(word 3,$+) --cutoff=0.2 --outfile $*.pvalindep0.2 --verbose >& $*.pvalindep0.2.log

%.pvalindep0.3 %.pvalindep0.3.log: $(RSQ_INDEPENDENT_FILTER) %.preindpvalsort ld_ALL_CEU.rsid1-rsid2-rsq.filter_rsq_gt_0.3.txt
	$(RSQ_INDEPENDENT_FILTER) --metalfile $(word 2,$+) --rsqfile $(word 3,$+) --cutoff=0.3 --outfile $*.pvalindep0.3 --verbose >& $*.pvalindep0.3.log

%.pvalindep0.4 %.pvalindep0.4.log: $(RSQ_INDEPENDENT_FILTER) %.preindpvalsort ld_ALL_CEU.rsid1-rsid2-rsq.filter_rsq_gt_0.4.txt
	$(RSQ_INDEPENDENT_FILTER) --metalfile $(word 2,$+) --rsqfile $(word 3,$+) --cutoff=0.4 --outfile $*.pvalindep0.4 --verbose >& $*.pvalindep0.4.log

%.pvalindep0.5 %.pvalindep0.5.log: $(RSQ_INDEPENDENT_FILTER) %.preindpvalsort ld_ALL_CEU.rsid1-rsid2-rsq.filter_rsq_gt_0.5.txt
	$(RSQ_INDEPENDENT_FILTER) --metalfile $(word 2,$+) --rsqfile $(word 3,$+) --cutoff=0.5 --outfile $*.pvalindep0.5 --verbose >& $*.pvalindep0.5.log

%.pvalindep0.6 %.pvalindep0.6.log: $(RSQ_INDEPENDENT_FILTER) %.preindpvalsort ld_ALL_CEU.rsid1-rsid2-rsq.filter_rsq_gt_0.6.txt
	$(RSQ_INDEPENDENT_FILTER) --metalfile $(word 2,$+) --rsqfile $(word 3,$+) --cutoff=0.6 --outfile $*.pvalindep0.6 --verbose >& $*.pvalindep0.6.log

%.pvalindep0.7 %.pvalindep0.7.log: $(RSQ_INDEPENDENT_FILTER) %.preindpvalsort ld_ALL_CEU.rsid1-rsid2-rsq.filter_rsq_gt_0.7.txt
	$(RSQ_INDEPENDENT_FILTER) --metalfile $(word 2,$+) --rsqfile $(word 3,$+) --cutoff=0.7 --outfile $*.pvalindep0.7 --verbose >& $*.pvalindep0.7.log

%.pvalindep0.8 %.pvalindep0.8.log: $(RSQ_INDEPENDENT_FILTER) %.preindpvalsort ld_ALL_CEU.rsid1-rsid2-rsq.filter_rsq_gt_0.8.txt
	$(RSQ_INDEPENDENT_FILTER) --metalfile $(word 2,$+) --rsqfile $(word 3,$+) --cutoff=0.8 --outfile $*.pvalindep0.8 --verbose >& $*.pvalindep0.8.log

%.pvalindep0.9 %.pvalindep0.9.log: $(RSQ_INDEPENDENT_FILTER) %.preindpvalsort ld_ALL_CEU.rsid1-rsid2-rsq.filter_rsq_gt_0.9.txt
	$(RSQ_INDEPENDENT_FILTER) --metalfile $(word 2,$+) --rsqfile $(word 3,$+) --cutoff=0.9 --outfile $*.pvalindep0.9 --verbose >& $*.pvalindep0.9.log

.INTERMEDIATE: %.preindpvalsort
%.preindpvalsort: %
	(head -n 1 $< && (tail -n +2 $< | sort -t $(TAB) -g -k `$(CUT_COL_NAME_SCRIPT) $< P-value`)) > $@

%.sortpvalue: %
	(head -n 1 $< && (tail -n +2 $< | sort -t $(TAB) -g -k `$(CUT_COL_NAME_SCRIPT) $< "[Pp].{0,2}[vV][aA][lL]"`)) > $@

.INTERMEDIATE: %.pisortttp
%.pisortttp: %
	(head -n 1 $< && (tail -n +2 $< | sort -t $(TAB) -g -k `$(CUT_COL_NAME_SCRIPT) $< T.TEST.T.PVAL`)) > $@

%.sortttp: %
	(head -n 1 $< && (tail -n +2 $< | sort -t $(TAB) -g -k `$(CUT_COL_NAME_SCRIPT) $< UNEQUAL.N.EQUAL.VAR.T.TEST.NORMAL.PVAL`)) > $@

%.sorttuunp: %
	(head -n 1 $< && (tail -n +2 $< | sort -t $(TAB) -g -k `$(CUT_COL_NAME_SCRIPT) $< UNEQUAL.N.UNEQUAL.VAR.T.TEST.NORMAL.PVAL`)) > $@

%.sorttuusnp: %
	(head -n 1 $< && (tail -n +2 $< | sort -t $(TAB) -g -k `$(CUT_COL_NAME_SCRIPT) $< UNEQUAL.N.UNEQUAL.VAR.SCORR.T.TEST.NORMAL.PVAL`)) > $@

%.pisortttuunp: %
	(head -n 1 $< && (tail -n +2 $< | sort -t $(TAB) -g -k `$(CUT_COL_NAME_SCRIPT) $< UNEQUAL.N.UNEQUAL.VAR.T.TEST.NORMAL.PVAL`)) > $@

%.pisortttuusnp: %
	(head -n 1 $< && (tail -n +2 $< | sort -t $(TAB) -g -k `$(CUT_COL_NAME_SCRIPT) $< UNEQUAL.N.UNEQUAL.VAR.SCORR.T.TEST.NORMAL.PVAL`)) > $@

.INTERMEDIATE: %.pisorttnp
%.pisorttnp: %
	(head -n 1 $< && (tail -n +2 $< | sort -t $(TAB) -g -k `$(CUT_COL_NAME_SCRIPT) $< T.TEST.NORM.PVAL`)) > $@

%.sorttnp: %
	(head -n 1 $< && (tail -n +2 $< | sort -t $(TAB) -g -k `$(CUT_COL_NAME_SCRIPT) $< T.TEST.NORM.PVAL`)) > $@

# specific rule to avoid not being able to sort twice in a pipelinue because of "avoiding implicit rule prerequisite"
%.metal.out.sortpvalue: %.metal.out
	 (head -n 1 $+ && (tail -n +2 $+ | sort -t $(TAB) -g -k 6)) > $@
%.metal-stderr.out.sortpvalue: %.metal-stderr.out
	 (head -n 1 $+ && (tail -n +2 $+ | sort -t $(TAB) -g -k 6)) > $@

%.filter_snp_in_WAIST-103: $(FILTER_ROWS_MATCHING_LIST) % WAIST-103.rsid.list
	(head -n 1 $(word 2,$+) && $(word 1,$+) $(word 3,$+) `$(CUT_COL_NAME_SCRIPT) $(word 2,$+) MarkerName` $(TAB) < $(word 2,$+)) > $@
%.filter_snp_in_WAIST-30: $(FILTER_ROWS_MATCHING_LIST) % WAIST-30.rsid.list
	(head -n 1 $(word 2,$+) && $(word 1,$+) $(word 3,$+) `$(CUT_COL_NAME_SCRIPT) $(word 2,$+) MarkerName` $(TAB) < $(word 2,$+)) > $@
%.filter_snp_in_WC-rep: $(FILTER_ROWS_MATCHING_LIST) % WC-rep.rsid.list
	(head -n 1 $(word 2,$+) && $(word 1,$+) $(word 3,$+) `$(CUT_COL_NAME_SCRIPT) $(word 2,$+) MarkerName` $(TAB) < $(word 2,$+)) > $@
%.filter_snp_in_WH2-rep: $(FILTER_ROWS_MATCHING_LIST) % WH2-rep.rsid.list
	(head -n 1 $(word 2,$+) && $(word 1,$+) $(word 3,$+) `$(CUT_COL_NAME_SCRIPT) $(word 2,$+) MarkerName` $(TAB) < $(word 2,$+)) > $@
%.filter_snp_in_WHR-rep: $(FILTER_ROWS_MATCHING_LIST) % WHR-rep.rsid.list
	(head -n 1 $(word 2,$+) && $(word 1,$+) $(word 3,$+) `$(CUT_COL_NAME_SCRIPT) $(word 2,$+) MarkerName` $(TAB) < $(word 2,$+)) > $@
%.filter_snp_in_WC-117: $(FILTER_ROWS_MATCHING_LIST) % GIANT+CHARGE-117.wc-only.rsid.list
	(head -n 1 $(word 2,$+) && $(word 1,$+) $(word 3,$+) `$(CUT_COL_NAME_SCRIPT) $(word 2,$+) MarkerName` $(TAB) < $(word 2,$+)) > $@
%.filter_snp_in_WH2-117: $(FILTER_ROWS_MATCHING_LIST) % GIANT+CHARGE-117.wh2-only.rsid.list
	(head -n 1 $(word 2,$+) && $(word 1,$+) $(word 3,$+) `$(CUT_COL_NAME_SCRIPT) $(word 2,$+) MarkerName` $(TAB) < $(word 2,$+)) > $@
%.filter_snp_in_WHR-117: $(FILTER_ROWS_MATCHING_LIST) % GIANT+CHARGE-117.whr-only.rsid.list
	(head -n 1 $(word 2,$+) && $(word 1,$+) $(word 3,$+) `$(CUT_COL_NAME_SCRIPT) $(word 2,$+) MarkerName` $(TAB) < $(word 2,$+)) > $@
%.filter_snp_in_WC-118: $(FILTER_ROWS_MATCHING_LIST) % GIANT+CHARGE-118.wc-only.rsid.list
	(head -n 1 $(word 2,$+) && $(word 1,$+) $(word 3,$+) `$(CUT_COL_NAME_SCRIPT) $(word 2,$+) MarkerName` $(TAB) < $(word 2,$+)) > $@
%.filter_snp_in_WH2-118: $(FILTER_ROWS_MATCHING_LIST) % GIANT+CHARGE-118.wh2-only.rsid.list
	(head -n 1 $(word 2,$+) && $(word 1,$+) $(word 3,$+) `$(CUT_COL_NAME_SCRIPT) $(word 2,$+) MarkerName` $(TAB) < $(word 2,$+)) > $@
%.filter_snp_in_WHR-118: $(FILTER_ROWS_MATCHING_LIST) % GIANT+CHARGE-118.whr-only.rsid.list
	(head -n 1 $(word 2,$+) && $(word 1,$+) $(word 3,$+) `$(CUT_COL_NAME_SCRIPT) $(word 2,$+) MarkerName` $(TAB) < $(word 2,$+)) > $@
%.filter_snp_in_WC-119: $(FILTER_ROWS_MATCHING_LIST) % GIANT+CHARGE-119.wc-only.rsid.list
	(head -n 1 $(word 2,$+) && $(word 1,$+) $(word 3,$+) `$(CUT_COL_NAME_SCRIPT) $(word 2,$+) MarkerName` $(TAB) < $(word 2,$+)) > $@
%.filter_snp_in_WH2-119: $(FILTER_ROWS_MATCHING_LIST) % GIANT+CHARGE-119.wh2-only.rsid.list
	(head -n 1 $(word 2,$+) && $(word 1,$+) $(word 3,$+) `$(CUT_COL_NAME_SCRIPT) $(word 2,$+) MarkerName` $(TAB) < $(word 2,$+)) > $@
%.filter_snp_in_WHR-119: $(FILTER_ROWS_MATCHING_LIST) % GIANT+CHARGE-119.whr-only.rsid.list
	(head -n 1 $(word 2,$+) && $(word 1,$+) $(word 3,$+) `$(CUT_COL_NAME_SCRIPT) $(word 2,$+) MarkerName` $(TAB) < $(word 2,$+)) > $@
%.filter_snp_in_WHRwomen-119: $(FILTER_ROWS_MATCHING_LIST) % GIANT+CHARGE-119.whr-women-only.rsid.list
	(head -n 1 $(word 2,$+) && $(word 1,$+) $(word 3,$+) `$(CUT_COL_NAME_SCRIPT) $(word 2,$+) MarkerName` $(TAB) < $(word 2,$+)) > $@


%.filter_rsq_gt_0.1.txt: %.txt
	awk -F" " '((($$3+0)==$$3)&&( $$3 > 0.1 ))' $< > $@

%.filter_rsq_gt_0.2.txt: %.filter_rsq_gt_0.1.txt
	awk -F" " '((($$3+0)==$$3)&&( $$3 > 0.2 ))' $< > $@

%.filter_rsq_gt_0.3.txt: %.filter_rsq_gt_0.2.txt
	awk -F" " '((($$3+0)==$$3)&&( $$3 > 0.3 ))' $< > $@

%.filter_rsq_gt_0.4.txt: %.filter_rsq_gt_0.3.txt
	awk -F" " '((($$3+0)==$$3)&&( $$3 > 0.4 ))' $< > $@

%.filter_rsq_gt_0.5.txt: %.filter_rsq_gt_0.4.txt
	awk -F" " '((($$3+0)==$$3)&&( $$3 > 0.5 ))' $< > $@

%.filter_rsq_gt_0.6.txt: %.filter_rsq_gt_0.5.txt
	awk -F" " '((($$3+0)==$$3)&&( $$3 > 0.6 ))' $< > $@

%.filter_rsq_gt_0.7.txt: %.filter_rsq_gt_0.6.txt
	awk -F" " '((($$3+0)==$$3)&&( $$3 > 0.7 ))' $< > $@

%.filter_rsq_gt_0.8.txt: %.filter_rsq_gt_0.7.txt
	awk -F" " '((($$3+0)==$$3)&&( $$3 > 0.8 ))' $< > $@

%.filter_rsq_gt_0.9.txt: %.filter_rsq_gt_0.8.txt
	awk -F" " '((($$3+0)==$$3)&&( $$3 > 0.9 ))' $< > $@

%.rsid1-rsid2-rsq.filterrsq0.9.txt: %.rsid1-rsid2-rsq.filterrsq0.8.txt
	awk -F" " '((($$3+0)==$$3)&&( $$3 > 0.9 ))' $+ > $@

%.rsid1-rsid2-rsq.filterrsq0.8.txt: %.rsid1-rsid2-rsq.txt
	awk -F" " '((($$3+0)==$$3)&&( $$3 > 0.8 ))' $+ > $@

%.rsid1-rsid2-rsq.filterrsq0.8.txt: %.rsid1-rsid2-rsq.txt.gz
	zcat $+ | awk -F" " '((($$3+0)==$$3)&&( $$3 > 0.8 ))' > $@

%.metal.out.top500: %.metal.out.sortpvalue
	head -n 501 $< > $@
%.metal-stderr.out.top500: %.metal-stderr.out.sortpvalue
	head -n 501 $< > $@

%.out.top1000: %.out.sortpvalue
	head -n 1001 $< > $@

%.top5000: %.sortpvalue
	head -n 5001  $< > $@

%.threshold1e-1: %.sortpvalue
	(head -n 1 $+ && awk -F$(TAB) '((($$6+0)==$$6)&&( $$6 < 1e-1 ))' $+) > $@

%.threshold1e-2: %.sortpvalue
	(head -n 1 $+ && awk -F$(TAB) '((($$6+0)==$$6)&&( $$6 < 1e-2 ))' $+) > $@

%.threshold1e-3: %.sortpvalue
	(head -n 1 $+ && awk -F$(TAB) '((($$6+0)==$$6)&&( $$6 < 1e-3 ))' $+) > $@

%.threshold1e-4: %.sortpvalue
	(head -n 1 $+ && awk -F$(TAB) '((($$6+0)==$$6)&&( $$6 < 1e-4 ))' $+) > $@

%.threshold8.5e-5: %.sortpvalue
	(head -n 1 $+ && awk -F$(TAB) '((($$6+0)==$$6)&&( $$6 < 8.5e-5 ))' $+) > $@

%.threshold2.25e-5: %.sortpvalue
	(head -n 1 $+ && awk -F$(TAB) '((($$6+0)==$$6)&&( $$6 < 2.25e-5 ))' $+) > $@

%.threshold1e-5: %.sortpvalue
	(head -n 1 $+ && awk -F$(TAB) '((($$6+0)==$$6)&&( $$6 < 1e-5 ))' $+) > $@

%.threshold1e-6: %.sortpvalue
	(head -n 1 $+ && awk -F$(TAB) '((($$6+0)==$$6)&&( $$6 < 1e-6 ))' $+) > $@

%.threshold1e-7: %.sortpvalue
	(head -n 1 $+ && awk -F$(TAB) '((($$6+0)==$$6)&&( $$6 < 1e-7 ))' $+) > $@

%.threshold1e-8: %.sortpvalue
	(head -n 1 $+ && awk -F$(TAB) '((($$6+0)==$$6)&&( $$6 < 1e-8 ))' $+) > $@

%.threshold1e-9: %.sortpvalue
	(head -n 1 $+ && awk -F$(TAB) '((($$6+0)==$$6)&&( $$6 < 1e-9 ))' $+) > $@

%.filter_TTP_lt_5e-2: %
	(head -n 1 $< && (tail -n +2 $< | awk -F$(TAB) '((($$'`$(CUT_COL_NAME_SCRIPT) $< T.TEST.T.PVAL`'+0)==$$'`$(CUT_COL_NAME_SCRIPT) $< T.TEST.T.PVAL`')&&( $$'`$(CUT_COL_NAME_SCRIPT) $< T.TEST.T.PVAL`' < 5e-2 && $$'`$(CUT_COL_NAME_SCRIPT) $< T.TEST.T.PVAL`' != "." ))')) > $@

%.filter_TTP_lt_1e-4: %
	(head -n 1 $< && (tail -n +2 $< | awk -F$(TAB) '((($$'`$(CUT_COL_NAME_SCRIPT) $< T.TEST.T.PVAL`'+0)==$$'`$(CUT_COL_NAME_SCRIPT) $< T.TEST.T.PVAL`')&&( $$'`$(CUT_COL_NAME_SCRIPT) $< T.TEST.T.PVAL`' < 1e-4 && $$'`$(CUT_COL_NAME_SCRIPT) $< T.TEST.T.PVAL`' != "." ))')) > $@

%.filter_TTP_lt_1e-3: %
	(head -n 1 $< && (tail -n +2 $< | awk -F$(TAB) '((($$'`$(CUT_COL_NAME_SCRIPT) $< T.TEST.T.PVAL`'+0)==$$'`$(CUT_COL_NAME_SCRIPT) $< T.TEST.T.PVAL`')&&( $$'`$(CUT_COL_NAME_SCRIPT) $< T.TEST.T.PVAL`' < 1e-3 && $$'`$(CUT_COL_NAME_SCRIPT) $< T.TEST.T.PVAL`' != "." ))')) > $@

%.filter_TTUUNP_lt_5e-2: %
	(head -n 1 $< && (tail -n +2 $< | awk -F$(TAB) '((($$'`$(CUT_COL_NAME_SCRIPT) $< UNEQUAL.N.UNEQUAL.VAR.T.TEST.NORMAL.PVAL`'+0)==$$'`$(CUT_COL_NAME_SCRIPT) $< UNEQUAL.N.UNEQUAL.VAR.T.TEST.NORMAL.PVAL`')&&( $$'`$(CUT_COL_NAME_SCRIPT) $< UNEQUAL.N.UNEQUAL.VAR.T.TEST.NORMAL.PVAL`' < 5e-2 && $$'`$(CUT_COL_NAME_SCRIPT) $< UNEQUAL.N.UNEQUAL.VAR.T.TEST.NORMAL.PVAL`' != "." ))')) > $@

%.filter_TTUUNP_lt_1e-4: %
	(head -n 1 $< && (tail -n +2 $< | awk -F$(TAB) '((($$'`$(CUT_COL_NAME_SCRIPT) $< UNEQUAL.N.UNEQUAL.VAR.T.TEST.NORMAL.PVAL`'+0)==$$'`$(CUT_COL_NAME_SCRIPT) $< UNEQUAL.N.UNEQUAL.VAR.T.TEST.NORMAL.PVAL`')&&( $$'`$(CUT_COL_NAME_SCRIPT) $< UNEQUAL.N.UNEQUAL.VAR.T.TEST.NORMAL.PVAL`' < 1e-4 && $$'`$(CUT_COL_NAME_SCRIPT) $< UNEQUAL.N.UNEQUAL.VAR.T.TEST.NORMAL.PVAL`' != "." ))')) > $@

%.filter_TTUUNP_lt_1e-3: %
	(head -n 1 $< && (tail -n +2 $< | awk -F$(TAB) '((($$'`$(CUT_COL_NAME_SCRIPT) $< UNEQUAL.N.UNEQUAL.VAR.T.TEST.NORMAL.PVAL`'+0)==$$'`$(CUT_COL_NAME_SCRIPT) $< UNEQUAL.N.UNEQUAL.VAR.T.TEST.NORMAL.PVAL`')&&( $$'`$(CUT_COL_NAME_SCRIPT) $< UNEQUAL.N.UNEQUAL.VAR.T.TEST.NORMAL.PVAL`' < 1e-3 && $$'`$(CUT_COL_NAME_SCRIPT) $< UNEQUAL.N.UNEQUAL.VAR.T.TEST.NORMAL.PVAL`' != "." ))')) > $@

%.filter_TTUUSNP_lt_5e-2: %
	FILTCOL=`$(CUT_COL_NAME_SCRIPT) $< UNEQUAL.N.UNEQUAL.VAR.SCORR.T.TEST.NORMAL.PVAL` && (head -n 1 $< && (tail -n +2 $< | awk -F$(TAB) '((($$'$$FILTCOL'+0)==$$'$$FILTCOL')&&( $$'$$FILTCOL' < 5e-2 && $$'$$FILTCOL' != "." ))')) > $@

%.filter_TTUUSNP_lt_1e-4: %
	FILTCOL=`$(CUT_COL_NAME_SCRIPT) $< UNEQUAL.N.UNEQUAL.VAR.SCORR.T.TEST.NORMAL.PVAL` && (head -n 1 $< && (tail -n +2 $< | awk -F$(TAB) '((($$'$$FILTCOL'+0)==$$'$$FILTCOL')&&( $$'$$FILTCOL' < 1e-4 && $$'$$FILTCOL' != "." ))')) > $@

%.filter_TTUUSNP_lt_1e-3: %
	FILTCOL=`$(CUT_COL_NAME_SCRIPT) $< UNEQUAL.N.UNEQUAL.VAR.SCORR.T.TEST.NORMAL.PVAL` && (head -n 1 $< && (tail -n +2 $< | awk -F$(TAB) '((($$'$$FILTCOL'+0)==$$'$$FILTCOL')&&( $$'$$FILTCOL' < 1e-3 && $$'$$FILTCOL' != "." ))')) > $@

%.filter_UP_lt_1e-4: %
	(head -n 1 $< && (tail -n +2 $< | awk -F$(TAB) '((($$'`$(CUT_COL_NAME_SCRIPT) $< Uncorrected.P-value`'+0)==$$'`$(CUT_COL_NAME_SCRIPT) $< Uncorrected.P-value`')&&( $$'`$(CUT_COL_NAME_SCRIPT) $< Uncorrected.P-value`' < 1e-4 && $$'`$(CUT_COL_NAME_SCRIPT) $< Uncorrected.P-value`' != "." ))')) > $@

%.filter_UP_lt_1e-5: %
	(head -n 1 $< && (tail -n +2 $< | awk -F$(TAB) '((($$'`$(CUT_COL_NAME_SCRIPT) $< Uncorrected.P-value`'+0)==$$'`$(CUT_COL_NAME_SCRIPT) $< Uncorrected.P-value`')&&( $$'`$(CUT_COL_NAME_SCRIPT) $< Uncorrected.P-value`' < 1e-5 && $$'`$(CUT_COL_NAME_SCRIPT) $< Uncorrected.P-value`' != "." ))')) > $@

%.filter_hapmap-ceu-maf_gt_0.05: %
	(head -n 1 $< && (tail -n +2 $< | awk -F$(TAB) '((($$'`$(CUT_COL_NAME_SCRIPT) $< hapmap-ceu-maf`'+0)==$$'`$(CUT_COL_NAME_SCRIPT) $< hapmap-ceu-maf`')&&( $$'`$(CUT_COL_NAME_SCRIPT) $< hapmap-ceu-maf`' > 0.05 && $$'`$(CUT_COL_NAME_SCRIPT) $< hapmap-ceu-maf`' != "." ))')) > $@

%.filter_P_lt_1e-4: %
	(head -n 1 $< && (tail -n +2 $< | awk -F$(TAB) '((($$'`$(CUT_COL_NAME_SCRIPT) $< P-value`'+0)==$$'`$(CUT_COL_NAME_SCRIPT) $< P-value`')&&( $$'`$(CUT_COL_NAME_SCRIPT) $< P-value`' < 1e-4 && $$'`$(CUT_COL_NAME_SCRIPT) $< P-value`' != "." ))')) > $@

%.filter_P_lt_1e-5: %
	(head -n 1 $< && (tail -n +2 $< | awk -F$(TAB) '((($$'`$(CUT_COL_NAME_SCRIPT) $< P-value`'+0)==$$'`$(CUT_COL_NAME_SCRIPT) $< P-value`')&&( $$'`$(CUT_COL_NAME_SCRIPT) $< P-value`' < 1e-5 && $$'`$(CUT_COL_NAME_SCRIPT) $< P-value`' != "." ))')) > $@

%.filter_TNP_lt_5e-2: %
	(head -n 1 $< && (tail -n +2 $< | awk -F$(TAB) '((($$'`$(CUT_COL_NAME_SCRIPT) $< T.TEST.NORM.PVAL`'+0)==$$'`$(CUT_COL_NAME_SCRIPT) $< T.TEST.NORM.PVAL`')&&( $$'`$(CUT_COL_NAME_SCRIPT) $< T.TEST.NORM.PVAL`' < 5e-2 && $$'`$(CUT_COL_NAME_SCRIPT) $< T.TEST.NORM.PVAL`' != "." ))')) > $@

%.filter_TNP_lt_1e-4: %
	(head -n 1 $< && (tail -n +2 $< | awk -F$(TAB) '((($$'`$(CUT_COL_NAME_SCRIPT) $< T.TEST.NORM.PVAL`'+0)==$$'`$(CUT_COL_NAME_SCRIPT) $< T.TEST.NORM.PVAL`')&&( $$'`$(CUT_COL_NAME_SCRIPT) $< T.TEST.NORM.PVAL`' < 1e-4 && $$'`$(CUT_COL_NAME_SCRIPT) $< T.TEST.NORM.PVAL`' != "." ))')) > $@

%.filter_TagRank_eq_1: %
	(head -n 1 $< && (tail -n +2 $< | awk -F$(TAB) '((($$'`$(CUT_COL_NAME_SCRIPT) $< TagRank`'+0)==$$'`$(CUT_COL_NAME_SCRIPT) $< TagRank`')&&( $$'`$(CUT_COL_NAME_SCRIPT) $< TagRank`' == 1 ))')) > $@

%.filter_TagRank_eq_2: %
	(head -n 1 $< && (tail -n +2 $< | awk -F$(TAB) '((($$'`$(CUT_COL_NAME_SCRIPT) $< TagRank`'+0)==$$'`$(CUT_COL_NAME_SCRIPT) $< TagRank`')&&( $$'`$(CUT_COL_NAME_SCRIPT) $< TagRank`' == 2 ))')) > $@

%.filter_BMI_P-value_gt_0.01: %
	(head -n 1 $< && (tail -n +2 $< | awk -F$(TAB) '((($$'`$(CUT_COL_NAME_SCRIPT) $< BMI_P-value`'+0)==$$'`$(CUT_COL_NAME_SCRIPT) $< BMI_P-value`')&&( $$'`$(CUT_COL_NAME_SCRIPT) $< BMI_P-value`' > 0.01 ))')) > $@

%.filter_HEIGHT_P-value_gt_0.01: %
	(head -n 1 $< && (tail -n +2 $< | awk -F$(TAB) '((($$'`$(CUT_COL_NAME_SCRIPT) $< HEIGHT_P-value`'+0)==$$'`$(CUT_COL_NAME_SCRIPT) $< HEIGHT_P-value`')&&( $$'`$(CUT_COL_NAME_SCRIPT) $< HEIGHT_P-value`' > 0.01 ))')) > $@

%.filter_HEIGHT_P-value_gt_5e-3: %
	(head -n 1 $< && (tail -n +2 $< | awk -F$(TAB) '((($$'`$(CUT_COL_NAME_SCRIPT) $< HEIGHT_P-value`'+0)==$$'`$(CUT_COL_NAME_SCRIPT) $< HEIGHT_P-value`')&&( $$'`$(CUT_COL_NAME_SCRIPT) $< HEIGHT_P-value`' > 5e-3 ))')) > $@

%.filter_Weight_gt_25000: %
	(head -n 1 $< && (tail -n +2 $< | awk -F$(TAB) '((($$'`$(CUT_COL_NAME_SCRIPT) $< Weight`'+0)==$$'`$(CUT_COL_NAME_SCRIPT) $< Weight`')&&( $$'`$(CUT_COL_NAME_SCRIPT) $< Weight`' > 25000 ))')) > $@

%.loci.list: %
	tail -n +2 $< | cut -f`$(CUT_COL_NAME_SCRIPT) $< NEAREST_GENE_SYMBOLS` | sort | uniq > $@

%.gene.list: %
	tail -n +2 $< | cut -f`$(CUT_COL_NAME_SCRIPT) $< NEAREST_GENE_SYMBOLS` | perl -pi -e 's/\,/\n/g' | sort | uniq > $@

%.rsid.list: %
	tail -n +2 $< | cut -f`$(CUT_COL_NAME_SCRIPT) $< $(METAL_MARKER_H)` | perl -pi -e 's/\,/\n/g' > $@

%.annothapmapmaf: $(MERGE_COL_SCRIPT) % $(METADATA_DIR)/allele_freqs_ALL_CEU_r21a_nr.rsid-maf.txt
	$(word 1,$+) --in $(word 2,$+)  --in $(word 3,$+) --out $@ --matchcolheaders $(METAL_MARKER_H):rsid --keepall 1 --missing "."

%.annotbmiheight: $(MERGE_COL_SCRIPT) % $(METADATA_DIR)/rsid-pvalueBMI-pvalueHEIGHT.txt
	$(MERGE_COL_SCRIPT) --in $(word 2,$+) --in $(word 3,$+) --out $@ --matchcolheaders $(METAL_MARKER_H):Marker --keepall 1 --missing "."

%.annott2d: $(MERGE_COL_SCRIPT) % $(METADATA_DIR)/rsid-pvalueT2D.txt
	$(MERGE_COL_SCRIPT) --in $(word 2,$+) --in $(word 3,$+) --out $@ --matchcolheaders $(METAL_MARKER_H):Marker --keepall 1 --missing "."

%.annotttchrpos_b35: $(MERGE_COL_SCRIPT) % $(METADATA_DIR)/snp_rs_affy_ccc-chr-pos_b35.map 
	$(MERGE_COL_SCRIPT) --in $(word 2,$+) --in $(word 3,$+) --out $@ --matchcolheaders MARKER:Marker --keepall 1 --missing "."

%.annotchrpos_b35: $(MERGE_COL_SCRIPT) % $(METADATA_DIR)/snp_rs_affy_ccc-chr-pos_b35.map 
	$(MERGE_COL_SCRIPT) --in $(word 2,$+) --in $(word 3,$+) --out $@ --matchcolheaders $(METAL_MARKER_H):Marker --keepall 1 --missing "."

%.annotchrpos_b36: $(MERGE_COL_SCRIPT) % $(METADATA_DIR)/snp_rs_affy_ccc-chr-pos_b36.map 
	$(MERGE_COL_SCRIPT) --in $(word 2,$+) --in $(word 3,$+) --out $@ --matchcolheaders $(METAL_MARKER_H):Marker --keepall 1 --missing "."

%.annotgene_b36: $(METALANNOTATE_SCRIPT) $(METADATA_DIR)/snp_rs_affy_ccc-chr-pos_b36.map $(METADATA_DIR)/ucsc-hg18-knownGene-kgXref-join.name-chr-txStart-txEnd-strand-geneSymbol-refSeq-description.txt %
	$+ "NEAREST_GENE_" 0 0 0 > $@

%.annotgene_b35: $(METALANNOTATE_SCRIPT) $(METADATA_DIR)/snp_rs_affy_ccc-chr-pos_b35.map $(METADATA_DIR)/ucsc-hg17-knownGene-kgXref-join.name-chr-txStart-txEnd-strand-geneSymbol-refSeq-description.txt %
	$+ "NEAREST_GENE_" 0 0 0 > $@

%.annotgene_nonloc_b36: $(METALANNOTATE_SCRIPT) $(METADATA_DIR)/snp_rs_affy_ccc-chr-pos_b36.map $(METADATA_DIR)/ucsc-hg18-knownGene-kgXref-join.name-chr-txStart-txEnd-strand-geneSymbol-refSeq-description.txt %
	$+ "NEAREST_NON_LOC_GENE_" 1 0 0 > $@

%.annotgene_nonloc_b35: $(METALANNOTATE_SCRIPT) $(METADATA_DIR)/snp_rs_affy_ccc-chr-pos_b35.map $(METADATA_DIR)/ucsc-hg17-knownGene-kgXref-join.name-chr-txStart-txEnd-strand-geneSymbol-refSeq-description.txt %
	$+ "NEAREST_NON_LOC_GENE_" 1 0 0 > $@

%.annotgene_nonlocak_b36: $(METALANNOTATE_SCRIPT) $(METADATA_DIR)/snp_rs_affy_ccc-chr-pos_b36.map $(METADATA_DIR)/ucsc-hg18-knownGene-kgXref-join.name-chr-txStart-txEnd-strand-geneSymbol-refSeq-description.txt %
	$+ "NEAREST_NON_LOCAK_GENE_" 1 1 0 > $@

%.annotgene_nonlocak_b35: $(METALANNOTATE_SCRIPT) $(METADATA_DIR)/snp_rs_affy_ccc-chr-pos_b35.map $(METADATA_DIR)/ucsc-hg17-knownGene-kgXref-join.name-chr-txStart-txEnd-strand-geneSymbol-refSeq-description.txt %
	$+ "NEAREST_NON_LOCAK_GENE_" 1 1 0 > $@

%.annotgene_nonlocakbx_b36: $(METALANNOTATE_SCRIPT) $(METADATA_DIR)/snp_rs_affy_ccc-chr-pos_b36.map $(METADATA_DIR)/ucsc-hg18-knownGene-kgXref-join.name-chr-txStart-txEnd-strand-geneSymbol-refSeq-description.txt %
	$+ "NEAREST_NON_LOCAKBX_GENE_" 1 1 1 > $@

%.annotgene_nonlocakbx_b35: $(METALANNOTATE_SCRIPT) $(METADATA_DIR)/snp_rs_affy_ccc-chr-pos_b35.map $(METADATA_DIR)/ucsc-hg17-knownGene-kgXref-join.name-chr-txStart-txEnd-strand-geneSymbol-refSeq-description.txt %
	$+ "NEAREST_NON_LOCAKBX_GENE_" 1 1 1 > $@

%.annotgene_nonlocafakbcbx_b36: $(METALANNOTATE_AVOIDRE_SCRIPT) $(METADATA_DIR)/snp_rs_affy_ccc-chr-pos_b36.map $(METADATA_DIR)/ucsc-hg18-knownGene-kgXref-join.name-chr-txStart-txEnd-strand-geneSymbol-refSeq-description.txt %
	$+ "NEAREST_NON_LOCAKBX_GENE_" "LOC[[:digit:]]" "AF[[:digit:]]" "AK[[:digit:]]" "BC[[:digit:]]" "BX[[:digit:]]" > $@

%.annotgene_nonlocafakbcbx_b35: $(METALANNOTATE_AVOIDRE_SCRIPT) $(METADATA_DIR)/snp_rs_affy_ccc-chr-pos_b35.map $(METADATA_DIR)/ucsc-hg17-knownGene-kgXref-join.name-chr-txStart-txEnd-strand-geneSymbol-refSeq-description.txt %
	$+ "NEAREST_NON_LOCAKBX_GENE_" "LOC[[:digit:]]" "AF[[:digit:]]" "AK[[:digit:]]" "BC[[:digit:]]" "BX[[:digit:]]" > $@

%.metal.million %.labelpos.txt: $(METAL2MILLION_SCRIPT) %.metal.out $(METADATA_DIR)/snp-chr-pos.map $(METADATA_DIR)/rsid-chr-pos-wtccc.map $(METADATA_DIR)/affyid-chr-pos-wtccc.map
	$(METAL2MILLION_SCRIPT) $*.labelpos.txt $(wordlist 2, $(words $+), $+) > $*.metal.million
%.metal-stderr.million %.labelpos-stderr.txt: $(METAL2MILLION_SCRIPT) %.metal-stderr.out $(METADATA_DIR)/snp-chr-pos.map $(METADATA_DIR)/rsid-chr-pos-wtccc.map $(METADATA_DIR)/affyid-chr-pos-wtccc.map
	$(METAL2MILLION_SCRIPT) $*.labelpos-stderr.txt $(wordlist 2, $(words $+), $+) > $*.metal-stderr.million

%.assoc.qqplot.pdf %.assoc.manhattan.pdf: %.assoc $(MANHATTAN_QQ_PLOT_R_SCRIPT) 
	$(RBIN) --args title="" inputdata=$(word 1,$+) qqoutfile=$*.assoc.qqplot.pdf manhattanoutfile=$*.assoc.manhattan.pdf chrheader="CHR" posheader="BP" pvalueheader="P" pvaluethreshold="1e-5" chrsep="0" < $(MANHATTAN_QQ_PLOT_R_SCRIPT)

%.qassoc.qqplot.pdf %.qassoc.manhattan.pdf: %.qassoc $(MANHATTAN_QQ_PLOT_R_SCRIPT) 
	$(RBIN) --args title="" inputdata=$(word 1,$+) qqoutfile=$*.qassoc.qqplot.pdf manhattanoutfile=$*.qassoc.manhattan.pdf chrheader="CHR" posheader="BP" pvalueheader="P" pvaluethreshold="1e-5" chrsep="0" < $(MANHATTAN_QQ_PLOT_R_SCRIPT)

%.cmh.qqplot.pdf %.cmh.manhattan.pdf: %.cmh $(MANHATTAN_QQ_PLOT_R_SCRIPT) 
	$(RBIN) --args title="" inputdata=$(word 1,$+) qqoutfile=$*.cmh.qqplot.pdf manhattanoutfile=$*.cmh.manhattan.pdf chrheader="CHR" posheader="POS" pvalueheader="P_BD" pvaluethreshold="1e-5" chrsep="0" < $(MANHATTAN_QQ_PLOT_R_SCRIPT)

%.ttues.qqplot.pdf %.ttues.manhattan.pdf: %.annotttchrpos_b35 $(MANHATTAN_QQ_PLOT_R_SCRIPT) 
	$(RBIN) --args sep=$(TAB) title="" inputdata=$(word 1,$+) qqoutfile=$*.ttues.qqplot.pdf manhattanoutfile=$*.ttues.manhattan.pdf chrheader="CHR" posheader="POS_B35" pvalueheader="UNEQUAL.N.EQUAL.VAR.T.TEST.STUDENT.PVAL" pvaluethreshold="1e-5" chrsep="0" na="." < $(MANHATTAN_QQ_PLOT_R_SCRIPT)

%.ttueps.qqplot.pdf %.ttueps.manhattan.pdf: %.annotttchrpos_b35 $(MANHATTAN_QQ_PLOT_R_SCRIPT) 
	$(RBIN) --args sep=$(TAB) title="" inputdata=$(word 1,$+) qqoutfile=$*.ttueps.qqplot.pdf manhattanoutfile=$*.ttueps.manhattan.pdf chrheader="CHR" posheader="POS_B35" pvalueheader="UNEQUAL.N.EQUAL.VAR.PCORR.T.TEST.STUDENT.PVAL" pvaluethreshold="1e-5" chrsep="0" na="." < $(MANHATTAN_QQ_PLOT_R_SCRIPT)

%.ttuupn.qqplot.pdf %.ttuupn.manhattan.pdf: %.annotttchrpos_b35 $(MANHATTAN_QQ_PLOT_R_SCRIPT) 
	$(RBIN) --args sep=$(TAB) title="" inputdata=$(word 1,$+) qqoutfile=$*.ttuupn.qqplot.pdf manhattanoutfile=$*.ttuupn.manhattan.pdf chrheader="CHR" posheader="POS_B35" pvalueheader="UNEQUAL.N.UNEQUAL.VAR.PCORR.T.TEST.NORMAL.PVAL" pvaluethreshold="1e-5" chrsep="0" na="." < $(MANHATTAN_QQ_PLOT_R_SCRIPT)

%.ttuess.qqplot.pdf %.ttuess.manhattan.pdf: %.annotttchrpos_b35 $(MANHATTAN_QQ_PLOT_R_SCRIPT) 
	$(RBIN) --args sep=$(TAB) title="" inputdata=$(word 1,$+) qqoutfile=$*.ttuess.qqplot.pdf manhattanoutfile=$*.ttuess.manhattan.pdf chrheader="CHR" posheader="POS_B35" pvalueheader="UNEQUAL.N.EQUAL.VAR.SCORR.T.TEST.STUDENT.PVAL" pvaluethreshold="1e-5" chrsep="0" na="." < $(MANHATTAN_QQ_PLOT_R_SCRIPT)

%.ttuusn.qqplot.pdf %.ttuusn.manhattan.pdf: %.annotttchrpos_b35 $(MANHATTAN_QQ_PLOT_R_SCRIPT) 
	$(RBIN) --args sep=$(TAB) title="" inputdata=$(word 1,$+) qqoutfile=$*.ttuusn.qqplot.pdf manhattanoutfile=$*.ttuusn.manhattan.pdf chrheader="CHR" posheader="POS_B35" pvalueheader="UNEQUAL.N.UNEQUAL.VAR.SCORR.T.TEST.NORMAL.PVAL" pvaluethreshold="1e-5" chrsep="0" na="." < $(MANHATTAN_QQ_PLOT_R_SCRIPT)

%.ttuun.qqplot.pdf %.ttuun.manhattan.pdf: %.annotttchrpos_b35 $(MANHATTAN_QQ_PLOT_R_SCRIPT) 
	$(RBIN) --args sep=$(TAB) title="" inputdata=$(word 1,$+) qqoutfile=$*.ttuun.qqplot.pdf manhattanoutfile=$*.ttuun.manhattan.pdf chrheader="CHR" posheader="POS_B35" pvalueheader="UNEQUAL.N.UNEQUAL.VAR.T.TEST.NORMAL.PVAL" pvaluethreshold="1e-5" chrsep="0" na="." < $(MANHATTAN_QQ_PLOT_R_SCRIPT)

%.ttuepn.qqplot.pdf %.ttuepn.manhattan.pdf: %.annotttchrpos_b35 $(MANHATTAN_QQ_PLOT_R_SCRIPT) 
	$(RBIN) --args sep=$(TAB) title="" inputdata=$(word 1,$+) qqoutfile=$*.ttuepn.qqplot.pdf manhattanoutfile=$*.ttuepn.manhattan.pdf chrheader="CHR" posheader="POS_B35" pvalueheader="UNEQUAL.N.EQUAL.VAR.PCORR.T.TEST.NORMAL.PVAL" pvaluethreshold="1e-5" chrsep="0" na="." < $(MANHATTAN_QQ_PLOT_R_SCRIPT)

%.ttuen.qqplot.pdf %.ttuen.manhattan.pdf: %.annotttchrpos_b35 $(MANHATTAN_QQ_PLOT_R_SCRIPT) 
	$(RBIN) --args sep=$(TAB) title="" inputdata=$(word 1,$+) qqoutfile=$*.ttuen.qqplot.pdf manhattanoutfile=$*.ttuen.manhattan.pdf chrheader="CHR" posheader="POS_B35" pvalueheader="UNEQUAL.N.EQUAL.VAR.T.TEST.NORMAL.PVAL" pvaluethreshold="1e-5" chrsep="0" na="." < $(MANHATTAN_QQ_PLOT_R_SCRIPT)

%.qqplot.pdf %.manhattan.pdf: %.annotchrpos_b35 $(MANHATTAN_QQ_PLOT_R_SCRIPT) 
	$(RBIN) --args sep=$(TAB) title="" inputdata=$(word 1,$+) qqoutfile=$*.qqplot.pdf manhattanoutfile=$*.manhattan.pdf chrheader="CHR" posheader="POS_B35" pvalueheader="P.value" pvaluethreshold="1e-5" chrsep="0" na="." < $(MANHATTAN_QQ_PLOT_R_SCRIPT)

%.qqplot-sep.pdf %.manhattan-sep.pdf: %.annotchrpos_b35 $(MANHATTAN_QQ_PLOT_R_SCRIPT) 
	$(RBIN) --args sep=$(TAB) title="" inputdata=$(word 1,$+) qqoutfile=$*.qqplot.pdf manhattanoutfile=$*.manhattan.pdf chrheader="CHR" posheader="POS_B35" pvalueheader="P.value" pvaluethreshold="1e-5" chrsep="20000000" < $(MANHATTAN_QQ_PLOT_R_SCRIPT)

#%.assoc.manhattan.pdf: %.assoc $(MANHATTANPLOT_R_SCRIPT) 
#	$(RBIN) --args title="" inputdata=$(word 1,$+) outfile=$@ chrheader="CHR" posheader="BP" pvalueheader="P" pvaluethreshold="1e-5" chrsep="0" < $(MANHATTANPLOT_R_SCRIPT)
#
#%.qassoc.manhattan.pdf: %.qassoc $(MANHATTANPLOT_R_SCRIPT) 
#	$(RBIN) --args title="" inputdata=$(word 1,$+) outfile=$@ chrheader="CHR" posheader="BP" pvalueheader="P" pvaluethreshold="1e-5" chrsep="0" < $(MANHATTANPLOT_R_SCRIPT)
#
#%.cmh.manhattan.pdf: %.cmh $(MANHATTANPLOT_R_SCRIPT) 
#	$(RBIN) --args title="" inputdata=$(word 1,$+) outfile=$@ chrheader="CHR" posheader="POS" pvalueheader="P_BD" pvaluethreshold="1e-5" chrsep="0" < $(MANHATTANPLOT_R_SCRIPT)
#
#%.manhattan.pdf: %.annotchrpos_b35 $(MANHATTANPLOT_R_SCRIPT) 
#	$(RBIN) --args sep="\t" title="" inputdata=$(word 1,$+) outfile=$@ chrheader="CHR" posheader="POS_B35" pvalueheader="P.value" pvaluethreshold="1e-5" chrsep="0" < $(MANHATTANPLOT_R_SCRIPT)
#
#%.manhattan-sep.pdf: %.annotchrpos_b35 $(MANHATTANPLOT_R_SCRIPT) 
#	$(RBIN) --args sep="\t" title="" inputdata=$(word 1,$+) outfile=$@ chrheader="CHR" posheader="POS_B35" pvalueheader="P.value" pvaluethreshold="1e-5" chrsep="20000000" < $(MANHATTANPLOT_R_SCRIPT)

%.million.pdf: %.metal.million $(METAL2MILLION_R_SCRIPT) %.labelpos.txt
	if test -s $(word 1,$+); then $(RBIN) --args title="GIANT $* Metal Results" inputdata=$*.metal.million labelposfile=$*.labelpos.txt outfile=$*.million.pdf < $(METAL2MILLION_R_SCRIPT); else touch $@; fi
%.million-stderr.pdf: %.metal-stderr.million $(METAL2MILLION_R_SCRIPT) %.labelpos-stderr.txt
	if test -s $(word 1,$+); then $(RBIN) --args title="GIANT $* Metal Results" inputdata=$*.metal-stderr.million labelposfile=$*.labelpos-stderr.txt outfile=$*.million-stderr.pdf < $(METAL2MILLION_R_SCRIPT); else touch $@; fi

%.regional.pdf: $(METAL2REGIONAL_R_SCRIPT) %.metal.out %.metal.out.threshold1e-4.annotbmiheight.annotgene_b35.sortpvalue known_genes.name-chr-txStart-txEnd-strand-geneSymbol-refSeq-description.txt %.metal.out.threshold1e-4 genetic_map_ALL.txt 
	if test -s $(word 2,$+); then $(RBIN) --args title="GIANT $* Metal Results" inputdata=$(word 2,$+) sorteddata=$(word 3,$+) knowngenesfile=$(word 4,$+) recombmapfile=$(word 5,$+) outfile=$@ < $(word 1,$+); else touch $@; fi
%.regional-stderr.pdf: $(METAL2REGIONAL_R_SCRIPT) %.metal-stderr.out %.metal-stderr.out.threshold1e-4.annotbmiheight.annotgene_b35.sortpvalue known_genes.name-chr-txStart-txEnd-strand-geneSymbol-refSeq-description.txt %.metal-stderr.out.threshold1e-4 genetic_map_ALL.txt 
	if test -s $(word 2,$+); then $(RBIN) --args title="GIANT $* Metal Results" inputdata=$(word 2,$+) sorteddata=$(word 3,$+) knowngenesfile=$(word 4,$+) recombmapfile=$(word 5,$+) outfile=$@ < $(word 1,$+); else touch $@; fi

%.qqplot.pvalue.pdf: %.metal.out $(METALPLOTS_R_SCRIPT)
	if test `wc -l<$(word 1,$+)` -ne 1; then $(RBIN) --args phenotypelabel="GIANT $*" inputdata=$*.metal.out outprefix=$* outsuffix="" < $(METALPLOTS_R_SCRIPT); else touch $@; fi
%.qqplot-stderr.pvalue.pdf: %.metal-stderr.out $(METALPLOTS_R_SCRIPT)
	if test `wc -l<$(word 1,$+)` -ne 1; then $(RBIN) --args phenotypelabel="GIANT $*" inputdata=$*.metal-stderr.out outprefix=$* outsuffix="-stderr" < $(METALPLOTS_R_SCRIPT); else touch $@; fi


%.72x72.png: %.pdf
	if test -s $(word 1,$+); then $(CONVERTBIN) $< $@; else touch $@; fi

%.png: %.pdf
	if test -s $(word 1,$+); then $(GSCONVERTBIN) -q -dQUIET -dPARANOIDSAFER -dBATCH -dNOPAUSE -dNOPROMPT -dMaxBitmap=500000000 -dAlignToPixels=1 -dGridFitTT=1 -sDEVICE=pngalpha -dTextAlphaBits=4 -dGraphicsAlphaBits=4 -r150x150 -sOutputFile=$@ -f$<; else touch $@; fi

%.300x300.png: %.pdf
	if test -s $(word 1,$+); then $(GSCONVERTBIN) -q -dQUIET -dPARANOIDSAFER -dBATCH -dNOPAUSE -dNOPROMPT -dMaxBitmap=500000000 -dAlignToPixels=1 -dGridFitTT=1 -sDEVICE=pngalpha -dTextAlphaBits=4 -dGraphicsAlphaBits=4 -r300x300 -sOutputFile=$@ -f$<; else touch $@; fi

%.whitebg.png: %.png
	if test -s $(word 1,$+); then $(CONVERTBIN) $< -fill white -draw 'matte 0,0 reset' $@; else touch $@; fi

%.giant.meta.tar: %.qqplot.pvalue.png %.million.png %.metal.out %.metal.out.info %.metal-uncorrected.out.log %.metal-gcc.out.log %.metal.out.top500 %.metal.out.threshold1e-4 %.metal.out.threshold1e-4.annotbmiheight %.metal.out.threshold1e-4.annotbmiheight.annotgene_b35.sortpvalue %.metal.out.threshold1e-5.annotbmiheight.annotgene_b35.annott2d.sortpvalue.pvalindep0.5 %.combined.metal.out.threshold1e-5.annotbmiheight.annotgene_b35.annott2d.sortpvalue.pvalindep0.5 %.checkalleles.log # %.checkacrossstudies.log
	$(TARBIN) -c -f $@ $+
%.giant.meta-stderr.tar: %.qqplot-stderr.pvalue.png %.million-stderr.png %.metal-stderr.out %.metal-stderr.out.info %.metal-stderr-uncorrected.out.log %.metal-stderr-gcc.out.log %.metal-stderr.out.top500 %.metal-stderr.out.threshold1e-4 %.metal-stderr.out.threshold1e-4.annotbmiheight %.metal-stderr.out.threshold1e-4.annotbmiheight.annotgene_b35.sortpvalue %.metal-stderr.out.threshold1e-5.annotbmiheight.annotgene_b35.annott2d.sortpvalue.pvalindep0.5 %.combined.metal-stderr.out.threshold1e-5.annotbmiheight.annotgene_b35.yannott2d.sortpvalue.pvalindep0.5 %.checkalleles.log # %.checkacrossstudies.log
	$(TARBIN) -c -f $@ $+


%.gz: %
	$(GZIPBIN) -c $< > $@

%.giant.meta.tar.gz: %.giant.meta.tar
	$(GZIPBIN) -c $< > $@
%.giant.meta-stderr.tar.gz: %.giant.meta-stderr.tar
	$(GZIPBIN) -c $< > $@


%.giant.meta.tar.bz2: %.giant.meta.tar
	$(BZIP2BIN) -k $<
%.giant.meta-stderr.tar.bz2: %.giant.meta-stderr.tar
	$(BZIP2BIN) -k $<



%.giant-association-results.annot_hapmap_alleles_freqs.txt: $(MERGE_COL_SCRIPT) %.giant-association-results.txt hapmap_genotypes_allele_freqs_ALL_CEU_r21a_nr_fwd.no-MNP-INDEL.rsid-snpalleles-ra-raf-oa-oaf.txt
	$(MERGE_COL_SCRIPT) --in $(word 2,$+) --in $(word 3,$+) --out $@ --matchcols MarkerName:rs# --colprefix "" --colprefix "hapmap." --keepall 1 --missing "."

%.freqcheck %.freqhist.png %.badalleles: %.giant-association-results.annot_hapmap_alleles_freqs.txt
	$(RBIN) --args freqcheckoutfile=$*.freqcheck freqhistoutpng=$*.freqhist.png badalleleoutfile=$*.badalleles inputdata=$(word 1,$+) < $(MOAMA_HAPMAP_STRAND_CHECK_R_SCRIPT)

