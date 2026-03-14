# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module SemanticPriming
      module Helpers
        class Connection
          include Constants

          attr_reader :id, :source_id, :target_id, :weight, :traversal_count, :created_at

          def initialize(source_id:, target_id:, weight: DEFAULT_WEIGHT)
            @id              = SecureRandom.uuid
            @source_id       = source_id
            @target_id       = target_id
            @weight          = weight.to_f.clamp(MIN_WEIGHT, 1.0).round(10)
            @traversal_count = 0
            @created_at      = Time.now.utc
          end

          def strengthen!(amount: WEIGHT_GROWTH_RATE)
            @weight = (@weight + amount).clamp(MIN_WEIGHT, 1.0).round(10)
            self
          end

          def weaken!(amount: WEIGHT_DECAY_RATE)
            @weight = (@weight - amount).clamp(MIN_WEIGHT, 1.0).round(10)
            self
          end

          def traverse!
            @traversal_count += 1
            strengthen!(amount: WEIGHT_GROWTH_RATE)
            self
          end

          def strong?
            @weight >= 0.7
          end

          def weak?
            @weight <= 0.2
          end

          def spreading_amount(source_activation)
            (source_activation * @weight * SPREADING_FACTOR).round(10)
          end

          def weight_label
            match = WEIGHT_LABELS.find { |range, _| range.cover?(@weight) }
            match ? match.last : :very_weak
          end

          def to_h
            {
              id:              @id,
              source_id:       @source_id,
              target_id:       @target_id,
              weight:          @weight,
              weight_label:    weight_label,
              strong:          strong?,
              weak:            weak?,
              traversal_count: @traversal_count,
              created_at:      @created_at
            }
          end
        end
      end
    end
  end
end
