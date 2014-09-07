############################################################
# locus-plot.R
############################################################
#
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
############################################################

require(ggplot2)
require(RColorBrewer)

############################################################
# Set Defaults
############################################################
dpi=150
na="NA"
title=""
sep="\t"
recomb.label = "Recombination Rate"
geneset.labels = c("UCSC Genes")
cytoband.label = "Cytogenic Band"
greythreshold = "0.1"
posformat = "posmbformat"


############################################################
# Helper functions
############################################################
recoderegexp <- function(var, from, to) {
  x <- as.vector(var)
  for (i in 1:length(from))
    x <- replace(x, grep(from[i], x), to[i])
  if(is.factor(var)) factor(x) else x
}


posmbformat <- function(pos) {
  prettyNum(pos/1000000,format="f",digits=7,drop0trailing=TRUE)
}


############################################################
# Process command-line arguments into variables
############################################################
for (e in commandArgs(trailingOnly=TRUE)) {
  ta = strsplit(e,"=",fixed=TRUE)
  if(!is.null(ta[[1]][2])) {
    if(!exists(ta[[1]][1])) {
      # this variable doesn't exist yet
      assign(ta[[1]][1],ta[[1]][2])
    } else {
      # this variable already exists, make it into a list and append to it
      assign(ta[[1]][1],c(get(ta[[1]][1]),ta[[1]][2]))
    }
  } else {
    assign(ta[[1]][1],TRUE)
  }
}

usage = ""
die <- function(message, status=0) {
  cat(usage)
  cat(message,"\n")
  cat("Exiting with status: ",status,"\n")
  quit(save="no", status=status, runLast=FALSE)
}


############################################################
# Check that necessary arguments have been provided
############################################################
if(!exists("inputdata")) {
  die("You must specify an input filename!",-1)
}

if(!exists("genefile")) {
  die("You must specify a gene input file!",-2)
}

if(!exists("cytobandfile")) {
  die("You must specify a cytoband input file!",-2)
}

if(!exists("chrheader")) {
  die("You must specify a chrheader!",-2)
}

if(!exists("markerheader")) {
  die("You must specify a markerheader!",-2)
}

if(!exists("leadmarker")) {
  die("You must specify a leadmarker!",-2)
}

if(!exists("othermarkers")) {
  othermarkers=c()
}

if(!exists("posheader")) {
  die("You must specify a posheader!",-2)
}

if(!exists("poslabel")) {
  die("You must specify a poslabel!",-2)
}

if(!exists("analysisplabels")) {
  die("You must specify a pvalueheader!",-2)
}

if(!exists("analysispheaders")) {
  die("You must specify a pvalueheader!",-2)
}

if(!exists("geneticposheader")) {
  die("You must specify a geneticposheader!",-2)
}

if(!exists("recombrateheader")) {
  die("You must specify a recombrateheader!",-2)
}

if(!exists("outfile")) {
  die("You must specify an output file!",-2)
}

if(!exists("plottitle")) {
  warning(paste("Did not specify plottitle, setting title to",leadmarker,"locus"));
  plottitle=paste(leadmarker, "locus")
}

if(exists("sep")) {
  if(sep=="TAB") {
    sep="\t"
  } else {
    sep = noquote(sep);
  }
} 

############################################################
# Oxford Brand Colors in RGB Colors (R has no CMYK support?)
############################################################
oxford.blue <- rgb(0,33,71,maxColorValue=255)
oxford.mid.blue <- rgb(75,146,219,maxColorValue=255)
oxford.pastel.blue <- rgb(197,210,224,maxColorValue=255)
oxford.green <- rgb(0,87,81,maxColorValue=255)
oxford.mid.green <- rgb(124,162,149,maxColorValue=255)
oxford.pastel.green <- rgb(190,197,194,maxColorValue=255)
oxford.brown <- rgb(89,44,53,maxColorValue=255)
oxford.mid.brown <- rgb(171,136,118,maxColorValue=255)
oxford.pastel.brown <- rgb(202,192,182,maxColorValue=255)
oxford.red <- rgb(130,36,51,maxColorValue=255)
oxford.mid.red <- rgb(219,77,105,maxColorValue=255)
oxford.pastel.red <- rgb(233,197,203,maxColorValue=255)
oxford.olive <- rgb(136,123,27,maxColorValue=255)
oxford.mid.olive <- rgb(194,176,0,maxColorValue=255)
oxford.pastel.olive <- rgb(225,222,174,maxColorValue=255)
oxford.tan <- rgb(120,35,39,maxColorValue=255)
oxford.mid.tan <- rgb(225,163,88,maxColorValue=255)
oxford.pastel.tan <- rgb(241,227,187,maxColorValue=255)
oxford.black <- rgb(0,0,0,maxColorValue=255)

