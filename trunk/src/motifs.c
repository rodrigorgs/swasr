#include <igraph.h>
#include <stdlib.h>
#include <stdio.h>

void help() {
  printf("This script takes a network and outputs the motif frequency.\n\
\n\
Parameters: input-network output-file [motif-size]\n\
(note: motif-size isn't implemented, it is always 3)\n\
\n\
  input-network: a text file which represents a network, in a format\n\
that can be understood by igraph (for example, a text file in which which pair\n\
of numbers is an edge between two vertices. See \n\
http://igraph.sourceforge.net/igraphbook/igraphbook-foreign.html)\n\
\n\
  output-file: a file in which the motif frequency will be recorded. \n\
\n\
  motif-size: 3 or 4\n\n");
  
  exit(1);
}

int main(int argc, char *argv[]) {
  igraph_t graph;
  char *in_filename;
  char *out_filename;
  FILE *file;
  int error;
  igraph_vector_t hist;
  igraph_vector_t cp;
  int i;
  igraph_real_t sum;
  int nmotifs = 3;
 
  if (argc < 3)
    help();
 
  in_filename = argv[1];
  out_filename = argv[2];

  file = fopen(in_filename, "r");
  
  error = igraph_read_graph_edgelist(&graph, file, 0, 1);
  if (error) {
    puts("Erro reading file.");
    exit(1);
  }

  fclose(file);

  igraph_vector_init(&hist, 0);
  igraph_vector_init_real(&cp, 8, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);

  error = igraph_motifs_randesu(&graph, &hist, 3, &cp);

  sum = igraph_vector_sum(&hist);

  file = fopen(out_filename, "w");

  fprintf(file, "%f\n", VECTOR(hist)[2] / sum);
  for (i = 4; i < igraph_vector_size(&hist); i++)
    fprintf(file, "%f\n", VECTOR(hist)[i] / sum);

  fclose(file);

  igraph_vector_destroy(&cp);
  igraph_vector_destroy(&hist);

  igraph_destroy(&graph);

  return 0;
}

