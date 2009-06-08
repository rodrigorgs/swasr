#!/usr/bin/Rscript --vanilla

library(igraph)

argv = commandArgs(T)

if (length(argv) < 3){
  cat("This script takes a network and outputs the motif frequency.

Parameters: input-network output-file [motif-size]

  input-network: a text file which represents a network, in a format
that can be understood by igraph (for example, a text file in which which pair
of numbers is an edge between two vertices. See 
http://igraph.sourceforge.net/igraphbook/igraphbook-foreign.html)

  output-file: a file in which the motif frequency will be recorded. 

  motif-size: 3 or 4

")

  quit("no")
}

inputFile = argv[1]
outputFile = argv[2]
size = argv[3]

g = read.graph(inputFile)
m = graph.motifs(g, size)
write(m, outputFile, 1)