############################################################
# Additional Colors
############################################################
wtccc.green <- rgb(0,205,102,maxColorValue=255)


############################################################
# Read input data
############################################################
locusdata <- read.table(inputdata,as.is=T,header=T,na.strings=".",sep="\t")
ucscgenedata <- read.table(genefile,header=T,as.is=T,na.strings=".",sep="\t")
cytobanddata <- read.table(cytobandfile,header=T,as.is=T,na.strings=".",sep="\t")



# standardize header names
names(locusdata)[names(locusdata)==markerheader] <- "MarkerName"
names(locusdata)[names(locusdata)==posheader] <- "Position"
names(locusdata)[grep(recombrateheader,names(locusdata))[1]] <- "Recombination.Rate"
names(locusdata)[grep(geneticposheader,names(locusdata))[1]] <- "Genetic.Position"

# get chr
chr <- locusdata[locusdata$MarkerName==leadmarker,chrheader]

# mark leadmarker and othermarkers as known
knownmarkers <- c(leadmarker,othermarkers)

# reshape data from wide to long format
locusdata.melt <- melt(locusdata,id.vars=c("MarkerName","Position","Recombination.Rate","Genetic.Position"),measure.vars=analysispheaders,variable_name="Dataset")
names(locusdata.melt)[names(locusdata.melt)=="value"]<-"P.value"

# remove missing rows
locusdata.melt <- subset(locusdata.melt,(!is.na(MarkerName) && !is.na(Position)))

# recode melted data to remove endings from the headers-now-values
locusdata.melt$Dataset <- recoderegexp(locusdata.melt$Dataset, analysispheaders, analysisplabels)

# calculate position range and create scale
posminmax <- range(locusdata.melt$Position,na.rm=T)
posrange <- posminmax[2]-posminmax[1]
minpos <- posminmax[1] - (posrange*0.01)
maxpos <- posminmax[2] + (posrange*0.01)

# y range of association data
maxy <- max(-log10(locusdata.melt$P.value),na.rm=T)
miny <- 0
assocyrange <- maxy-miny

# rescale recombination rate
#maxrecomb <- max(locusdata.melt$Recombination.Rate)
# cap recomb at 100
maxrecomb <- 100
locusdata.melt$Recombination.Rate[locusdata.melt$Recombination.Rate > maxrecomb] = maxrecomb
recomb.scaling <- maxy/maxrecomb

# prepare gene data
chrstr <- paste("chr",chr,sep="")
ucscgenedata.subset <- subset(ucscgenedata,subset=(CHR==chrstr & TXEND >= minpos & TXSTART <= maxpos))
ucscgenedata.subset$TXEND <- ifelse(ucscgenedata.subset$TXEND > maxpos,maxpos,ucscgenedata.subset$TXEND)
ucscgenedata.subset$TXSTART <- ifelse(ucscgenedata.subset$TXSTART < minpos,minpos,ucscgenedata.subset$TXSTART)
ucscgenedata.subset$TXMID <- ucscgenedata.subset$TXSTART + ((ucscgenedata.subset$TXEND-ucscgenedata.subset$TXSTART)/2)
ucscgenedata.subset <- transform(ucscgenedata.subset,ARROW=ifelse(STRAND=="+","last","first"))
ucscgenedata.subset <- transform(ucscgenedata.subset,SYMBOLDIR=ifelse(STRAND=="+",paste(SYMBOL,"->",sep=""),paste("<-",SYMBOL,sep="")))
ucscgenedata.subset$Dataset <- "UCSC Genes"

#genedata.subset <-rbind.fill(ucscgenedata.subset)
genedata.subset <- ucscgenedata.subset
genedata.subset$Dataset <- as.factor(genedata.subset$Dataset)

