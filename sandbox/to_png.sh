for x in *.graph; do
  echo $x
  ssgraph -T png -L $x $@ < $x > $x.png
done
