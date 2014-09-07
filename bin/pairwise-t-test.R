###############################################################################
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
###############################################################################

# R command line example:
# R --vanilla --args infile=MENunr.WEIGHT.UNIFORM.vs.WOMENunr.WEIGHT.UNIFORM.metal.out effect1header=MENunr.WEIGHT.UNIFORM.Effect effect2header=WOMENunr.WEIGHT.UNIFORM.Effect se1header=MENunr.WEIGHT.UNIFORM.StdErr se2header=WOMENunr.WEIGHT.UNIFORM.StdErr n=28 < pairwise-t-test.R

# process command line arguments
for (e in commandArgs(trailingOnly=TRUE)) {
  ta = strsplit(e,"=",fixed=TRUE)
  if(!is.null(ta[[1]][2])) {
    assign(ta[[1]][1],ta[[1]][2])
  } else {
    assign(ta[[1]][1],TRUE)
  }
}

if(!exists("infile")) {
  stop("You must specify an input filename!")
}

if(!exists("effect1header")) {
  stop("You must specify a effect header for data set 1!")
} else {
  effect1header <- make.names(effect1header)
}

if(!exists("effect2header")) {
  stop("You must specify a effect header for data set 2!")
} else {
  effect2header <- make.names(effect2header)
}

if(!exists("se1header")) {
  stop("You must specify a standard error header for data set 1!")
} else {
  se1header <- make.names(se1header)
}

if(!exists("se2header")) {
  stop("You must specify a standard error header for data set 2!")
} else {
  se2header <- make.names(se2header)
}

if(!exists("totaln1header")) {
  stop("You must specify a total N header for data set 1!")
}  else {
  totaln1header <- make.names(totaln1header)
}

if(!exists("totaln2header")) {
  stop("You must specify a total N header for data set 2!")
} else {
  totaln2header <- make.names(totaln2header)
}

if(!exists("markerheader")) {
  stop("You must specify a marker header!")
} else {
  markerheader <- make.names(markerheader)
}

if(!exists("outfile")) {
  stop("You must specify an output file!")
}

if(!exists("nstudies")) {
  if(!(exists("direction1header") && exists("direction2header"))) {
    stop("You must specify n or direction headers!")
  }
} else {
  nstudies <- as.numeric(nstudies)
}


# read first 10000 lines to determine the classes to use
datafirst10000 <- read.table(infile,stringsAsFactors=FALSE,header=TRUE,sep="\t",nrows=10000,na.strings=c("NA",".",""))
dataclasses <- sapply(datafirst10000, class)
remove(datafirst10000)
# now actually read the whole thing
data<-read.table(infile,stringsAsFactors=FALSE,header=TRUE,sep="\t",colClasses=dataclasses,na.strings=c("NA",".",""))

n.inds <- data[,totaln1header] + data[,totaln2header] 
#data <- data[n.inds>33565.66,]

marker <- data[,markerheader]
effect.1 <- data[,effect1header]
effect.2 <- data[,effect2header]
se.1 <- data[,se1header]
se.2 <- data[,se2header]
n.inds.1 <- data[,totaln1header]
n.inds.2 <- data[,totaln2header]

sd.1 <- sqrt(n.inds.1) * se.1
sd.2 <- sqrt(n.inds.2) * se.2
  
var.1 <- sd.1^2
var.2 <- sd.2^2

if(exists("direction1header") && exists("direction2header")) {
  dir.1 <- data[,make.names(direction1header)]
  dir.2 <- data[,make.names(direction2header)]
  k.studies <- nchar(gsub("?","",dir.1,fixed=TRUE),type="chars")+nchar(gsub("?","",dir.2,fixed=TRUE),type="chars")
}

#####################################################
# Calculate correlation between effect estimates
#####################################################
p.cor.1.2 <- cor.test(effect.1,effect.2,alternative="two.sided",method="pearson")
p.cor.coef.1.2 <- p.cor.1.2$estimate
print(p.cor.1.2)

s.cor.1.2 <- cor.test(effect.1,effect.2,alternative="two.sided",method="spearman")
s.cor.coef.1.2 <- s.cor.1.2$estimate
print(s.cor.1.2)


