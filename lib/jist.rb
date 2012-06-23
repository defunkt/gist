require 'net/https'
require 'cgi'
require 'multi_json'

# It just gists.
module Jist

  VERSION = '0.2'

  module_function
  # Upload a gist to https://gist.github.com
  #
  # @param [String] content  the code you'd like to gist
  # @param [Hash] options  more detailed options
  #
  # @option options [String] :description  the description
  # @option options [String] :filename  ('a.rb') the filename
  # @option options [Boolean] :public  (false) is this gist public
  # @option options [String] :access_token  (`File.read("~/.jist")`) The OAuth2 access token.
  #
  # @return [Hash]  the decoded JSON response from the server
  # @raise [Exception]  if something went wrong
  #
  # @see http://developer.github.com/v3/gists/
  def gist(content, options={})
    json = {}

    json[:description] = options[:description] if options[:description]
    json[:public] = !!options[:public]

    filename = options[:filename] || 'a.rb'

    json[:files] = {
      filename => {
        :content => content
      }
    }

    access_token = (options[:access_token] || File.read(File.expand_path("~/.jist")) rescue nil)

    url = "/gists"
    url << "?access_token=" << CGI.escape(access_token) if access_token.to_s != ''

    request = Net::HTTP::Post.new(url)
    request.body = MultiJson.encode(json)

    response = http(request)

    if Net::HTTPCreated === response
      MultiJson.decode(response.body)
    else
      raise RuntimeError.new "Got #{response.class} from gist: #{response.body}"
    end
  end

  # Log the user into jist.
  #
  # This method asks the user for a username and password, and tries to obtain
  # and OAuth2 access token, which is then stored in ~/.jist
  def login!
    puts "Obtaining OAuth2 access_token from github."
    print "Github username:"
    username = gets.strip
    print "Github password:"
    password = gets.strip

    request = Net::HTTP::Post.new("/authorizations")
    request.body = MultiJson.encode({
      :scopes => [:gist],
      :note => "The jist gem",
      :note_url => "https://github.com/ConradIrwin/jist"
    })
    request.basic_auth(username, password)

    response = http(request)

    if Net::HTTPCreated === response
      File.open(File.expand_path("~/.jist"), 'w') do |f|
        f.write MultiJson.decode(response.body)['token']
      end
      puts "Success! https://github.com/settings/applications"
    else
      raise RuntimeError.new "Got #{response.class} from gist: #{response.body}"
    end
  end

  private

  module_function
  # Run an HTTP operation against api.github.com
  #
  # @param [Net::HTTP::Request]
  # @return [Net::HTTP::Response]
  def http(request)
    connection = Net::HTTP.new("api.github.com", 443)
    connection.use_ssl = true
    connection.verify_mode = OpenSSL::SSL::VERIFY_NONE
    connection.read_timeout = 10
    connection.start do |http|
      http.request request
    end
  end
end
