###############################################################################
#
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
###############################################################################
# R command line example:
# R --vanilla --args outfile=forest.pdf title="GIANT WH2 meta-analysis" inputdata=metal.out < giantforestplots.R

library(meta)

# process command line arguments
for (e in commandArgs(trailingOnly=TRUE)) {
  ta = strsplit(e,"=",fixed=TRUE)
  if(!is.null(ta[[1]][2])) {
    assign(ta[[1]][1],ta[[1]][2])
  } else {
    assign(ta[[1]][1],TRUE)
  }
}

if(!exists("inputdata")) {
  stop("You must specify an input filename!")
}

if(!exists("outfile")) {
  stop("You must specify a forest plot output filename!")
}

if(!exists("pheno")) {
  stop("You must specify a phenotype!")
}

effect.header="Effect"
stderr.header="StdErr"
pvalue.header="P.value"
ea.header="Allele1"
oa.header="Allele2"
ea.studyheadersuffix="gcc.se.Allele1"
oa.studyheadersuffix="gcc.se.Allele2"
effect.studyheadersuffix="gcc.se.Effect"
stderr.studyheadersuffix="gcc.se.StdErr"
weight.studyheadersuffix="N"
#eaf.studyheadersuffix="EAF"


metadata <- read.table(inputdata,header=TRUE,quote="",sep="\t",as.is=TRUE,na.strings=".",comment.char="",stringsAsFactors=FALSE,colClasses="character")


giantheterogeneity <- function(gender1,gender2,metasnp,metadata) {
	g1.studies <- sub(paste("\\.",gender1,sep=""),"\\.*",sub(paste("\\.",effect.studyheadersuffix,sep=""),"",as.character(names(metadata[metadata[,1]==metasnp,grep(paste("\\.",gender1,"\\..*\\.",effect.studyheadersuffix,"$",sep=""),names(metadata))]))))
	g2.studies <- sub(paste("\\.",gender2,sep=""),"\\.*",sub(paste("\\.",effect.studyheadersuffix,sep=""),"",as.character(names(metadata[metadata[,1]==metasnp,grep(paste("\\.",gender2,"\\..*\\.",effect.studyheadersuffix,"$",sep=""),names(metadata))]))))

	studies <- g1.studies[g1.studies %in% g2.studies]

	snpmetadata <- subset(metadata,metadata[,1]==metasnp,c(
		sapply(studies,function(study) { grep(study,names(metadata)) })
		)
	)


	g1.effect <- as.numeric(snpmetadata[,grep(paste("\\.",gender1,"\\..*\\.",effect.studyheadersuffix,"$",sep=""),names(snpmetadata))])
	g2.effect <- as.numeric(snpmetadata[,grep(paste("\\.",gender2,"\\..*\\.",effect.studyheadersuffix,"$",sep=""),names(snpmetadata))])

	g1.n <- as.numeric(snpmetadata[,grep(paste("\\.",gender1,"\\..*\\.",weight.studyheadersuffix,"$",sep=""),names(snpmetadata))])
	g2.n <- as.numeric(snpmetadata[,grep(paste("\\.",gender2,"\\..*\\.",weight.studyheadersuffix,"$",sep=""),names(snpmetadata))])

	effect.allele <- snpmetadata[,grep(paste("\\.",gender1,"\\..*\\.",ea.studyheadersuffix,"$",sep=""),names(snpmetadata))][1]

	g1.flip <- sapply(snpmetadata[,grep(paste("\\.",gender1,"\\..*\\.",ea.studyheadersuffix,"$",sep=""),names(snpmetadata))],function(x) {ifelse(x==effect.allele,1,-1)})
	g2.flip <- sapply(snpmetadata[,grep(paste("\\.",gender2,"\\..*\\.",ea.studyheadersuffix,"$",sep=""),names(snpmetadata))],function(x) {ifelse(x==effect.allele,1,-1)})
	
	g1.stderr <- as.numeric(snpmetadata[,grep(paste("\\.",gender1,"\\..*\\.",stderr.studyheadersuffix,"$",sep=""),names(snpmetadata))])
	g2.stderr <- as.numeric(snpmetadata[,grep(paste("\\.",gender2,"\\..*\\.",stderr.studyheadersuffix,"$",sep=""),names(snpmetadata))])

	g1.analyses <- sub(paste("\\.",effect.studyheadersuffix,sep=""),"",as.character(names(snpmetadata[,grep(paste("\\.",gender1,"\\..*\\.",effect.studyheadersuffix,"$",sep=""),names(snpmetadata))])))
	g2.analyses <- sub(paste("\\.",effect.studyheadersuffix,sep=""),"",as.character(names(snpmetadata[,grep(paste("\\.",gender2,"\\..*\\.",effect.studyheadersuffix,"$",sep=""),names(snpmetadata))])))


	g1.labels <- sub(paste("\\.",gender1,"\\.WEIGHT\\.UNIFORM",sep=""),"",g1.analyses)
	g2.labels <- sub(paste("\\.",gender2,"\\.WEIGHT\\.UNIFORM",sep=""),"",g2.analyses)

	labels <- c(g1.labels,g2.labels)

	heterogeneity <- metacont(
		g1.n,
		g1.effect,
		g1.stderr,
		g2.n,
		g2.effect,
		g2.stderr,
		g1.labels,
		sm="WMD"	
	)	
	return(heterogeneity)
}

