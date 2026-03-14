# frozen_string_literal: true

module Legion
  module Extensions
    module SemanticPriming
      class Client
        include Runners::SemanticPriming

        def initialize(engine: nil)
          @default_engine = engine || Helpers::PrimingNetwork.new
        end
      end
    end
  end
end
