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
# META ANALYSIS PIPELINE FOR GIANT CONSORTIUM
#
# Modified: 6 May 2009
# Created: 15 February 2008
# Author: Joshua Randall <jrandall@well.ox.ac.uk>
#######################################################################################

#######################################################################################
# PIPELINE_HOME is the location of the pipeline and the root of supporting file directories
# Can also be set from the environment
#######################################################################################
PIPELINE_HOME		?= /raid/data/giant/moama/version5-pipeline

#######################################################################################
# List of INPUT directories
#######################################################################################
ANALYSIS_INPUT_DIRS	= $(PIPELINE_HOME)/ANALYSES
PRECLEAN_INPUT_DIRS	= $(PIPELINE_HOME)/PRECLEAN $(PIPELINE_HOME)/PRECLEAN/WHR $(PIPELINE_HOME)/PRECLEAN/WC $(PIPELINE_HOME)/PRECLEAN/HIP  $(PIPELINE_HOME)/PRECLEAN/WEIGHT  $(PIPELINE_HOME)/PRECLEAN/HEIGHT  $(PIPELINE_HOME)/PRECLEAN/BMI
CLEANED_INPUT_DIRS	= $(PIPELINE_HOME)/CLEANED
METADATA_DIRS		= $(PIPELINE_HOME)/METADATA $(PIPELINE_HOME)/DOWNLOADS

MARKERLABEL = "MarkerName"
MISSING = "."

#######################################################################################
#######################################################################################
#######################################################################################
################### THERE SHOULD BE NO NEED TO EDIT BELOW THIS LINE ###################
###################      IF YOU ARE JUST RUNNING THE PIPELINE       ###################
#######################################################################################
#######################################################################################
#######################################################################################

#######################################################################################
# Flags for GNU Make
#######################################################################################
MAKEFLAGS = -r --check-symlink-times
SHELL = /bin/bash

