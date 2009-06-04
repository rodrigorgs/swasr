#!/usr/bin/Rscript --vanilla

library(igraph)

argv = commandArgs(T)

if (length(argv) < 2){
  cat("This script takes a network and outputs the motif frequency.

Parameters: input-network output-file

  input-network: a text file which represents a network, in a format
that can be understood by igraph (for example, a text file in which which pair
of numbers is an edge between two vertices. See 
http://igraph.sourceforge.net/igraphbook/igraphbook-foreign.html)

  output-file: a file in which the motif frequency will be recorded. 

")

  quit("no")
}

inputFile = argv[1]
outputFile = argv[2]

g = read.graph(inputFile)
m = graph.motifs(g)
write(m, outputFile, 1)
