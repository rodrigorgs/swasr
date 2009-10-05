import bunch.api.*;
import java.util.*;

public class BunchCmd {
  public static void main(String[] args) throws Throwable {
    String mdgFile = args[0];

    BunchAPI api = new BunchAPI();
    BunchProperties bp = new BunchProperties();
    
    bp.setProperty("RunMode", "Cluster");
    bp.setProperty("ClusteringApproach", "ClustApproachOneLevel");
    bp.setProperty("MDGInputFile", mdgFile);
    bp.setProperty(BunchProperties.MDG_OUTPUT_MODE, BunchProperties.OUTPUT_MEDIAN);
    
    bp.setProperty(BunchProperties.CLUSTERING_ALG,
        BunchProperties.ALG_HILL_CLIMBING);
    bp.setProperty(BunchProperties.ALG_HC_HC_PCT, "55");
    bp.setProperty(BunchProperties.ALG_HC_RND_PCT, "20");
    bp.setProperty(BunchProperties.ALG_HC_SA_CLASS,
        "bunch.SASimpleTechnique");
    bp.setProperty(BunchProperties.ALG_HC_SA_CONFIG,
        "InitialTemp=10.0,Alpha=0.85");
    
    api.setProperties(bp);

    api.run();
    
    BunchGraph graph = api.getPartitionedGraph();
    Collection clusters = graph.getClusters();
    Iterator iter = clusters.iterator();
    int i = 0;
    while (iter.hasNext()) {
      BunchCluster cluster = (BunchCluster)iter.next();
      Collection nodes = cluster.getClusterNodes();
      Iterator iter2 = nodes.iterator();
      while (iter2.hasNext()) {
        BunchNode node = (BunchNode)iter2.next();
        System.out.println(node.getName() + " " + i);
      }
      i++;
    }
  }
}
