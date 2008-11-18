for x in *.graph; do
  graph.sh -L $x $@ < $x
done
