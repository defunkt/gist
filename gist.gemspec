Gem::Specification.new do |s|
  s.name              = "gist"
  s.version           = "1.0.1"
  s.date              = "2010-02-28"
  s.summary           = "Creates Gists from STDIN or files."
  s.homepage          = "http://github.com/defunkt/gist"
  s.email             = "chris@ozmm.org"
  s.authors           = [ "Chris Wanstrath" ]
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
