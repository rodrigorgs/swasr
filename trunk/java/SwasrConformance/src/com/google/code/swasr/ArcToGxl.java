package com.google.code.swasr;

import java.io.BufferedReader;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStreamReader;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Set;
import java.util.Map.Entry;

import design.model.Design;
import design.model.HierarchicalSparseGraph;
import design.model.TypeOfEdge;
import edu.uci.ics.jung.algorithms.blockmodel.GraphCollapser;
import edu.uci.ics.jung.graph.Graph;
import edu.uci.ics.jung.graph.Vertex;
import edu.uci.ics.jung.graph.impl.DirectedSparseEdge;
import edu.uci.ics.jung.graph.impl.SparseVertex;
import edu.uci.ics.jung.utils.UserData;

public class ArcToGxl {
	static int vindex = 0;

	private static Set getSet(Graph g, HashMap<String, Set> sets, String name) {
		Set cs = sets.get(name);
		if (cs == null) {
			cs = new HashSet();
			sets.put(name, cs);
		}
		return cs;
	}
	
	public static Vertex getVertex(Graph g, HashMap<String, Vertex> vertices, String name) {
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
	
	public static Graph loadArcs(String filename) throws IOException {
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
	
	private static Design loadMod(Graph graph, String filename) throws IOException {
		HashMap<String, Vertex> vertices = new HashMap<String, Vertex>();
		HashMap<String, Set> sets = new HashMap<String, Set>();
		
		BufferedReader br = new BufferedReader(new InputStreamReader(new FileInputStream(filename)));
		String line;
		while ((line = br.readLine()) != null) {
			String[] ids = line.split(" ");
			Vertex v = getVertex(graph, vertices, ids[0].trim());
			Set set = getSet(graph, sets, ids[1].trim());
			set.add(v);
		}
		
		HierarchicalSparseGraph hgraph = new HierarchicalSparseGraph();
		hgraph.importUserData(graph);
		
		int i = 0;
		for (Entry<String, Set> entry : sets.entrySet()) {
			
			String name = entry.getKey();
			Set set = entry.getValue();
			
			GraphCollapser.CollapsedSparseVertex cVertex = new GraphCollapser.CollapsedSparseVertex(set);
			cVertex.addUserDatum("id", "cluster" + i, UserData.SHARED);
			cVertex.addUserDatum("shortlabel", name, UserData.SHARED);
			cVertex.addUserDatum("label", name, UserData.SHARED);
			cVertex.addUserDatum("type", "module", UserData.SHARED);
			hgraph.addVertex(cVertex);
		}
	
		Design design = new Design(graph);
		design.addGraph(hgraph, TypeOfEdge.COLLAPSED);
		
		return design;
	}
	
	public static void convertArcModToGxl(String arcFilename,
			String modFilename, String gxlBasename) throws IOException {
		Graph graph = loadArcs(arcFilename);
		Design d = loadMod(graph, modFilename);
		d.saveDesigns(gxlBasename);
	}

	private static void help() {
		System.out.println("Converts a network in arc/mod format to GXL format.");
		System.out.println("Parameters: arc_filename mod_filename gxl_basename");
		System.out.println();
		System.exit(1);
	}
	
	public static void main(String[] args) throws Throwable {
		if (args.length < 3)
			help();
		else {
			convertArcModToGxl(args[0], args[1], args[2]);
		}
	}
}
