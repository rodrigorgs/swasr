# returns breaks for a histogram that define bins that grow exponentially
logbreaks <- function(data, pow=2) {
  a = floor(min(data)**(1/pow))
  b = ceiling(max(data)**(1/pow))
  return((a:b)**pow)
}

# plots the histogram of the data as a scatterplot, using bins that grow
# exponentially
#
# the default is to use the function plot to plot the data, but you
# can use another function such as points, lines etc.
#
plot.logbins <- function(data, pow=2, func=plot, ...) {
  h = hist(data, plot=FALSE, breaks=logbreaks(data, pow))
  func(h$density ~ h$mids, ...)
}

# Each line is the distribution of motifs of one network
plot.motifs <- function(motifs) {
  n = length(motifs[,1])
  for (x in 1:n) {
    motifs[x,] = motifs[x,] / sum(motifs[x,])
  }
  maximum = max(motifs)
  plot(motifs[1,] / sum(motifs[1,]), ylim=c(0,maximum))
  for (x in 1:n) {
    z = motifs[x,]
    z = z / sum(z)
    points(z, col=x)
    lines(z, col=x)
  }
}
