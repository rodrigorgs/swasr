#!/usr/bin/env ruby

require 'test/unit'
require '../network'

class TC_Network < Test::Unit::TestCase
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
