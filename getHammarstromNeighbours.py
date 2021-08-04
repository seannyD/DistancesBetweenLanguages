import sys

inFile = "glottologDistances.csv"
outFile = "HammarstromNeighbours.tab"

if "-t" in sys.argv:
	inFile = "glottologDistancesTest.csv"
	outFile = "HammarstromNeighboursTest.tab"

o = open(inFile)
d = o.read()
o.close()

d = d.split("\n")
langs = d[0].split(",")
dist = [[float(y) for y in x.split(",")] for x in d[1:] if len(x)>3]



res= []

# Explore lower triangle
for i in range(len(dist)):
	print i
	for j in range(i):
		AB = dist[i][j]
		nei = True
		for z in range(len(dist)):
			AC = dist[i][z]
			BC = dist[j][z]
			
			if (AC < AB) and (BC < AB):
				nei = False
				break
		if nei:
			res.append((langs[i],langs[j]))

outString = "la\tlb\n"
for i in range(len(res)):
	outString +=  "\t".join(res[i]) + "\n"
o = open(outFile,'w')
o.write(outString)
o.close()