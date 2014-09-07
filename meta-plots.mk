#######################################################################################
# Copyright 2009 Joshua Randall
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

# PDF to PNG Conversion
include $(PIPELINE_HOME)/pdf2png.mk

# TODO: split qq plot and manhattan plot into separate scripts?
# TODO: allow resolution from the command line

R_GRAPHICS_OUTPUT=png

%.qqplot_assoc.$(R_GRAPHICS_OUTPUT) %.manhattan_assoc.$(R_GRAPHICS_OUTPUT): %.add_gene_non_loc_af_ak_bc_bx_b36 $(MANHATTAN_QQ_PLOT_R_SCRIPT) 
	$(RBIN) --args title="Association P" inputdata=$(word 1,$+) qq$(R_GRAPHICS_OUTPUT)outfile="$*.qqplot_assoc.$(R_GRAPHICS_OUTPUT)" pvalueheader="P.value" manhattan$(R_GRAPHICS_OUTPUT)outfile="$*.manhattan_assoc.$(R_GRAPHICS_OUTPUT)" chrheader="CHR" posheader="POS_B36" pvaluethreshold="5e-8" chrsep="0" na="." res="300" sep="TAB" < $(word 2,$+)

%.qqplot_het.$(R_GRAPHICS_OUTPUT) %.manhattan_het.$(R_GRAPHICS_OUTPUT): %.add_gene_non_loc_af_ak_bc_bx_b36 $(MANHATTAN_QQ_PLOT_R_SCRIPT) 
	$(RBIN) --args title="Heterogeneity P" inputdata=$(word 1,$+) qq$(R_GRAPHICS_OUTPUT)outfile=$*.qqplot_het.$(R_GRAPHICS_OUTPUT) pvalueheader="HetPVal" manhattan$(R_GRAPHICS_OUTPUT)outfile="$*.manhattan_het.$(R_GRAPHICS_OUTPUT)" chrheader="CHR" posheader="POS_B36" pvaluethreshold="5e-8" chrsep="0" na="." res="300" sep="TAB" < $(word 2,$+)

%.qqplot_mvw.$(R_GRAPHICS_OUTPUT) %.manhattan_mvw.$(R_GRAPHICS_OUTPUT): %.add_gene_non_loc_af_ak_bc_bx_b36 $(MANHATTAN_QQ_PLOT_R_SCRIPT) 
	$(RBIN) --args title="Gender Heterogeneity P" inputdata=$(word 1,$+) qq$(R_GRAPHICS_OUTPUT)outfile="$*.qqplot_assoc.$(R_GRAPHICS_OUTPUT)" pvalueheader="MENvsWOMEN.P.value" manhattan$(R_GRAPHICS_OUTPUT)outfile="$*.manhattan_assoc.$(R_GRAPHICS_OUTPUT)" chrheader="CHR" posheader="POS_B36" pvaluethreshold="5e-8" chrsep="0" na="." res="300" sep="TAB" < $(word 2,$+)

%.eaf_vs_assoc.$(R_GRAPHICS_OUTPUT): % $(XLOGY_PLOT_R_SCRIPT) 
	$(RBIN) --args title="EAF vs Association" inputdata=$(word 1,$+) $(R_GRAPHICS_OUTPUT)outfile=$*.eaf_vs_assoc.$(R_GRAPHICS_OUTPUT) xheader="Freq1" yheader="P.value" res="300" < $(word 2,$+)

%.eaf_vs_het.$(R_GRAPHICS_OUTPUT): % $(XLOGY_PLOT_R_SCRIPT) 
	$(RBIN) --args title="EAF vs Heterogeneity" inputdata=$(word 1,$+) $(R_GRAPHICS_OUTPUT)outfile=$*.eaf_vs_het.$(R_GRAPHICS_OUTPUT) xheader="Freq1" yheader="HetPVal" res="300" < $(word 2,$+)

%.assoc_vs_het.$(R_GRAPHICS_OUTPUT): % $(LOGXLOGY_PLOT_R_SCRIPT) 
	$(RBIN) --args title="Association vs Heterogeneity" inputdata=$(word 1,$+) $(R_GRAPHICS_OUTPUT)outfile=$*.assoc_vs_het.$(R_GRAPHICS_OUTPUT) xheader="P.value" yheader="HetPVal" res="300" < $(word 2,$+)



