# Work out distances between languages for use with Hammarstrom's algorithm for finding neighbours

library(fields)
setwd("~/Documents/MPI/NTS/Complexity/Distance/")

gdat = read.csv("../Data/glottolog-languoid.csv/languoid.csv",stringsAsFactors = F)
gdat$family = gdat[match(gdat$family_pk,gdat$pk),]$name
gdat[is.na(gdat$family),]$family = paste("Isolate",1:sum(is.na(gdat$family)))
# Keep languages and dialects
gdat = gdat[gdat$level!='family' & !is.na(gdat$longitude) & !is.na(gdat$latitude),]

# Remove bookkeeping and unattested
gdat = gdat[gdat$bookkeeping == "False",]
gdat = gdat[gdat$family!="Unattested",]

# Keep extinct languages, since some NTS languages are extinct


glotto.dist = rdist.earth(cbind(gdat$longitude,gdat$latitude),miles=F)
rownames(glotto.dist) = gdat$id
colnames(glotto.dist) = gdat$id

glotto.dist[glotto.dist<0.1] = 0

write.csv(glotto.dist,"glottologDistances.csv",row.names = F, quote=F)

#i = which(colnames(glotto.dist)=='west2368')
#j = which(colnames(glotto.dist)=='yagn1238')

# neighbours = matrix(nrow=nrow(glotto.dist),ncol=nrow(glotto.dist))
# 
# sapply(1:(nrow(glotto.dist)-1), function(i){
#   lA = glotto.dist[i,]
#   sapply((i+1):nrow(glotto.dist),function(j){
#     lB = glotto.dist[j,]
#     print(paste(i,j))
#     AB = lA[j]
#     AC = lA[-j]
#     BC = lB[-i]
#     
#     glotto.dist[i,]
#     glotto.dist[j,]
#     
#     neighbours[i,j] = !(sum((AC < AB & BC < AB))>0)
#   })
# })
# 