giantmetalgender <- function(gender,metasnp,metadata) {
	effect <- as.numeric(metadata[metadata[,1]==metasnp,grep(paste("\\.",gender,".{0,2}\\..*\\.",effect.studyheadersuffix,"$",sep=""),names(metadata))])
        
	flip <- sapply(metadata[metadata[,1]==metasnp,grep(paste("\\.",gender,".{0,2}\\..*\\.",ea.studyheadersuffix,"$",sep=""),names(metadata))],function(x) {ifelse(x==metadata[metadata[,1]==metasnp,grep(paste("\\.",gender,".{0,2}\\..*\\.",ea.studyheadersuffix,"$",sep=""),names(metadata))][1],1,-1)})

	stderr <- as.numeric(metadata[metadata[,1]==metasnp,grep(paste("\\.",gender,".{0,2}\\..*\\.",stderr.studyheadersuffix,"$",sep=""),names(metadata))])

	studies <- sub(paste("\\.",effect.studyheadersuffix,sep=""),"",as.character(names(metadata[metadata[,1]==metasnp,grep(paste("\\.",gender,".{0,2}\\..*\\.",effect.studyheadersuffix,"$",sep=""),names(metadata))])))

	labels <- sub(paste("\\.",gender,".{0,2}\\.WEIGHT\\.UNIFORM",sep=""),"",studies)

	metal <- metagen(
		effect*flip,
		stderr,
		labels,
		sm="WMD"
	)

	return(metal)
}

giantmetal <- function(metasnp,metadata) {
	stderr.unchecked <- as.numeric(metadata[metadata[,1]==metasnp,grep(paste(".*\\.",stderr.studyheadersuffix,"$",sep=""),names(metadata))])
        good.stderr <- (stderr.unchecked > 0)
        if(FALSE %in% good.stderr) {
          warning(paste("invalid standard error present in",metasnp))
        }
        stderr <- ifelse(good.stderr,stderr.unchecked,NA)
        
	studies <- sub(paste("\\.",effect.studyheadersuffix,sep=""),"",as.character(names(metadata[metadata[,1]==metasnp,grep(paste(".*\\.",effect.studyheadersuffix,"$",sep=""),names(metadata))])))

	effect <- as.numeric(metadata[metadata[,1]==metasnp,grep(paste(".*\\.",effect.studyheadersuffix,"$",sep=""),names(metadata))])

        allele.effect <- toupper(metadata[metadata[,1]==metasnp,ea.header])
        allele.noneffect <- toupper(metadata[metadata[,1]==metasnp,oa.header])

        alleles.effect <- metadata[metadata[,1]==metasnp,grep(paste(".*\\.",ea.studyheadersuffix,"$",sep=""),names(metadata))]
        
	flip <- sapply(alleles.effect,function(x) {ifelse(toupper(x)==allele.effect,1,ifelse(toupper(x)==allele.noneffect,-1,NA))})


	labels <- sub(paste("WEIGHT\\.UNIFORM",sep=""),"",studies)

	metal <- metagen(
		effect*flip,
		stderr,
		labels,
		sm="WMD"
	)

	return(metal)
}

