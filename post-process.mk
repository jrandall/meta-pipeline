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

METAL_MARKER_H=MarkerName

################################################################################
# Append CHR/POS
################################################################################
%.add_chrpos_b35: $(MERGE_COL_SCRIPT) % snp_rs_affy_ccc-chr-pos_b35.map 
	$(word 1,$+)  --tmpdir="$(TMP_DIR)" --in $(word 2,$+) --in $(word 3,$+) --out $@ --matchcolheaders $(METAL_MARKER_H):Marker --keepall 1 --missing "."

%.add_chrpos_b36: $(MERGE_COL_SCRIPT) % dbsnp.MarkerName-CHR-POS_B36-Genetic_Rate-Genetic_Map.txt
	$(word 1,$+)  --tmpdir="$(TMP_DIR)" --in $(word 2,$+) --in $(word 3,$+) --out $@ --matchcolheaders $(METAL_MARKER_H):MarkerName --keepall 1 --missing "."

%.chr: dbsnp.MarkerName-CHR-POS_B36-Genetic_Rate-Genetic_Map.txt
	awk '$$$$1==$* {print $$$$2;}' $< | head -n 1 > $@

################################################################################
# Change CHR X and Y to 23 and 24
################################################################################
%.recode_chr_XY_23_24: $(REMAP_COL_SCRIPT) % chrXY-23-24.map
	$(word 1,$+) --in="$(word 2,$+)" --map="$(word 3,$+)" --out="$@" --colnum=`$(CUT_COL_NAME_SCRIPT) $(word 2,$+) CHR` --log="$@.log"



################################################################################
# Create gene annotation of SNP list
################################################################################
%.annotgene_non_loc_af_ak_bc_bx_b36: $(ANNOTATE_NEAREST_GENE_AVOIDRE_SCRIPT) % ucsc-hg18-knownGene-kgXref-join.name-chr-txStart-txEnd-strand-geneSymbol-refSeq-description.txt
	$(word 1,$+) --in="$(word 2,$+)" --knowngenes="$(word 3,$+)" --outheaderprefix="NEAREST_NON_LOC_AF_AK_BC_BX_GENE_" --avoidre="LOC[[:digit:]]" --avoidre="AF[[:digit:]]" --avoidre="AK[[:digit:]]" --avoidre="BC[[:digit:]]" --avoidre="BX[[:digit:]]" --out="$@" --missing="."

%.add_gene_non_loc_af_ak_bc_bx_b36: $(MERGE_COL_SCRIPT) % dbsnp.MarkerName-CHR-POS_B36.txt.annotgene_non_loc_af_ak_bc_bx_b36
	$(word 1,$+)  --tmpdir="$(TMP_DIR)" --in $(word 2,$+) --in $(word 3,$+) --out $@ --matchcolheaders $(METAL_MARKER_H):MarkerName --keepall 1 --missing "."

################################################################################
# Process command-line goals to determine numeric options 
################################################################################

################################################################################
# this is the full list of params, including both those that require sorted input 
# and those that don't
################################################################################
PARAMDEFS += sort[header] sortint[header][dummy] filternum[header][comparison][value] filterstr[header][comparison][value] column_values[header] pull_cols[colorder] only_locus[marker][threshold] indrank[ldsource][sort_header][threshold] top[sort_header][topnum] gw[header] indrankgd[sort_header][threshold][headerprefix] add_logradius[pcol1header][pcol2header][outheader] greatercol[pcol1header][pcol2header][outheader] lessercol[pcol1header][pcol2header][outheader]

# todo: make params pass vars back with signature so that two functions can have the same base name but different numbers of params

################################################################################
# some parameters require sorted input, so in addition to normal processing, 
# we need to make an additional sort routine called e.g. indrank_sort[header] 
# corresponding to each of these parameters, using sort_header as the header 
# for sorting (to avoid rule recursion if sorted output is also requested)
# 
# here we also support creation of other arbitrary requirements that will be 
# expanded by the paramdefs processing script and added to the paramdefs goals
################################################################################
PARAMDEF_MAPPINGS += indrank[][_header_][]:sortint[_header_][INDRANK] top[_header_][]:sortint[_header_][TOP] gw[_header_]:sortint[_header_][GW] indrankgd[_header_][][]:sortint[_header_][INDRANKGD] indrank[][][_threshold_]:filternum[foo][foo][_threshold_] gw[_header_]:filternum[_header_][lt][5e-8] 

