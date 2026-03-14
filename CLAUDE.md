# lex-semantic-priming

**Level 3 Leaf Documentation**
- **Parent**: `/Users/miverso2/rubymine/legion/extensions-agentic/CLAUDE.md`
- **Gem**: `lex-semantic-priming`
- **Version**: `0.1.0`
- **Namespace**: `Legion::Extensions::SemanticPriming`

## Purpose

Implements spreading activation across a weighted semantic network. Nodes represent concepts; connections carry directional weights that grow stronger each time they are traversed (Hebbian reinforcement). When a seed concept is primed, activation spreads outward through connected nodes with both a per-hop decay factor and a weight-attenuated spread amount. Distinct from `lex-semantic-memory` (which stores named concept definitions with typed relations) — this stores activation states and connection weights for dynamic priming behavior.

## Gem Info

- **Gem name**: `lex-semantic-priming`
- **License**: MIT
- **Ruby**: >= 3.4
- **No runtime dependencies** beyond the Legion framework

## File Structure

```
lib/legion/extensions/semantic_priming/
  version.rb                         # VERSION = '0.1.0'
  helpers/
    constants.rb                     # limits, activation params, weight params, node types
    semantic_node.rb                 # SemanticNode class — concept node with activation state
    connection.rb                    # Connection class — weighted directional edge, Hebbian traversal
    priming_network.rb               # PrimingNetwork class — full network with BFS spreading activation
  runners/
    semantic_priming.rb              # Runners::SemanticPriming module — all public runner methods
  client.rb                          # Client class including Runners::SemanticPriming
```

## Key Constants

| Constant | Value | Purpose |
|---|---|---|
| `MAX_NODES` | 500 | Maximum nodes in the network |
| `MAX_CONNECTIONS` | 2000 | Maximum edges |
| `ACTIVATION_DECAY` | 0.05 | Per-tick activation decrease for all nodes |
| `SPREADING_FACTOR` | 0.6 | Base fraction of activation that spreads per hop |
| `PRIMING_BOOST` | 0.3 | Direct boost applied to a node when primed |
| `ACTIVATION_THRESHOLD` | 0.1 | Minimum activation to be considered active |
| `DEFAULT_WEIGHT` | 0.5 | Starting connection weight for new edges |
| `WEIGHT_GROWTH_RATE` | 0.02 | Weight increase on each traversal (Hebbian) |
| `WEIGHT_DECAY_RATE` | 0.01 | Weight decrease per decay cycle |
| `MIN_WEIGHT` | 0.05 | Floor for connection weights; pruned at or below |
| `MAX_SPREAD_DEPTH` | 3 | Maximum BFS hops during spreading activation |
| `DEPTH_DECAY_FACTOR` | 0.5 | Activation multiplier per depth level |
| `NODE_TYPES` | 7 symbols | `:concept`, `:entity`, `:action`, `:property`, `:relation`, `:event`, `:context` |

## Helpers

### `Helpers::SemanticNode`

Concept node with activation state and metadata.

- `initialize(id:, label:, node_type: :concept, domain: :general)` — initial activation = 0.0
- `prime!(amount = PRIMING_BOOST)` — boosts activation by amount, clamps to 1.0
- `decay!(rate = ACTIVATION_DECAY)` — decrements activation; floors at 0.0
- `access!` — records last_accessed timestamp
- `reset!` — sets activation back to 0.0
- `primed?` — activation >= 0.4
- `active?` — activation > ACTIVATION_THRESHOLD
- `activation_label` — `:dormant`, `:trace`, `:weak`, `:moderate`, `:strong`, `:peak` based on activation value

### `Helpers::Connection`

Weighted directional edge between two nodes.

- `initialize(source_id:, target_id:, weight: DEFAULT_WEIGHT)` — assigned UUID
- `strengthen!(amount = WEIGHT_GROWTH_RATE)` — increases weight, clamps to 1.0
- `weaken!(amount = WEIGHT_DECAY_RATE)` — decreases weight; removes when at or below MIN_WEIGHT
- `traverse!(source_activation)` — calls `strengthen!` (Hebbian) and returns `spreading_amount`
- `spreading_amount(source_activation)` — `source_activation * weight * SPREADING_FACTOR`
- `weight_label` — `:negligible`, `:weak`, `:moderate`, `:strong`, `:dominant`

### `Helpers::PrimingNetwork`

Full network with BFS spreading activation.

