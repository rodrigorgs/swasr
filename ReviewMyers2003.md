**Titulo**: Software systems as complex networks: structure, function, and evolvability of software collaboration graphs.

**Autores**: Christopher R Myers

**Ano**: 2003


---


## Degree distributions ##

Segue power law com expoentes gamma\_in (para graus de entrada) e gamma\_out (para graus de saída).

Sistemas OO (arestas: colaboração entre classes = herança e agregação)
gamma\_out ~ 3
gamma\_in ~ 2

Sistemas procedimentais (arestas: call graph)
gamma\_in = gamma\_out = 2.5

## Degree correlation ##

Nós com alto grau de entrada têm baixo grau de saída e vice-versa.

## Clustering coefficient ##

C(k) ~ k^{-1} <-- indicador da natureza hierárquica do software

C(k) é a média do coeficiente de clustering para os nós com grau k (considerando o grafo não orientado)

## Misc ##

O artigo introduz um modelo de evolução de software baseado em refactorings.