# prepare cytoband data
cytobanddata.subset <- subset(cytobanddata,subset=(CHR==chrstr & ENDPOS_B36 >= minpos & STARTPOS_B36 <= maxpos))
cytobanddata.subset$TXEND <- ifelse(cytobanddata.subset$ENDPOS_B36 > maxpos,maxpos,cytobanddata.subset$ENDPOS_B36)
cytobanddata.subset$TXSTART <- ifelse(cytobanddata.subset$STARTPOS_B36 < minpos,minpos,cytobanddata.subset$STARTPOS_B36)
cytobanddata.subset$TXMID <- cytobanddata.subset$TXSTART + ((cytobanddata.subset$TXEND-cytobanddata.subset$TXSTART)/2)
cytobanddata.subset <- transform(cytobanddata.subset,SYMBOLDIR=paste(chr,CYTOBAND,sep=""))
cytobanddata.subset$Dataset <- cytoband.label
cytobanddata.subset$Dataset <- as.factor(cytobanddata.subset$Dataset)


# y offsets are a fraction of the y range
genecount <- length(genedata.subset[,1]) + 1 # an extra one for cytoband!
markercount <- length(knownmarkers)
markerfraction <- 72
genefraction <- 60
totalyrange <- assocyrange / (1 - genecount/genefraction - markercount/markerfraction)
geneoffset <- totalyrange/genefraction
markeroffset <- totalyrange/markerfraction

# generate y position (one for each gene for now) -- todo: could check for non-overlapping and allow them to be on the same line
genedata.subset$geney <- seq(from=-geneoffset,by=-geneoffset,length.out=length(genedata.subset[,1]))

cytobanddata.subset$geney <- min(c(-geneoffset,genedata.subset$geney), na.rm=T)-geneoffset


exonexpand <- function (df) { exonstarts <- strsplit(df$EXONSTARTS,","); exonends <- strsplit(df$EXONENDS,","); cbind(subset(df,select=c(Dataset,geney,uid,CHR)),EXONSTART=as.numeric(exonstarts[[1]]),EXONEND=as.numeric(exonends[[1]])); }
exondata <- ddply(genedata.subset, .(uid), exonexpand)
exondata.subset <- subset(exondata,subset=(EXONSTART<maxpos & EXONEND>minpos))
exondata.subset$EXONEND <- ifelse(exondata.subset$EXONEND > maxpos,maxpos,exondata.subset$EXONEND)
exondata.subset$EXONSTART <- ifelse(exondata.subset$EXONSTART < minpos,minpos,exondata.subset$EXONSTART)
exondata.subset$DATATYPE <- "Exons"


if(length(genedata.subset[,1])>0) {
  genedata.subset.melt <- melt(genedata.subset,measure.vars=c("TXSTART","TXEND","TXMID"),variable_name="StartEndMid", na.rm=TRUE)
  names(genedata.subset.melt)[names(genedata.subset.melt)=="value"] <- "Position"
  genedata.subset$DATATYPE <- "Genes"
  genedata.subset.melt$DATATYPE <- "MeltedGenes"
}

cytobanddata.subset.melt <- melt(cytobanddata.subset,measure.vars=c("TXSTART","TXEND","TXMID"),variable_name="StartEndMid", na.rm=TRUE)
names(cytobanddata.subset.melt)[names(cytobanddata.subset.melt)=="value"] <- "Position"
cytobanddata.subset$DATATYPE <- "Genes"
cytobanddata.subset.melt$DATATYPE <- "MeltedGenes"

miny <- min(cytobanddata.subset$geney-(0.4*geneoffset),na.rm=T)

# prepare overall data
recombination.melt <- locusdata.melt
locusdata.melt$DATATYPE <- "Association"
recombination.melt$DATATYPE <- "Recombination"
recombination.melt$Dataset <- recomb.label

lrdata <- rbind(locusdata.melt,recombination.melt)
lrcdata <- rbind.fill(lrdata,cytobanddata.subset.melt,cytobanddata.subset)
if(exists("genedata.subset.melt")) {
  lrcgdata <- rbind.fill(lrcdata,genedata.subset.melt,genedata.subset)
} else {
  lrcgdata <- lrcdata
}
if(exists("exondata.subset")) {
  data <- rbind.fill(lrcgdata,exondata.subset)
} else {
  data <- lrcgdata
}
data$DATATYPE = as.factor(data$DATATYPE)
data <- subset(data,!is.na(Position) | !is.na(TXSTART) | !is.na(TXEND)| !is.na(EXONSTART) | !is.na(EXONEND))


