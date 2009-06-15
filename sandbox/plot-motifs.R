#!/usr/bin/Rscript 

#--vanilla

#aba-reduced  gdata-reduced  jfreechart-reduced  villonanny

argv = commandArgs(T)

if (length(argv) < 2) {
  cat("This script plots motif frequencies from a list of text files. Each
text file contains a sequence of numbers that represent the motif frequencies
of a single network. The first number is the frequency of the first motif and
so on.

Parameters: output-image.png network-filename+
")

  quit("no")
}

image = argv[1]

png(image)

motifs = rbind()
for (filename in argv[2:length(argv)]) {
  vec = scan(filename)
  motifs = rbind(motifs, vec)
}
plot.motifs(motifs)

dev.off()


