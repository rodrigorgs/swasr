require 'test/unit'
require '../network'

class TC_Network < Test::Unit::TestCase
  def test_node_creation
    net = Network.new
    net.n('no1')
    net.n('no2')
    net.n('no1')
    net.n('no3')
    assert_equal(3, net.nodes.size)
  end

  def test_edge_creates_node
    net = Network.new
    net.n(1)
    net.e(1, 2)
    assert_equal(2, net.nodes.size)
    net.e(3, 1)
    assert_equal(3, net.nodes.size)
  end

  def test_edge_assimetry
    net = Network.new
    net.e(1, 2)
    net.e(2, 1)
    assert_equal(2, net.edges.size)
  end

  def test_edge_updates_node_neighbors
    net = Network.new
    a = net.n('a')
    b = net.n('b')
    net.e(a, b)
    assert_equal(1, a.out_edges_map.size)
    assert_equal(0, a.in_edges_map.size)
    assert_equal(0, b.out_edges_map.size)
    assert_equal(1, b.in_edges_map.size)
  end

  def test_degree_metrics
    net = Network.new
    a = net.n('a')
    b = net.n('b')
    c = net.n('c')
    net.e(a, b)
    net.e(a, c)
    net.e(c, b)

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
