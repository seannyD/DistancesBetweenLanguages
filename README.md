#  Geographic distances between languages


## WalkingDistances_Final.csv

Walking distances between glottolog languages, according to Google Maps (derived in 2017). Only information for languages within the same Autotyp region are available. Routes to some remote languages cannot be calculated. Duration is in seconds, distance is in meters.

## PolygonDistanceWithEIDs.rds

R RDS file with a matrix of distances between languages, calculated as the shortest distance between two language polygons from the World Mapping System (in km). The row and column names show the iso2-a codes from Ethnologue. 

The data is provided in 7 files due to limits on Github file sizes. Load the data together using code like this:

```
dx = readRDS("PolygonDistanceWithEIDs_A.rds")
for(L in LETTERS[2:7]){
  dx = cbind(dx,readRDS(paste0("PolygonDistanceWithEIDs_",L,".rds")))
}
```


## HammarstromNeighbours.tab

A list of glottolog language codes that are neighbours according to the method in Hammarström & Güldemann (2014). Two languages A and B are neighbours if and only if there is no language C located between them.  C is between A and B if C is both closer to A and closer to B, than A and B are to each other.  This is equivalent to checking if the intersection of circles centered at A and B with radius d(A,B) is inhabited.  This was based on Glottolog coordinates - each language has a single point location.  

Hammarström, H., & Güldemann, T. (2014). Quantifying geographical determinants of large-scale distributions of linguistic features. Language Dynamics and Change, 4(1), 87-115.

# Processing:

Get walking distances by google maps (see the file for details):

`R getDistances.r`

Get distances between shapefiles (geographic polygons):

`R getShapeFileDistance.r`

Make a matrix of distances - saves to glottologDistances.csv ( a big file!):

`R -f getHammarstromNeighbours.R`


Make list of neighbouring languages. This creates "HammarstromNeighbours.tab".
python getHammarstromNeighbours.py


# compile distance measures
analyzeDistances.R

# combine distance measures with NTS data
NTS_Complexity2.R

