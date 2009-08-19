package com.google.code.swasr;

import java.io.BufferedReader;
import java.io.FileInputStream;
import java.io.FileWriter;
import java.io.IOException;
import java.io.InputStreamReader;
import java.util.HashMap;
import java.util.Properties;
import java.util.Set;

import abstractor.util.FileUtilities;
import design.model.Design;
import design.model.HierarchicalSparseGraph;
import edu.uci.ics.jung.algorithms.blockmodel.GraphCollapser.CollapsedSparseVertex;
import edu.uci.ics.jung.graph.Graph;
import edu.uci.ics.jung.graph.Vertex;
import edu.uci.ics.jung.graph.impl.DirectedSparseEdge;
import edu.uci.ics.jung.graph.impl.SparseVertex;
import edu.uci.ics.jung.utils.UserData;

public class Abstractor {
	static int vindex = 0;

	private static Vertex getVertex(Graph g, HashMap<String, Vertex> vertices, String name) {
		Vertex v = vertices.get(name);
		if (v == null) {
			v = new SparseVertex();
			v.addUserDatum("id", "class" + vindex, UserData.SHARED);
			v.addUserDatum("shortlabel", name, UserData.SHARED);
			v.addUserDatum("label", name, UserData.SHARED);
			v.addUserDatum("access", "public", UserData.SHARED);
			v.addUserDatum("type", "class", UserData.SHARED);
			vindex++;

			vertices.put(name, v);
			g.addVertex(v);
		}
		return v;
	}
	
	private static Graph loadArcs(String filename) throws IOException {
		Graph g = new HierarchicalSparseGraph();
		HashMap<String, Vertex> vertices = new HashMap<String, Vertex>();
		
		BufferedReader br = new BufferedReader(new InputStreamReader(new FileInputStream(filename)));
		String line;
		while ((line = br.readLine()) != null) {
			String[] ids = line.split(" ");
			Vertex v1 = getVertex(g, vertices, ids[0].trim());
			Vertex v2 = getVertex(g, vertices, ids[1].trim());
			if (!v2.isSuccessorOf(v1))
				g.addEdge(new DirectedSparseEdge(v1, v2));
		}
		return g;
	}
	
	private static void saveMod(Graph g, String filename) throws IOException {
		FileWriter fw = new FileWriter(filename);
		int i = 0;
		for (Object o : g.getVertices()) {
			CollapsedSparseVertex cluster = (CollapsedSparseVertex)o;
			String clusterName = (String)cluster.getUserDatum("label");
			Set set = cluster.getRootSet();
//			System.out.println(cluster);
			
			for (Object o2 : set) {
				Vertex v = (Vertex)o2;
				fw.write("" + v.getUserDatum("label") + " " + i + "\n");
			}
			i++;
		}
		fw.close();
	}
	
	/**
	 * @param args
	 * @throws IOException 
	 */
	public static void main(String[] args) throws IOException {
		String propertiesFilename = args[0];
		String inputFilename = args[1];
		String outputFilename= args[2];
		
		
		Graph g = loadArcs(inputFilename);
		Design d = new Design(g);
		Properties p = FileUtilities.loadProperties(propertiesFilename);
		abstractor.Abstractor a = new abstractor.Abstractor(d, p);
		
		Graph g2 = a.getClusteringFacade().cluster();
		if (g2 == null) {
			System.err.println("Clusterer returned null");
			System.exit(1);
		}
		
		saveMod(g2, outputFilename);
//		Utilities.saveGXLFile("/tmp/teste.gxl", g);
	}

}
