# frozen_string_literal: true

require_relative 'semantic_priming/version'
require_relative 'semantic_priming/helpers/constants'
require_relative 'semantic_priming/helpers/semantic_node'
require_relative 'semantic_priming/helpers/connection'
require_relative 'semantic_priming/helpers/priming_network'
require_relative 'semantic_priming/runners/semantic_priming'
require_relative 'semantic_priming/client'

module Legion
  module Extensions
    module SemanticPriming
      extend Legion::Extensions::Core if defined?(Legion::Extensions::Core)
    end
  end
end
