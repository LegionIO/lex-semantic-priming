# frozen_string_literal: true

module Legion
  module Extensions
    module SemanticPriming
      module Helpers
        module Constants
          # Network limits
          MAX_NODES = 500
          MAX_CONNECTIONS = 2000

          # Activation dynamics
          DEFAULT_ACTIVATION = 0.0
          RESTING_ACTIVATION = 0.0
          MAX_ACTIVATION = 1.0
          ACTIVATION_DECAY = 0.05
          SPREADING_FACTOR = 0.6
          PRIMING_BOOST = 0.3
          ACTIVATION_THRESHOLD = 0.1

          # Connection properties
          DEFAULT_WEIGHT = 0.5
          WEIGHT_GROWTH_RATE = 0.02
          WEIGHT_DECAY_RATE = 0.01
          MIN_WEIGHT = 0.05

          # Spreading activation
          MAX_SPREAD_DEPTH = 3
          DEPTH_DECAY_FACTOR = 0.5

          # Node types
          NODE_TYPES = %i[concept category feature relation action emotion context].freeze

          # Activation labels
          ACTIVATION_LABELS = {
            (0.8..)     => :highly_primed,
            (0.6...0.8) => :primed,
            (0.4...0.6) => :partially_primed,
            (0.2...0.4) => :weakly_primed,
            (..0.2)     => :unprimed
          }.freeze

          # Connection strength labels
          WEIGHT_LABELS = {
            (0.8..)     => :very_strong,
            (0.6...0.8) => :strong,
            (0.4...0.6) => :moderate,
            (0.2...0.4) => :weak,
            (..0.2)     => :very_weak
          }.freeze

          # Priming effect labels
          PRIMING_LABELS = {
            (0.8..)     => :massive,
            (0.6...0.8) => :strong,
            (0.4...0.6) => :moderate,
            (0.2...0.4) => :mild,
            (..0.2)     => :negligible
          }.freeze
        end
      end
    end
  end
end
