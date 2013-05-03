require './lib/gist'
Gem::Specification.new do |s|
  s.name          = 'gist'
  s.version       = Gist::VERSION
  s.summary       = 'Just allows you to upload gists'
  s.description   = 'Provides a single function (Gist.gist) that uploads a gist.'
  s.homepage      = 'https://github.com/ConradIrwin/gist'
  s.email         = 'conrad.irwin@gmail.com'
  s.authors       = ['Conrad Irwin']
  s.license       = 'MIT'
  s.files         = `git ls-files`.split("\n")
  s.require_paths = ["lib"]

  s.executables << 'gist'

  s.add_dependency 'json'
  %w(rake rspec webmock ronn).each do |gem|
    s.add_development_dependency gem
  end
end