################################################################################
# Arbitrary X vs Y plots specified from command line
################################################################################
PARAMDEFS += xyplot[XHEADER][YHEADER] xlogyplot[XHEADER][YHEADER] logxlogyplot[XHEADER][YHEADER] logxlogylabelplot[XHEADER][YHEADER][LABELHEADER] qqplot[QQHEADER]
PARAMDEF_MAPPINGS += 

define paramdefs_XYPLOT_rules # XHEADER YHEADER
%.xyplot[$(1)][$(2)].$(R_GRAPHICS_OUTPUT): % $(XY_PLOT_R_SCRIPT)
	$(RBIN) --args title="$$<" inputdata=$$(word 1,$$+) $(R_GRAPHICS_OUTPUT)outfile=$$*.xyplot[$(1)][$(2)].$(R_GRAPHICS_OUTPUT) xheader="$$(call R-safe-name,$(1))" yheader="$$(call R-safe-name,$(2))" res="300" < $$(word 2,$$+)
endef # paramdefs_XYPLOT_rules
$(foreach xheader,$(paramdefs_xyplot_XHEADER_values),$(foreach yheader,$(paramdefs_xyplot_YHEADER_values),$(eval $(call paramdefs_XYPLOT_rules,$(xheader),$(yheader)))))

define paramdefs_XLOGYPLOT_rules # XHEADER YHEADER
%.xlogyplot[$(1)][$(2)].$(R_GRAPHICS_OUTPUT): % $(XLOGY_PLOT_R_SCRIPT)
	$(RBIN) --args title="$$<" inputdata=$$(word 1,$$+) $(R_GRAPHICS_OUTPUT)outfile=$$*.xlogyplot[$(1)][$(2)].$(R_GRAPHICS_OUTPUT) xheader="$$(call R-safe-name,$(1))" yheader="$$(call R-safe-name,$(2))" res="300" < $$(word 2,$$+)
endef # paramdefs_XLOGYPLOT_rules
$(foreach xheader,$(paramdefs_xlogyplot_XHEADER_values),$(foreach yheader,$(paramdefs_xlogyplot_YHEADER_values),$(eval $(call paramdefs_XLOGYPLOT_rules,$(xheader),$(yheader)))))

define paramdefs_LOGXLOGYPLOT_rules # XHEADER YHEADER
%.logxlogyplot[$(1)][$(2)].$(R_GRAPHICS_OUTPUT): % $(LOGXLOGY_PLOT_R_SCRIPT)
	$(RBIN) --args title="$$<" inputdata=$$(word 1,$$+) $(R_GRAPHICS_OUTPUT)outfile=$$*.logxlogyplot[$(1)][$(2)].$(R_GRAPHICS_OUTPUT) xheader="$$(call R-safe-name,$(1))" yheader="$$(call R-safe-name,$(2))" res="300" < $$(word 2,$$+)
endef # paramdefs_LOGXLOGYPLOT_rules
$(foreach xheader,$(paramdefs_logxlogyplot_XHEADER_values),$(foreach yheader,$(paramdefs_logxlogyplot_YHEADER_values),$(eval $(call paramdefs_LOGXLOGYPLOT_rules,$(xheader),$(yheader)))))

define paramdefs_LOGXLOGYLABELPLOT_rules # XHEADER YHEADER
%.logxlogylabelplot[$(1)][$(2)][$(3)].$(R_GRAPHICS_OUTPUT): % $(LOGXLOGYLABEL_PLOT_R_SCRIPT)
	$(RBIN) --args title="$$<" inputdata=$$(word 1,$$+) $(R_GRAPHICS_OUTPUT)outfile=$$*.logxlogylabelplot[$(1)][$(2)][$(3)].$(R_GRAPHICS_OUTPUT) xheader="$$(call R-safe-name,$(1))" yheader="$$(call R-safe-name,$(2))" labelheader="$$(call R-safe-name,$(3))" res="300" < $$(word 2,$$+)
endef # paramdefs_LOGXLOGYLABELPLOT_rules
$(foreach xheader,$(paramdefs_logxlogylabelplot_XHEADER_values),$(foreach yheader,$(paramdefs_logxlogylabelplot_YHEADER_values),$(foreach labelheader,$(paramdefs_logxlogylabelplot_LABELHEADER_values),$(eval $(call paramdefs_LOGXLOGYLABELPLOT_rules,$(xheader),$(yheader),$(labelheader))))))