################################################################################
# Calculate -log10 cartesian distance for two p-value columns (such as for "log-radius" filtering for het and gender)
################################################################################
define paramdefs_ADD_LOGRADIUS_rules # PCOL1HEADER PCOL2HEADER OUTHEADER
%.add_logradius[$(1)][$(2)][$(3)]: %
	awk 'BEGIN {FS="\t"; OFS="\t"; CONVFMT="%.18g"; OFMT="%.18g";} NR==1 {split($$$$0, tmp); for(i = 1; i <= NF; i++) headercol[tmp[i]] = i; newcol = NF+1; $$$$newcol="$(3)"; print $$$$0;} ((NR!=1) && ($$$$headercol["$(1)"] != ".") && ($$$$headercol["$(2)"] != ".")) {$$$$newcol=sqrt( (-log($$$$headercol["$(1)"])/log(10))^2 + (-log($$$$headercol["$(2)"])/log(10))^2 ); print $$$$0;} ((NR!=1) && ($$$$headercol["$(1)"] == ".") || ($$$$headercol["$(2)"] == ".")) {$$$$newcol="."; print $$$$0;}' $$< > $$@
endef # paramdefs_ADD_LOGRADIUS_rules
$(foreach pcol1header,$(paramdefs_add_logradius_pcol1header_values),$(foreach pcol2header,$(paramdefs_add_logradius_pcol2header_values),$(foreach outheader,$(paramdefs_add_logradius_outheader_values),$(eval $(call paramdefs_ADD_LOGRADIUS_rules,$(pcol1header),$(pcol2header),$(outheader))))))

################################################################################
# Invert column outheader to 1/inheader (for sorting)
################################################################################
PARAMDEFS += invert_column[inheader][outheader]
PARAMDEF_MAPPINGS += 
define paramdefs_INVERT_COLUMN_rules # INHEADER OUTHEADER
%.invert_column[$(1)][$(2)]: %
	awk 'BEGIN {FS="\t"; OFS="\t"; CONVFMT="%.18g"; OFMT="%.18g";} NR==1 {split($$$$0, tmp); for(i = 1; i <= NF; i++) headercol[tmp[i]] = i; newcol = NF+1; $$$$newcol="$(2)"; print $$$$0;} ((NR!=1) && ($$$$headercol["$(1)"] != ".")) {$$$$newcol=1/$$$$headercol["$(1)"]; print $$$$0;} ((NR!=1) && ($$$$headercol["$(1)"] == ".")) {$$$$newcol="."; print $$$$0;}' $$< > $$@
endef # paramdefs_INVERT_COLUMN_rules
$(foreach inheader,$(paramdefs_invert_column_inheader_values),$(foreach outheader,$(paramdefs_invert_column_outheader_values),$(eval $(call paramdefs_INVERT_COLUMN_rules,$(inheader),$(outheader)))))

################################################################################
# Take the greater value of two columns
################################################################################
define paramdefs_GREATERCOL_rules # PCOL1HEADER PCOL2HEADER OUTHEADER
%.greatercol[$(1)][$(2)][$(3)]: %
	awk 'BEGIN {FS="\t"; OFS="\t"; CONVFMT="%.18g"; OFMT="%.18g";} NR==1 {split($$$$0, tmp); for(i = 1; i <= NF; i++) headercol[tmp[i]] = i; newcol = NF+1; $$$$newcol="$(3)"; print $$$$0;} NR!=1 {if($$$$headercol["$(1)"]>$$$$headercol["$(2)"]) $$$$newcol=$$$$headercol["$(1)"]; else $$$$newcol=$$$$headercol["$(2)"]; print $$$$0;}' $$< > $$@
endef # paramdefs_GREATERCOL_rules
$(foreach pcol1header,$(paramdefs_greatercol_pcol1header_values),$(foreach pcol2header,$(paramdefs_greatercol_pcol2header_values),$(foreach outheader,$(paramdefs_greatercol_outheader_values),$(eval $(call paramdefs_GREATERCOL_rules,$(pcol1header),$(pcol2header),$(outheader))))))

