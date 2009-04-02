class ArtificialDesign
  def initialize(props)
    @props = props
  end

  def saveAsJava(dirname)
  end

  def saveAsGXL(filename)
  end

  def saveAsGXLVersions(dirname)
    @version_counter += 1;
  end

  def evolve
  end
end

=begin
TODO: Escrever documento curto descrevendo como o software sintetico 
e' gerado e em que sentido ele segue as restricoes arquiteturais
especificadas.

"Benchmark graphs for testing community detection algorithms"
Lancichinetti, Fortunato and Radicchi, 2008

Características
* Grafo não-orientado
* Não permite restringir quais comunidades poderão ser ligadas.
Essa restrição é interessante porque podemos ver o que acontece se
a arquitetura for um grafo regular vs. um grafo livre de escala, por exemplo.
* O parâmetro de mixing é constante, ou seja, a razão entre arestas entre
comunidades e arestas dentro de uma comunidade não varia de comunidade
para comunidade.
* Todos os vértices possuem arestas internas e arestas externas. Isso
não parece muito realista.

o expoente e o grau medio, <k>, são suficientes para determinar 
k_min e k_max?

comparação entre clusterings: normalized mutual information

conclusões sobre modularity optimization:
piora quando <k> diminui
piora quando N aumenta
piora quando comunidades têm tamanhos parecidos.

TODO: como é o scatterplot do coeficiente de clustering vs. k?
TODO: qual é o coeficiente de clustering médio?
TODO: dá pra generalizar pra grafo orientado?

=end
class FortunatoArtificialDesign < ArtificialDesign
end

