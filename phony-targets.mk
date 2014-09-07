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
# Phony Target Rules
#######################################################################################

# default target, to make everything
.PHONY: all
all: millions qqplots archive annott2ds checkalleles metalprep annott2ds1e-6 annott2ds1e-6genelist annott2ds1e-6locilist annott2ds1e-5 annott2ds1e-5genelist annott2ds1e-4genelist

.PHONY: metalprep 
metalprep: $(foreach input,$(INPUTS),$(input).metalprep.txt)

.PHONY: millions 
millions: $(foreach pheno,$(ANALYSES),$(pheno).million.png)

.PHONY: qqplots
qqplots: $(foreach pheno,$(ANALYSES),$(pheno).qqplot.pvalue.png)

.PHONY: checkalleles
checkalleles: $(foreach pheno,$(ANALYSES),$(pheno).checkalleles.log)

.PHONY: annott2ds
annott2ds: $(foreach pheno,$(ANALYSES),$(pheno).metal.out.threshold1e-5.annotbmiheight.annotgene_b35.annott2d.sortpvalue)

.PHONY: annott2ds1e-6
annott2ds1e-6: $(foreach pheno,$(ANALYSES),$(pheno).metal.out.threshold1e-5.annotbmiheight.annotgene_b35.annott2d.threshold1e-6)

.PHONY: independent1e-5
independent1e-5: $(foreach pheno,$(ANALYSES),$(pheno).metal.out.threshold1e-5.annotbmiheight.annotgene_b35.annott2d.threshold1e-5.pvalindep0.5)

.PHONY: annott2ds1e-6genelist
annott2ds1e-6genelist: $(foreach pheno,$(ANALYSES),$(pheno).metal.out.threshold1e-5.annotbmiheight.annotgene_b35.annott2d.threshold1e-6.gene.list)

.PHONY: annott2ds1e-6locilist
annott2ds1e-6locilist: $(foreach pheno,$(ANALYSES),$(pheno).metal.out.threshold1e-5.annotbmiheight.annotgene_b35.annott2d.threshold1e-6.loci.list)

.PHONY: annott2ds1e-5
annott2ds1e-5: $(foreach pheno,$(ANALYSES),$(pheno).metal.out.threshold1e-5.annotbmiheight.annotgene_b35.annott2d.threshold1e-5)

.PHONY: annott2ds1e-5genelist
annott2ds1e-5genelist: $(foreach pheno,$(ANALYSES),$(pheno).metal.out.threshold1e-5.annotbmiheight.annotgene_b35.annott2d.threshold1e-5.gene.list)

.PHONY: annott2ds1e-4genelist
annott2ds1e-4genelist: $(foreach pheno,$(ANALYSES),$(pheno).metal.out.threshold1e-4.annotgene_b35.gene.list)

.PHONY: archive
archive: $(foreach pheno,$(ANALYSES),$(pheno).giant.meta.tar.gz)

$(foreach analysis,$(ANALYSES),$(eval .PHONY: $(analysis)))
$(foreach analysis,$(ANALYSES),$(eval $(analysis): $(analysis).giant.meta.tar.gz))