################################################################################
# Take the lesser value of two columns
################################################################################
define paramdefs_LESSERCOL_rules # PCOL1HEADER PCOL2HEADER OUTHEADER
%.lessercol[$(1)][$(2)][$(3)]: %
	awk 'BEGIN {FS="\t"; OFS="\t"; CONVFMT="%.18g"; OFMT="%.18g";} NR==1 {split($$$$0, tmp); for(i = 1; i <= NF; i++) headercol[tmp[i]] = i; newcol = NF+1; $$$$newcol="$(3)"; print $$$$0;} NR!=1 {if($$$$headercol["$(1)"]<$$$$headercol["$(2)"]) $$$$newcol=$$$$headercol["$(1)"]; else $$$$newcol=$$$$headercol["$(2)"]; print $$$$0;}' $$< > $$@
endef # paramdefs_LESSERCOL_rules
$(foreach pcol1header,$(paramdefs_lessercol_pcol1header_values),$(foreach pcol2header,$(paramdefs_lessercol_pcol2header_values),$(foreach outheader,$(paramdefs_lessercol_outheader_values),$(eval $(call paramdefs_LESSERCOL_rules,$(pcol1header),$(pcol2header),$(outheader))))))


################################################################################
# Sort file with header on specified column
################################################################################
define paramdefs_SORT_rules # HEADER
%.sort[$(1)]: %
	(head -n 1 $$< && (tail -n +2 $$< | sort -t $(TAB) -g -k `$(CUT_COL_NAME_SCRIPT) $$< "$(1)"`)) > $$@
endef # paramdefs_SORT_rules
$(foreach header,$(paramdefs_sort_header_values),$(eval $(call paramdefs_SORT_rules,$(header))))

################################################################################
# Sort file with header on specified column - internal version 
# (not to be used as an external goal)
################################################################################
define paramdefs_SORTINT_rules # HEADER DUMMY
%.sortint[$(1)][$(2)]: %
	(head -n 1 $$< && (tail -n +2 $$< | sort -t $(TAB) -g -k `$(CUT_COL_NAME_SCRIPT) $$< "$(1)"`)) > $$@
endef # paramdefs_SORTINT_rules
$(foreach header,$(paramdefs_sortint_header_values),$(foreach dummy,$(paramdefs_sortint_dummy_values),$(eval $(call paramdefs_SORTINT_rules,$(header),$(dummy)))))


################################################################################
# Limit to top hits 
################################################################################
define paramdefs_TOP_rules # SORT_HEADER TOPNUM
%.top[$(1)][$(2)]: %.top_sort[$(1)]
	head -n `echo "$(2)+1" | bc -l` $$< > $$@
endef # paramdefs_TOP_rules
$(foreach sort_header,$(paramdefs_top_sort_header_values),$(foreach topnum,$(paramdefs_top_topnum_values),$(eval $(call paramdefs_TOP_rules,$(sort_header),$(topnum)))))

################################################################################
# Link to shorter name for "Genome-wide" results -- sorted and filtered on header < 5e-8
################################################################################
define paramdefs_GW_rules # HEADER 
%.gw[$(1)]: %.gw_sort[$(1)].filternum[$(1)][lt][5e-8]
	ln -fs $$< $$@
endef # paramdefs_GW_rules
$(foreach header,$(paramdefs_gw_header_values),$(eval $(call paramdefs_GW_rules,$(header))))


################################################################################
# "Independentize" based on HapMap LD &/or distance
################################################################################
# TODO: fix this so the high memory version cannot possibly run in parallel!
# it is a machine killer!
define paramdefs_INDRANK_rules # LDSOURCE SORT_HEADER THRESHOLD
%.indrank[$(1)][$(2)][$(3)]: $(RSQ_INDEPENDENT_RANK) %.indrank_sort[$(2)] $(1)_ld_ALL.rsid1-rsid2-rsq.txt.filternum[rsq][gt][$(3)]
	$$(word 1,$$+) --metalfile $$(word 2,$$+) --rsqfile $$(word 3,$$+) --cutoff=$(3) --outfile $$*.indrank[$(1)][$(2)][$(3)] --verbose >& $$*.indrank[$(1)][$(2)][$(3)].log
endef # paramdefs_INDRANK_rules
$(foreach ldsource,$(paramdefs_indrank_ldsource_values),$(foreach sort_header,$(paramdefs_indrank_sort_header_values),$(foreach threshold,$(paramdefs_indrank_threshold_values),$(eval $(call paramdefs_INDRANK_rules,$(ldsource),$(sort_header),$(threshold))))))

