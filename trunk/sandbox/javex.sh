#!/bin/sh

# Exemplo de como extrair fatos de design a partir de arquivos .class usando
# o javex.

DIR=$1 || '.'
echo "Running javex..."
find $DIR -name '*.class' -exec javex -z -f -l '{}' \; > l0.ta
echo "Running grok..."
grok `dirname $0`/lift_to_classlevel.grok l0.ta l1.tmp
grep -v '^contain' l1.tmp > l1.rsf
rm -f l1.tmp
echo "Done"

