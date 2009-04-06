#!/bin/sh

# Exemplo de como extrair fatos de design a partir de arquivos .class usando
# o javex.

find -name '*.class' -exec javex -z -f -l '{}' \; > fatos.ta
