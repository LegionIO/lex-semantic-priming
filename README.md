# lex-semantic-priming

Spreading activation network for LegionIO cognitive agents. Nodes represent concepts; connections carry weights that strengthen each time they are traversed (Hebbian reinforcement).

## What It Does

`lex-semantic-priming` maintains a weighted semantic network where priming one concept causes activation to spread to related concepts with depth-attenuated strength. The network learns from use: every edge traversal during spreading activation calls `strengthen!` on that connection, gradually building stronger pathways for frequently co-activated concepts.

- **Nodes**: typed concept nodes (`:concept`, `:entity`, `:action`, `:property`, `:relation`, `:event`, `:context`)
- **Connections**: directional weighted edges; weights grow on traversal (Hebbian), decay over time
- **Spreading activation**: BFS from a seed node across outgoing connections; activation decays by `DEPTH_DECAY_FACTOR` (0.5) per hop and by `weight * SPREADING_FACTOR` (0.6) per edge
- **Decay**: all node activations and connection weights decay each tick; connections pruned at MIN_WEIGHT (0.05)
- **Primed nodes**: activation >= 0.4; active nodes: activation > 0.1

## Usage

```ruby
require 'legion/extensions/semantic_priming'

client = Legion::Extensions::SemanticPriming::Client.new

# Add concept nodes
ruby_id   = client.add_node(label: 'ruby', node_type: :concept, domain: :programming)[:node_id]
oop_id    = client.add_node(label: 'object_oriented', node_type: :concept, domain: :programming)[:node_id]
class_id  = client.add_node(label: 'class', node_type: :concept, domain: :programming)[:node_id]

# Connect them
client.connect_nodes(source_id: ruby_id, target_id: oop_id)
client.connect_nodes(source_id: oop_id, target_id: class_id)

# Prime a seed and spread activation
result = client.prime_and_spread(node_id: ruby_id)
# => { success: true, node_id: ..., activation: 0.3, spread_count: 2 }

# See which nodes are primed (activation >= 0.4)
client.primed_nodes
# => { success: true, nodes: [...], count: 1 }

# Most activated nodes
client.most_primed(limit: 5)
# => { success: true, nodes: [{ label: 'ruby', activation: 0.3, ... }, ...], count: ... }

# Per-tick decay (call each cognitive cycle)
client.decay
# => { success: true, active_nodes: 2, pruned_connections: 0 }

# Network summary
client.priming_report
# => { node_count:, connection_count:, active_count:, primed_count:, average_activation:, density:, ... }
```

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
