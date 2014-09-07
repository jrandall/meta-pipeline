#!/bin/sh
tmpcmd="/usr/bin/tail -n +9 $0 | /usr/bin/R --vanilla --slave --args $@"
'sh -c "${tmpcmd}"'="this command will not be found, don't worry!"
echo = `sh -c "${tmpcmd}"`
"exit"
############################################################
# Do not edit the above three lines
# unless you know what you are doing!
############################################################

############################################################
# manhattan-qq-plots.R
############################################################
#
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
############################################################

options(echo=FALSE)
if(exists("tmpcmd")) { rm(tmpcmd) } # remove shell var from the R session
if(exists("echo")) { rm(echo) } # remove shell command from the R session

############################################################
# Usage from the R command line (with examples)
############################################################
usage <- '\
*****************************************************************************\
* manhattan-qq-plots.R                                                      *\
*****************************************************************************\
	Copyright 2008 Joshua Randall\
	Joshua Randall <jcrandall@alum.mit.edu>\
\
	This program is free software: you can redistribute it and/or modify\
	it under the terms of the GNU General Public License as published by\
	the Free Software Foundation, either version 3 of the License, or\
	(at your option) any later version.\
\
	This program is distributed in the hope that it will be useful,\
	but WITHOUT ANY WARRANTY; without even the implied warranty of\
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the\
	GNU General Public License for more details.\
\
	You should have received a copy of the GNU General Public License\
	along with this program.  If not, see <http://www.gnu.org/licenses/>.\
\
*****************************************************************************\
* Description                                                               *\
*****************************************************************************\
This program produces genome-wide Manhattan plots and Q-Q\
Plots for a set of markers.  It is an R script that requires\
the R interpreter to run.\
\
It can be called from the command line using:\
R --slave --vanilla --args < manhattan-qq-plots.R\
\
It can also be sourced within R using:\
source("manhattan-qq-plots.R")\
\
This program accepts parameters (in fact, it requires them), which can be set
either from the command line or within R.  See below for examples of how to
set parameters.  Some parameters are required, others are optional.\
\
The required parameters are:\
\
inputdata:        The filename which contains a data table in text format,
                  with a header row and numeric columns for:
                    P-value (required),
                    chromosome (only required for manhattan plots), and
                    position (only required for manhattan plots).
                  The input file may contain any number of additional
                  columns of any type.\
\
pvalueheader:     The value of the header field for the P-value column.\
\
qqpdfoutfile:     The filename of the desired Q-Q plot in PDF\
                  (only required if you want to make a QQ Plot)\
\
manhattanpdfoutfile: The filename of the desired manhattan plot in PDF\
                  (only required if you want to make a Manhattan Plot)\
\
qqpngoutfile:     The filename of the desired Q-Q plot in PNG\
                  (only required if you want to make a QQ Plot)\
\
manhattanpngoutfile: The filename of the desired manhattan plot in PNG\
                  (only required if you want to make a Manhattan Plot)\
\
chrheader:        The value of the header field for the chromosome column.\
                  (only required if you want to make a Manhattan Plot)\
\
posheader:        The value of the header field for the position column.\
                  (only required if you want to make a Manhattan Plot)\
\
Optional parameters are:\
sep:              The field separator character in the input file.\
                  Can specify special value "TAB" for a tab character.\
                  (default: any white space)\
na:               The string indicating missing data in the input\
                  file. (default: NA)\
\
title:            A title for the plot. (default: "" - no title)\
\
pvaluethreshold:  The P-value threshold at which to draw a horizontol line
                  on the Manhattan plot. (default: 1e-5)\
\
chrsep:           Separation (in base-pair units) to insert between\
                  chromosomes for the Manhattan plot.  (default: 0)\
\
*****************************************************************************\
* Example Command Line Usage                                                *\
*****************************************************************************\
\
 * Tab-separated input, plot both manhattan and Q-Q plots:\
R --slave --vanilla --args inputdata=mydata.tsv sep="\t" chrheader="CHR" \\\
posheader="POS_B35" pvalueheader="P.value" pvaluethreshold="1e-5" \\\
manhattanpdfoutfile=manhattan.pdf qqpdfoutfile=qq-plot.pdf < manhattan-qq-plots.R\
\
 * CSV input file, with title, plot both manhattan and Q-Q plots:\
R --slave --vanilla --args title="My beautiful plots" inputdata=mydata.csv \\\
sep="," chrheader="CHR" posheader="POS_B35" pvalueheader="P.value" \\\
pvaluethreshold="1e-5" manhattanpdfoutfile=manhattan.pdf \\\
qqpdfoutfile=qq-plot.pdf < manhattan-qq-plots.R\
\
 * White-space separated input, only plot manhattan plot:\
