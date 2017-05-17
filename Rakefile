task :default => :test

desc 'run the tests' # that's non-DRY
task :test do
  sh 'rspec spec'
end

task :clipfailtest do
  sh 'PATH=/ /usr/bin/ruby -Ilib -S bin/gist -ac < lib/gist.rb'
end

task :man do
  mkdir_p "build"
  File.write "README.md.ron", File.read("README.md").gsub("\u200c", "* ")
  sh 'ronn --roff --manual="Gist manual" README.md.ron'
  rm 'README.md.ron'
  mv 'README.1', 'build/gist.1'
end

task :standalone do
  mkdir_p "build"
  File.open("build/gist", "w") do |f|
    f.puts "#!/usr/bin/env ruby"
    f.puts "# This is generated from https://github.com/defunkt/gist using 'rake standalone'"
    f.puts "# any changes will be overwritten."
    f.puts File.read("lib/gist.rb").split("require 'json'\n").join(File.read("vendor/json.rb"))

    f.puts File.read("bin/gist").gsub(/^require.*gist.*\n/, '');
  end
  sh 'chmod +x build/gist'
end

task :build => [:man, :standalone]

desc "Install standalone script and man pages"
task :install => :standalone do
  prefix = ENV['PREFIX'] || ENV['prefix'] || '/usr/local'

  FileUtils.mkdir_p "#{prefix}/bin"
  FileUtils.cp "build/gist", "#{prefix}/bin"

  FileUtils.mkdir_p "#{prefix}/share/man/man1"
  FileUtils.cp "build/gist.1", "#{prefix}/share/man/man1"
end
