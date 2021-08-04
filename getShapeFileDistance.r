# Running this requires data from the world mapping system, which is not provided in this repository

library(rgdal)
library(maptools)
library(spdep)
setwd("~/Documents/MPI/NTS/Complexity/Distance/")


#d = readOGR("LangShapeFiles_DONOTSHARE/gmi16/eth_wlms.dbf",'polygons')

d = readShapePoly('../../LangShapeFiles_DONOTSHARE/gmi16/langa.shp')


area = sapply(d@polygons,function(X){X@area})
areaX = data.frame(
  area=area,
  id = as.character(d$ID),
  iso=as.character(d$LANG_ISO),
  iso.a2 = as.character(d$ID_ISO_A2),
  iso.a2 = as.character(d$ID_ISO_A2),
  family = as.character(d$FAMILYPROP),
  name = as.character(d$NAME_PROP),
  pop = as.character(d$POP)
)
write.csv(areaX,file='../../Ethnologue_data.csv')



spolys = SpatialPolygons(d@polygons,1:nrow(d))
spolys <- SpatialPolygonsDataFrame(spolys, data.frame(ID=d$ID) ,match.ID=F)   

proj4string(spolys) <- "+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0"
   
   
skNN.nb <- knn2nb(knearneigh(coordinates(spolys), longlat=TRUE), row.names=spolys@data$ID)
   
# Calculate maximum distance for all linkages 
maxDist <- max(unlist(nbdists(skNN.nb, coordinates(spolys), longlat=TRUE)))

# Create spdep distance object
sDist <- dnearneigh(coordinates(spolys), 0, maxDist^2, row.names=spolys@data$ID, longlat = T)
summary(sDist, coordinates(spolys), longlat=TRUE)

dist.list <- nbdists(sDist, coordinates(spolys), longlat=TRUE) 

dist.min <- lapply(dist.list, FUN=min) 

#save(dist.list,file='Complexity/Distance/PolygonDistance.rDat')
#save(dist.min,file='Complexity/Distance/PolygonDistance_min.rDat')


#dist.m = matrix(unlist(dist.list),ncol=length(dist.list),byrow=T)
#row.names(dist.m) = d$ID

m = matrix(nrow=length(dist.list),ncol=length(dist.list))
for(i in 1:length(dist.list)){
		if(length(dist.list[i][[1]])==ncol(m)-1){
			m[i,] = append(dist.list[i][[1]],0,i-1)
		}
}
rownames(m) = d$ID
colnames(m)= d$ID
write.csv(m,file='PolygonDistance.csv',row.names=F,quote=F)
dx = m
saveRDS(dx,"PolygonDistanceWithEIDs.rds")
