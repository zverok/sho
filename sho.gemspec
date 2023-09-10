require_relative 'lib/sho/version'

Gem::Specification.new do |s|
  s.name     = 'sho'
  s.version  = Sho::VERSION
  s.authors  = ['Victor Shepelev']
  s.email    = 'zverok.offline@gmail.com'
  s.homepage = 'https://github.com/zverok/sho'

  s.summary = 'Experimental post-framework view library'
  s.description = <<-EOF
    Post-framework Ruby view library. It is based on Tilt and meant to provide entire
    view layer for a web application (based on any framework or completely frameworkless).
  EOF
  s.licenses = ['MIT']

  s.files = `git ls-files lib LICENSE.txt *.md`.split($RS)
  s.require_paths = ["lib"]

  s.required_ruby_version = '>= 2.1.0'

  s.add_runtime_dependency 'tilt'

  s.add_development_dependency 'yard'
  unless RUBY_ENGINE == 'jruby'
    s.add_development_dependency 'redcarpet'
    s.add_development_dependency 'github-markup'
  end
  s.add_development_dependency 'yard-junk'

  s.add_development_dependency 'rspec', '~> 3.12.0'
  s.add_development_dependency 'rspec-its'
  s.add_development_dependency 'saharspec'
  s.add_development_dependency 'fakefs'
  s.add_development_dependency 'slim'

  s.add_development_dependency 'rubocop', '~> 0.57.2'
  s.add_development_dependency 'rubocop-rspec', '~> 1.27.0'

  s.add_development_dependency 'rake'
  s.add_development_dependency 'rubygems-tasks'
end