#$(info have paramdefs_indrankgd_sort_header_values $(paramdefs_indrankgd_sort_header_values) and paramdefs_indrankgd_threshold_values $(paramdefs_indrankgd_threshold_values))
################################################################################
# "Independentize" based on Genetic Distance
################################################################################
define paramdefs_INDRANKGD_rules # SORT_HEADER THRESHOLD HEADERPREFIX
# $(in#fo evaluating macro paramdefs_INDRANKGD_rules $(1) $(2))
%.indrankgd[$(1)][$(2)][$(3)]: $(GD_INDEPENDENT_RANK) %.sortint[$(1)][INDRANKGD] 
	$$(word 1,$$+) --metalfile $$(word 2,$$+) --cutoff=$(2) --chrheader="CHR" --gmheader="Genetic_Map_cM_rel22" --outfile $$*.indrankgd[$(1)][$(2)][$(3)] --taglociheader "$(3)Loci" --tagrankheader "$(3)Rank" --tagdistheader "$(3)GD" --verbose >& $$*.indrankgd[$(1)][$(2)][$(3)].log
endef # paramdefs_INDRANKGD_rules
$(foreach sort_header,$(paramdefs_indrankgd_sort_header_values),$(foreach threshold,$(paramdefs_indrankgd_threshold_values),$(foreach headerprefix,$(paramdefs_indrankgd_headerprefix_values),$(eval $(call paramdefs_INDRANKGD_rules,$(sort_header),$(threshold),$(headerprefix))))))

################################################################################
# Filters (numeric) 
# FIXME don't call CUT_COL_NAME multiple times (old makefile has example with shell variable)
################################################################################
define paramdefs_FILTERNUM_rules # HEADER COMPARISON VALUE
%.filternum[$(1)][$(2)][$(3)]: %
	awk 'BEGIN {FS="\t"; OFS="\t"; CONVFMT="%.18g"; OFMT="%.18g";} NR==1 {split($$$$0, tmp); for(i = 1; i <= NF; i++) headercol[tmp[i]] = i; print $$$$0;} (NR!=1 && ((($$$$headercol["$(1)"]+0)==$$$$headercol["$(1)"]) && ($$$$headercol["$(1)"] $$(subst ne,!=,$$(subst eq,==,$$(subst lt,<,$$(subst gt,>,$$(subst lte,<=,$$(subst gte,>=,$(2))))))) $(3)) && ($$$$headercol["$(1)"] != "."))) { print $$$$0; }' $$< > $$@
#%.filternum[$(1)][$(2)][$(3)]: %
#	(head -n 1 $$< && (tail -n +2 $$< | awk -F$(TAB) '((($$$$'`$(CUT_COL_NAME_SCRIPT) $$< $(1)`'+0)==$$$$'`$(CUT_COL_NAME_SCRIPT) $$< $(1)`')&&( $$$$'`$(CUT_COL_NAME_SCRIPT) $$< $(1)`' $$(subst ne,!=,$$(subst eq,==,$$(subst lt,<,$$(subst gt,>,$$(subst lte,<=,$$(subst gte,>=,$(2))))))) $(3) && $$$$'`$(CUT_COL_NAME_SCRIPT) $$< $(1)`' != "." ))')) > $$@

endef # paramdefs_FILTERNUM_rules
$(foreach header,$(paramdefs_filternum_header_values),$(foreach comparison,$(paramdefs_filternum_comparison_values),$(foreach value,$(paramdefs_filternum_value_values),$(eval $(call paramdefs_FILTERNUM_rules,$(header),$(comparison),$(value))))))

################################################################################
# Filters (string)
# FIXME don't call CUT_COL_NAME multiple times (old makefile has example with shell variable)
################################################################################
define paramdefs_FILTERSTR_rules # HEADER COMPARISON VALUE
%.filterstr[$(1)][$(2)][$(3)]: %
	(head -n 1 $$< && (tail -n +2 $$< | awk -F$(TAB) '$$$$'`$(CUT_COL_NAME_SCRIPT) $$< $(1)`' $$(subst ne,!=,$$(subst eq,==,$$(subst lt,<,$$(subst gt,>,$$(subst lte,<=,$$(subst gte,>=,$(2))))))) "$(3)"')) > $$@
