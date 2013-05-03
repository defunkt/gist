task :default => :test

desc 'run the tests' # that's non-DRY
task :test do
  sh 'rspec spec'
end

task :clipfailtest do
  sh 'PATH=/ /usr/bin/ruby -Ilib -S bin/gist -ac < lib/gist.rb'
end