# prepare positions for marker labels
data.knownmarkers.subset <- subset(data,(MarkerName %in% knownmarkers & DATATYPE=="Association"))
markerlabely <- seq(from=maxy+markeroffset,by=markeroffset,length.out=length(knownmarkers))
maxy <- max(maxy,markerlabely)
markerlabel.df <- data.frame(MarkerName=knownmarkers,markerlabely=markerlabely)
data.knownmarkers <- merge(data.knownmarkers.subset,markerlabel.df,by="MarkerName",all.x=TRUE)

# set colour mappings
Dataset.levels <- levels(as.factor(data$Dataset))
fullcolourmap <- c(brewer.pal(n=length(c(geneset.labels,analysisplabels))+1,name="Dark2"),"black")
names(fullcolourmap) <- c(analysisplabels,geneset.labels,cytoband.label,recomb.label) # map colours to labels
fullcolourkeyorder <- c(analysisplabels,recomb.label,geneset.labels,cytoband.label) # set order for key
colourmap <- fullcolourmap[names(fullcolourmap) %in% levels(as.factor(data[,"Dataset"]))]
colourkeyorder <- fullcolourkeyorder[fullcolourkeyorder %in% levels(as.factor(data[,"Dataset"]))]
# set fill colours
fillcolourmap <- alpha(colourmap,I(2/3))
names(fillcolourmap) <- names(colourmap)
fillcolourkeyorder <- colourkeyorder

# find position range of genetic.position cutoff (grey region)
leadgpos <- data[data$MarkerName==leadmarker,"Genetic.Position"][1]
locushighgpos <- leadgpos + as.numeric(greythreshold)
locuslowgpos <- leadgpos - as.numeric(greythreshold)
locushighpos <- data[data$Genetic.Position==min(data[data$Genetic.Position>=locushighgpos,"Genetic.Position"],na.rm=T),"Position"][1]
locuslowpos <- data[data$Genetic.Position==max(data[data$Genetic.Position<=locuslowgpos,"Genetic.Position"],na.rm=T),"Position"][1]
greydata <- data.frame(start=c(minpos,locushighpos),end=c(locuslowpos,maxpos))

# build the association plot layers
# main layer of all points
association.layer.points <- layer(data=subset(data,subset=(DATATYPE=="Association")),geom="point",mapping=aes(y=-log10(P.value),colour=Dataset),alpha=I(2/3),size=I(1.25))

# layer to circle "known" markers
association.layer.known <- layer(data=data.knownmarkers, geom="point",mapping=aes(y=-log10(P.value),fill=Dataset),colour=alpha("black",I(1)),size=I(1.25),shape=I(21))

# layer to label known marker in the upper margin
association.layer.known.text <- layer(data=data.knownmarkers,geom="text",position=position_dodge(),mapping=aes(label=MarkerName,y=markerlabely),colour="black",alpha=I(1),size=I(2))

# layers for gene annotations
data.genes.subset <- subset(data,subset=((DATATYPE=="Genes")))
data.genes.subset.melt <- subset(data,subset=((DATATYPE=="MeltedGenes")))
if(length(data.genes.subset[,1])>0) {
#  gene.layer.lines <- layer(data=data.genes.subset,geom="line",mapping=aes(group=uid,colour=Dataset,y=geney),alpha=I(1/2),size=I(3),arrow=arrow(angle=90,ends="both",type="open"))
#  ,arrow=arrow(ends=ARROW,type="closed"))
  gene.layer.lines <- layer(data=data.genes.subset,geom="rect",mapping=aes(fill=Dataset,xmin=TXSTART,xmax=TXEND,ymin=(geney-(0.4*geneoffset)),ymax=(geney+(0.4*geneoffset))),colour=alpha("black",I(1/3)))
  gene.layer.text <- layer(data=subset(data.genes.subset.melt,subset=((StartEndMid=="TXMID"))),geom="text",mapping=aes(label=SYMBOLDIR,y=geney),colour="black",alpha=I(1),size=I(2))
}

