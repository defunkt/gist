#!/usr/bin/env ruby

# cat file.txt | gist
# echo hi | gist
# gist 1234 > something.txt

require 'open-uri'
require 'net/http'

module Gist
  extend self

  @@gist_url    = 'http://gist.github.com/%d.txt'
  @@gist_regexp = Regexp.new('http://gist.github.com/(\d+)')

  def read(gist_id)
    open(@@gist_url % gist_id).read
  end

  def write(content)
    url = URI.parse('http://gist.github.com/gists')
    req = Net::HTTP.post_form(url, data(nil, nil, content))

    copy req.body[@@gist_regexp]
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