R --slave --vanilla --args inputdata=mydata.tsv chrheader="CHR" posheader="POS_B35" \\\
pvalueheader="P.value" manhattanpdfoutfile=manhattan.pdf  < manhattan-qq-plots.R\
\
 * White-space separated input, only plot Q-Q plot:\
R --slave --vanilla --args inputdata=mydata.tsv pvalueheader="P.value" \\\
qqpdfoutfile=qq-plot.pdf  < manhattan-qq-plots.R\
\
*****************************************************************************\
* Example Usage from Within R                                               *\
*****************************************************************************\
\
 * White-space separated input, only plot Q-Q plot:\
> inputdata <- "mydata.tsv"\
> pvalueheader <- "P.value"\
> qqpdfoutfile <- "qq-plot.pdf"\
> source("manhattan-qq-plots.R")\
\
*****************************************************************************\
' # End of usage statement


############################################################
# Set defaults for optional arguments
############################################################
pvaluethreshold = 1e-5
dpi=150
na="NA"
title=""
chrsep = 0;

############################################################
# Process command-line arguments into variables
############################################################
for (e in commandArgs(trailingOnly=TRUE)) {
  ta = strsplit(e,"=",fixed=TRUE)
  if(!is.null(ta[[1]][2])) {
    assign(ta[[1]][1],ta[[1]][2])
  } else {
    assign(ta[[1]][1],TRUE)
  }
}

die <- function(message, status=0) {
  cat(usage)
  cat(message,"\n")
  cat("Exiting with status: ",status,"\n")
  quit(save="no", status=status, runLast=FALSE)
}

sortchr <- function(chrlist) {
  return(c(sort(as.numeric(chrlist[!is.na(as.numeric(chrlist))])),sort(as.character(chrlist[is.na(as.numeric(chrlist))]))))
}

############################################################
# Check that necessary arguments have been provided
############################################################
if(!exists("inputdata")) {
  die("You must specify an input filename!",-1)
}

if(!exists("pvalueheader")) {
  die("You must specify pvalueheader!",-2)
}

if((exists("manhattanpdfoutfile") || exists("manhattanpngoutfile")) && !exists("chrheader")) {
  die("You must specify chrheader to make a manhattan plot!",-3)
}

if((exists("manhattanpdfoutfile") || exists("manhattanpngoutfile")) && !exists("posheader")) {
  die("You must specify posheader to make a manhattan plot!",-4)
}

if(!exists("qqpdfoutfile") && !exists("manhattanpdfoutfile") && !exists("qqpngoutfile") && !exists("manhattanpngoutfile") ) {
  die("You must specify at least one of a manhattan plot output filename (manhattanpdfoutfile or manhattanpngoutfile) or a qq plot output filename (qqpdfoutfile or qqpngoutfile)!",-4)
}

if(exists("pvaluethreshold")) {
  pvaluethreshold = as.numeric(pvaluethreshold)
}