data.exons.subset <- subset(data,subset=((DATATYPE=="Exons")))
if(length(data.exons.subset[,1])>0) {
#  gene.layer.exons <- layer(data=data.exons.subset,geom="rect",mapping=aes(colour=alpha(Dataset,I(1/2)),fill=alpha(Dataset,I(1/2)),xmin=EXONSTART,xmax=EXONEND,ymin=(geney-(0.4*geneoffset)),ymax=(geney+(0.4*geneoffset))))
  gene.layer.exons <- layer(data=data.exons.subset,geom="rect",mapping=aes(xmin=EXONSTART,xmax=EXONEND,ymin=(geney-(0.4*geneoffset)),ymax=(geney+(0.4*geneoffset))),fill=alpha("black",I(1/3)))
}

# recombination rate
recomb.layer <- layer(data=subset(data,(DATATYPE=="Recombination" & !is.na(Recombination.Rate))),geom="line",mapping=aes(y=Recombination.Rate*recomb.scaling),colour="black",group=I(0),alpha=I(1/3))

# layer to grey out area beyond greythreshold
greyoutside.layer.rects <- layer(data=greydata,geom="rect",mapping=aes(x=NULL,y=NULL,xmin=start,xmax=end),fill="black",ymin=(miny-(maxy-miny)*1.01),ymax=(maxy+(maxy-miny)*1.01),alpha=I(1/10))

# combine layers, set scales, formatting, title, theme
locus.plot <- ggplot(mapping=aes(x=Position),data=data)
locus.plot <- locus.plot + association.layer.points + association.layer.known.text
if(exists("gene.layer.lines")) {
  locus.plot <- locus.plot + gene.layer.lines
}
if(exists("gene.layer.exons")) {
  locus.plot <- locus.plot + gene.layer.exons
}
if(exists("gene.layer.text")) {
  locus.plot <- locus.plot + gene.layer.text
}
locus.plot <- locus.plot + recomb.layer
locus.plot <- locus.plot + association.layer.known
locus.plot <- locus.plot + scale_x_continuous(name=paste("Chromosome",chr,poslabel,"(Mb)"),formatter=posformat,limits=c(minpos,maxpos),expand=c(0,0))
locus.plot <- locus.plot + scale_colour_manual(values=colourmap,breaks=colourkeyorder)
locus.plot <- locus.plot + scale_fill_manual(values=fillcolourmap,breaks=fillcolourkeyorder)
locus.plot <- locus.plot + opts(title=plottitle)
locus.plot <- locus.plot + scale_y_continuous(name=expression(-log[10](P-value)),limits=c(miny,maxy),breaks=seq(from=0,to=as.integer(maxy)+1,by=1),expand=c(0.01,0))
locus.plot <- locus.plot + greyoutside.layer.rects


############################################################
# Output Plot to File
############################################################
ggsave(outfile,locus.plot)


############################################################
# Output Plot with smoother
############################################################
if(exists("smoothoutfile")) {
  locus.plot.smooth <- ggplot(mapping=aes(x=Position),data=data)
  locus.plot.smooth <- locus.plot.smooth + association.layer.points + stat_smooth(mapping=aes(y=-log10(P.value),colour=Dataset),method="loess",span=0.1,family="symmetric",degree=2,level=0.99,data=subset(data,subset=(DATATYPE=="Association"))) + association.layer.known.text
  if(exists("gene.layer.lines")) {
    locus.plot.smooth <- locus.plot.smooth + gene.layer.lines
  }
  if(exists("gene.layer.exons")) {
    locus.plot.smooth <- locus.plot.smooth  + gene.layer.exons
  }
  if(exists("gene.layer.text")) {
    locus.plot.smooth <- locus.plot.smooth + gene.layer.text
  }
  locus.plot.smooth <- locus.plot.smooth + recomb.layer
  locus.plot.smooth <- locus.plot.smooth + association.layer.known
  locus.plot.smooth <- locus.plot.smooth + scale_x_continuous(name=paste("Chromosome",chr,poslabel,"(Mb)"),formatter="posmbformat",limits=c(minpos,maxpos),expand=c(0,0)) + scale_colour_manual(values=colourmap,breaks=colourkeyorder) + scale_fill_manual(values=fillcolourmap,breaks=fillcolourkeyorder) + opts(title=plottitle) + scale_y_continuous(name=expression(-log[10](P-value)),limits=c(miny,maxy),breaks=seq(from=0,to=as.integer(maxy)+1,by=1),expand=c(0.01,0)) 
  locus.plot.smooth <- locus.plot.smooth + greyoutside.layer.rects
  ggsave(smoothoutfile,locus.plot.smooth)
}

