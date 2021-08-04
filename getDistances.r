# Get walking distances between glottolog languages via google maps
# This requires a google API key.
# And assumes there's a folder "GoogleDistanceFiles" is present, and within this a folder called "a", "b", "c", "d", etc.. These folders store temporary results files.

# Note that by now there is a function to get distance matrices directly:
# https://developers.google.com/maps/documentation/distance-matrix/overview

# Google limits the number of queries, so this file runs until that limit is reached, saving the progress so far.  Run the script again to fill up the results.

setwd("~/Documents/MPI/NTS/Complexity/Distance/")
#library(rjson)
library(fields)
library(RCurl)
library(jsonlite)

# limit search to langauge pairs which are within this range:
searchDistanceThreshold = 200#km

googleAPIKey = readLines("APIKEY.txt",n=1)

#outFilename = paste("WalkingDistances_",sample(1:10000,1),'.csv',sep='')

outFilename = "WalkingDistances_6666.csv"

readJSON = function(d){
	
	# try reading JSON using fromJSON
	# (sometimes this doesn't work because of parsing errors)
	d2 = c()
	try(d2 <- fromJSON(d),silent=T)
	if(length(d2)>0){
		if(!"status" %in% names(d2)){
			return(c(NA,NA,"ERRORNoData"))	
		}	
		if(d2$status=="OK"){
			dist = d2$routes[[1]]$legs[[1]]$distance$value
			dur = d2$routes[[1]]$legs[[1]]$duration$value
			return(c(dist,dur,"OK"))
		}
		else{
			return(c(NA,NA,d2$status))
			}
	}
	
	# try extracting just the bits we need, then re-parsing
	d2 = substr(d,regexpr("distance",d)[1]-2,regexpr("end_address",d)[1]-2)
	
	endComma = tail(gregexpr("\\,",d2)[[1]],1)
	d2 = substr(d2,1,endComma-1)
	
	jx = fromJSON(paste("{",d2,"}"))
	return(c(jx$distance$value,jx$duration$value,"OK"))
}


getFromAPI = function(long1,lat1,long2,lat2,lang1,lang2){
		s1 = "https://maps.googleapis.com/maps/api/directions/json?origin="
		s2 = "&destination="
		s3 = paste("&mode=walking&avoid=ferries&alternatives=false&key=",googleAPIKey,sep='')
		
		callString = paste(s1,lat1,",",long1,s2,lat2,",",long2,s3,sep='')
		
		
		# usage limits are set to 10 per second
		Sys.sleep(2/10)
		d = getURL(callString)
		
		if(length(d)>1){
			d = paste(d,collapse='\n')
		}
	return(d)
}


getGoogleDistance = function(long1,lat1,long2,lat2,lang1,lang2){
	# return dist, duration and server response message
	folder = paste('GoogleDistanceFiles/',substr(lang1,1,1),'/',lang1,sep='')
	
	dir.create(folder,showWarnings=F)

	fn = paste(folder,"/",paste(lang1,lang2,sep='_'),'.json',sep='')
	
	getFromWeb=F
	d = ""
	# check if we've already downloaded the data
	if(file.exists(fn)){
		d = readLines(fn)
		d = paste(d,collapse='\n')
		# but if the downloaded file hit a query limit, download again
		if(grepl("OVER_QUERY_LIMIT",d)[1]){
			getFromWeb=T
		}
	}
	else{
		getFromWeb=T
	}
	
	if(getFromWeb){
		d = getFromAPI(long1,lat1,long2,lat2,lang1,lang2)
		cat(d,file=fn)
	}
	
	gOut = c(NA,NA,"ErrorInReadJSON")
	try(gOut <- readJSON(d))
	
	return(gOut)	

}

saveTheData = function(res){
	res = res[!is.na(res$from),]
	write.csv(res,file=outFilename,row.names=F)
}


glotto = read.table("../Data/isoLatLongGlotto.tab",sep='\t',stringsAsFactors=F,header=T)
rownames(glotto) = glotto$glottoID

glotto.dist = rdist.earth(cbind(glotto$long,glotto$lat),miles=F)
rownames(glotto.dist) = glotto$glottoID
colnames(glotto.dist) = glotto$glottoID

# matrix is symmetrical, so set one triangle high to avoid calculating it (also sets diagnoal to infinite so we're not requesting distance from langauge to itself)
glotto.dist[upper.tri(glotto.dist,diag=T)] = Inf

# find pairs of languages that are reasonably close
targetPairs = which(glotto.dist<=searchDistanceThreshold & glotto.dist>0,arr.ind=T)

origin = rownames(glotto.dist)[targetPairs[,1]]
dest = rownames(glotto.dist)[targetPairs[,2]]

origin.long = glotto[origin,]$long
origin.lat = glotto[origin,]$lat

dest.long = glotto[dest,]$long
dest.lat = glotto[dest,]$lat

res = data.frame(from=NA,to=NA,dist=NA,dur=NA,gAPI=NA)
# if we've made some progress, just load the progress
if(file.exists(outFilename)){
	res = read.csv(outFilename)
	# take out possible row name column
	res = res[,names(res)!='X']
	res = res[!is.na(res$from),]
	
	# find pairs that we've done already
	pairsToDo = apply(cbind(origin,dest),1,function(X){paste(X,collapse='')})
	donePairs = apply(res[!is.na(res$from),c('from','to')],1,function(X){paste(X,collapse='')})
	
	# keep the pair in the list for processing if it's already in res or if the last time we tried, we got a server error
	toKeep = (pairsToDo %in% donePairs) | res$gAPI=="OVER_QUERY_LIMIT"
	
	# remove them from target pairs
	targetPairs = targetPairs[toKeep,]
	origin = origin[toKeep]
	dest = dest[toKeep]
	origin.long = origin.long[toKeep]
	origin.lat = origin.lat[toKeep]
	dest.long = dest.long[toKeep]
	dest.lat = dest.lat[toKeep]
	
}


for(i in 1:length(origin)){
	fromX = origin[i]
	toX = dest[i]
	# get distance
	g = getGoogleDistance(origin.long[i],origin.lat[i],dest.long[i],dest.lat[i],fromX,toX)
	#long1 = origin.long[i]; lat1 = origin.lat[i]; long2 = dest.long[i]; lat2 = dest.lat[i]
	
	# if we've reached the query limit, quit
	if(!is.na(g[3])){
		if(g[3]=="OVER_QUERY_LIMIT"){

			saveTheData(res)
			
			print("OVER QUERY LIMIT")
			print(date())
			quit(save='no')
		}
	}
	
	# add to data frame
	res = rbind(res,c(fromX,toX,g))
	
	if((i %% 100)==0){
		# periodically write the file
		saveTheData(res)
		print(i)
	}
}
# write the file
saveTheData(res)