#####################################################
# Independent two-sample t-tests
#####################################################

# calculate t-test statistic for equal sample size, equal variance
equal.n.equal.var.sd.pooled.1.2 <- sqrt((var.1+var.2)/2)
equal.n.equal.var.t.test <- (effect.1 - effect.2)/(equal.n.equal.var.sd.pooled.1.2 * sqrt(2/n.inds))
equal.n.equal.var.df <- (2 * n.inds) - 2

# calculate t-test statistic for unequal sample size, equal variance
unequal.n.equal.var.sd.pooled.1.2 <- sqrt((( ((n.inds.1-1) * var.1) + ((n.inds.2 - 1) * var.2)))/(n.inds.1 + n.inds.2 - 2))
unequal.n.equal.var.t.test <- (effect.1 - effect.2)/(unequal.n.equal.var.sd.pooled.1.2 * sqrt(1/n.inds.1 + 1/n.inds.2))
unequal.n.equal.var.df <- n.inds.1 + n.inds.2 - 2

# calculate t-test statistic for unequal sample size, unequal variance (Welch's T-test)
se.difference.1.2 <- sqrt(se.1^2 + se.2^2)
unequal.n.unequal.var.t.test <- (effect.1-effect.2)/se.difference.1.2
unequal.n.unequal.var.df <- ((se.1^2+se.2^2)^2) / ( ((se.1^2)^2/(n.inds.1-1))+((se.2^2)^2/(n.inds.2-1))) # welch-satterthwaite equation for df with unequal sample size and unequal variance

# calculate t-test statistic for unequal sample size, unequal variance (Welch's T-test), correcting for correlation (Pearson)
se.difference.pcorr.1.2 <- sqrt(se.1^2 + se.2^2 - (2 * p.cor.coef.1.2 * se.1 * se.2))
unequal.n.unequal.var.pcorr.t.test <- (effect.1-effect.2)/se.difference.pcorr.1.2
unequal.n.unequal.var.pcorr.df <- ((se.1^2+se.2^2)^2) / ( ((se.1^2)^2/(n.inds.1-1))+((se.2^2)^2/(n.inds.2-1))) # welch-satterthwaite equation for df with unequal sample size and unequal variance

# calculate t-test statistic for unequal sample size, unequal variance (Welch's T-test), correcting for correlation (Spearman)
se.difference.scorr.1.2 <- sqrt(se.1^2 + se.2^2 - (2 * s.cor.coef.1.2 * se.1 * se.2))
unequal.n.unequal.var.scorr.t.test <- (effect.1-effect.2)/se.difference.scorr.1.2
unequal.n.unequal.var.scorr.df <- ((se.1^2+se.2^2)^2) / ( ((se.1^2)^2/(n.inds.1-1))+((se.2^2)^2/(n.inds.2-1))) # welch-satterthwaite equation for df with unequal sample size and unequal variance

# Student's T distribution P-values
equal.n.equal.var.t.test.student.pval <- 2*pt(-abs(equal.n.equal.var.t.test),df=equal.n.equal.var.df)
unequal.n.equal.var.t.test.student.pval <- 2*pt(-abs(unequal.n.equal.var.t.test),df=unequal.n.equal.var.df)
unequal.n.unequal.var.t.test.student.pval <- 2*pt(-abs(unequal.n.unequal.var.t.test),df=unequal.n.unequal.var.df)
unequal.n.unequal.var.pcorr.t.test.student.pval <- 2*pt(-abs(unequal.n.unequal.var.pcorr.t.test),df=unequal.n.unequal.var.pcorr.df)
unequal.n.unequal.var.scorr.t.test.student.pval <- 2*pt(-abs(unequal.n.unequal.var.scorr.t.test),df=unequal.n.unequal.var.scorr.df)

# Normal distribution P-values (normal approximation)
equal.n.equal.var.t.test.normal.pval <- 2*pnorm(-abs(equal.n.equal.var.t.test))
unequal.n.equal.var.t.test.normal.pval <- 2*pnorm(-abs(unequal.n.equal.var.t.test))
unequal.n.unequal.var.t.test.normal.pval <- 2*pnorm(-abs(unequal.n.unequal.var.t.test))
unequal.n.unequal.var.pcorr.t.test.normal.pval <- 2*pnorm(-abs(unequal.n.unequal.var.pcorr.t.test))
unequal.n.unequal.var.scorr.t.test.normal.pval <- 2*pnorm(-abs(unequal.n.unequal.var.scorr.t.test))

