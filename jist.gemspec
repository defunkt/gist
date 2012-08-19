require './lib/jist'
Gem::Specification.new do |s|
  s.name          = 'jist'
  s.version       = Jist::VERSION
  s.summary       = 'Just allows you to upload gists'
  s.description   = 'Provides a single function (Jist.gist) that uploads a gist.'
  s.homepage      = 'https://github.com/ConradIrwin/jist'
  s.email         = 'conrad.irwin@gmail.com'
  s.authors       = ['Conrad Irwin']
  s.license       = 'MIT'
  s.files         = Dir["lib/**/*.rb"]
  s.files        += %w( README.md LICENSE.MIT )
  s.require_paths = ["lib"]

  s.executables << 'jist'

  s.add_dependency 'json'
  %w(rake rspec).each do |gem|
    s.add_development_dependency gem
  end
end
