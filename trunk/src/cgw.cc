#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define rnd() ((double)rand() / RAND_MAX)

class Network {
public:
  char *g;
  int size;
  int num_edges;
  int maxnode;
  int *modules;
  int *degrees;

  Network(int size) {
    this->size = size;
    g = new char[size*size];
    num_edges = 0;
    maxnode = -1;
    modules = new int[size];
    degrees = new int[size];

    memset(g, 0, sizeof(char)*size*size);
    memset(modules, 0, sizeof(int)*size);
    memset(degrees, 0, sizeof(int)*size);
  }

  int new_node() {
    return ++maxnode;
  }

  int has_edge(int from, int to) {
    return g[from*size+to];
  }

  void add_edge(int from, int to) {
    int index = from * size + to;
    if (!g[index]) { 
      g[index] = 1; 
      degrees[from] += 1; 
      degrees[to] += 1; 
      num_edges++; 
    } 
  }

  int remove_edge(int from, int to) {
    int index = from * size + to;
    if (g[index]) {
      g[index] = 0;
      degrees[from] -= 1;
      degrees[to] -= 1;
      num_edges--;
      return 1;
    }
    else
      return 0;
  }

  int choose_with_mbpa(int _v, double alpha) {
    int tmpint[size + 1];
    double tmpdouble[size + 1];

    int _w;
    int _j;
    int _i;
    double sum;
    double prob;
    int i;

    tmpdouble[0] = 0.0;
    tmpint[0] = -1;
    _j = 1;
 
    for (_w = 0; _w <= maxnode; _w++) {
      if (_v != _w && !g[_v*size+_w]) {
        tmpint[_j] = _w;
        if (modules[_w] == modules[_v])
          tmpdouble[_j] = tmpdouble[_j-1] + degrees[_w] * (1 + alpha) + 1;
        else
          tmpdouble[_j] = tmpdouble[_j-1] + degrees[_w] + 1;
        _j++;
      }
    }
 
    //printf("v = %d, j = %d\n", _v, _j);

    sum = tmpdouble[_j-1];
    prob = rnd() * sum;

    //printf("sum: %lf, prob: %lf\n", sum, prob);
    for (_i = 1; _i < _j; _i++)
      if (tmpdouble[_i] >= prob)
        return tmpint[_i-1];

    return -1;
  }

  void print() {
    int i, j;
    char *p = g;

    for (i = 0; i <= maxnode; i++) {
      for (j = 0; j <= maxnode; j++) {
        if (has_edge(i, j))
          printf("%d %d\n", i, j);
      }
    }
  }
};

// sample parameters:
// 100,1,0,0,0,2,0,0,0,100,3
int main(int argc, char *argv[]) {
  // parameters
  int size;
  double p1, p2, p3, p4;
  int e1, e2, e3, e4;
  double alpha;
  int num_modules;

  // work variables
  double event;
  int v;
  int w;
  int tmp, i, j;

  sscanf(argv[1], "%d,%lf,%lf,%lf,%lf,%d,%d,%d,%d,%lf,%d", &size, 
      &p1, &p2, &p3, &p4, 
      &e1, &e2, &e3, &e4,
      &alpha, &num_modules);

  //puts("== ARGS ==");
  //printf("size = %d\n", size);
  //printf("p1 = %lf, p2 = %lf, p3 = %lf, p4 = %lf\n", p1, p2, p3, p4);
  //printf("e1 = %d, e2 = %d, e3 = %d, e4 = %d\n", e1, e2, e3, e4);
  //printf("alpha = %lf, num_modules = %d\n", alpha, num_modules);

  Network g(size);
  v = g.new_node();
  w = g.new_node();
  g.add_edge(v, w);
  //g.print();
  //puts("   ");
  
  // accumulated probabilities
  p2 += p1;
  p3 += p2;
  p4 += p3;
  //printf("p1 = %lf, p2 = %lf, p3 = %lf, p4 = %lf\n", p1, p2, p3, p4);
 
  srand(0);

  while (g.maxnode < g.size - 1) {
    event = rnd();
    //printf("event %lf, p1 %lf, maxnode = %d\n", event, p1, g.maxnode);

    if (event <= p1) {
      //printf("%d\n", maxnode);
      v = g.new_node();
      g.modules[v] = rand() % num_modules;
      for (i = 0; i < e1; i++) {
        w = g.choose_with_mbpa(v, alpha);
        //printf("w = %d\n", w);
        if (w >= 0)
          g.add_edge(v, w);
      }
    }
    else if (event <= p2) {
      for (i = 0; i < e2; i++) {
        v = rand() % (g.maxnode + 1);
        w = g.choose_with_mbpa(v, alpha);
        if (w >= 0)
          g.add_edge(v, w);
      }
    }
    else if (event <= p3) {
      // TODO: implement rewire
    }
    else if (event <= p4) {
      for (i = 0; i < e4; i++) {
        if (g.num_edges > 0) {
          while (1) {
            v = rand() % (g.maxnode + 1);
            w = rand() % (g.maxnode + 1);
            if (g.remove_edge(v, w))
              break;
          }
        }
      }
    }
    else {
      puts("erro");
    }
  }

  g.print();
}