giantforestplot <- function(pheno,allele.effect,allele.noneffect,fixed.p,random.p,metasnp,metal,...) {
	plot(metal,comb.f=TRUE,comb.r=TRUE,xlab=paste("Weighted mean difference attributable to allele",allele.effect),main=paste("GIANT meta-analysis of ",metasnp," (",allele.effect,"/",allele.noneffect,") ","\n",pheno,sep=""),...)
        if(metal$TE.fixed >= 0) {
          text(metal$TE.fixed+2*metal$seTE.fixed,-0.5,paste("P-value:",sprintf("%.2E",fixed.p)),pos=4)
        } else {
          text(metal$TE.fixed-2*metal$seTE.fixed,-0.5,paste("P-value:",sprintf("%.2E",fixed.p)),pos=2)
        }
        if(metal$TE.random >= 0) {
          text(metal$TE.random+2*metal$seTE.random,-2,paste("P-value:",sprintf("%.2E",random.p)),pos=4)
        } else {
          text(metal$TE.random-2*metal$seTE.random,-2,paste("P-value:",sprintf("%.2E",random.p)),pos=2)
        }
#        x <- max(c(abs(min(ci(metal$TE,metal$seTE,level=0.8)$lower,na.rm=TRUE)),abs(max(ci(metal$TE,metal$seTE,level=0.8)$upper,na.rm=TRUE))))
#        mtext(paste(allele.effect,"allele"),side=1,line=2,at=x)
#        mtext(paste(allele.noneffect,"allele"),side=1,line=2,at=-x)
}

giantforestplotgender <- function(gender,metasnp,metal,...) {
	plot(metal,comb.f=TRUE,comb.r=FALSE,xlab=paste("Weighted mean difference attributable to allele",metadata[metadata[,1]==metasnp,grep(paste("\\.",gender,".{0,2}\\..*\\.",ea.studyheadersuffix,"$",sep=""),names(metadata))][1]),main=paste("GIANT meta-analysis of ",metasnp," (",metadata[metadata[,1]==metasnp,grep(paste("\\.",gender,".{0,2}\\..*\\.",ea.studyheadersuffix,"$",sep=""),names(metadata))][1],"/",metadata[metadata[,1]==metasnp,grep(paste("\\.",gender,".{0,2}\\..*\\.",oa.studyheadersuffix,"$",sep=""),names(metadata))][1],")\n","Inverse-normal transformed Weight in ",gender,sep=""),...)
}

giantfunnelplot <- function(gender,metasnp,metal,...) {
	funnel(metal,comb.f=TRUE,level=0.95,xlab=paste("Weighted mean difference attributable to allele",metadata[metadata[,1]==metasnp,grep(paste("\\.",gender,".{0,2}\\..*\\.",ea.studyheadersuffix,"$",sep=""),names(metadata))][1]),main=paste("GIANT meta-analysis of ",metasnp," (",metadata[metadata[,1]==metasnp,grep(paste("\\.",gender,".{0,2}\\..*\\.",ea.studyheadersuffix,"$",sep=""),names(metadata))][1],"/",metadata[metadata[,1]==metasnp,grep(paste("\\.",gender,".{0,2}\\..*\\.",oa.studyheadersuffix,"$",sep=""),names(metadata))][1],")\n","Inverse-normal transformed Weight in ",gender,sep=""),...)
}

giantradialplot <- function(gender,metasnp,metal,...) {
#	radial(metal,comb.f=TRUE,level=0.95,xlab=paste("Weighted mean difference attributable to allele",metadata[metadata[,1]==metasnp,grep(paste("\\.",gender,".{0,2}\\..*\\.",ea.studyheadersuffix,"$",sep=""),names(metadata))][1]),main=paste("GIANT meta-analysis of ",metasnp," (",metadata[metadata[,1]==metasnp,grep(paste("\\.",gender,".{0,2}\\..*\\.",ea.studyheadersuffix,"$",sep=""),names(metadata))][1],"/",metadata[metadata[,1]==metasnp,grep(paste("\\.",gender,".{0,2}\\..*\\.",oa.studyheadersuffix,"$",sep=""),names(metadata))][1],")\n","Inverse-normal transformed Weight in ",gender,sep=""),...)
	radial(metal,comb.f=TRUE,level=0.95,...)
}



giantforestplotsgender <- function(metadata,metasnp) {
	def.par <- par(no.readonly = TRUE)
	layout(matrix(c(1,1,2,2),2,2))
	#layout.show(2)
	menmetal <- giantmetalgender("MEN",metasnp,metadata)
	womenmetal <- giantmetalgender("WOMEN",metasnp,metadata)
        if(!is.na(menmetal$TE) && !is.na(womenmetal$TE)) {
          print(paste("forest plotting snp:",metasnp))
          xmin <- min(c(ci(menmetal$TE,menmetal$seTE)$lower,ci(womenmetal$TE,womenmetal$seTE)$lower),na.rm=TRUE)
          xmax <- max(c(ci(menmetal$TE,menmetal$seTE)$upper,ci(womenmetal$TE,womenmetal$seTE)$upper),na.rm=TRUE)
          giantforestplotgender("MEN",metasnp,menmetal, xlim=c(xmin,xmax))
          giantforestplotgender("WOMEN",metasnp,womenmetal, xlim=c(xmin,xmax))
          par(def.par)
        } else {
          print(paste("skipping snp:",metasnp))
          par(def.par)
        }
}

