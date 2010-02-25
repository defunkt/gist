#!/usr/bin/env ruby

# = USAGE
#  gist < file.txt
#  echo secret | gist -p  # or --private
#  gist 1234 > something.txt
#
# = INSTALL
#  curl http://github.com/dudektria/gist/raw/master/gist.rb > gist &&
#  chmod 755 gist &&
#  mv gist /usr/local/bin/gist

require 'open-uri'
require 'net/http'

module Gist
  extend self
  GIST_URL = 'http://gist.github.com/%s.txt'
  GIST_URL_REGEXP = /https?:\/\/gist.github.com\/\d+$/

  @proxy = ENV['http_proxy'] ? URI(ENV['http_proxy']) : nil

  def read(gist_id)
    return help if gist_id.nil? || gist_id[/^\-h|help$/]
    return open(GIST_URL % gist_id).read unless gist_id.to_i.zero?
    return open(gist_id + '.txt').read if gist_id[GIST_URL_REGEXP]
  end

  def write(content, private_gist, gist_extension=nil)
    url = URI.parse('http://gist.github.com/gists')
    if @proxy
      proxy = Net::HTTP::Proxy(@proxy.host, @proxy.port)
      req = proxy.post_form(url, data(nil, gist_extension, content, private_gist))
    else
      req = Net::HTTP.post_form(url, data(nil, gist_extension, content, private_gist))
    end
    copy req['Location']
  end

  def help
    help = File.read(__FILE__).scan(/# = USAGE(.+?)# = INSTALL/m)[0][0]
    "usage: \n" + help.strip.gsub(/^# ?/, '')
  end

private
  def copy(content)
    case RUBY_PLATFORM
    when /darwin/
      return content unless system("which pbcopy")
      IO.popen('pbcopy', 'r+') { |clip| clip.print content }
      `open #{content}`
    when /linux/
      return content unless system("which xclip  2> /dev/null")
      IO.popen('xclip -sel clip', 'r+') { |clip| clip.print content }
    when /i386-cygwin/
      return content if `which putclip`.strip == ''
      IO.popen('putclip', 'r+') { |clip| clip.print content }
    end

    content
  end

  def data(name, ext, content, private_gist)
    return {
      'file_ext[gistfile1]'      => ext,
      'file_name[gistfile1]'     => name,
      'file_contents[gistfile1]' => content
    }.merge(private_gist ? { 'action_button' => 'private' } : {}).merge(auth)
  end

  def auth
    user  = `git config --global github.user`.strip
    token = `git config --global github.token`.strip

    user.empty? ? {} : { :login => user, :token => token }
  end
end

if $stdin.tty?
  puts Gist.read(ARGV.first)
else
  require 'optparse'
  private_gist = false
  gist_extension = nil
  opts = OptionParser.new do |opts|
    opts.banner = "Usage: gist [options]" #[-p|--private] [-t|--type FILE_TYPE_EXTENSION]"
    opts.on('-p', '--private', 'Make the gist private') do
      private_gist = true
    end

    opts.on('-t', '--type [EXTENSION]', 'set the syntax highlighting of the gist by file extension') do |extension|
      gist_extension = '.' + extension
    end

    opts.on('-h', '--help', 'Display this screen') do
      puts opts
      exit
    end
  end

  begin
    opts.parse!(ARGV)
    puts Gist.write($stdin.read, private_gist, gist_extension)
  rescue
    puts opts
  end
end
