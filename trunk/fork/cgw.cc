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
  int *out_degrees;
  double *tmpdouble;
  int *tmpint;

  Network(int size) {
    this->size = size;
    g = new char[size*size];
    num_edges = 0;
    maxnode = -1;
    modules = new int[size];
    degrees = new int[size];
    out_degrees = new int[size];
    tmpdouble = new double[size + 1];
    tmpint = new int[size + 1];

    memset(g, 0, sizeof(char)*size*size);
    memset(modules, 0, sizeof(int)*size);
    memset(degrees, 0, sizeof(int)*size);
    memset(out_degrees, 0, sizeof(int)*size);
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
      out_degrees[from] += 1;
      degrees[from] += 1; 
      degrees[to] += 1; 
      num_edges++; 
    } 
  }

  int remove_edge(int from, int to) {
    int index = from * size + to;
    if (g[index]) {
      g[index] = 0;
      out_degrees[from] -= 1;
      degrees[from] -= 1;
      degrees[to] -= 1;
      num_edges--;
      return 1;
    }
    else
      return 0;
  }

  int pick_node_by_out_degree() {
    int sum_degrees = num_edges * 2;
    int prob = rand() % sum_degrees;
    int sum = 0;
    int i;

    for (i = 0; i <= maxnode; i++) {
      sum += out_degrees[i];
      if (sum > prob)
        return i;
    }

    return maxnode;
  }

  int choose_with_mbpa(int _v, double alpha) {
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

  int pick_out_edge(int v) {
    int j = 0;
    int w;

    for (w = 0; w <= maxnode; w++)
      if (v != w && has_edge(v, w))
        tmpint[j++] = w;

    if (j == 0)
      return -1;
    else
      return tmpint[rand() % j];
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

    for (i = 0; i <= maxnode; i++) {
      fprintf(stderr, "%d %d\n", i, modules[i]);
    }
  }
};

void help_and_exit() {
  puts("CGW network model");
  puts("");
  puts("Parameters:");
  puts("  n,p1,p2,p3,p4,e1,e2,e3,e4,alpha,m,seed");
  puts("");
  puts("Sample invocation:");
  puts("  ./cgw 100,0.4,0.2,0.2,0.2,2,2,2,2,100,3,0");
  puts("");
  puts("Output:");
  puts("  Arcs are output to stdout in the format node_id node_id");
  puts("  Modules are output to stderr in the format node_id module_id");
  puts("");
  puts("More information: rodrigorgs@gmail.com");
  puts("");
  exit(0);
}

// sample parameters:
// 100,0.4,0.2,0.2,0.2,2,2,2,2,100,3,0
int main(int argc, char *argv[]) {
  // parameters
  int size;
  double p1, p2, p3, p4;
  int e1, e2, e3, e4;
  double alpha;
  int num_modules;
  int seed;

  // work variables
  double event;
  int v;
  int w;
  int tmp, i, j;

  if (argc < 12)
    help_and_exit();

  sscanf(argv[1], "%d,%lf,%lf,%lf,%lf,%d,%d,%d,%d,%lf,%d,%d", &size, 
      &p1, &p2, &p3, &p4, 
      &e1, &e2, &e3, &e4,
      &alpha, &num_modules, &seed);

  Network g(size);
  v = g.new_node();
  w = g.new_node();
  g.add_edge(v, w);

  // accumulated probabilities
  p2 += p1;
  p3 += p2;
  p4 += p3;
 
  srand(seed);

  while (g.maxnode < g.size - 1) {
    event = rnd();

    if (event <= p1) { // new node
      v = g.new_node();
      g.modules[v] = rand() % num_modules;
      for (i = 0; i < e1; i++) {
        w = g.choose_with_mbpa(v, alpha);
        if (w >= 0)
          g.add_edge(v, w);
      }
    }
    else if (event <= p2) { // new edge
      for (i = 0; i < e2; i++) {
        v = rand() % (g.maxnode + 1);
        w = g.choose_with_mbpa(v, alpha);
        if (w >= 0)
          g.add_edge(v, w);
      }
    }
    else if (event <= p3) { // rewire
      for (i = 0; i < e3; i++) {
        v = rand() % (g.maxnode + 1);
        j = g.pick_out_edge(v);
        if (j >= 0) {
          w = g.choose_with_mbpa(v, alpha);
          if (w >= 0) {
            g.remove_edge(v, j);
            g.add_edge(v, w);
          }
        }
      }
    }
    else if (event <= p4) { // remove edge
      for (i = 0; i < e4; i++) {
        if (g.num_edges > 0) {
          while (1) {
            v = g.pick_node_by_out_degree();
            //w = rand() % (g.maxnode + 1);
            w = g.pick_out_edge(v);
            //printf("v, w = %d, %d\n", v, w);
            if (w >= 0 && g.remove_edge(v, w))
              break;
          }
        }
      }
    }
    else {
      puts("error");
    }
  }

  g.print();
}