giantforestplots <- function(pheno,metadata,metasnp) {
	def.par <- par(no.readonly = TRUE)
#	layout(matrix(c(1,1,2,2),2,2))
	allmetal <- giantmetal(metasnp,metadata)
        print(metasnp)
        print(summary(allmetal))

        heterogeneity.i2 <- summary(allmetal)$I2$TE
        heterogeneity.q <- summary(allmetal)$Q
        heterogeneity.p <- 1-pchisq(summary(allmetal)$Q,df=summary(allmetal)$k-1,lower.tail=TRUE)
        
        fixed <- ci(allmetal$TE.fixed,allmetal$seTE.fixed,level=0.95)
        fixed.p <- pnorm(abs(fixed$z),lower.tail=F)*2

        random <- ci(allmetal$TE.random,allmetal$seTE.random,level=0.95)
        random.p <- pnorm(abs(random$z),lower.tail=F)*2

        allele.effect <- toupper(metadata[metadata[,1]==metasnp,ea.header])
        allele.noneffect <- toupper(metadata[metadata[,1]==metasnp,oa.header])

#        gene.symbols <- metadata[metadata[,1]==metasnp,"NEAREST_NON_LOCAKBX_GENE_SYMBOLS"]
#        gene.refseqs <- metadata[metadata[,1]==metasnp,"NEAREST_NON_LOCAKBX_GENE_REFSEQS"]
#        gene.distance <- metadata[metadata[,1]==metasnp,"NEAREST_NON_LOCAKBX_GENE_DISTANCE"]
        chr <- as.numeric(metadata[metadata[,1]==metasnp,"CHR"])
        pos <- as.numeric(metadata[metadata[,1]==metasnp,"POS_B36"])
        pos.mb <- sprintf("%1.2f",(pos/1000000))
        
        stated.effect <- toupper(metadata[metadata[,1]==metasnp,effect.header])
        stated.stderr <- toupper(metadata[metadata[,1]==metasnp,stderr.header])
        stated.p <- toupper(metadata[metadata[,1]==metasnp,pvalue.header])

        print(paste("effect allele:",allele.effect))

        print(paste("stated effect:",stated.effect))
        print(paste("calculated fixed effect:",fixed$TE))
        print(paste("calculated random effect:",random$TE))

        print(paste("stated stderr:",stated.stderr))
        print(paste("calculated fixed stderr:",fixed$seTE))
        print(paste("calculated random stderr:",random$seTE))

        print(paste("stated p-value:",stated.p)) 
        print(paste("calculated fixed effects p-value:",fixed.p))
        print(paste("calculated random effects p-value:",random.p))

        if(exists("heterooutfile")) {
#          heteroresult <- data.frame(MarkerName=metasnp,I2=heterogeneity.i2,Q=heterogeneity.q,Q.P=heterogeneity.p,Fixed.Effect=fixed$TE,Fixed.StdErr=fixed$seTE,Fixed.P=fixed.p,Random.Effect=random$TE,Random.StdErr=random$seTE,Random.P=random.p,Allele1=allele.effect,Allele2=allele.noneffect,CHR=chr,POS=pos,GENE_SYMBOL=gene.symbols,GENE_REFSEQS=gene.refseqs,GENE_DISTANCE=gene.distance)
          heteroresult <- data.frame(MarkerName=metasnp,I2=heterogeneity.i2,Q=heterogeneity.q,Q.P=heterogeneity.p,Fixed.Effect=fixed$TE,Fixed.StdErr=fixed$seTE,Fixed.P=fixed.p,Random.Effect=random$TE,Random.StdErr=random$seTE,Random.P=random.p,Allele1=allele.effect,Allele2=allele.noneffect,CHR=chr,POS=pos)
          if(exists("heteroresults")) {
            print(paste("merging..."))
            print(summary(heteroresults))
            print(summary(heteroresult))
            assign("heteroresults",rbind(heteroresults,heteroresult),envir=globalenv())
          } else {
            assign("heteroresults",heteroresult,envir=globalenv())
          }
        }
        
        print(paste("have",sum(!is.na(allmetal$TE)),"studies for",metasnp))
        if(sum(!is.na(allmetal$TE))>1) {
          print(paste("forest plotting snp:",metasnp))
          xmin <- min(ci(allmetal$TE,allmetal$seTE)$lower,na.rm=TRUE)
          xmax <- max(ci(allmetal$TE,allmetal$seTE)$upper,na.rm=TRUE)
          giantforestplot(paste(pheno," on chr",chr," at ",pos.mb,"Mb)",sep=""),allele.effect,allele.noneffect,fixed.p,random.p,metasnp,allmetal,xlim=c(xmin,xmax))
          par(def.par)
        } else {
          print(paste("skipping snp:",metasnp))
          par(def.par)
        }
}

