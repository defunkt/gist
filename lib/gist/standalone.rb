module Gist
  module Standalone
    extend self

    PREAMBLE = <<-preamble
#!/usr/bin/env ruby
#
# This file, gist, is generated code.
# Please DO NOT EDIT or send patches for it.
#
# Please take a look at the source from
# http://github.com/defunkt/gist
# and submit patches against the individual files
# that build gist.
#

preamble

    POSTAMBLE = "Gist.execute(*ARGV)\n"
    __DIR__   = File.dirname(__FILE__)
    MANPAGE   = "__END__\n#{File.read(__DIR__ + '/../../man/gist.1')}"
    CACERT    = "__CACERT__\n#{File.read(__DIR__ + '/cacert.pem')}"

    def save(filename, path = '.')
      target = File.join(File.expand_path(path), filename)
      File.open(target, 'w') do |f|
        f.puts build
        f.chmod 0755
      end
    end

    def build
      root = File.dirname(__FILE__)

      puts "Building standalone gist script, starting with preamble."
      standalone = ''
      standalone << PREAMBLE

      Dir["#{root}/../{*,.}/*.rb"].each do |file|
        puts "Adding #{File.expand_path(file)}"
        # skip standalone.rb
        next if File.expand_path(file) == File.expand_path(__FILE__)

        File.readlines(file).each do |line|
          next if line =~ /^\s*#/
          standalone << line
        end
      end

      puts "Adding postamble."
      standalone << POSTAMBLE
      puts "Embedding man page."
      standalone << MANPAGE
      puts "Embedding CA certificates."
      standalone << CACERT
      standalone
    end
  end
end
