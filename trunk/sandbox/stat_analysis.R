#!/usr/bin/env R 

v = read.table("vertices.data", header=T)
c = read.table("clusters.data", header=T)
g = read.table("global.data", header=T)

#############################################
# Retrieves parameters used in Lancichinetti's model
#############################################

write(c(), file="stat.data")

# Number of nodes
write(c("nodes", g$size), file="stat.data", append=T)

# Average degree
write(c("avgdeg", mean(v$deg)), file="stat.data", append=T)

# Maximum degree
write(c("maxdeg", max(v$deg)), file="stat.data", append=T)

# Degree distribution
fit = plfit(v$deg[v$deg > 0])
write(c("degree", fit$xmin, fit$alpha, fit$D), file="stat.data", append=T)

# Community size
fit = plfit(c$size[c$size > 0])
write(c("moduleSize", fit$xmin, fit$alpha, fit$D), file="stat.data", append=T)

# Mixing parameter
write(c("mixing", g$mixing), file="stat.data", append=T)

# Minimum for the community sizes

write(c("minModuleSize", min(c$size)), file="stat.data", append=T)

# Maximum for the community sizes

write(c("maxModuleSize", max(c$size)), file="stat.data", append=T)
