#!/usr/bin/env ruby

=begin

INSTALL:

  curl http://github.com/defunkt/gist/tree/master%2Fgist.rb?raw=true > gist &&
  chmod 755 gist &&
  sudo mv gist /usr/local/bin/gist

USE:

  cat file.txt | gist
  echo hi | gist
  gist 1234 > something.txt

=end

require 'open-uri'
require 'net/http'

module Gist
  extend self

  @@gist_url    = 'http://gist.github.com/%d.txt'
  @@gist_regexp = Regexp.new('http://gist.github.com/(\d+)')

  def read(gist_id)
    return help if gist_id == '-h' || gist_id.nil? || gist_id[/help/]
    open(@@gist_url % gist_id).read
  end

  def write(content)
    url = URI.parse('http://gist.github.com/gists')
    req = Net::HTTP.post_form(url, data(nil, nil, content))

    copy req.body[@@gist_regexp]
  end

  def help
    "USE:\n  " + File.read(__FILE__).match(/USE:(.+?)=end/m)[1].strip
  end

private
  def copy(content)
    return content if `which pbcopy`.strip == ''

    IO.popen('pbcopy', 'r+') do |clipboard|
      clipboard.puts content
    end

    content
  end

  def data(name, ext, content)
    return {
      'file_ext[gistfile1]'      => ext,
      'file_name[gistfile1]'     => name,
      'file_contents[gistfile1]' => content
    }
  end
end

if $stdin.tty?
  puts Gist.read(ARGV.first)
else
  puts Gist.write($stdin.read)
end
