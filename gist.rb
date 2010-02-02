#!/usr/bin/env ruby

# = USAGE
#  gist < file.txt
#  echo secret | gist -p  # or --private
#  gist 1234 > something.txt
#  gist http://gist.github.com/1234 > something.txt # it also works with full urls
#  gist http://pastebin.com/abcd1234 > something.txt # pastebin.com, sprunge.us and fpaste.org full urls are supported
#  gist http://sprunge.us/abcd | gist # updating stuff to gist.github.com
#
# = INSTALL
#  curl http://github.com/dudektria/gist/raw/master/gist.rb > gist &&
#  chmod +x gist &&
#  mv gist /usr/local/bin/gist # or maybe sudo mv gist /usr/local/bin/gist

require 'open-uri'
require 'net/http'

module Gist
	extend self
	GIST_URL = 'http://gist.github.com/%s.txt'
	GIST_URL_REGEXP = /https?:\/\/gist.github.com\/\d+$/
	SPRUNGE_URL_REGEXP = /http:\/\/sprunge.us\/\w+\??\w+$/
	PASTEBIN_URL_REGEXP = /http:\/\/.*pastebin.com\/.+$/
	FPASTE_URL_REGEXP = /http:\/\/fpaste.org\/.+\/?$/

	@proxy = ENV['http_proxy'] ? URI(ENV['http_proxy']) : nil

	def read(id)
		return help if id.nil? || id[/^\-h|help$/]
		return open(GIST_URL % id).read unless id.to_i.zero?
		return open(id + '.txt').read if id[GIST_URL_REGEXP]
		return open(id.gsub(/http:\/\/(.*)pastebin.com\/(.+)$/, 'http://\1pastebin.com/pastebin.php?dl=\2')).read if id[PASTEBIN_URL_REGEXP]
		return open(id + '/raw').read if id[FPASTE_URL_REGEXP]
		return open(id.gsub(/\?\w+$/, "")).read if id[SPRUNGE_URL_REGEXP]
	end

	def write(content, private_gist)
		url = URI.parse('http://gist.github.com/gists')
		if @proxy
			proxy = Net::HTTP::Proxy(@proxy.host, @proxy.port)
			req = proxy.post_form(url, data(nil, nil, content, private_gist))
		else
			req = Net::HTTP.post_form(url, data(nil, nil, content, private_gist))
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
	puts Gist.write($stdin.read, %w( -p --private ).include?(ARGV.first))
end