- `initialize` — empty nodes hash, connections hash (keyed by `source_id:target_id`)
- `add_node(label:, node_type: :concept, domain: :general)` — returns nil if at MAX_NODES
- `remove_node(node_id)` — removes node and all connections to/from it
- `connect(source_id:, target_id:, weight: DEFAULT_WEIGHT)` — creates or returns existing connection; returns nil if at MAX_CONNECTIONS
- `prime_node(node_id, amount: PRIMING_BOOST)` — calls `node.prime!`
- `spread_activation(node_id, depth: MAX_SPREAD_DEPTH, visited: {})` — recursive BFS; each level multiplied by `DEPTH_DECAY_FACTOR`; each edge traversal calls `connection.traverse!` for Hebbian strengthening
- `prime_and_spread(node_id, amount: PRIMING_BOOST, depth: MAX_SPREAD_DEPTH)` — primes seed, then spreads
- `decay_all!` — decays all node activations; weakens all connection weights (prunes at MIN_WEIGHT)
- `reset_all!` — resets all node activations to 0.0
- `find_node_by_label(label)` — substring or exact match search
- `neighbors(node_id)` — returns all outgoing connections
- `connection_between(source_id, target_id)` — direct lookup
- `primed_nodes` — nodes with `primed? == true`
- `active_nodes` — nodes with `active? == true`
- `most_primed(limit: 5)` — sorted by activation descending
- `strongest_connections(limit: 10)` — sorted by weight descending
- `average_activation` — mean activation across all nodes
- `network_density` — `connections.size.to_f / [nodes.size * (nodes.size - 1), 1].max`
- `priming_report` — summary hash including active/primed counts, average activation, density, top nodes

## Runners

All runners are in `Runners::SemanticPriming`. Callers may pass an optional `engine:` parameter to operate on a non-default network instance.

| Runner | Parameters | Returns |
|---|---|---|
| `add_node` | `label:, node_type: :concept, domain: :general` | `{ success:, node_id:, label:, node_type: }` |
| `remove_node` | `node_id:` | `{ success: }` |
| `connect_nodes` | `source_id:, target_id:, weight: DEFAULT_WEIGHT` | `{ success:, connection_id:, source_id:, target_id:, weight: }` |
| `prime` | `node_id:, amount: PRIMING_BOOST` | `{ success:, node_id:, activation: }` |
| `prime_and_spread` | `node_id:, amount: PRIMING_BOOST, depth: MAX_SPREAD_DEPTH` | `{ success:, node_id:, activation:, spread_count: }` |
| `spread_activation` | `node_id:, depth: MAX_SPREAD_DEPTH` | `{ success:, node_id:, spread_count: }` |
| `decay` | (none) | `{ success:, active_nodes:, pruned_connections: }` |
| `reset` | (none) | `{ success: }` |
| `find_node` | `label:` | `{ success:, found:, node: }` |
| `neighbors` | `node_id:` | `{ success:, node_id:, neighbors:, count: }` |
| `primed_nodes` | (none) | `{ success:, nodes:, count: }` |
| `most_primed` | `limit: 5` | `{ success:, nodes:, count: }` |
| `priming_report` | (none) | Full `PrimingNetwork#priming_report` hash |
| `status` | (none) | Node count, connection count, average activation, density |

## Integration Points

- **lex-semantic-memory**: semantic-memory stores named concept definitions with relational structure; semantic-priming stores transient activation state and connection weights. They are complementary — semantic-memory provides the schema; semantic-priming provides the dynamic activation surface
- **lex-dream**: association walking in the dream cycle can use `prime_and_spread` to find conceptually adjacent concepts for contradiction resolution and agenda synthesis
- **lex-tick / lex-cortex**: `prime_and_spread` or `decay` can be wired as a tick phase handler for ongoing network maintenance
- **lex-memory**: when a memory trace is retrieved, its associated concept nodes can be primed to model recency effects on conceptual accessibility

## Development Notes

- Spreading activation is recursive, not iterative; depth is tracked via `visited` hash to prevent re-activation of already-visited nodes in the same spread call
- Each `traverse!` call on a connection triggers Hebbian strengthening — frequent traversals produce stronger connections over time, modeling use-dependent accessibility
- `DEPTH_DECAY_FACTOR = 0.5` means activation at depth 2 is 25% of the seed's activation; at depth 3, 12.5%
- `spreading_amount` = `source_activation * weight * SPREADING_FACTOR`; this triple-product means low-weight connections transmit very little even with high source activation
- `decay_all!` weaken-and-prune connections in the same pass; connections at or below `MIN_WEIGHT` are deleted
- The optional `engine:` parameter on all runners supports multiple independent networks in a single process
