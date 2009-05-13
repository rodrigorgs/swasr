// g++ ga.cpp -o ga -lga -lm

#include <ga/GASimpleGA.h>
#include <ga/GA1DArrayGenome.h>
#include <ga/GAArray.h>

using namespace std;

typedef unsigned char dist;


class MyGenome : public GA1DArrayGenome<dist> {
public:
  MyGenome(int x) : GA1DArrayGenome::GA1DArrayGenome(x) {
  }

  MyGenome(const MyGenome &g) : GA1DArrayGenome::GA1DArrayGenome(g) {
  }
};

float Objective(GAGenome&);

int main() {
  int n;
  n = 1000;

  //GA1DArrayGenome<dist> genome(n);
  MyGenome genome(n);
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

float Objective(GAGenome& genome) {
  MyGenome &g = (MyGenome &)genome;
  float sum = 0;
  for (int i = 0; i < g.length(); i++)
    if (g.gene(i) == 0)
      sum++;
  return sum;
}

