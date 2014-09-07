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
# Process input files through cleaning script, compare to reference frequencies 
################################################################################
define CLEAN_rules # extension
%.giant-association-results.cleaned.txt.gz %.giant-association-results.cleaned.excluded.txt.gz %.giant-association-results.cleaned.report.txt %.giant-association-results.cleaned.warnings.txt.gz: $(MOAMA_CLEAN_SCRIPT) $(DETECT_SEP_SCRIPT) %.giant-association-results$(1)  hapmap_rel24_CEU_allele_freqs_ALL.rsid-ref_allele-nonref_allele-ref_freq.txt  hapmap_rel21a_CEU_allele_freqs_ALL.rsid-ref_allele-nonref_allele-ref_freq.txt markerlist.list
	$$(word 1,$$+) --insep="`$$(word 2,$$+) --in=$$(word 3,$$+)`" --in="$$(word 3,$$+)" --referencefile="$$(word 4,$$+)" --referencesep="\t" --referencefile="$$(word 5,$$+)" --referencesep="\t" --referencefile="$$(word 6,$$+)" --referencesep="\t" --out="$$*.giant-association-results.cleaned.txt.gz" --outmissing="." --reportout="$$*.giant-association-results.cleaned.report.txt" --logfile="$$*.giant-association-results.cleaned.log" --excludeout="$$*.giant-association-results.cleaned.excluded.txt.gz" --warnout="$$*.giant-association-results.cleaned.warnings.txt.gz"
#%.giant-association-results.reformat.txt: $(MOAMA_REFORMAT_SCRIPT) $(DETECT_SEP_SCRIPT) %.giant-association-results$(1)
#	$$(word 1,$$+) --in="$$(word 3,$$+)" --insep="`$$(word 2,$$+) --in=$$(word 3,$$+)`" --out="$$*.giant-association-results.reformat.txt" --outmissing="." --logfile="$$*.giant-association-results.reformat.log"
endef
#$(foreach extension,.txt .txt.gz .zip .csv .csv.gz .tsv .tsv.gz .txt.zip,$(eval $(call CLEAN_rules,$(extension))))
$(foreach extension,.txt .txt.gz .txt.bz2 .txt.Z,$(eval $(call CLEAN_rules,$(extension))))


################################################################################
# Calculate MAF from EAF and MAC (Minor Allele Count) from MAF * N
################################################################################
%.giant-association-results.cleaned.add_maf_mac.txt: %.giant-association-results.cleaned.txt.gz
	zcat $< | $(AWKBIN) 'BEGIN {FS="\t"; OFS="\t"; CONVFMT="%.18g"; OFMT="%.18g";}  NR==1 {print $$0,"MAF","MAC"} NR!=1 {if ($$6<=0.5) $$13=$$6; else $$13=1-$$6; $$14=$$3*$$13; print $$0;}' > $@

%.giant-association-results.reformat.add_maf_mac.txt: %.giant-association-results.reformat.txt
	cat $< | $(AWKBIN) 'BEGIN {FS="\t"; OFS="\t"; CONVFMT="%.18g"; OFMT="%.18g";}  NR==1 {print $$0,"MAF","MAC"} NR!=1 {if ($$6<=0.5) $$13=$$6; else $$13=1-$$6; $$14=$$3*$$13; print $$0;}' > $@


################################################################################
# Change MarkerName (rsid) from HapMap b35 to b36 (r21 -> r23)
################################################################################
%.b35_rsid_to_b36.txt: $(REMAP_COL_SCRIPT) %.txt rsmerge_b35_b36_lookup.tsv
	$(word 1,$+) --in="$(word 2,$+)" --map="$(word 3,$+)" --out="$@" --colnum=1 --log="$@.log"

################################################################################
# Rules to make scripts for GC-correction of input files (STDERR only)
################################################################################
%.gcc-se.script: $(MAKE_METAL_SCRIPT) %.txt
	$(word 1,$+) --scheme="se" --out="$*" --outsuffix=".gcc-se.txt" --in $(word 2,$+) --markerlabel=MarkerName --ealabel=Effect_allele --oalabel=Other_allele --effectlabel=BETA --weightlabel=N --pvaluelabel=P --stderrlabel=SE --freqlabel=EAF > $@

################################################################################
# Rules to perform GC-correction of input files (STDERR only)
################################################################################
%.gcc-se.txt: %.gcc-se.script %.txt
	(($(METAL_BIN) < $(word 1,$+)) >& $*.gcc-se.log) && \
	mv $*1.gcc-se.txt $*.gcc-se.txt && \
	mv $*1.gcc-se.txt.info $*.gcc-se.txt.info

################################################################################
# Add GC-correction data to existing input files
################################################################################
%.add_gcc-se.txt: $(MERGE_COL_SCRIPT) %.txt %.gcc-se.txt 
	$(word 1,$+)  --tmpdir="$(TMP_DIR)" --in $(word 2,$+) --colprefix "" --in $(word 3,$+) --colprefix "gcc-se." --out $@ --matchcolheaders $(MARKERLABEL):$(MARKERLABEL) --keepall 1 --missing "."
