// g++ ga.cpp -o ga -lga -lm

#include <ga/GASimpleGA.h>
#include <ga/GA1DArrayGenome.h>
#include <ga/GAArray.h>

using namespace std;

typedef unsigned char dist;
int g_size = 100;


float Objective(GAGenome &genome) {
  MyGenome &g = (MyGenome &)genome;
  float sum = 0;
  for (int i = 0; i < g.length(); i++)
    if (g.gene(i) == 0)
      sum++;
  return sum;
}

void RandomInitializer(GAGenome &g) {
  g.resize(g_size);
  for (int i = 0; i < g_size; i++)
    g.gene(i, rand() % (g_size - i));
}

// GAStringGenome?
class MyGenome : public GA1DArrayGenome<dist> {
private:
  int m_size;

public:
  MyGenome(int n) {
    g_size = n;
    initializer(::RandomInitializer);
    evaluator(::Objective);
    // crossover();
    // mutator();
    // comparator();
  }

  /*
  MyGenome(int x) : GA1DArrayGenome::GA1DArrayGenome(x) {
  }
  */
  MyGenome(const MyGenome &g) : GA1DArrayGenome::GA1DArrayGenome(g) {
  }

};

int main() {
  //GA1DArrayGenome<dist> genome(n);
  MyGenome genome(10);
  GASimpleGA ga(genome);
  /*
  ga.populationSize(popsize);
  ga.nGenerations(ngen);
  ga.pMutation(pmut);
  ga.pCrossover(pcross);
  */
  ga.evolve();
  cout << ga.statistics() << endl;
  cout << "Best individual\n" << ga.statistics().bestIndividual() << endl;
}

