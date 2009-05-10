/*
 * Algoritmo Monte Carlo (Simulated Annealing) que calcula a distancia entre
 * duas redes complexas.
 *
 * Baseado no artigo de Andrade et al, 2008:
 * "Measuring distances between complex networks"
 *
 */
#include <stdio.h>
#include <stdlib.h>
#include <float.h>
#include <math.h>

typedef unsigned char dist;

void help() {
  puts("Arguments: N distance-matrix1 distance-matrix2");
}

float distance(dist *a, dist *b, int n) {
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

/* Takes a nXn matrix, a, and swaps two indices, i, j < n */
inline float swap_indices(dist *b, int n, int i, int j) {
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
inline void sort_matrix(dist *b, int n, int *indices) {
  int i;

  for (i = 0; i < n; i++) {
    if (i > indices[i])
      swap_indices(b, n, i, indices[i]);
  }
}

inline void scramble(dist *b, int n, int times) {
  int i, j, k;
  int indices[n];
  dist disttmp;

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

int main(int argc, char *argv[]) {
  int n;

  if (argc < 4)
    help();

  srand(time(NULL));
  n = atoi(argv[1]);

  dist a[n][n], b[n][n];
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
