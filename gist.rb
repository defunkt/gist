#!/usr/bin/env ruby

=begin

INSTALL:

  curl http://github.com/defunkt/gist/raw/master/gist.rb > gist &&
  chmod 755 gist &&
  sudo mv gist /usr/local/bin/gist

USE:

  gist < file.txt
  echo secret | gist -p # or --private
  gist 1234 > something.txt

=end

require 'open-uri'
require 'net/http'

module Gist
  extend self

  @@gist_url = 'http://gist.github.com/%s.txt'

  def read(gist_id)
    return help if gist_id == '-h' || gist_id.nil? || gist_id[/help/]
    open(@@gist_url % gist_id).read
  end

  def write(content, private_gist)
    url = URI.parse('http://gist.github.com/gists')
    req = Net::HTTP.post_form(url, data(nil, nil, content, private_gist))
    copy req['Location']
  end

  def help
    "USE:\n  " + File.read(__FILE__).match(/USE:(.+?)=end/m)[1].strip
  end

private
  def copy(content)
    case RUBY_PLATFORM
    when /darwin/
      return content if `which pbcopy`.strip == ''
      IO.popen('pbcopy', 'r+') { |clip| clip.puts content }
    when /linux/
      return content if `which xclip`.strip == ''
      IO.popen('xclip', 'r+') { |clip| clip.puts content }
    end

    content
  end

  def data(name, ext, content, private_gist)
    return {
      'file_ext[gistfile1]'      => ext,
      'file_name[gistfile1]'     => name,
      'file_contents[gistfile1]' => content
    }.merge(private_gist ? { 'private' => 'on' } : {}).merge(auth)
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
  puts Gist.write($stdin.read, %w[-p --private].include?(ARGV.first))
end
