#!/usr/bin/env ruby

require 'test/unit'
require '../network'

class TC_Network < Test::Unit::TestCase
  def test_size
    net = Network.new [[0, 1], [1, 2]], [[0, :a], [1, :b], [2, :b]]
    assert_equal(3, net.size)
  end

  def test_load
    net = Network.new
    net.load2('numbers')
    assert_equal(4, net.size)
    assert_equal(4, net.edges.size)
    assert_equal(2, net.clusters.size)
  end
 
  #
  # 0 <-> 1
  # |
  # v
  # 2 <-> 3
  #
  def test_dyad_census
    net = Network.new [[0, 1], [1, 0], [0, 2], [2, 3], [3, 2]]
    net.set_cluster(2, :x)
    census = net.dyad_census
    assert_equal 0, census[:internal_asym]
    assert_equal 1, census[:internal_mutual]
    assert_equal 1, census[:external_asym]
    assert_equal 1, census[:external_mutual]
  end

  def test_connects_to
    net = Network.new [[0, 1], [1, 0], [0, 2], [2, 3]]
    n0 = net.node?(0)
    n1 = net.node?(1)
    n2 = net.node?(2)
    assert n0.connects_to(n2)
    assert !n2.connects_to(n0)
    assert !n1.connects_to(n2)
  end

  def test_reduce_size
    net = Network.new
    20.times { |i| net.edge!(2*i, 1+2*i) }
    40.upto(49) { |i| net.node!(i) }

    net.reduce_size(45)
    assert_equal(45, net.size)
    0.upto(39) { |i| assert_not_nil(net.node?(i)) }
    count = 0
    40.upto(49) { |i| count += 1 if net.node?(i).nil?  }
    assert_equal(5, count)

    net.reduce_size(30)
    40.upto(49) { |i| assert_nil(net.node?(i)) }
    assert_equal(30, net.size)
  end

  def test_edge_remove
    net = Network.new [[0, 1], [1, 0], [0, 2], [2, 3]]
    assert_equal(4, net.edges.size)
    net.remove_edge(net.edge?(0, 1))
    assert_equal(3, net.edges.size)
    assert_nil(net.edge?(0, 1))
    assert_equal(1, net.node?(0).out_edges.size)
    assert_equal(1, net.node?(1).out_edges.size)
    assert_equal(0, net.node?(1).in_edges.size)
  end
  
  def test_node_remove
    net = Network.new [[0, 1], [1, 0], [0, 2], [2, 3]]
    net.remove_node(0)
    assert_equal(3, net.size)
    assert_equal(1, net.edges.size)
    assert_equal(0, net.node?(1).degree)
    assert_equal(1, net.node?(2).degree)
    assert_equal(1, net.node?(3).degree)
  end

  def test_undirected
    net = Network.new [[0, 1], [1, 0], [0, 2], [2, 3]]
    net.to_undirected!
    assert_equal(6, net.edges.size)
  end

  def test_node_creation
    net = Network.new
    net.node!('no1')
    net.node!('no2')
    net.node!('no1')
    net.node!('no3')
    assert_equal(3, net.nodes.size)
  end

  def test_edge_creates_node
    net = Network.new
    net.node!(1)
    net.edge!(1, 2)
    assert_equal(2, net.nodes.size)
    net.edge!(3, 1)
    assert_equal(3, net.nodes.size)
  end

  def teste_edge?
    net = Network.new
    net.edge!(1, 2)
    net.edge!(2, 3)
    assert_nil(net.edge?(1, 3))
    assert_not_nil(net.edge?(1, 2))
  end

  def test_edge_assimetry
    net = Network.new
    net.edge!(1, 2)
    net.edge!(2, 1)
    assert_equal(2, net.edges.size)
  end

  def test_edge_updates_node_neighbors
    net = Network.new
    a = net.node!('a')
    b = net.node!('b')
    net.edge!(a, b)
    assert_equal(1, a.out_edges_map.size)
    assert_equal(0, a.in_edges_map.size)
    assert_equal(0, b.out_edges_map.size)
    assert_equal(1, b.in_edges_map.size)
  end

  def test_degree_metrics
    net = Network.new
    a = net.node!('a')
    b = net.node!('b')
    c = net.node!('c')
    net.edge!(a, b)
    net.edge!(a, c)
    net.edge!(c, b)

    # degree
    assert_equal(2, a.degree)
    assert_equal(2, b.degree)
    assert_equal(2, c.degree)

    # in_degree
    assert_equal(0, a.in_degree)
    assert_equal(2, b.in_degree)
    assert_equal(1, c.in_degree)

    # out_degree
    assert_equal(2, a.out_degree)
    assert_equal(0, b.out_degree)
    assert_equal(1, c.out_degree)
  end

  # TODO: cluster
end