if(exists("chrsep")) { # separation between chromosomes, in bp
  chrsep = as.numeric(chrsep)
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
# Set high and low color ranges
# TODO: make this a command-line option
############################################################
lowcolors <- c(oxford.blue,oxford.mid.blue)
highcolors <- lowcolors
#highcolors <- c(wtccc.green,wtccc.green)
#highcolors <- c(oxford.mid.green,oxford.mid.green)
#highcolors <- c(oxford.mid.olive,oxford.mid.olive)


############################################################
# Read input data
############################################################
# First read first 10000 lines to determine the classes to use
if(!exists("sep")) {
  data <- read.table(inputdata, header=TRUE, na.strings=na, nrows=10000, comment.char="", quote="", strip.white=TRUE)
} else {
  data <- read.table(inputdata, header=TRUE, sep=sep, na.strings=na, nrows=10000, comment.char="", quote="", strip.white=TRUE)
}
# Determine data classes automatically
dataclasses <- sapply(data, class)

# Eliminate unwanted columns from the read
if(exists("manhattanpdfoutfile") || exists("manhattanpngoutfile")) {
	dataclasses[!names(data) %in% c(chrheader,posheader,pvalueheader)]<-"NULL"
        # Verify columns we need are present
	if(!chrheader %in% names(data)) {
		cat("have headers ",names(data))
		stop(paste("Could not find chrheader ",chrheader,"in input file",inputdata))
	} else {
          # have chr header -- input chromosome column as character so that X and Y work
          dataclasses[names(data) %in% chrheader]<-"character"
        }
	if(!posheader %in% names(data)) {
		cat("have headers ",names(data))
		stop(paste("Could not find posheader ",posheader,"in input file",inputdata))
	}
} else {
	dataclasses[!names(data) %in% c(pvalueheader)]<-"NULL"
}

if(!pvalueheader %in% names(data)) {
  cat("have headers ",names(data))
  stop(paste("Could not find pvalueheader",pvalueheader,"in input file",inputdata,sep=" "))
}

# Remove old copy of data
remove(data)

# Now actually read the whole input file
if(!exists("sep")) {
  data <- read.table(inputdata, header=TRUE, na.strings=na, colClasses=dataclasses, comment.char="", quote="", strip.white=TRUE)
} else {
  data <- read.table(inputdata, header=TRUE, sep=sep, na.strings=na, colClasses=dataclasses, comment.char="", quote="", strip.white=TRUE)
}

stop()

# recode chr X and Y to 23 and 24
data[,chrheader]<-ifelse(data[,chrheader]=="X",23,data[,chrheader])
data[,chrheader]<-ifelse(data[,chrheader]=="Y",24,data[,chrheader])
data[,chrheader]<-as.numeric(data[,chrheader])

if(exists("manhattanpdfoutfile") || exists("manhattanpngoutfile")) {
  ############################################################
  # Calculate chr/pos offsets
  ############################################################
  chrlist <- sortchr(c(levels(as.factor(as.character(data[,chrheader])))))
  chrstartend <- sapply(chrlist, 
                        function(chr) {
                          chrstartpos <- min(data[data[,chrheader]==chr,posheader],na.rm=TRUE)
                          chrendpos <- max(data[data[,chrheader]==chr,posheader],na.rm=TRUE)
                          overallpos <- 
                            return(c(chrstartpos,chrendpos))
                        })
  chrstart <- chrstartend[1,]
  chrend <- chrstartend[2,] + chrsep
  chroffset <- c(0,cumsum(as.numeric(chrend)))
  labelpos <- ((chroffset[2:(length(chrlist)+1)]-chroffset[1:length(chrlist)])/2) + chroffset[1:length(chrlist)]
  
  
  ############################################################
  # Calculate overall SNP positions
  ############################################################
  snpcumpos <- data[,posheader] + chroffset[match(data[,chrheader],chrlist)]

  ############################################################
  # Calculate SNP colors
  ############################################################
  snpcolor <- lowcolors[data[,chrheader]%%2+1]
  snpcolor[data[,pvalueheader]<=pvaluethreshold] <- highcolors[data[data[,pvalueheader]<=pvaluethreshold,chrheader]%%2+1]
  

  ############################################################
  # Output Manhattan Plot to PDF Device
  ############################################################
  if(exists("manhattanpdfoutfile")) {
    pdf(manhattanpdfoutfile,height=6,width=20) # Open PDF graphics device
  } else if(exists("manhattanpngoutfile")) {
    png(manhattanpngoutfile,height=6,width=20,units="in",res=dpi,bg="transparent") # Open PNG graphics device
  }    
  
  par(mgp=c(1,0,-1.5),mar=c(2,2,1,0)) # Set up the margin lines (sote this will cause a warning for negative values)

  ymax <- max(c(-log10(data[,pvalueheader])),10)
  
  # Make the plot
  plot(snpcumpos,-log10(data[,pvalueheader]),pch=20,col=snpcolor,axes=F,ylab=quote(-log[10] (p)),xlab="Chromosome",main=title,bty="n",ylim=c(0,ymax),cex=data$V6)
  axis(2,las=1)
  mtext(chrlist,1,at=labelpos,cex=1.0,line=0)
  abline(a=-log10(pvaluethreshold),b=0,col=oxford.mid.red)

  # Close graphics device (and write file)
  dev.off()
}

if(exists("qqpdfoutfile") || exists("qqpngoutfile")) {
  ############################################################
  # Output QQ Plot to PDF/PNG Device
  ############################################################
  if(exists("qqpdfoutfile")) {
    pdf(qqpdfoutfile,height=6,width=6) # Open graphics device
  } else if(exists("qqpngoutfile")) {
    png(qqpngoutfile,height=6,width=6,units="in",res=dpi,bg="transparent") # Open graphics device
  }
          
          
  # Setup the plot
  observedpval <- sort(data[,pvalueheader])
  minuslog10observedpval <- -(log10(observedpval))
  expectedpval <- c(1:length(observedpval))
  minuslog10expectedpval <- -(log10( (expectedpval-0.5)/length(expectedpval)))
  obsmax <- trunc(max(minuslog10observedpval))+1
  expmax <- trunc(max(minuslog10expectedpval))+1
  boxlimit <- max(c(obsmax,expmax))
  plot(c(0,boxlimit), c(0,boxlimit), col=oxford.blue, lwd=3, type="l", xlab="Expected (-log10 P-value)", ylab="Observed (-log10 P-value)", xlim=c(0,boxlimit), ylim=c(0,boxlimit), las=1, xaxs="i", yaxs="i", bty="l")

  # Plot the data points
  points(minuslog10expectedpval, minuslog10observedpval, pch=23, cex=.4, col=oxford.mid.blue,bg=oxford.mid.blue) 
  
  dev.off() # Close graphics device (and write file)
}

