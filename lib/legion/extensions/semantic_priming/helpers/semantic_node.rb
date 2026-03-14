# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module SemanticPriming
      module Helpers
        class SemanticNode
          include Constants

          attr_reader :id, :label, :node_type, :activation, :prime_count,
                      :access_count, :created_at

          def initialize(label:, node_type: :concept, activation: DEFAULT_ACTIVATION)
            @id           = SecureRandom.uuid
            @label        = label.to_s
            @node_type    = node_type.to_sym
            @activation   = activation.to_f.clamp(0.0, MAX_ACTIVATION).round(10)
            @prime_count  = 0
            @access_count = 0
            @created_at   = Time.now.utc
          end

          def prime!(amount: PRIMING_BOOST)
            @activation = (@activation + amount).clamp(0.0, MAX_ACTIVATION).round(10)
            @prime_count += 1
            self
          end

          def decay!
            @activation = (@activation - ACTIVATION_DECAY).clamp(0.0, MAX_ACTIVATION).round(10)
            self
          end

          def access!
            @access_count += 1
            self
          end

          def reset!
            @activation = RESTING_ACTIVATION
            self
          end

          def primed?
            @activation >= 0.4
          end

          def active?
            @activation > ACTIVATION_THRESHOLD
          end

          def activation_label
            match = ACTIVATION_LABELS.find { |range, _| range.cover?(@activation) }
            match ? match.last : :unprimed
          end

          def to_h
            {
              id:               @id,
              label:            @label,
              node_type:        @node_type,
              activation:       @activation,
              activation_label: activation_label,
              primed:           primed?,
              active:           active?,
              prime_count:      @prime_count,
              access_count:     @access_count,
              created_at:       @created_at
            }
          end
        end
      end
    end
  end
end
