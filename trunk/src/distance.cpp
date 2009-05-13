/*
 * Algoritmo Monte Carlo (Simulated Annealing) que calcula a distancia entre
 * duas redes complexas.
 *
 * Baseado no artigo de Andrade et al, 2008:
 * "Measuring distances between complex networks"
 *
 */
#include <cstdio>
#include <cstdlib>
#include <cfloat>
#include <cmath>
#include <cstring>

#include <ga/GASimpleGA.h>
#include <ga/GA1DArrayGenome.h>
#include <ga/GAArray.h>

using namespace std;

// GLOBAL variables and declarations
typedef unsigned char t_dist;
typedef GA1DArrayGenome<short> Genome;
t_dist *g_matrix1, *g_matrix2;
short *g_indices;
int g_size;

void GenomeToIndices(Genome &g, short *indices, int n);



void help() {
  puts("Arguments: N distance-matrix1 distance-matrix2");
  exit(1);
}


float distance(t_dist *a, t_dist *b, int n) {
  float dif, sum;
  int i, j;

  sum = 0.0;
  for (i = 0; i < n; i++) {
    for (j = 0; j < n; j++) {
      // dif = *b++ - *a++;
      dif = b[i*n+j] - a[i*n+j];
      sum += dif * dif;
    }
  }
  return sum;
}

/**
 * b is reindexed by indices
 */
float distance_indices(t_dist *a, t_dist *b, int n, int *indices) {
  float dif, sum;
  int i, j, x, y;

  sum = 0.0;
  for (i = 0; i < n; i++) {
    x = indices[i];
    for (j = 0; j < n; j++) {
      y = indices[j];
      dif = b[x*n+y] - a[x*n+y];
      sum += dif * dif;
    }
  }
  return sum;
}


/* Takes a nXn matrix, a, and swaps two indices, i, j < n */
inline float swap_indices(t_dist *b, int n, int i, int j) {
  int l, tmp;
  /* swap i, j */
  for (l = 0; l < n; l++) {
    tmp = b[i*n+l];
    b[i*n+l] = b[j*n+l];
    b[j*n+l] = tmp;
  }
  for (l = 0; l < n; l++) {
    tmp = b[l*n+i];
    b[l*n+i] = b[l*n+j];
    b[l*n+j] = tmp;
  }
}

/* Sorts a matrix by the given indices */
inline void sort_matrix(t_dist *b, int n, int *indices) {
  int i;

  for (i = 0; i < n; i++) {
    if (i > indices[i])
      swap_indices(b, n, i, indices[i]);
  }
}

inline void scramble(t_dist *b, int n, int times) {
  int i, j, k;
  int indices[n];
  t_dist disttmp;

  for (i = 0; i < n; i++)
    indices[i] = i;

  for (k = 0; k < n*n; k++) {
    i = rand() % n;
    j = rand() % n;

    disttmp = indices[i];
    indices[i] = indices[j];
    indices[j] = disttmp;
  }
  sort_matrix(b, n, indices);
}

inline void genome_to_indices(int *genome, int *indices, int n) {
  int i, j, k, rank;
  int visited[n];
  memset(visited, 0, sizeof(int) * n);

  for (i = 0; i < n; i++) {
    rank = genome[i];
    j = 0;
    k = 0;
    for (j = 0; ; j = (j + 1) % n) {
      if (k != rank && !visited[j])
        k++;
      else if (k == rank && !visited[j])
        break;
    }
    visited[j] = 1;
    indices[i] = j;
  }
}

///////////////////////////////////////////////////////////////////////////

void GenomeToIndices(Genome &g, short *indices, int n) {
  int i, j, k, rank;
  int visited[n];
  memset(visited, 0, sizeof(int) * n);

  for (i = 0; i < n; i++) {
    rank = g.gene(i);
    j = 0;
    k = 0;
    for (j = 0; ; j = (j + 1) % n) {
      if (k != rank && !visited[j])
        k++;
      else if (k == rank && !visited[j])
        break;
    }
    visited[j] = 1;
    indices[i] = j;
  }
}

#ifdef GALIB
void Initializer(GAGenome &genome) {
  Genome &g = (Genome &)genome;
  g.resize(g_size);
  for (int i = 0; i < g_size; i++)
    g.gene(i, rand() % (g_size - i));
}

int Mutator(GAGenome &genome, float prob) {
  Genome &g = (Genome &)genome;
  if (prob <= 0.0)
    return 0;

  int nmut = 0;
  int n = g.length();
  for (int i = 0; i < n; i++) {
    if (GAFlipCoin(prob)) {
      g.gene(i, rand() % (n - i));
      nmut++;
    }
  }
    
  return nmut;
}

