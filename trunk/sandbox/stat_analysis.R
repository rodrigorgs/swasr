#!/usr/bin/env R 

source("~/svn/swasr/opt/pli-R-v0.0.3-2007-07-25/plfit.R")

v = read.table("vertices.data", header=T)
c = read.table("clusters.data", header=T)
g = read.table("global.data", header=T)

# Degree distribution
fit = plfit(v$deg)
write(fit, file="stat.data", append=T)

# Community size
fit = plfit(c$size)
write(fit, file="stat.data", append=T)

# Number of nodes
write(g$size)

# Mixing parameter
write(g$mixing)
