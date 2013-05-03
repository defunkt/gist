# encoding: utf-8
#
task :default => :test

desc 'run the tests' # that's non-DRY
task :test do
  sh 'rspec spec'
end

task :clipfailtest do
  sh 'PATH=/ /usr/bin/ruby -Ilib -S bin/gist -ac < lib/gist.rb'
end

task :man do
  File.write "README.md.ron", File.read("README.md").gsub(?‌, "* ")
  sh 'ronn --roff --manual="Gist manual" README.md.ron'
  rm 'README.md.ron'
  sh 'man ./README.1'
end
