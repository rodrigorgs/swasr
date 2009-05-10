#!/usr/bin/R CMD BATCH

library(igraph)

#filename = commandArgs()[0]
filename = "l1.pairs"

g = read.graph(filename, directed=F)
s = shortest.paths(g)
s[s == Inf] = 0
write.table(s, file="distances.csv", row.names=F, col.names=F)
