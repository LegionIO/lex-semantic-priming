# frozen_string_literal: true

RSpec.describe Legion::Extensions::SemanticPriming::Helpers::Connection do
  subject(:conn) { described_class.new(source_id: 'src-1', target_id: 'tgt-1') }

  describe '#initialize' do
    it 'assigns a UUID id' do
      expect(conn.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'sets source and target' do
      expect(conn.source_id).to eq('src-1')
      expect(conn.target_id).to eq('tgt-1')
    end

    it 'defaults weight to 0.5' do
      expect(conn.weight).to eq(0.5)
    end

    it 'clamps low weight' do
      low = described_class.new(source_id: 'a', target_id: 'b', weight: 0.0)
      expect(low.weight).to eq(0.05)
    end
  end

  describe '#strengthen!' do
    it 'increases weight' do
      original = conn.weight
      conn.strengthen!
      expect(conn.weight).to be > original
    end

    it 'clamps at 1.0' do
      30.times { conn.strengthen!(amount: 0.1) }
      expect(conn.weight).to eq(1.0)
    end
  end

  describe '#weaken!' do
    it 'decreases weight' do
      original = conn.weight
      conn.weaken!
      expect(conn.weight).to be < original
    end
  end

  describe '#traverse!' do
    it 'increments traversal count' do
      conn.traverse!
      expect(conn.traversal_count).to eq(1)
    end

    it 'strengthens connection' do
      original = conn.weight
      conn.traverse!
      expect(conn.weight).to be > original
    end
  end

  describe '#spreading_amount' do
    it 'computes spread based on activation and weight' do
      amount = conn.spreading_amount(0.8)
      expect(amount).to be > 0
      expect(amount).to be < 0.8
    end

    it 'returns zero for zero activation' do
      expect(conn.spreading_amount(0.0)).to eq(0.0)
    end
  end

  describe '#strong?' do
    it 'is false at default weight' do
      expect(conn.strong?).to be false
    end

    it 'is true at high weight' do
      high = described_class.new(source_id: 'a', target_id: 'b', weight: 0.8)
      expect(high.strong?).to be true
    end
  end

  describe '#weight_label' do
    it 'returns a symbol' do
      expect(conn.weight_label).to be_a(Symbol)
    end
  end

  describe '#to_h' do
    it 'includes all fields' do
      hash = conn.to_h
      expect(hash).to include(
        :id, :source_id, :target_id, :weight, :weight_label,
        :strong, :weak, :traversal_count, :created_at
      )
    end
  end
end
