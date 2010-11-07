# -*- encoding: utf-8 -*-
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'gist'

Gem::Specification.new do |s|
  s.name              = "gist"
  s.version           = Gist::Version.to_s
  s.date              = Time.now.strftime('%Y-%m-%d')
  s.summary           = "Creates Gists from STDIN or files."
  s.homepage          = "http://github.com/defunkt/gist"
  s.email             = "andre@arko.net"
  s.authors           = [ "Chris Wanstrath", "André Arko" ]
  s.has_rdoc          = false

  s.files             = %w( README.markdown Rakefile LICENSE )
  s.files            += Dir.glob("lib/**/*")
  s.files            += Dir.glob("bin/**/*")
  s.files            += Dir.glob("man/**/*")
  s.files            += Dir.glob("public/**/*")

  s.executables       = %w( gist )
  s.description       = <<desc
  Creates Gists (pastes) on gist.github.com from standard input or
  arbitrary files. Can link to your GitHub account, create private gists,
  and enable syntax highlighting.
desc
end
