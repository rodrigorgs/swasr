#!/usr/bin/Rscript --vanilla

x = scan("~/svn/swasr/corpora/systems/JabRef-2.5b2-src/motifs.data")
pdf("triad-jabref.pdf")
barplot(rev(x), main="Triad Concentration Profile for JabRef (software)",
  ylab="triad id",
  xlab="concentration (%)",
  xlim=c(0,1),
  names.arg=c(13:1),
  horiz=T)
dev.off()

x = scan("~/svn/swasr/corpora/non-sw/circuit-s420/motifs.data")
pdf("triad-circuit.pdf")
barplot(rev(x), main="Triad Concentration Profile for an Electronic Circuit",
  ylab="triad id",
  xlab="concentration (%)",
  xlim=c(0,1),
  names.arg=c(13:1),
  horiz=T)
dev.off()

x = scan("~/svn/swasr/corpora/non-sw/facebook-Caltech36/motifs.data")
pdf("triad-facebook.pdf")
barplot(rev(x), main="Triad Concentration Profile for an Electronic Circuit",
  ylab="triad id",
  xlab="concentration (%)",
  xlim=c(0,1),
  names.arg=c(13:1),
  horiz=T)
dev.off()

x = scan("~/svn/swasr/corpora/non-sw/metabolic-AA/motifs.data")
pdf("triad-metabolic.pdf")
barplot(rev(x), main="Triad Concentration Profile for a Metabolic Network",
  ylab="triad id",
  xlab="concentration (%)",
  xlim=c(0,1),
  names.arg=c(13:1),
  horiz=T)
dev.off()

x = scan("~/svn/swasr/corpora/non-sw/protein-eaw/motifs.data")
pdf("triad-protein.pdf")
barplot(rev(x), main="Triad Concentration Profile for a Protein Network",
  ylab="triad id",
  xlab="concentration (%)",
  xlim=c(0,1),
  names.arg=c(13:1),
  horiz=T)
dev.off()

x = scan("~/svn/swasr/corpora/non-sw/lang-japanese/motifs.data")
pdf("triad-lang.pdf")
barplot(rev(x), main="Triad Concentration Profile for Japanese Language",
  ylab="triad id",
  xlab="concentration (%)",
  xlim=c(0,1),
  names.arg=c(13:1),
  horiz=T)
dev.off()
