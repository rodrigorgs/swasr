FUNC=$@

if [ -z "$1" ]; then
  echo "
Plots a function applied to each file *.rsf in the current directory.

Usage: `basename $0` func

where func is the name of the function to plot.
some func names:
  clustering_coefficients
  out_in_degrees
  cumulative_in_degrees
  cumulative_out_degrees
"
  exit 1
fi

DIR=$1

mkdir $DIR 2> /dev/null

for x in *.rsf; do echo $x; ssrun.rb read_rsf_pairs $x // $FUNC // puts_pairs > $DIR/$x-cc.graph; done
