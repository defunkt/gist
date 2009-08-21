#!/usr/bin/env ruby

# = USAGE
#  gist < file.txt
#  echo secret | gist -p  # or --private
#  gist 1234 > something.txt
#
# = INSTALL
#  curl http://github.com/evaryont/gist/tree/master%2Fgist.rb?raw=true > gist &&
#  chmod 755 gist &&
#  sudo mv gist /usr/local/bin/gist

require 'open-uri'
require 'net/http'

class Gist
	class << self
		GIST_URL = 'http://gist.github.com/%s.txt'

		@proxy = ENV['http_proxy'] ? URI(ENV['http_proxy']) : nil

		def read(gist_id)
			return help if gist_id.nil? || gist_id[/^\-h|help$/]
			return open(GIST_URL % gist_id).read unless gist_id.to_i.zero?
			return open(gist_id + '.txt').read if gist_id[/https?:\/\/gist.github.com\/\d+$/]
		end

		def write(content, private_gist)
			url = URI.parse('http://gist.github.com/gists')
			if @proxy
				req = Net::HTTP::Proxy(@proxy.host, @proxy.port).post_form(url, data(nil, nil, content, private_gist))
			else
				req = Net::HTTP.post_form(url, data(nil, nil, content, private_gist))
			end
			copy req['Location']
		end

		def help
			require 'rdoc/usage'
			RDoc.usage('USAGE') # w/o parameters it does both INSTALL and USAGE
		end

		private
		def copy(content)
			case RUBY_PLATFORM
			when /darwin/
				return content if `which pbcopy`.strip == ''
				IO.popen('pbcopy', 'r+') { |clip| clip.print content }
				`open #{content}`
			when /linux/
				return content if `which xclip  2> /dev/null`.strip == ''
				IO.popen('xclip', 'r+') { |clip| clip.print content }
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
			}.merge(private_gist ? { 'private' => 'on' } : {}).merge(auth)
		end

		def auth
			user  = `git config --global github.user`.strip
			token = `git config --global github.token`.strip

			user.empty? ? {} : { :login => user, :token => token }
		end
	end
end

if $stdin.tty?
	puts Gist.read(ARGV.first)
else
	puts Gist.write($stdin.read, %w[-p --private].include?(ARGV.first))
end
