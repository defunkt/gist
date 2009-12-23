#!/usr/bin/env ruby

# = USAGE
#  gist file.php file2.rb
#  gist < file.txt
#  echo secret | gist -p  # or --private
#  gist 1234 > something.txt
#
# = INSTALL
#  curl -s http://github.com/evaryont/gist/raw/master/gist.rb > gist &&
#  chmod 755 gist &&
#  mv gist /usr/local/bin/gist

require 'open-uri'
require 'net/http'

module Gist
  extend self

  TEMP_FILE = '.tmp_gists'
  @@gist_url = 'http://gist.github.com/%s.txt'
  @@files = []

  def read(gist_id)
    open(@@gist_url % gist_id).read
  end
  
  def add_file(name, content)
    load_files
    @@files << {:name => name, :content => content}
    puts "#{name} added."
    save_files
  end

  def list_files
     load_files
     ret = []
     @@files.each do|a|
        ret << a[:name]
     end

     return ret
  end
  
  def send(private_gist)
    load_files
    url = URI.parse('http://gist.github.com/gists')
    req = Net::HTTP.post_form(url, data(private_gist))
    url = copy req['Location']
    puts "Created gist at #{url}"
    clear
  end
  
  def clear
    @@files = []
    path = File.join(File.dirname(__FILE__), TEMP_FILE)
    File.delete(path)
  end

  def help
    help = File.read(__FILE__).scan(/# = USAGE(.+?)# = INSTALL/m)[0][0]
    "usage: \n" + help.strip.gsub(/^# ?/, '')
  end
  
  def write(content)
    gistname = Time.now.to_i
    gistname = "#{gistname}.txt"
    add_file(gistname, content)
  end
  
private
  def load_files
    path = File.join(File.dirname(__FILE__), TEMP_FILE)
    save_files unless File.exists?(path)
    @@files = Marshal.load(File.read(path))
    @@files ||= []
  end
  
  def save_files
    path = File.join(File.dirname(__FILE__), TEMP_FILE)
    File.open(path, 'w') {|f| f.puts Marshal.dump(@@files) }
  end
  
  def copy(content)
    case RUBY_PLATFORM
    when /darwin/
      return content unless system("which pbcopy")
      IO.popen('pbcopy', 'r+') { |clip| clip.print content }
      `open #{content}`
    when /linux/
      return content unless system("which xclip  2> /dev/null")
      IO.popen('xclip', 'r+') { |clip| clip.print content }
    when /i386-cygwin/
      return content if `which putclip`.strip == ''
      IO.popen('putclip', 'r+') { |clip| clip.print content }
    end

    content
  end

  def data(private_gist)
    params = {}
    @@files.each_with_index do |file, i|
      params.merge!({
        "file_ext[gistfile#{i+1}]"      => nil,
        "file_name[gistfile#{i+1}]"     => file[:name],
        "file_contents[gistfile#{i+1}]" => file[:content]
      })
    end
    params.merge(private_gist ? { 'private' => 'on' } : {}).merge(auth)
  end

  def auth
    user  = `git config --global github.user`.strip
    token = `git config --global github.token`.strip

    user.empty? ? {} : { :login => user, :token => token }
  end
end

if ARGV.count > 0
   private_gist = false
   ARGV.each do|file_name|
      if File.exist?(file_name)
         Gist.add_file(file_name, File.new(file_name).read())
      elsif %w( -p --private ).include?(file_name)
         private_gist = true
      elsif %w( -h --help).include?(file_name)
         puts Gist.help
      elsif file_name.to_i > 0
         Gist.read(file_name)
      else
         puts "#{file_name} does not exist"
      end
   end

   if private_gist and ARGV.count == 1
      Gist.write($stdin.read)
   end
else
  Gist.write($stdin.read)
end

if Gist.list_files.count > 0
  Gist.send(private_gist)
end
