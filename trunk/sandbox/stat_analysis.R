#!/usr/bin/Rscript

argv = commandArgs(T)

if (length(argv) < 3) {
  argv = c("vertices.data", "clusters.data", "global.data")
}

v = read.table(argv[1], header=T)
c = read.table(argv[2], header=T)
g = read.table(argv[3], header=T)

#############################################
# Retrieves parameters used in Lancichinetti's model
#############################################
library(igraph)

sink("parameters.fit", split=F, type="output")

cat("# computing degree fit")
degmincut = 1
cat("# degmincut =", degmincut, "\n")
deg = v$deg[v$deg >= degmincut]
#degfit = coef(power.law.fit(deg))
degfit = plfit(deg)
degexp = degfit$alpha
degmin = degfit$xmin

cat("\n# computing size fit")
size = c$size
#sizefit = plfit(c$size[c$size > 0])
sizemin = 1
sizefit = power.law.fit(c$size, sizemin)
sizeexp = coef(sizefit)

cat("\n", g$nodes, " # Number of nodes")
cat("\n", mean(deg), " # Average degree")
cat("\n", max(deg), " # Maximum degree")
cat("\n", degexp, " # Degree distribution exponent, xmin = ", degmin)
cat("\n", sizeexp, " # Community size exponent")
cat("\n", g$mixing, " # Mixing parameter")
cat("\n", min(c$size), " # Minimum community size")
cat("\n", max(c$size), " # Maximum community size")

sink()