# Prepare to Output data
outdata <- data.frame(MarkerName=marker, EFFECT.1=effect.1, STDERR.1=se.1, SD.1=sd.1, VAR.1=var.1, EFFECT.2=effect.2, STDERR.2=se.2, SD.2=sd.2, VAR.2=var.2, EQUAL.N.EQUAL.VAR.SD.POOLED.1.2=equal.n.equal.var.sd.pooled.1.2, EQUAL.N.EQUAL.VAR.T.TEST=equal.n.equal.var.t.test, EQUAL.N.EQUAL.VAR.DF=equal.n.equal.var.df, UNEQUAL.N.EQUAL.VAR.SD.POOLED.1.2=unequal.n.equal.var.sd.pooled.1.2, UNEQUAL.N.EQUAL.VAR.T.TEST=unequal.n.equal.var.t.test, UNEQUAL.N.EQUAL.VAR.DF=unequal.n.equal.var.df, SE.DIFFERENCE.1.2=se.difference.1.2, UNEQUAL.N.UNEQUAL.VAR.T.TEST=unequal.n.unequal.var.t.test, UNEQUAL.N.UNEQUAL.VAR.DF=unequal.n.unequal.var.df, SE.DIFFERENCE.PCORR.1.2=se.difference.pcorr.1.2, UNEQUAL.N.UNEQUAL.VAR.PCORR.T.TEST=unequal.n.unequal.var.pcorr.t.test, UNEQUAL.N.UNEQUAL.VAR.PCORR.DF=unequal.n.unequal.var.pcorr.df, SE.DIFFERENCE.SCORR.1.2=se.difference.scorr.1.2, UNEQUAL.N.UNEQUAL.VAR.SCORR.T.TEST=unequal.n.unequal.var.scorr.t.test, UNEQUAL.N.UNEQUAL.VAR.SCORR.DF=unequal.n.unequal.var.scorr.df, EQUAL.N.EQUAL.VAR.T.TEST.NORMAL.PVAL=equal.n.equal.var.t.test.normal.pval, UNEQUAL.N.EQUAL.VAR.T.TEST.NORMAL.PVAL=unequal.n.equal.var.t.test.normal.pval, UNEQUAL.N.UNEQUAL.VAR.T.TEST.NORMAL.PVAL=unequal.n.unequal.var.t.test.normal.pval, UNEQUAL.N.UNEQUAL.VAR.PCORR.T.TEST.NORMAL.PVAL=unequal.n.unequal.var.pcorr.t.test.normal.pval, UNEQUAL.N.UNEQUAL.VAR.SCORR.T.TEST.NORMAL.PVAL=unequal.n.unequal.var.scorr.t.test.normal.pval, EQUAL.N.EQUAL.VAR.T.TEST.STUDENT.PVAL=equal.n.equal.var.t.test.student.pval, UNEQUAL.N.EQUAL.VAR.T.TEST.STUDENT.PVAL=unequal.n.equal.var.t.test.student.pval, UNEQUAL.N.UNEQUAL.VAR.T.TEST.STUDENT.PVAL=unequal.n.unequal.var.t.test.student.pval, UNEQUAL.N.UNEQUAL.VAR.PCORR.T.TEST.STUDENT.PVAL=unequal.n.unequal.var.pcorr.t.test.student.pval, UNEQUAL.N.UNEQUAL.VAR.SCORR.T.TEST.STUDENT.PVAL=unequal.n.unequal.var.scorr.t.test.student.pval, N.1=n.inds.1, N.2=n.inds.2, N=n.inds, K.STUDIES=k.studies)

# Only keep markers present in at least 2 studies
outdata <- subset(outdata,K.STUDIES>=2)

# Write to file
write.table(outdata, file=outfile, quote=FALSE, sep="\t", na=".", row.names=FALSE, col.names=TRUE)


