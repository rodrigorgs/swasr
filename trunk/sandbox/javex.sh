#!/bin/sh

# Exemplo de como extrair fatos de design a partir de arquivos .class usando
# o javex.

DIR=$1 || '.'
find $DIR -name '*.class' -exec javex -z -f -l '{}' \; > l0.ta
grok lift_to_classlevel.grok l0.ta l1.tmp
grep -v '^contain' l1.tmp > l1.rsf
rm -f l1.tmp