################################################################################
# Arbitrary QQ plots specified from command line
################################################################################
PARAMDEFS += qqplot[QQHEADER]
PARAMDEF_MAPPINGS += 
define paramdefs_QQPLOT_rules # QQHEADER
%.qqplot[$(1)].$(R_GRAPHICS_OUTPUT): %.add_gene_non_loc_af_ak_bc_bx_b36 $(MANHATTAN_QQ_PLOT_R_SCRIPT) 
	$(RBIN) --args title="$(1)" inputdata=$$(word 1,$$+) qq$(R_GRAPHICS_OUTPUT)outfile=$$*.qqplot[$(1)].$(R_GRAPHICS_OUTPUT) pvalueheader="$(1)" chrheader="CHR" posheader="POS_B36" na="." res="300" sep="TAB" < $$(word 2,$$+)
endef # paramdefs_QQPLOT_rules
$(foreach qqheader,$(paramdefs_qqplot_QQHEADER_values),$(eval $(call paramdefs_QQPLOT_rules,$(qqheader))))



################################################################################
# Locus Plots
################################################################################
PARAMDEFS += locusplot[HEADER][THRESHOLD][LEADMARKER][OTHERMARKERS][PHENOTYPES] 
PARAMDEF_MAPPINGS += locusplot[_header_][_threshold_][leadmarker][][]:indrankgd[_header_][_threshold_][Tag] locusplot[header][threshold][_leadmarker_][][]:filterstr[TagLoci][eq][_leadmarker_]
define paramdefs_LOCUSPLOT_rules # HEADER THRESHOLD LEADMARKER OTHERMARKERS PHENOTYPES
%.locusplot[$(1)][$(2)][$(3)][$(4)][$(5)].$(R_GRAPHICS_OUTPUT): %.add_chrpos_b36.indrankgd[$(1)][$(2)][Tag].filterstr[TagLoci][eq][$(3)] ucsc-hg18-knownGene-kgXref-join.pruned.chr-txStart-txEnd-strand-geneSymbol-uid.txt ucsc-hg18-cytoBand.chr-chromStart-chromEnd-cytoBandName-gieStain.txt $(LOCUS_PLOT_R_SCRIPT)
	$(RBIN) --args inputdata="$$(word 1,$$+)" genefile="$$(word 2,$$+)" markerheader="MarkerName" leadmarker="$(3)" $$(foreach othermarker,$$(subst $$(COMMA),$$(SPACE),$(4)),othermarkers="$$(othermarker)") chrheader="CHR" posheader="POS_B36" poslabel="Position (Build 36)" $$(foreach phenotype,$$(subst $$(COMMA),$$(SPACE),$(5)),analysisplabels="$$(phenotype)" analysispheaders="$$(phenotype).P.value") geneticposheader="Genetic_Map_cM_rel22" recombrateheader="COMBINED_rate_cM_per_Mb_rel22" outfile="$$@" na="." cytobandfile="$$(word 3,$$+)" < $$(word 4,$$+)
endef # paramdefs_LOCUSPLOT_rules
$(foreach header,$(paramdefs_locusplot_HEADER_values),$(foreach threshold,$(paramdefs_locusplot_THRESHOLD_values),$(foreach leadmarker,$(paramdefs_locusplot_LEADMARKER_values),$(foreach phenotypes,$(paramdefs_locusplot_PHENOTYPES_values),$(eval $(call paramdefs_LOCUSPLOT_rules,$(header),$(threshold),$(leadmarker),,$(phenotypes)))))))
$(foreach header,$(paramdefs_locusplot_HEADER_values),$(foreach threshold,$(paramdefs_locusplot_THRESHOLD_values),$(foreach leadmarker,$(paramdefs_locusplot_LEADMARKER_values),$(foreach othermarkers,$(paramdefs_locusplot_OTHERMARKERS_values),$(eval $(call paramdefs_LOCUSPLOT_rules,$(header),$(threshold),$(leadmarker),$(othermarkers),))))))
$(foreach header,$(paramdefs_locusplot_HEADER_values),$(foreach threshold,$(paramdefs_locusplot_THRESHOLD_values),$(foreach leadmarker,$(paramdefs_locusplot_LEADMARKER_values),$(foreach othermarkers,$(paramdefs_locusplot_OTHERMARKERS_values),$(foreach phenotypes,$(paramdefs_locusplot_PHENOTYPES_values),$(eval $(call paramdefs_LOCUSPLOT_rules,$(header),$(threshold),$(leadmarker),$(othermarkers),$(phenotypes))))))))

