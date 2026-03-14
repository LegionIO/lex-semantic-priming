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

          def reset_all! = @nodes.each_value(&:reset!) && { nodes_reset: @nodes.size }
          def find_node_by_label(label:) = @nodes.values.find { |n| n.label == label.to_s }

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

          def primed_nodes = @nodes.values.select(&:primed?)
          def active_nodes = @nodes.values.select(&:active?)
          def most_primed(limit: 5) = @nodes.values.sort_by { |n| -n.activation }.first(limit)
          def strongest_connections(limit: 5) = @connections.values.sort_by { |c| -c.weight }.first(limit)

          def average_activation
            return DEFAULT_ACTIVATION if @nodes.empty?

            vals = @nodes.values.map(&:activation)
            (vals.sum / vals.size).round(10)
          end

          def average_connection_weight
            return DEFAULT_WEIGHT if @connections.empty?

            vals = @connections.values.map(&:weight)
            (vals.sum / vals.size).round(10)
          end

          def network_density
            return 0.0 if @nodes.size < 2

            (@connections.size.to_f / (@nodes.size * (@nodes.size - 1) / 2)).round(10)
          end

          def priming_report
            to_h.merge(
              average_weight:        average_connection_weight,
              most_primed:           most_primed(limit: 3).map(&:to_h),
              strongest_connections: strongest_connections(limit: 3).map(&:to_h)
            )
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
            return if current_depth >= max_depth || activation < ACTIVATION_THRESHOLD

            each_neighbor(node_id) do |conn, other_id, target_node|
              next if activated.key?(other_id)

              amount = (conn.spreading_amount(activation) * (DEPTH_DECAY_FACTOR**current_depth)).round(10)
              next if amount < ACTIVATION_THRESHOLD

              conn.traverse!
              target_node.prime!(amount: amount)
              activated[other_id] = amount
              spread_recursive(other_id, amount, max_depth, current_depth + 1, activated)
            end
          end

          def each_neighbor(node_id)
            (@adjacency[node_id] || []).each do |cid|
              conn = @connections[cid]
              next unless conn

              other_id = conn.source_id == node_id ? conn.target_id : conn.source_id
              target_node = @nodes[other_id]
              yield conn, other_id, target_node if target_node
            end
          end

          def connection_involves?(cid, nid)
            (c = @connections[cid]) && (c.source_id == nid || c.target_id == nid)
          end

          def prune_nodes_if_needed
            return if @nodes.size < MAX_NODES

            remove_node(node_id: @nodes.values.min_by(&:activation).id)
          end

          def prune_connections_if_needed
            return if @connections.size < MAX_CONNECTIONS

            remove_connection(@connections.values.min_by(&:weight).id)
          end

          def prune_weak_connections
            @connections.each { |id, c| remove_connection(id) if c.weight <= MIN_WEIGHT }
          end

          def remove_connection(conn_id)
            return unless (conn = @connections.delete(conn_id))

            @adjacency[conn.source_id]&.delete(conn_id)
            @adjacency[conn.target_id]&.delete(conn_id)
          end
        end
      end
    end
  end
end
