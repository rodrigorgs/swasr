#!/usr/bin/Rscript --vanilla

library(igraph)

argv = commandArgs(T)

if (length(argv) < 3){
  cat("This script takes a network and outputs a distance matrix.

Parameters: input-network output-file directed? [number_of_nodes]

  input-network: a text file which represents a network, in a format
that can be understood by igraph (for example, a text file in which which pair
of numbers is an edge between two vertices. See 
http://igraph.sourceforge.net/igraphbook/igraphbook-foreign.html)

  output-file: a file in which the distance matrix will be recorded. Each
line in the matrix is written as a line in a file, and columns are separated
by empty space. In other words the format is a CSV separated by spaces.

  directed?: TRUE or FALSE. whether to read the input-network as a directed 
(TRUE) or undirected (FALSE) network.

")

  quit("no")
}

inputFile = argv[1]
outputFile = argv[2]
directed = as.logical(argv[3])
n = argv[4]

edges = as.matrix(read.table(inputFile, header=F))
if (length(argv) == 3) {
  g = graph(edges, directed=directed)
} else {
  g = graph(edges, n=argv[4], directed=directed)
}
s = shortest.paths(g)
s[s == Inf] = 0
write.table(s, file=outputFile, row.names=F, col.names=F)