PARAMDEFS += locusplotgd[HEADER][THRESHOLD][LEADMARKER][OTHERMARKERS][PHENOTYPES] 
PARAMDEF_MAPPINGS += locusplotgd[_header_][_threshold_][leadmarker][][]:indrankgd[_header_][_threshold_][Tag] locusplotgd[header][threshold][_leadmarker_][][]:filterstr[TagLoci][eq][_leadmarker_]
define paramdefs_LOCUSPLOTGD_rules # HEADER THRESHOLD LEADMARKER OTHERMARKERS PHENOTYPES
%.locusplotgd[$(1)][$(2)][$(3)][$(4)][$(5)].$(R_GRAPHICS_OUTPUT): %.add_chrpos_b36.indrankgd[$(1)][$(2)][Tag].filterstr[TagLoci][eq][$(3)] ucsc-hg18-knownGene-kgXref-join.pruned.chr-txStart-txEnd-strand-geneSymbol-uid.txt ucsc-hg18-cytoBand.chr-chromStart-chromEnd-cytoBandName-gieStain.txt $(LOCUS_PLOT_R_SCRIPT)
	$(RBIN) --args inputdata="$$(word 1,$$+)" genefile="$$(word 2,$$+)" markerheader="MarkerName" leadmarker="$(3)" $$(foreach othermarker,$$(subst $$(COMMA),$$(SPACE),$(4)),othermarkers="$$(othermarker)") chrheader="CHR" posheader="Genetic_Map_cM_rel22" poslabel="Position (Build 36)" $$(foreach phenotype,$$(subst $$(COMMA),$$(SPACE),$(5)),analysisplabels="$$(phenotype)" analysispheaders="$$(phenotype).P.value") geneticposheader="Genetic_Map_cM_rel22" recombrateheader="COMBINED_rate_cM_per_Mb_rel22" outfile="$$@" na="." cytobandfile="$$(word 3,$$+)" < $$(word 4,$$+)
endef # paramdefs_LOCUSPLOTGD_rules
$(foreach header,$(paramdefs_locusplotgd_HEADER_values),$(foreach threshold,$(paramdefs_locusplotgd_THRESHOLD_values),$(foreach leadmarker,$(paramdefs_locusplotgd_LEADMARKER_values),$(foreach phenotypes,$(paramdefs_locusplotgd_PHENOTYPES_values),$(eval $(call paramdefs_LOCUSPLOTGD_rules,$(header),$(threshold),$(leadmarker),,$(phenotypes)))))))
$(foreach header,$(paramdefs_locusplotgd_HEADER_values),$(foreach threshold,$(paramdefs_locusplotgd_THRESHOLD_values),$(foreach leadmarker,$(paramdefs_locusplotgd_LEADMARKER_values),$(foreach othermarkers,$(paramdefs_locusplotgd_OTHERMARKERS_values),$(eval $(call paramdefs_LOCUSPLOTGD_rules,$(header),$(threshold),$(leadmarker),$(othermarkers),))))))
$(foreach header,$(paramdefs_locusplotgd_HEADER_values),$(foreach threshold,$(paramdefs_locusplotgd_THRESHOLD_values),$(foreach leadmarker,$(paramdefs_locusplotgd_LEADMARKER_values),$(foreach othermarkers,$(paramdefs_locusplotgd_OTHERMARKERS_values),$(foreach phenotypes,$(paramdefs_locusplotgd_PHENOTYPES_values),$(eval $(call paramdefs_LOCUSPLOTGD_rules,$(header),$(threshold),$(leadmarker),$(othermarkers),$(phenotypes))))))))

