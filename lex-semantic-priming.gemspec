# frozen_string_literal: true

require_relative 'lib/legion/extensions/semantic_priming/version'

Gem::Specification.new do |spec|
  spec.name          = 'lex-semantic-priming'
  spec.version       = Legion::Extensions::SemanticPriming::VERSION
  spec.authors       = ['Esity']
  spec.email         = ['matthewdiverson@gmail.com']

  spec.summary       = 'Semantic priming and spreading activation network for LegionIO'
  spec.description   = 'Models spreading activation in semantic networks - priming one concept activates related ' \
                        'concepts with distance-based decay for rapid associative retrieval.'
  spec.homepage      = 'https://github.com/LegionIO/lex-semantic-priming'
  spec.license       = 'MIT'

  spec.required_ruby_version = '>= 3.4'

  spec.metadata['homepage_uri']      = spec.homepage
  spec.metadata['source_code_uri']   = 'https://github.com/LegionIO/lex-semantic-priming'
  spec.metadata['documentation_uri'] = 'https://github.com/LegionIO/lex-semantic-priming/blob/master/README.md'
  spec.metadata['changelog_uri']     = 'https://github.com/LegionIO/lex-semantic-priming/blob/master/CHANGELOG.md'
  spec.metadata['bug_tracker_uri']   = 'https://github.com/LegionIO/lex-semantic-priming/issues'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.require_paths = ['lib']
end
