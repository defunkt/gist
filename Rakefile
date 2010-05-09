begin
  require "mg"
  MG.new("gist.gemspec")
rescue LoadError
  nil
end

desc "Build standalone script and manpages"
task :build => [ :standalone, :build_man ]

desc "Build standalone script"
task :standalone => :load_gist do
  require 'gist/standalone'
  Gist::Standalone.save('gist')
end

desc "Build gist manual"
task :build_man do
  sh "ronn -br5 --organization=GITHUB --manual='Gist Manual' man/*.ron"
end

desc "Show gist manual"
task :man => :build_man do
  exec "man man/gist.1"
end

task :load_gist do
  $LOAD_PATH.unshift 'lib'
  require 'gist'
end

Rake::TaskManager.class_eval do
  def remove_task(task_name)
    @tasks.delete(task_name.to_s)
  end
end

# Remove mg's install task
Rake.application.remove_task(:install)

desc "Install standalone script and man pages"
task :install => :standalone do
  prefix = ENV['PREFIX'] || ENV['prefix'] || '/usr/local'

  FileUtils.mkdir_p "#{prefix}/bin"
  FileUtils.cp "gist", "#{prefix}/bin"

  FileUtils.mkdir_p "#{prefix}/share/man/man1"
  FileUtils.cp "man/gist.1", "#{prefix}/share/man/man1"
end