endef # paramdefs_FILTERSTR_rules
$(foreach header,$(paramdefs_filterstr_header_values),$(foreach comparison,$(paramdefs_filterstr_comparison_values),$(foreach value,$(paramdefs_filterstr_value_values),$(eval $(call paramdefs_FILTERSTR_rules,$(header),$(comparison),$(value))))))

################################################################################
# Pull Columns
################################################################################
define paramdefs_PULL_COLS_rules # COLORDER
%.pull_cols[$(1)]: % $(REORDER_COLS_SCRIPT)
	$$(word 2,$$+) --in $$(word 1,$$+) --out $$@ --onlylisted 1 --relabelsep '_-_' --colorder "$(1)"
endef # paramdefs_PULL_COLS_rules
$(foreach colorder,$(paramdefs_pull_cols_colorder_values),$(eval $(call paramdefs_PULL_COLS_rules,$(colorder))))

%.gender-results: % $(REORDER_COLS_SCRIPT)
	$(word 2,$+) --in $(word 1,$+) --out $@ --onlylisted 1 --relabelsep ':' --colorder "MarkerName,MEN.GCIn.Allele1:MEN.Effect_allele,MEN.GCIn.Allele2:MEN.Other_allele,WOMEN.GCIn.Allele1:WOMEN.Effect_allele,WOMEN.GCIn.Allele2:WOMEN.Other_allele,MEN.GCIn.Freq1:MEN.EAF,WOMEN.GCIn.Freq1:WOMEN.EAF,MEN.GCIn.N:MEN.N,WOMEN.GCIn.N:WOMEN.N,MEN.GCIn.Effect:MEN.Effect,WOMEN.GCIn.Effect:WOMEN.Effect,MEN.GCIn.StdErr,WOMEN.GCIn.StdErr,MEN.GCIn.P-value,WOMEN.GCIn.P-value,MENvsWOMEN.GCIn.UNEQUAL.N.UNEQUAL.VAR.SCORR.T.TEST.NORMAL.PVAL:MENvsWOMEN.P-value,MEN.GCIn.GCOut.StdErr,WOMEN.GCIn.GCOut.StdErr,MEN.GCIn.GCOut.P-value,WOMEN.GCIn.GCOut.P-value,MENvsWOMEN.GCIn.GCOut.UNEQUAL.N.UNEQUAL.VAR.SCORR.T.TEST.NORMAL.PVAL:MENvsWOMEN.GCIn.GCOut.P-value"


################################################################################
# Rules to put metal output back into input file format
################################################################################
%.metal2in: % $(REORDER_COLS_SCRIPT)
	$(word 2,$+) --in $(word 1,$+) --out $@ --onlylisted 1 --relabelsep ':' --colorder "MarkerName,N,Allele1:Effect_allele,Allele2:Other_allele,Freq1:EAF,Effect:BETA,StdErr:SE,P-value:P"

################################################################################
# Filter only SNPs genetically "near" this one (locus)
################################################################################
define paramdefs_ONLY_LOCUS_rules # MARKER THRESHOLD
%.only_locus[$(1)][$(2)]: % 
	GPT=$(2) && RECORD=`awk -F$$(subst `,\`,$(TAB)) '$$$$1=="'$(1)'"' $$<` && CHR=`echo $$$$RECORD | cut -f16 -d" "` && GPOS=`echo $$$$RECORD | cut -f19 -d" "`  && awk -F$(TAB) 'NR==1 || ($$$$16=='$$$$CHR' && $$$$19 >= '$$$$GPOS'-'$$$$GPT' && $$$$19 <='$$$$GPOS'+'$$$$GPT')' $$<  > $$@
endef # paramdefs_ONLY_LOCUS_rules
$(foreach marker,$(paramdefs_only_locus_marker_values),$(foreach threshold,$(paramdefs_only_locus_threshold_values),$(eval $(call paramdefs_ONLY_LOCUS_rules,$(marker),$(threshold)))))


