#!/usr/bin/env R 

source("~/svn/swasr/opt/pli-R-v0.0.3-2007-07-25/plfit.R")

v = read.table("vertices.data", header=T)
c = read.table("clusters.data", header=T)
g = read.table("global.data", header=T)



# Degree distribution
fit = plfit(v$deg[v$deg > 0])
write(c("degree", fit$xmin, fit$alpha, fit$D), file="stat.data", append=F)

# Community size
fit = plfit(c$size[c$size > 0])
write(c("moduleSize", fit$xmin, fit$alpha, fit$D), file="stat.data", append=T)

# Number of nodes
write(c("nodes", g$size), file="stat.data", append=T)

# Mixing parameter
write(c("mixing", g$mixing), file="stat.data", append=T)

