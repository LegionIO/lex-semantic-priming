# frozen_string_literal: true

RSpec.describe Legion::Extensions::SemanticPriming::Helpers::PrimingNetwork do
  subject(:network) { described_class.new }

  let(:doctor) { network.add_node(label: 'doctor') }
  let(:nurse) { network.add_node(label: 'nurse') }
  let(:hospital) { network.add_node(label: 'hospital') }

  describe '#add_node' do
    it 'creates a semantic node' do
      node = network.add_node(label: 'test')
      expect(node).to be_a(Legion::Extensions::SemanticPriming::Helpers::SemanticNode)
    end

    it 'stores the node' do
      node = network.add_node(label: 'stored')
      found = network.find_node_by_label(label: 'stored')
      expect(found.id).to eq(node.id)
    end
  end

  describe '#remove_node' do
    it 'removes the node' do
      node = network.add_node(label: 'remove_me')
      network.remove_node(node_id: node.id)
      expect(network.find_node_by_label(label: 'remove_me')).to be_nil
    end

    it 'returns nil for unknown node' do
      expect(network.remove_node(node_id: 'nonexistent')).to be_nil
    end

    it 'removes associated connections' do
      conn = network.connect(source_id: doctor.id, target_id: nurse.id)
      network.remove_node(node_id: doctor.id)
      expect(network.connection_between(source_id: doctor.id, target_id: nurse.id)).to be_nil
    end
  end

  describe '#connect' do
    it 'creates a connection between nodes' do
      conn = network.connect(source_id: doctor.id, target_id: nurse.id)
      expect(conn).to be_a(Legion::Extensions::SemanticPriming::Helpers::Connection)
    end

    it 'returns nil for self-connection' do
      expect(network.connect(source_id: doctor.id, target_id: doctor.id)).to be_nil
    end

    it 'returns nil for unknown nodes' do
      expect(network.connect(source_id: 'bad', target_id: nurse.id)).to be_nil
    end
  end

  describe '#prime_node' do
    it 'increases node activation' do
      doctor
      network.prime_node(node_id: doctor.id)
      expect(doctor.activation).to be > 0.0
    end

    it 'returns nil for unknown node' do
      expect(network.prime_node(node_id: 'bad')).to be_nil
    end
  end

  describe '#prime_and_spread' do
    it 'primes the target and spreads to neighbors' do
      network.connect(source_id: doctor.id, target_id: nurse.id)
      result = network.prime_and_spread(node_id: doctor.id)
      expect(result[:primed_node][:activation]).to be > 0
      expect(result[:spread].size).to be >= 1
    end

    it 'spreads activation through multi-hop paths' do
      network.connect(source_id: doctor.id, target_id: nurse.id, weight: 0.8)
      network.connect(source_id: nurse.id, target_id: hospital.id, weight: 0.8)
      network.prime_and_spread(node_id: doctor.id, amount: 0.8)
      expect(hospital.activation).to be > 0
    end

    it 'returns nil for unknown node' do
      expect(network.prime_and_spread(node_id: 'bad')).to be_nil
    end
  end

  describe '#spread_activation' do
    it 'activates connected nodes' do
      network.connect(source_id: doctor.id, target_id: nurse.id)
      network.prime_node(node_id: doctor.id, amount: 0.8)
      activated = network.spread_activation(source_id: doctor.id)
      expect(activated.size).to be >= 1
    end
  end

  describe '#decay_all!' do
    it 'reduces activation on all nodes' do
      network.prime_node(node_id: doctor.id, amount: 0.5)
      network.decay_all!
      expect(doctor.activation).to be < 0.5
    end
  end

  describe '#reset_all!' do
    it 'resets all activations to zero' do
      network.prime_node(node_id: doctor.id, amount: 0.5)
      network.reset_all!
      expect(doctor.activation).to eq(0.0)
    end
  end

  describe '#find_node_by_label' do
    it 'finds node by label string' do
      doctor
      found = network.find_node_by_label(label: 'doctor')
      expect(found.id).to eq(doctor.id)
    end

    it 'returns nil for unknown label' do
      expect(network.find_node_by_label(label: 'nonexistent')).to be_nil
    end
  end

  describe '#neighbors' do
    it 'returns connected nodes' do
      network.connect(source_id: doctor.id, target_id: nurse.id)
      nbrs = network.neighbors(node_id: doctor.id)
      expect(nbrs.map(&:id)).to include(nurse.id)
    end
  end

  describe '#connection_between' do
    it 'finds bidirectional connection' do
      network.connect(source_id: doctor.id, target_id: nurse.id)
      conn = network.connection_between(source_id: nurse.id, target_id: doctor.id)
      expect(conn).not_to be_nil
    end
  end

  describe '#primed_nodes' do
    it 'returns only primed nodes' do
      network.prime_node(node_id: doctor.id, amount: 0.5)
      nurse
      expect(network.primed_nodes.map(&:id)).to include(doctor.id)
      expect(network.primed_nodes.map(&:id)).not_to include(nurse.id)
    end
  end

  describe '#most_primed' do
    it 'returns nodes sorted by activation descending' do
      network.prime_node(node_id: doctor.id, amount: 0.8)
      network.prime_node(node_id: nurse.id, amount: 0.3)
      top = network.most_primed(limit: 2)
      expect(top.first.id).to eq(doctor.id)
    end
  end

  describe '#average_activation' do
    it 'returns 0.0 with no nodes' do
      expect(network.average_activation).to eq(0.0)
    end

    it 'computes mean activation' do
      network.prime_node(node_id: doctor.id, amount: 0.6)
      nurse
      avg = network.average_activation
      expect(avg).to be > 0.0
      expect(avg).to be < 0.6
    end
  end

  describe '#network_density' do
    it 'returns 0.0 with fewer than 2 nodes' do
      network.add_node(label: 'solo')
      expect(network.network_density).to eq(0.0)
    end

    it 'increases with more connections' do
      network.connect(source_id: doctor.id, target_id: nurse.id)
      hospital
      density1 = network.network_density
      network.connect(source_id: doctor.id, target_id: hospital.id)
      density2 = network.network_density
      expect(density2).to be > density1
    end
  end

  describe '#priming_report' do
    it 'returns comprehensive report' do
      doctor
      report = network.priming_report
      expect(report).to include(
        :total_nodes, :total_connections, :primed_count, :active_count,
        :average_activation, :average_weight, :network_density,
        :most_primed, :strongest_connections
      )
    end
  end

  describe '#to_h' do
    it 'returns summary hash' do
      doctor
      hash = network.to_h
      expect(hash).to include(:total_nodes, :total_connections, :primed_count, :active_count)
    end
  end
end
