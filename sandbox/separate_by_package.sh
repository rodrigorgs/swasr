
# Example for JHotDraw 5.2

PREFIX='CH.ifa.draw.'
PKGS='samples contrib applet application figures standard framework util'
SUFFIX='.*'

INPUTDB=classes.rsf
FILTER=`dirname $0`/filter.ql

for pkg in $PKGS; do
  echo $pkg
  ql $FILTER $INPUTDB packages/$pkg.rsf $PREFIX$pkg$SUFFIX
done
