#!/usr/bin/env ruby
=begin

INSTALL:

  curl http://github.com/elim/gist/tree/master%2Fgist.rb?raw=true > gist &&
  chmod 755 gist &&
  sudo mv gist /usr/local/bin/gist

USE:

  write:
    % cat file.txt | gist

  read:
    % gist 1234

=end

require 'open-uri'
require 'net/http'

class Gist
  GIST_URL = 'http://gist.github.com/%s.txt'
  attr_accessor(:account_store, :private)

  def initialize(opts = {})
    self.account_store = opts[:account_store] || :gitconfig
    self.private       = opts[:private]
  end

  def read(gist_id)
    open(GIST_URL % gist_id).read
  end

  def write(content)
    url = URI.parse('http://gist.github.com/gists')
    req = Net::HTTP.post_form(url, data(nil, nil, content, @private))
    req['Location']
  end

  private
  def data(name, ext, content, private_gist)
    return {
      'file_ext[gistfile1]'      => ext,
      'file_name[gistfile1]'     => name,
      'file_contents[gistfile1]' => content
    }.merge(private_gist ? { 'private' => 'on' } : {}).merge(auth)
  end

  def auth
    case @account_store
    when :gitconfig;  read_gitconfig
    when :pit;        read_pit
    end || {}
  end

  def read_gitconfig
    user  = %x(git config --global github.user).strip
    token = %x(git config --global github.token).strip

    unless (user.empty? || token.empty?)
      { :login => user, :token => token }
    end
  end

  def read_pit
    require 'rubygems'
    require 'pit'

    config = Pit.get("github.com", :require => {
        "user"   => "your username in github",
        "token"  => "your token in github",
      })

    config['user'] && config['token'] &&
      { :login => config['user'], :token => config['token'] }
  end
end

if $0 == __FILE__
  def executable_find(progname)
    prog = %x(which #{progname}).strip
    prog unless prog.empty?
  end

  def set_pasteboard(str)
    pb_prog =
      case RUBY_PLATFORM
      when /darwin/
        executable_find 'pbcopy'
      when /linux/
        executable_find 'xclip'
      when /cygwin/
        executable_find 'putclip'
      end

    if pb_prog
      IO.popen(pb_prog, 'r+') { |clip| clip.puts str }
    end
  end

  require 'optparse'
  opts = {}

  OptionParser.new do |parser|
    parser.instance_eval do
      self.banner =
        "USE:\n  " + File.read(__FILE__).match(/USE:(.+?)=end/m)[1].lstrip

      on('-p', '--private', 'private post.') do
        opts[:private] = true
      end

      on('-a', '--anonymous', 'anonymous post.') do
        opts[:account_store] = :none
      end

      on('-P', '--pit', 'using pit.') do
        opts[:account_store]  = :pit
      end

      parse(ARGV)
    end
  end

  gist = Gist.new(opts)

  if $stdin.tty?
    puts gist.read(ARGV.first)
  else
    url = gist.write($stdin.read)
    set_pasteboard(url)
    puts url
  end
end
