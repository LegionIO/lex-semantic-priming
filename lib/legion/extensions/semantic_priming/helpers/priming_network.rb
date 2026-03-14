# frozen_string_literal: true

module Legion
  module Extensions
    module SemanticPriming
      module Helpers
        class PrimingNetwork
          include Constants

          def initialize
            @nodes       = {}
            @connections = {}
            @adjacency   = Hash.new { |h, k| h[k] = [] }
          end

          def add_node(label:, node_type: :concept)
            prune_nodes_if_needed
            node = SemanticNode.new(label: label, node_type: node_type)
            @nodes[node.id] = node
            node
          end

          def remove_node(node_id:)
            node = @nodes.delete(node_id)
            return nil unless node

            @adjacency.delete(node_id)
            @adjacency.each_value { |list| list.reject! { |cid| connection_involves?(cid, node_id) } }
            @connections.reject! { |_, c| c.source_id == node_id || c.target_id == node_id }
            node
          end

          def connect(source_id:, target_id:, weight: DEFAULT_WEIGHT)
            return nil unless @nodes[source_id] && @nodes[target_id]
            return nil if source_id == target_id

            prune_connections_if_needed
            conn = Connection.new(source_id: source_id, target_id: target_id, weight: weight)
            @connections[conn.id] = conn
            @adjacency[source_id] << conn.id
            @adjacency[target_id] << conn.id
            conn
          end

          def prime_node(node_id:, amount: PRIMING_BOOST)
            node = @nodes[node_id]
            return nil unless node

            node.prime!(amount: amount)
            node
          end

          def spread_activation(source_id:, depth: MAX_SPREAD_DEPTH)
            source = @nodes[source_id]
            return nil unless source

            activated = {}
            spread_recursive(source_id, source.activation, depth, 0, activated)
            activated.map { |nid, amount| { node_id: nid, label: @nodes[nid]&.label, activation_added: amount } }
          end

          def prime_and_spread(node_id:, amount: PRIMING_BOOST, depth: MAX_SPREAD_DEPTH)
            node = prime_node(node_id: node_id, amount: amount)
            return nil unless node

            node.access!
            spread = spread_activation(source_id: node_id, depth: depth)
            { primed_node: node.to_h, spread: spread }
          end

          def decay_all!
            @nodes.each_value(&:decay!)
            @connections.each_value { |c| c.weaken!(amount: WEIGHT_DECAY_RATE) }
            prune_weak_connections
            { nodes_decayed: @nodes.size, connections_remaining: @connections.size }
          end

          def reset_all!
            @nodes.each_value(&:reset!)
            { nodes_reset: @nodes.size }
          end

          def find_node_by_label(label:)
            @nodes.values.find { |n| n.label == label.to_s }
          end

          def neighbors(node_id:)
            conn_ids = @adjacency[node_id] || []
            conn_ids.filter_map do |cid|
              conn = @connections[cid]
              next unless conn

              other_id = conn.source_id == node_id ? conn.target_id : conn.source_id
              @nodes[other_id]
            end
          end

          def connection_between(source_id:, target_id:)
            @connections.values.find do |c|
              (c.source_id == source_id && c.target_id == target_id) ||
                (c.source_id == target_id && c.target_id == source_id)
            end
          end

          def primed_nodes
            @nodes.values.select(&:primed?)
          end

          def active_nodes
            @nodes.values.select(&:active?)
          end

          def most_primed(limit: 5)
            @nodes.values.sort_by { |n| -n.activation }.first(limit)
          end

          def strongest_connections(limit: 5)
            @connections.values.sort_by { |c| -c.weight }.first(limit)
          end

          def average_activation
            return DEFAULT_ACTIVATION if @nodes.empty?

            activations = @nodes.values.map(&:activation)
            (activations.sum / activations.size).round(10)
          end

          def average_connection_weight
            return DEFAULT_WEIGHT if @connections.empty?

            weights = @connections.values.map(&:weight)
            (weights.sum / weights.size).round(10)
          end

          def network_density
            return 0.0 if @nodes.size < 2

            max_connections = @nodes.size * (@nodes.size - 1) / 2
            (@connections.size.to_f / max_connections).round(10)
          end

          def priming_report
            {
              total_nodes:             @nodes.size,
              total_connections:       @connections.size,
              primed_count:            primed_nodes.size,
              active_count:            active_nodes.size,
              average_activation:      average_activation,
              average_weight:          average_connection_weight,
              network_density:         network_density,
              most_primed:             most_primed(limit: 3).map(&:to_h),
              strongest_connections:   strongest_connections(limit: 3).map(&:to_h)
            }
          end

          def to_h
            {
              total_nodes:        @nodes.size,
              total_connections:  @connections.size,
              primed_count:       primed_nodes.size,
              active_count:       active_nodes.size,
              average_activation: average_activation,
              network_density:    network_density
            }
          end

          private

          def spread_recursive(node_id, activation, max_depth, current_depth, activated)
            return if current_depth >= max_depth
            return if activation < ACTIVATION_THRESHOLD

            conn_ids = @adjacency[node_id] || []
            conn_ids.each do |cid|
              conn = @connections[cid]
              next unless conn

              other_id = conn.source_id == node_id ? conn.target_id : conn.source_id
              next if activated.key?(other_id)

              spread_amount = conn.spreading_amount(activation) * (DEPTH_DECAY_FACTOR**current_depth)
              next if spread_amount < ACTIVATION_THRESHOLD

              target_node = @nodes[other_id]
              next unless target_node

              conn.traverse!
              target_node.prime!(amount: spread_amount)
              activated[other_id] = spread_amount.round(10)

              spread_recursive(other_id, spread_amount, max_depth, current_depth + 1, activated)
            end
          end

          def connection_involves?(conn_id, node_id)
            conn = @connections[conn_id]
            return false unless conn

            conn.source_id == node_id || conn.target_id == node_id
          end

          def prune_nodes_if_needed
            return if @nodes.size < MAX_NODES

            least_active = @nodes.values.min_by(&:activation)
            remove_node(node_id: least_active.id) if least_active
          end

          def prune_connections_if_needed
            return if @connections.size < MAX_CONNECTIONS

            weakest = @connections.values.min_by(&:weight)
            remove_connection(weakest.id) if weakest
          end

          def prune_weak_connections
            @connections.each do |id, conn|
              remove_connection(id) if conn.weight <= MIN_WEIGHT
            end
          end

          def remove_connection(conn_id)
            conn = @connections.delete(conn_id)
            return unless conn

            @adjacency[conn.source_id]&.delete(conn_id)
            @adjacency[conn.target_id]&.delete(conn_id)
          end
        end
      end
    end
  end
end
