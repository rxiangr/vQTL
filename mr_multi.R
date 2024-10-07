#!/usr/bin/env Rscript
args = commandArgs(trailingOnly=TRUE)
if (length(args)<4) {
  stop(" argument must be supplied", call.=FALSE)
}

library(data.table)
library(dplyr)
library(MendelianRandomization)
library(MRPRESSO)
source("/rds/project/asb38/rds-asb38-ceu-ukbiobank/projects/P7439/inouyelab/rx235/vqtl/mr/gsmr_plot_rx.r")

efffn <- args[1] # a file that contains GWAS summary statistics including SNP ID, beta, se and p for X (exposure) and beta, se and p for Y (outcome) 
x <- args[2] # name of exopure trait, e.g., blodd cell trait variance
y <- args[3] # name of outcome trait, e.g., alcohol consumption
outpath <- args[4]
outpref <- args[5]

effdt <- read.table(efffn)
effdt1 <- setDT(data.frame(SNP=effdt$snp,b.x=effdt$bzx,se.x=effdt$bzx_se,p.x=effdt$bzx_pval,b.y=effdt$bzy,se.y=effdt$bzy_se,p.y=effdt$bzy_pval))
MRInputObject <- mr_input(bx =effdt1$b.x,bxse =effdt1$se.x, by =effdt1$b.y, byse =effdt1$se.y)
WeightedMedianObject <- mr_median(MRInputObject,weighting = "weighted",distribution = "normal",alpha = 0.05,iterations = 10000,seed = 314159265)
cat(paste0('Doing wm at ',Sys.time()),'\n')
wmerres <- data.frame(fn=outpref,method='wm',b=WeightedMedianObject$Estimate,se=WeightedMedianObject$StdError,p=WeightedMedianObject$Pvalue,nSNP=WeightedMedianObject$SNPs)
cat(paste0('Doing presso at ',Sys.time()),'\n')
pressodt <- as.data.frame(copy(effdt1))
pressores <-  mr_presso(BetaOutcome = "b.y", BetaExposure = "b.x", SdOutcome = "se.y", SdExposure = "se.x", OUTLIERtest = TRUE, DISTORTIONtest = TRUE, data = pressodt, NbDistribution = 1000,  SignifThreshold = 0.05)
pressores
pressores_colsub <- data.frame(fn=outpref,method='presso',b=data.frame(pressores[1])[,c(3)],se=data.frame(pressores[1])[,c(4)],p=data.frame(pressores[1])[,c(6)],nSNP=WeightedMedianObject$SNPs)
pressores_colsub[1,3] <- 'presso_raw'
cbres <- setDT(rbind(wmerres,pressores_colsub))
cbres[,b:=round(b,3)]
cbres[,se:=round(se,3)]
cbres[,p:=ifelse(p>1e-3,round(p,4),round(p,5))]
write.table(cbres,paste0(outpath,'/',outpref,'.table.txt'),row.names=F,quote=F,sep='\t')
cat(paste0('All analyses finished at ',Sys.time()),'\n')