################################################################################
# Get list of lead SNPs at a particular significance level and GD cutoff
################################################################################
PARAMDEFS += leadsnplist[pheader][pthreshold][gdthreshold]
PARAMDEF_MAPPINGS += leadsnplist[_pheader_][_pthreshold_][]:filternum[_pheader_][lt][_pthreshold_] leadsnplist[_pheader_][][_gdthreshold_]:indrankgd[_pheader_][_gdthreshold_] leadsnplist[][][]:filternum[TagRank][eq][1] leadsnplist[][][]:pull_cols[MarkerName]
define paramdefs_LEADSNPLIST_rules # PHEADER PTHRESHOLD GDTHRESHOLD
%.leadsnplist[$(1)][$(2)][$(3)]: %.add_chrpos_b36.recode_chr_XY_23_24.filternum[$(1)][lt][$(2)].indrankgd[$(1)][$(3)].filternum[TagRank][eq][1].pull_cols[MarkerName]
	cp $$< $$@
endef # paramdefs_LEADSNPLIST_rules
$(foreach pheader,$(paramdefs_leadsnplist_pheader_values),$(foreach pthreshold,$(paramdefs_leadsnplist_phtreshold_values),$(foreach gdthreshold,$(paramdefs_leadsnplist_gdthreshold_values),$(eval $(call paramdefs_LEADSNPLIST_rules,$(pheader),$(pthreshold),$(gdthreshold))))))

#define paramdefs_FILTERAWK_rules # RULES
#%.filterawk[$(1)].awk: %
#	(echo 'BEGIN { FS="\t"; OFS="\t"; ' && ((head -n 1 $$< | perl -pi -e 's/\t/\n/g' | nl -w1 -s" ") | perl -pi -e 's/(.*?)\ (.*)/\2\=\1/g' | perl -pi -e 's/\n/; /g' | perl -pi -e 's/\./\_/g') && echo '} ' && (echo "$(1)" | perl -pi -e 's/\((.*?)_lt_(.*?)\)/\(\$\1\<\2\)/g; s/\((.*?)_lte_(.*?)\)/\(\$\1\<=\2\)/g; s/\((.*?)_gt_(.*?)\)/\(\$\1\>\2\)/g; s/\((.*?)_gte_(.*?)\)/\(\$\1\>\=\2\)/g; s/\((.*?)_eq_(.*?)\)/\(\$\1\=\=\2\)/g; s/\((.*?)_ne_(.*?)\)/\(\$\1\!\=\2\)/g; s/_and_/\&\&/g; s/_or_/\|\|/g; ') && echo ' { print $$$$0; }') > "$$@"
#%.filterawk[$(1)]: % %.filterawk[$(1)].awk
#	(head -n 1 $$(word 1,$$+) && (tail -q -n +2 $$(word 1,$$+) | awk -f "$$(word 2,$$+)")) > "$$@"
#endef # paramdefs_FILTERAWK_rules
#$(foreach rules,$(paramdefs_filterawk_rules_values),$(eval $(call paramdefs_FILTERAWK_rules,$(rules))))



################################################################################
# Get a list of unique column values
################################################################################
define paramdefs_COLUMN_VALUES_rules # HEADER
%.column_values[$(1)]: %
	tail -n +2 $$< | cut -d$(TAB) -f`$(CUT_COL_NAME_SCRIPT) $$< $(1)` | sort | uniq > $$@
endef # paramdefs_COLUMN_VALUES_rules
$(foreach header,$(paramdefs_column_values_header_values),$(eval $(call paramdefs_COLUMN_VALUES_rules,$(header))))



################################################################################
# Define analysis-specific rules
################################################################################
define paramdefs_ANALYSIS_rules # ANALYSIS
################################################################################
# Add GC-correted input data (for forest plots, etc)
################################################################################
$(1).%.add_input_gcc-se: $(MERGE_COL_LOWMEM_SCRIPT) $(1).% $(foreach result,$($(1)_INPUT),$(patsubst %.txt,%.add_gcc-se.txt,$(result)))
	$$(word 1,$$+) --tmpdir="$(TMP_DIR)" --keepall 1 --missing "." --in $$(word 2,$$+) --colprefix "" $$(foreach inputfile,$$(wordlist 3, $$(words $$+), $$+), --in $$(inputfile) --colprefix `echo $$(notdir $$(inputfile))|$(SED_BIN) 's/\.giant-association-results.*//'`. ) --out $$@ --matchcolheaders $(METAL_MARKER_H):$(MARKERLABEL)
endef # paramdefs_ANALYSIS_rules

################################################################################
# Evaluate analysis specific rules
################################################################################
$(foreach analysis,$(ANALYSES),$(eval $(call paramdefs_ANALYSIS_rules,$(analysis))))



