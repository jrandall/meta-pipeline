############################################################
# logx-logy-label-plot.R
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

############################################################
# Set Defaults
############################################################
dpi=150
na="NA"
title=""
sep="\t"

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


############################################################
# Check that necessary arguments have been provided
############################################################
if(!exists("inputdata")) {
  die("You must specify an input filename!",-1)
}

if(!exists("xheader")) {
  die("You must specify an X header!",-2)
}

if(!exists("yheader")) {
  die("You must specify an Y header!",-2)
}

if(!exists("labelheader")) {
  die("You must specify a label header!",-2)
}

if(!(exists("pdfoutfile") || exists("pngoutfile"))) {
  die("You must specify an output file!",-2)
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
# First read first 10000 lines to determine the classes to use
if(!exists("sep")) {
  data <- read.table(inputdata, header=TRUE, na.strings=na, nrows=10000, comment.char="", quote="", strip.white=TRUE)
} else {
  data <- read.table(inputdata, header=TRUE, sep=sep, na.strings=na, nrows=10000, comment.char="", quote="", strip.white=TRUE)
}
# Determine data classes automatically
dataclasses <- sapply(data, class)

# Eliminate unwanted columns from the read
dataclasses[!names(data) %in% c(xheader,yheader,labelheader)]<-"NULL"

# Verify columns we need are present
if(!xheader %in% names(data)) {
  cat("have headers ",names(data))
  stop(paste("Could not find xheader ",xheader,"in input file",inputdata))
}
if(!yheader %in% names(data)) {
  cat("have headers ",names(data))
  stop(paste("Could not find yheader ",yheader,"in input file",inputdata))
}
if(!labelheader %in% names(data)) {
  cat("have headers ",names(data))
  stop(paste("Could not find labelheader ",labelheader,"in input file",inputdata))
}

# Remove old copy of data
remove(data)

# Now actually read the whole input file
if(!exists("sep")) {
  data <- read.table(inputdata, header=TRUE, na.strings=na, colClasses=dataclasses, comment.char="", quote="", strip.white=TRUE)
} else {
  data <- read.table(inputdata, header=TRUE, sep=sep, na.strings=na, colClasses=dataclasses, comment.char="", quote="", strip.white=TRUE)
}



############################################################
# Prepare to output Plot to PDF/PNG Device
############################################################
if(exists("pdfoutfile")) {
  pdf(pdfoutfile,height=6,width=6) # Open graphics device
} else if(exists("pngoutfile")) {
  png(pngoutfile,height=6,width=6,units="in",res=dpi,bg="transparent") # Open graphics device
}


# Make the plot
plotdata <- data.frame(x=-log10(data[,xheader]), y=-log10(data[,yheader]), label=data[,labelheader])

ggplot(data=plotdata, mapping=aes(x=x,y=y)) + geom_point() + geom_text(mapping=aes(label=label),size=I(2),hjust=I(0),vjust=I(0)) + scale_x_continuous(name=paste("-log[10] (",xheader,")")) + scale_y_continuous(name=paste("-log[10] (",yheader,")",sep="")) + opts(title=title)


# Close graphics device (and write file)
dev.off()

