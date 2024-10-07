library(r2redux)
#trNum: number of traits
#mprsdt: a pre-calculated file with conventional PGS across traits
#v_tr_cbdt: a precalculated file with vPGS across traits (mprsdt, and v_tr_cbdt have matched column name)
#phedt: phenotype file for all target traits (the 1st and 2nd columns of mprsdt, v_tr_cbdt and phedt are FID and IID, the trait values start from the 3rd column)
#


r2_trlooplist <- list()
for (trNum in gsub('tr','',colnames(mprsdt)[-1])){
trn <- paste0('tr',trNum)
trname <- colnames(phedt)[2+as.numeric(trNum)]
tmp <- merge(mprsdt[,which(colnames(mprsdt) %in% c('IID',trn)),with=F],v_tr_cbdt[,which(colnames(v_tr_cbdt) %in% c('IID',trn)),with=F],by='IID',sort=F)
colnames(tmp) <- gsub('.x','.m',colnames(tmp))
colnames(tmp) <- gsub('.y','.v',colnames(tmp))
tmp1 <- merge(phedt[,c(2,2+as.numeric(trNum)),with=F],tmp,by='IID',sort=F)
tmp2 <- tmp1[complete.cases(tmp1),-1]
output=r2redux::r2_diff(tmp2,c(1,2),1,nrow(tmp2))
res <- data.frame(trn,trname,r2_2prs=output$rsq1,r2_muprs=output$rsq2,r2_diff=output$mean_diff,r2_p=output$r2_based_p,r2_lrt_p=as.numeric(strsplit(as.character(output$LRT_p)," +")[[1]][1]))
r2_trlooplist[[trn]] <- res
}



