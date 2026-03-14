# frozen_string_literal: true

RSpec.describe Legion::Extensions::SemanticPriming::Helpers::SemanticNode do
  subject(:node) { described_class.new(label: 'doctor') }

  describe '#initialize' do
    it 'assigns a UUID id' do
      expect(node.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'sets label' do
      expect(node.label).to eq('doctor')
    end

    it 'defaults to concept type' do
      expect(node.node_type).to eq(:concept)
    end

    it 'starts with zero activation' do
      expect(node.activation).to eq(0.0)
    end

    it 'starts with zero prime count' do
      expect(node.prime_count).to eq(0)
    end

    it 'clamps high activation' do
      high = described_class.new(label: 'x', activation: 5.0)
      expect(high.activation).to eq(1.0)
    end
  end

  describe '#prime!' do
    it 'increases activation' do
      node.prime!
      expect(node.activation).to be > 0.0
    end

    it 'increments prime count' do
      node.prime!
      expect(node.prime_count).to eq(1)
    end

    it 'clamps at max activation' do
      5.times { node.prime!(amount: 0.5) }
      expect(node.activation).to eq(1.0)
    end

    it 'returns self' do
      expect(node.prime!).to eq(node)
    end
  end

  describe '#decay!' do
    it 'reduces activation' do
      node.prime!(amount: 0.5)
      original = node.activation
      node.decay!
      expect(node.activation).to be < original
    end

    it 'does not go below zero' do
      node.decay!
      expect(node.activation).to eq(0.0)
    end
  end

  describe '#access!' do
    it 'increments access count' do
      node.access!
      expect(node.access_count).to eq(1)
    end
  end

  describe '#reset!' do
    it 'resets activation to resting level' do
      node.prime!(amount: 0.8)
      node.reset!
      expect(node.activation).to eq(0.0)
    end
  end

  describe '#primed?' do
    it 'is false when unactivated' do
      expect(node.primed?).to be false
    end

    it 'is true when highly activated' do
      node.prime!(amount: 0.5)
      expect(node.primed?).to be true
    end
  end

  describe '#active?' do
    it 'is false at zero activation' do
      expect(node.active?).to be false
    end

    it 'is true above threshold' do
      node.prime!(amount: 0.3)
      expect(node.active?).to be true
    end
  end

  describe '#activation_label' do
    it 'returns unprimed for zero activation' do
      expect(node.activation_label).to eq(:unprimed)
    end

    it 'returns primed for high activation' do
      node.prime!(amount: 0.7)
      expect(node.activation_label).to eq(:primed)
    end
  end

  describe '#to_h' do
    it 'includes all fields' do
      hash = node.to_h
      expect(hash).to include(
        :id, :label, :node_type, :activation, :activation_label,
        :primed, :active, :prime_count, :access_count, :created_at
      )
    end
  end
end
