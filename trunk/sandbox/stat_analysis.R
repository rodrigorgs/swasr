#!/usr/bin/env R 

v = read.table("vertices.data", header=T)
c = read.table("clusters.data", header=T)
g = read.table("global.data", header=T)

#############################################
# Retrieves parameters used in Lancichinetti's model
#############################################

sink("parameters.fit")

cat(g$size, " # Number of nodes\n")
cat(mean(v$deg), " # Average degree\n")
cat(max(v$deg), " # Maximum degree\n")
fit = plfit(v$deg[v$deg > 0])
cat(fit$alpha, " # Degree distribution exponent\n")
fit = plfit(c$size[c$size > 0])
cat(fit$alpha, " # Community size exponent\n")
cat(g$mixing, " # Mixing parameter\n")
cat(min(c$size), " # Minimum community size\n")
cat(max(c$size), " # Maximum community size\n")

sink()