PARAMDEFS += locusplotsmooth[HEADER][THRESHOLD][LEADMARKER][OTHERMARKERS][PHENOTYPES] 
PARAMDEF_MAPPINGS += locusplotsmooth[_header_][_threshold_][leadmarker][][]:indrankgd[_header_][_threshold_][Tag] locusplotsmooth[header][threshold][_leadmarker_][][]:filterstr[TagLoci][eq][_leadmarker_]
define paramdefs_LOCUSPLOTSMOOTH_rules # HEADER THRESHOLD LEADMARKER OTHERMARKERS PHENOTYPES
%.locusplot[$(1)][$(2)][$(3)][$(4)][$(5)].$(R_GRAPHICS_OUTPUT) %.locusplotsmooth[$(1)][$(2)][$(3)][$(4)][$(5)].$(R_GRAPHICS_OUTPUT): %.add_chrpos_b36.indrankgd[$(1)][$(2)][Tag].filterstr[TagLoci][eq][$(3)] ucsc-hg18-knownGene-kgXref-join.pruned.chr-txStart-txEnd-strand-geneSymbol-uid.txt ucsc-hg18-cytoBand.chr-chromStart-chromEnd-cytoBandName-gieStain.txt $(LOCUS_PLOT_R_SCRIPT)
	$(RBIN) --args inputdata="$$(word 1,$$+)" genefile="$$(word 2,$$+)" markerheader="MarkerName" leadmarker="$(3)" $$(foreach othermarker,$$(subst $$(COMMA),$$(SPACE),$(4)),othermarkers="$$(othermarker)") chrheader="CHR" posheader="POS_B36" poslabel="Position (Build 36)" $$(foreach phenotype,$$(subst $$(COMMA),$$(SPACE),$(5)),analysisplabels="$$(phenotype)" analysispheaders="$$(phenotype).P.value") geneticposheader="Genetic_Map_cM_rel22" recombrateheader="COMBINED_rate_cM_per_Mb_rel22" smoothoutfile="$$*.locusplotsmooth[$(1)][$(2)][$(3)][$(4)][$(5)].$(R_GRAPHICS_OUTPUT)" outfile="$$*.locusplot[$(1)][$(2)][$(3)][$(4)][$(5)].$(R_GRAPHICS_OUTPUT)" na="." cytobandfile="$$(word 3,$$+)" < $$(word 4,$$+)
endef # paramdefs_LOCUSPLOTSMOOTH_rules
$(foreach header,$(paramdefs_locusplotsmooth_HEADER_values),$(foreach threshold,$(paramdefs_locusplotsmooth_THRESHOLD_values),$(foreach leadmarker,$(paramdefs_locusplotsmooth_LEADMARKER_values),$(foreach phenotypes,$(paramdefs_locusplotsmooth_PHENOTYPES_values),$(eval $(call paramdefs_LOCUSPLOTSMOOTH_rules,$(header),$(threshold),$(leadmarker),,$(phenotypes)))))))
$(foreach header,$(paramdefs_locusplotsmooth_HEADER_values),$(foreach threshold,$(paramdefs_locusplotsmooth_THRESHOLD_values),$(foreach leadmarker,$(paramdefs_locusplotsmooth_LEADMARKER_values),$(foreach othermarkers,$(paramdefs_locusplotsmooth_OTHERMARKERS_values),$(eval $(call paramdefs_LOCUSPLOTSMOOTH_rules,$(header),$(threshold),$(leadmarker),$(othermarkers),))))))
$(foreach header,$(paramdefs_locusplotsmooth_HEADER_values),$(foreach threshold,$(paramdefs_locusplotsmooth_THRESHOLD_values),$(foreach leadmarker,$(paramdefs_locusplotsmooth_LEADMARKER_values),$(foreach othermarkers,$(paramdefs_locusplotsmooth_OTHERMARKERS_values),$(foreach phenotypes,$(paramdefs_locusplotsmooth_PHENOTYPES_values),$(eval $(call paramdefs_LOCUSPLOTSMOOTH_rules,$(header),$(threshold),$(leadmarker),$(othermarkers),$(phenotypes))))))))


################################################################################
# Define analysis-specific rules
################################################################################
define meta_plots_ANALYSIS_rules # ANALYSIS

################################################################################
# Study EAF vs Meta EAF
################################################################################
$(1).%.eaf_vs_metaeaf.$(R_GRAPHICS_OUTPUT): $(1).%.add_input_gcc-se $(EAF_METAEAF_PLOT_R_SCRIPT)
	$(RBIN) --args inputdata=$$(word 1,$$+) $(R_GRAPHICS_OUTPUT)outfile=$(1).$$*.eaf_vs_metaeaf.$(R_GRAPHICS_OUTPUT) pheno="$(1)" < $(GIANT_FOREST_PLOT_R_SCRIPT) >& $(1).$$*.eaf_vs_metaeaf.log

################################################################################
# Forest Plots (always generate PDF since these plots have few points)
################################################################################
$(1).%.forest.pdf $(1).%.hetero.txt: $(1).%.add_input_gcc-se $(GIANT_FOREST_PLOT_R_SCRIPT)
	$(RBIN) --args inputdata=$$(word 1,$$+) outfile=$(1).$$*.forest.pdf heterooutfile=$(1).$$*.hetero.txt pheno="$(1)" < $(GIANT_FOREST_PLOT_R_SCRIPT) >& $(1).$$*.forest.log

endef # meta_plots_ANALYSIS_rules

################################################################################
# Evaluate analysis specific rules
################################################################################
$(foreach analysis,$(ANALYSES),$(eval $(call meta_plots_ANALYSIS_rules,$(analysis))))