float Objective(GAGenome &genome) {
  Genome &g = (Genome &)genome;
  float dif, sum;
  int i, j, x, y;

  GenomeToIndices(g, g_indices, g_size);

  sum = 0.0;
  for (i = 0; i < g_size; i++) {
    x = g_indices[i];
    for (j = 0; j < g_size; j++) {
      y = g_indices[j];
      dif = g_matrix2[x*g_size+y] - g_matrix1[x*g_size+y];
      sum += dif * dif;
    }
  }
  return sum;
}

int main(int argc, char *argv[]) {
  int n;

  if (argc < 4)
    help();

  srand(time(NULL));
  n = atoi(argv[1]);

  t_dist a[n][n], b[n][n];
  short indices[n];
  g_indices = indices;
  g_matrix1 = &a[0][0];
  g_matrix2 = &b[0][0];
  g_size = n;
  FILE *file1, *file2;
  int i, j, k, l, tmp;

  file1 = fopen(argv[2], "r");
  file2 = fopen(argv[3], "r");

  printf("n = %d\n", n);

  puts("loading files...");
  for (i = 0; i < n; i++) {
    for (j = 0; j < n; j++) {
      fscanf(file1, "%d", &tmp);
      a[i][j] = tmp;
      fscanf(file2, "%d", &tmp);
      b[i][j] = tmp;
    }
  }
  puts("done");

  ///////////////////////////////////////////////////////////////////

  Genome genome(g_size, Objective);
  genome.initializer(Initializer);
  genome.mutator(Mutator);
  GASimpleGA ga(genome);

  ga.nGenerations(32767);
  ga.minimize();
  ga.populationSize(8);
  ga.pCrossover(0.1);
  ga.pMutation(2.0 / g_size);

  
  cout << "population size: " << ga.populationSize() << endl;
  cout << "nGenerations: " << ga.nGenerations() << endl;
  cout << "mutation p: " << ga.pMutation() << endl;
  cout << "crossover p: " << ga.pCrossover() << endl;

  ga.initialize();
  for (int i = 0; i < ga.nGenerations(); i++) {
    ga.step();
    cout << i << " " << ga.statistics().minEver() << endl;
    cout << "   " << ga.statistics().mutations() << endl;
  }

}

#else

int main(int argc, char *argv[]) {
  int n;

  if (argc < 4)
    help();

  srand(time(NULL));
  n = atoi(argv[1]);

  t_dist a[n][n], b[n][n];
  g_matrix1 = &a[0][0];
  g_matrix2 = &b[0][0];
  g_size = n;
  FILE *file1, *file2;
  int i, j, k, l, tmp;
  float lastdist, mindist, olddist;
  float temperature, delta, alpha = 0.90;
  // alpha entre 0.8 e 0.99
  // temperatura final = 1 (ou 0.1?)

  file1 = fopen(argv[2], "r");
  file2 = fopen(argv[3], "r");

  printf("n = %d\n", n);

  puts("loading files...");
  for (i = 0; i < n; i++) {
    for (j = 0; j < n; j++) {
      fscanf(file1, "%d", &tmp);
      a[i][j] = tmp;
      fscanf(file2, "%d", &tmp);
      b[i][j] = tmp;
    }
  }
  puts("done");

  puts("scrambling...");
//  scramble(b, n, n);
  puts("done");

  lastdist = distance(&a[0][0], &b[0][0], n);
  mindist = lastdist;
  temperature = mindist;
  printf("% 5d %f\n", k, mindist);
  for (k = 0; ; k++) {
    olddist = lastdist;

    i = rand() % n;
    do {
      j = rand() % n;
    } while (j == i);

    swap_indices(&b[0][0], n, i, j);

    lastdist = distance(&a[0][0], &b[0][0], n);
    delta = lastdist - olddist;

    if (lastdist < mindist) {
      mindist = lastdist;
    }
    /*
    else if (delta > 0) { // nova solucao e' pior do que a ultima
      float u = rand() / (float)RAND_MAX;
      //printf("%f >? %f\n", u, exp(-delta / temperature));
      // se u < exp..., mantem a solucao, caso contrario volta `a anterior
      if (u > exp(-delta / temperature))
        swap_indices(&b[0][0], n, i, j);

    }
      */ else  swap_indices(&b[0][0], n, i, j);

    printf("% 5d %f\n", k, mindist);

    temperature *= alpha;
  }

  fclose(file1);
  fclose(file2);
}
#endif