#######################################################################################
# Generate Analysis List from ANALYSIS_INPUT_DIRS
#######################################################################################
ANALYSES = $(foreach inputdir,$(ANALYSIS_INPUT_DIRS),$(patsubst %.analysisfiles.list,%,$(notdir $(wildcard $(inputdir)/*.analysisfiles.list))))

#######################################################################################
# Pipeline Subdirectories 
#######################################################################################
BIN_DIR		= $(PIPELINE_HOME)/bin
TMP_DIR		= /raid/scratch/tmp
VPATH		= $(ANALYSIS_INPUT_DIRS) $(CLEANED_INPUT_DIRS) $(PRECLEAN_INPUT_DIRS) $(METADATA_DIRS) $(DATA_DIRS)

#######################################################################################
# External Programs
#######################################################################################
RBIN					= /usr/bin/R --no-save
METAL_BIN				= /home/jrandall/bin/x86_64/metal
CONVERTBIN				= /usr/bin/convert
GSCONVERTBIN				= /usr/bin/gs
TARBIN					= /bin/tar 
GZIPBIN					= /bin/gzip
BZIP2BIN				= /bin/bzip2
AWKBIN					= /usr/bin/awk
SED_BIN					= /bin/sed

#######################################################################################
# Path to Perl and R libraries
#######################################################################################
#export PERL5LIB=$(PIPELINE_HOME)/perl_local/lib/perl5
export R_LIBS=$(PIPELINE_HOME)/Rlibs

#######################################################################################
# Special Targets (configuration)
#######################################################################################
.SUFFIXES: # with no dependencies, this eliminates all existing prerequisites for suffix rules
.SECONDARY: # with no dependencies, this keeps all secondary files
.DELETE_ON_ERROR: # delete target of a rule if it has changed and its commands exit with a nonzero status

#######################################################################################
# Tab, space, comma
#######################################################################################
TAB:="`$(BIN_DIR)/printtab.sh`"
BLANK:= 
SPACE:=$(BLANK) $(BLANK)
COMMA:=,

#######################################################################################
# External Program Output Data Header Names
#######################################################################################
METAL_MARKER_H				= MarkerName
METALPREP_MARKER_H			= SNP

#######################################################################################
# Pipeline Scripts
#######################################################################################
MAKE_METAL_SCRIPT			= $(BIN_DIR)/make-metal-script.pl
MERGE_COL_SCRIPT 			= $(BIN_DIR)/merge-col-lowmem.pl
MERGE_COL_LOWMEM_SCRIPT 		= $(BIN_DIR)/merge-col-lowmem.pl
CUT_COL_NAME_SCRIPT			= $(BIN_DIR)/cut-col-name.pl
MANHATTAN_QQ_PLOT_R_SCRIPT		= $(BIN_DIR)/manhattan-qq-plots.R
XY_PLOT_R_SCRIPT			= $(BIN_DIR)/x-y-plot.R
XLOGY_PLOT_R_SCRIPT			= $(BIN_DIR)/x-logy-plot.R
LOGXLOGY_PLOT_R_SCRIPT			= $(BIN_DIR)/logx-logy-plot.R
LOGXLOGYLABEL_PLOT_R_SCRIPT			= $(BIN_DIR)/logx-logy-label-plot.R
EAF_METAEAF_PLOT_R_SCRIPT		= $(BIN_DIR)/eaf-metaeaf-plot.R
DETECT_SEP_SCRIPT			= $(BIN_DIR)/detect-sep.pl
MOAMA_CLEAN_SCRIPT			= $(BIN_DIR)/moama-clean-and-report.pl
MOAMA_REFORMAT_SCRIPT			= $(BIN_DIR)/moama-reformat.pl
REMAP_COL_SCRIPT			= $(BIN_DIR)/remap-col.pl
RSQ_INDEPENDENT_RANK			= $(BIN_DIR)/rsq-independent-rank-metal-bigmem.pl 
GD_INDEPENDENT_RANK			= $(BIN_DIR)/gd-independent-rank.pl 
ANNOTATE_NEAREST_GENE_AVOIDRE_SCRIPT	= $(BIN_DIR)/annotate-nearest-gene-avoidre.pl
GENERATE_PARAMDEFS_MAKEFILE_SCRIPT	= $(BIN_DIR)/generate-paramdefs-makefile.pl
PAIRWISE_T_TEST_R_SCRIPT		= $(BIN_DIR)/pairwise-t-test.R
REORDER_COLS_SCRIPT			= $(BIN_DIR)/reorder-cols.pl
METALLOG2STUDYINFO_SCRIPT		= $(BIN_DIR)/metallog2studyinfo.pl
LOCUS_PLOT_R_SCRIPT			= $(BIN_DIR)/locus-plot.R
PRUNE_UCSC_GENES_SCRIPT			= $(BIN_DIR)/prune-genetable.pl

#######################################################################################
# Old Pipeline Scripts
#######################################################################################
METAL2MILLION_SCRIPT			= $(BIN_DIR)/metal2million.pl
METALANNOTATE_SCRIPT			= $(BIN_DIR)/metal-annotate.pl
MANHATTANPLOT_R_SCRIPT			= $(BIN_DIR)/manhattan-plot.R
METAL2MILLION_R_SCRIPT			= $(BIN_DIR)/metal2million.R
METAL2REGIONAL_R_SCRIPT			= $(BIN_DIR)/metal2regionalplot.R
METALPLOTS_R_SCRIPT			= $(BIN_DIR)/metalplots.R	
RSQ_INDEPENDENT_FILTER			= $(BIN_DIR)/rsq-independent-filter-metal.pl 
#RSQ_INDEPENDENT_RANK			= $(BIN_DIR)/rsq-independent-rank-metal.pl 
DIST_INDEPENDENT_FILTER			= $(BIN_DIR)/dist-independent-filter-metal.pl 
APPEND_CONSTANT_COL_SCRIPT		= $(BIN_DIR)/append-constant-col.pl
CALC_TOTAL_N_SCRIPT			= $(BIN_DIR)/calc-total-n.pl
COL_MAX_SCRIPT				= $(BIN_DIR)/max-col.pl
FILTER_ROWS_MATCHING_LIST		= $(BIN_DIR)/filter_rows_only_matching_col_list.pl
GIANT_FOREST_PLOT_R_SCRIPT		= $(BIN_DIR)/giantforestplots.R
MOAMA_HAPMAP_STRAND_CHECK_R_SCRIPT	= $(BIN_DIR)/moama-hapmap-strand-allele-check.R


#######################################################################################
# Include GMSL (GNU Make Standard Library)
#######################################################################################
include $(PIPELINE_HOME)/gmsl/gmsl


#######################################################################################
# Get R safe versions of header names (call with first param as name) 
#######################################################################################
define R-safe-name # NAME
`echo 'cat(make.names("$(1)"))' | R --no-save --no-restore --slave`
endef

################################################################################
# Ensure that paramdefs are recreated when this makefile is loaded
################################################################################
$(shell touch generated-paramdefs.stamp)
PARAMDEFS:=
PARAMDEF_MAPPINGS:=

#######################################################################################
# Include files
#######################################################################################
include $(PIPELINE_HOME)/generate-vars.mk
include $(PIPELINE_HOME)/phony-targets.mk
include $(PIPELINE_HOME)/list-vars.mk
include $(PIPELINE_HOME)/paramdefs.mk

include $(PIPELINE_HOME)/shortcuts.mk

# include $(PIPELINE_HOME)/premoama.mk

# Merge HYB, MEN, WOMEN, and gender heterogeneity results for a single trait in a single file
include $(PIPELINE_HOME)/trait-merge.mk

# Clean and prepare for analysis
include $(PIPELINE_HOME)/clean.mk

# Generate cleaning reports for each analysis
include $(PIPELINE_HOME)/clean-report.mk

# GC Correct Input Files
#include $(PIPELINE_HOME)/gc-correct.mk

# Meta-analyse Using METAL
include $(PIPELINE_HOME)/meta-metal.mk

# Post processing (sorting, filtering, independetizing, etc) meta-analysis results
include $(PIPELINE_HOME)/post-process.mk

# Compare two analyses, testing heterogeneity and such (e.g. Men vs Women)
include $(PIPELINE_HOME)/analysis-compare.mk

# Plotting meta-analysis results
include $(PIPELINE_HOME)/meta-plots.mk

# Gzip, gunzip
include $(PIPELINE_HOME)/gzip.mk
#include $(PIPELINE_HOME)/gunzip.mk
#include $(PIPELINE_HOME)/decompress.mk
#include $(PIPELINE_HOME)/compress.mk

# Download and prepare gene-annotation resources
include $(PIPELINE_HOME)/gene-annotation.mk

