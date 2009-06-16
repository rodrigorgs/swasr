#!/usr/bin/Rscript --vanilla

library(igraph)

argv = commandArgs(T)

g = read.graph(argv[1], format="gml")

write.graph(g, argv[2], format="edgelist")
