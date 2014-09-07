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

# HUGO Gene Names (see http://www.genenames.org/data/gdlw_index.html)
#.PHONY: hgnc.ApprovedSymbol-ApprovedName-CHR-RefSeq.txt
hgnc.ApprovedSymbol-ApprovedName-CHR-RefSeq.txt: 
	wget -S "http://www.genenames.org/cgi-bin/hgnc_downloads.cgi?title=HGNC+output+data&hgnc_dbtag=on&col=gd_app_sym&col=gd_app_name&col=gd_pub_chrom_map&col=gd_pub_refseq_ids&status=Approved&status_opt=2&level=pri_sec&=on&where=&order_by=gd_app_sym_sort&limit=&format=text&submit=submit&.cgifields=&.cgifields=level&.cgifields=chr&.cgifields=status&.cgifields=hgnc_dbtag" -O hgnc.ApprovedSymbol-ApprovedName-CHR-RefSeq.txt >& $@.log

hgnc.ApprovedSymbol-ApprovedName-CHR-RefSeq.no-missing-refseq.txt: 
	wget -S "http://www.genenames.org/cgi-bin/hgnc_downloads.cgi?title=HGNC+output+data&hgnc_dbtag=on&col=gd_app_sym&col=gd_app_name&col=gd_pub_chrom_map&col=gd_pub_refseq_ids&status=Approved&status_opt=2&level=pri_sec&=on&where=&order_by=gd_app_sym_sort&limit=&format=text&submit=submit&.cgifields=&.cgifields=level&.cgifields=chr&.cgifields=status&.cgifields=hgnc_dbtag" -O hgnc.ApprovedSymbol-ApprovedName-CHR-RefSeq.txt >& $@.log

# UCSC tables (see http://hgdownload.cse.ucsc.edu/downloads.html#human)
# http://hgdownload.cse.ucsc.edu/goldenPath/hg18/database/
# knownGene: ftp://hgdownload.cse.ucsc.edu/goldenPath/hg18/database/knownGene.txt.gz
#.PHONY: ucsc.hg18.knownGene.txt.gz
ucsc.hg18.knownGene.txt.gz:
	mkdir -p $(PIPELINE_HOME)/DOWNLOADS/ucsc.hg18
	wget -S -N http://hgdownload.cse.ucsc.edu/goldenPath/hg18/database/knownGene.txt.gz -P $(PIPELINE_HOME)/DOWNLOADS/ucsc.hg18 >& $(PIPELINE_HOME)/DOWNLOADS/ucsc.hg18/$@.log
	if test $(PIPELINE_HOME)/DOWNLOADS/ucsc.hg18/knownGene.txt.gz -nt $@; then ln -fs $(PIPELINE_HOME)/DOWNLOADS/ucsc.hg18/knownGene.txt.gz $@; else echo "file not newer"; fi
ucsc.hg18.knownGene.txt: ucsc.hg18.knownGene.txt.gz
	zcat $< > $@

# kgXref: ftp://hgdownload.cse.ucsc.edu/goldenPath/hg18/database/kgXref.txt.gz
#.PHONY: ucsc.hg18.kgXref.txt.gz
ucsc.hg18.kgXref.txt.gz: 
	mkdir -p $(PIPELINE_HOME)/DOWNLOADS/ucsc.hg18
	wget -S -N http://hgdownload.cse.ucsc.edu/goldenPath/hg18/database/kgXref.txt.gz -P $(PIPELINE_HOME)/DOWNLOADS/ucsc.hg18 >& $(PIPELINE_HOME)/DOWNLOADS/ucsc.hg18/$@.log
	if test $(PIPELINE_HOME)/DOWNLOADS/ucsc.hg18/kgXref.txt.gz -nt $@; then ln -fs $(PIPELINE_HOME)/DOWNLOADS/ucsc.hg18/kgXref.txt.gz $@; else echo "file not newer"; fi
ucsc.hg18.kgXref.txt: ucsc.hg18.kgXref.txt.gz
	zcat $< > $@

# cytoBand: ftp://hgdownload.cse.ucsc.edu/goldenPath/hg18/database/cytoBand.txt.gz
#.PHONY: ucsc.hg18.cytoBand.txt.gz
ucsc.hg18.cytoBand.txt.gz: 
	mkdir -p $(PIPELINE_HOME)/DOWNLOADS/ucsc.hg18
	wget -S -N http://hgdownload.cse.ucsc.edu/goldenPath/hg18/database/cytoBand.txt.gz -P $(PIPELINE_HOME)/DOWNLOADS/ucsc.hg18 >& $(PIPELINE_HOME)/DOWNLOADS/ucsc.hg18/$@.log
	if test $(PIPELINE_HOME)/DOWNLOADS/ucsc.hg18/cytoBand.txt.gz -nt $@; then ln -fs $(PIPELINE_HOME)/DOWNLOADS/ucsc.hg18/cytoBand.txt.gz $@; else echo "file not newer"; fi
ucsc.hg18.cytoBand.txt: ucsc.hg18.cytoBand.txt.gz
	zcat $< > $@


# Join knownGene and kgXref tables
ucsc-hg18-knownGene-kgXref-join.name-chr-txStart-txEnd-strand-geneSymbol-refSeq-description.noheader.txt: $(MERGE_COL_SCRIPT) ucsc.hg18.knownGene.txt ucsc.hg18.kgXref.txt
	$(word 1,$+) --tmpdir="$(TMP_DIR)" --in $(word 2,$+) --header 0 --in $(word 3,$+) --header 0 --out $@ --outheader 0 --matchcolnums 1:1 --keepall 1 --missing "." 

ucsc-hg18-knownGene-kgXref-join.name-chr-txStart-txEnd-strand-geneSymbol-refSeq-description.txt: ucsc-hg18-knownGene-kgXref-join.name-chr-txStart-txEnd-strand-geneSymbol-refSeq-description.noheader.txt
	(echo "NAME	CHR	STRAND	TXSTART	TXEND	CDSSTART	CDSEND	EXONCOUNT	EXONSTARTS	EXONENDS	PROTEINID	ALIGNID	MRNA	SPID	SPDISPLAYID	SYMBOL	REFSEQ	PROTACC	DESCRIPTION" && cat $<) > $@ 

ucsc-hg18-cytoBand.chr-chromStart-chromEnd-cytoBandName-gieStain.txt: ucsc.hg18.cytoBand.txt
	(echo "CHR	STARTPOS_B36	ENDPOS_B36	CYTOBAND	GIESTAIN" && cat $<) > $@

# Prune hg18 genes ("CHR","TXSTART","TXEND","STRAND","SYMBOL","uid")
ucsc-hg18-knownGene-kgXref-join.pruned.chr-txStart-txEnd-strand-geneSymbol-uid.txt: $(PRUNE_UCSC_GENES_SCRIPT) ucsc-hg18-knownGene-kgXref-join.name-chr-txStart-txEnd-strand-geneSymbol-refSeq-description.txt
	$(word 1,$+) < $(word 2,$+) > $@

# Combine HGNC and UCSC gene annotations into a merged list
#genes.hg18.txt: $(MERGE_COL_SCRIPT) ucsc-hg18-knownGene-kgXref-join.name-chr-txStart-txEnd-strand-geneSymbol-refSeq-description.txt hgnc.ApprovedSymbol-ApprovedName-CHR-RefSeq.no-missing-refseq.txt
#	$(word 1,$+) --tmpdir="$(TMP_DIR)" --in $(word 2,$+) --header 1 --in $(word 3,$+) --header 1 --out $@ --matchcols "REFSEQ:RefSeq IDs" --keepall 1 --missing "." 