giantfunnelplots <- function(metadata,metasnp) {
	def.par <- par(no.readonly = TRUE)
	layout(matrix(c(1,1,2,2),2,2))
	#layout.show(2)
	menmetal <- giantmetalgender("men",metasnp,metadata)
	womenmetal <- giantmetalgender("wom",metasnp,metadata)
        if(!is.na(menmetal$TE) && !is.na(womenmetal$TE)) {
          print(paste("funnel plotting snp:",metasnp))
          xmin <- min(c(ci(menmetal$TE,menmetal$seTE)$lower,ci(womenmetal$TE,womenmetal$seTE)$lower),na.rm=TRUE)
          xmax <- max(c(ci(menmetal$TE,menmetal$seTE)$upper,ci(womenmetal$TE,womenmetal$seTE)$upper),na.rm=TRUE)
          giantfunnelplot("MEN",metasnp,menmetal, xlim=c(xmin,xmax))
          giantfunnelplot("WOMEN",metasnp,womenmetal, xlim=c(xmin,xmax))
          par(def.par)
        } else {
          print(paste("skipping snp:",metasnp))
          par(def.par)
        }
}


giantradialplots <- function(metadata,metasnp) {
	def.par <- par(no.readonly = TRUE)
	layout(matrix(c(1,1,2,2),2,2))
	#layout.show(2)
	menmetal <- giantmetalgender("men",metasnp,metadata)
	womenmetal <- giantmetalgender("wom",metasnp,metadata)
        if(!is.na(menmetal$TE) && !is.na(womenmetal$TE)) {
          print(paste("radial plotting snp:",metasnp))
          #	xmin <- min(c(ci(menmetal$TE,menmetal$seTE)$lower,ci(womenmetal$TE,womenmetal$seTE)$lower),na.rm=TRUE)
          #	xmax <- max(c(ci(menmetal$TE,menmetal$seTE)$upper,ci(womenmetal$TE,womenmetal$seTE)$upper),na.rm=TRUE)
          xmin <- min(c(1/menmetal$seTE,1/womenmetal$seTE),na.rm=TRUE)
          xmax <- max(c(1/menmetal$seTE,1/womenmetal$seTE),na.rm=TRUE)
          giantradialplot("MEN",metasnp,menmetal,xlim=c(xmin,xmax),ylim=c(-3,3))
          giantradialplot("WOMEN",metasnp,womenmetal,xlim=c(xmin,xmax),ylim=c(-3,3))
          par(def.par)
        } else {
          print(paste("skipping snp:",metasnp))
          par(def.par)
        }
}


giantforestplotsmetadata <- function(metasnp) {
	giantforestplots(pheno,metadata,metasnp)
}

giantforestplotsmetadatapause <- function(metasnp) {
	giantforestplots(pheno,metadata,metasnp)
	pause()
}

giantfunnelplotsmetadata <- function(metasnp) {
	giantfunnelplots(pheno,metadata,metasnp)
}

giantfunnelplotsmetadatapause <- function(metasnp) {
	giantfunnelplots(pheno,metadata,metasnp)
	pause()
}

giantradialplotsmetadata <- function(metasnp) {
	giantradialplots(pheno,metadata,metasnp)
}

giantradialplotsmetadatapause <- function(metasnp) {
	giantradialplots(pheno,metadata,metasnp)
	pause()
}


giantplotsmetadata <- function(metasnp,pheno) {
	giantforestplots(pheno,metadata,metasnp)
	giantfunnelplots(pheno,metadata,metasnp)
	giantradialplots(pheno,metadata,metasnp)
}

giantplotsmetadatapause <- function(metasnp,pheno) {
	giantforestplots(pheno,metadata,metasnp)
	giantfunnelplots(pheno,metadata,metasnp)
	giantradialplots(pheno,metadata,metasnp)
	pause()
}

giantplotpdf <- function(filename) {
	pdf(filename,width=11.69,height=8.26)
	sapply(metadata[,1],giantplotsmetadata)
	dev.off()
}


#pdf(outfile,width=116.9,height=82.6)
pdf(outfile,width=35.07,height=24.78)
sapply(metadata[,1],giantforestplotsmetadata)
dev.off()

if(exists("heterooutfile")) {
  write.table(heteroresults,file=heterooutfile,quote=FALSE,sep="\t",row.names=FALSE,col.names=TRUE)
}
