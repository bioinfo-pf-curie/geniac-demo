require(GLAD)

data(snijders)
gm13330$Clone <- gm13330$BAC
profileCGH <- as.profileCGH(gm13330)


###########################################################
###
###  daglad function
###
###########################################################


res <- daglad(profileCGH, mediancenter=FALSE, normalrefcenter=FALSE, genomestep=FALSE,
              smoothfunc="lawsglad", lkern="Exponential", model="Gaussian",
              qlambda=0.999,  bandwidth=10, base=FALSE, round=1.5,
              lambdabreak=8, lambdaclusterGen=40, param=c(d=6), alpha=0.001, msize=2,
              method="centroid", nmin=1, nmax=8,
              amplicon=1, deletion=-5, deltaN=0.10,  forceGL=c(-0.15,0.15), nbsigma=3,
              MinBkpWeight=0.35, CheckBkpPos=TRUE)

write.table(res$BkpInfo, file="BkpInfo.tsv", sep="\t", row.names=FALSE)

