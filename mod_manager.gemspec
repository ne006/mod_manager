# frozen_string_literal: true

require_relative 'lib/mod_manager/version'

Gem::Specification.new do |spec|
  spec.name          = 'mod_manager'
  spec.version       = ModManager::VERSION
  spec.authors       = ['ne006']
  spec.email         = ['IATikhomirov@gmail.com']

  spec.summary       = 'Mod manager for Stellaris'
  spec.description   = 'Mod manager for Stellaris 2.6+'
  spec.homepage      = 'https://github.com/ne006/mod_manager'
  spec.license       = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('~> 2.6')

  spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'rake', '~> 12.0'
  spec.add_development_dependency 'rspec', '~> 3.8'
  spec.add_development_dependency 'rubocop'

  spec.add_dependency 'rubyzip'
end
