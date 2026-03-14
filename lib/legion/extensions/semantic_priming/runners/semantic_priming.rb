# frozen_string_literal: true

module Legion
  module Extensions
    module SemanticPriming
      module Runners
        module SemanticPriming
          if defined?(Legion::Extensions::Helpers::Lex)
            include Legion::Extensions::Helpers::Lex
          end

          def add_node(label:, node_type: :concept, engine: nil, **)
            eng = engine || default_engine
            node = eng.add_node(label: label, node_type: node_type)
            { success: true, node: node.to_h }
          end

          def remove_node(node_id:, engine: nil, **)
            eng = engine || default_engine
            node = eng.remove_node(node_id: node_id)
            return { success: false, error: 'node not found' } unless node

            { success: true, removed: node.to_h }
          end

          def connect_nodes(source_id:, target_id:, weight: nil, engine: nil, **)
            eng = engine || default_engine
            w = weight || Helpers::Constants::DEFAULT_WEIGHT
            conn = eng.connect(source_id: source_id, target_id: target_id, weight: w)
            return { success: false, error: 'invalid nodes or self-connection' } unless conn

            { success: true, connection: conn.to_h }
          end

          def prime(node_id:, amount: nil, engine: nil, **)
            eng = engine || default_engine
            amt = amount || Helpers::Constants::PRIMING_BOOST
            node = eng.prime_node(node_id: node_id, amount: amt)
            return { success: false, error: 'node not found' } unless node

            { success: true, node: node.to_h }
          end

          def prime_and_spread(node_id:, amount: nil, depth: nil, engine: nil, **)
            eng = engine || default_engine
            amt = amount || Helpers::Constants::PRIMING_BOOST
            d = depth || Helpers::Constants::MAX_SPREAD_DEPTH
            result = eng.prime_and_spread(node_id: node_id, amount: amt, depth: d)
            return { success: false, error: 'node not found' } unless result

            { success: true, **result }
          end

          def spread_activation(source_id:, depth: nil, engine: nil, **)
            eng = engine || default_engine
            d = depth || Helpers::Constants::MAX_SPREAD_DEPTH
            result = eng.spread_activation(source_id: source_id, depth: d)
            return { success: false, error: 'node not found' } unless result

            { success: true, activated: result }
          end

          def decay(engine: nil, **)
            eng = engine || default_engine
            result = eng.decay_all!
            { success: true, **result }
          end

          def reset(engine: nil, **)
            eng = engine || default_engine
            result = eng.reset_all!
            { success: true, **result }
          end

          def find_node(label:, engine: nil, **)
            eng = engine || default_engine
            node = eng.find_node_by_label(label: label)
            return { success: false, error: 'node not found' } unless node

            { success: true, node: node.to_h }
          end

          def neighbors(node_id:, engine: nil, **)
            eng = engine || default_engine
            nodes = eng.neighbors(node_id: node_id)
            { success: true, neighbors: nodes.map(&:to_h) }
          end

          def primed_nodes(engine: nil, **)
            eng = engine || default_engine
            { success: true, nodes: eng.primed_nodes.map(&:to_h) }
          end

          def most_primed(limit: 5, engine: nil, **)
            eng = engine || default_engine
            { success: true, nodes: eng.most_primed(limit: limit).map(&:to_h) }
          end

          def priming_report(engine: nil, **)
            eng = engine || default_engine
            { success: true, report: eng.priming_report }
          end

          def status(engine: nil, **)
            eng = engine || default_engine
            { success: true, **eng.to_h }
          end

          private

          def default_engine
            @default_engine ||= Helpers::PrimingNetwork.new
          end
        end
      end
    end
  end
end
