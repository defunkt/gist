require 'net/https'
require 'cgi'
require 'json'

# It just gists.
module Jist

  VERSION = '0.7'

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
  # @option options [String] :update  the URL or id of a gist to update
  #
  # @return [Hash]  the decoded JSON response from the server
  # @raise [Exception]  if something went wrong
  #
  # @see http://developer.github.com/v3/gists/
  def gist(content, options = {})
    filename = options[:filename] || "a.rb"
    multi_gist({filename => content}, options)
  end

  # Upload a gist to https://gist.github.com
  #
  # @param [Hash] files  the code you'd like to gist: filename => content
  # @param [Hash] options  more detailed options
  #
  # @option options [String] :description  the description
  # @option options [Boolean] :public  (false) is this gist public
  # @option options [String] :access_token  (`File.read("~/.jist")`) The OAuth2 access token.
  # @option options [String] :update  the URL or id of a gist to update
  #
  # @return [Hash]  the decoded JSON response from the server
  # @raise [Exception]  if something went wrong
  #
  # @see http://developer.github.com/v3/gists/
  def multi_gist(files, options={})
    json = {}

    json[:description] = options[:description] if options[:description]
    json[:public] = !!options[:public]
    json[:files] = {}

    files.each_pair do |(name, content)|
      json[:files][File.basename(name)] = {:content => content}
    end

    existing_gist = options[:update].to_s.split("/").last
    access_token = (options[:access_token] || File.read(File.expand_path("~/.jist")) rescue nil)

    url = "/gists"
    url << "/" << CGI.escape(existing_gist) if existing_gist.to_s != ''
    url << "?access_token=" << CGI.escape(access_token) if access_token.to_s != ''

    request = Net::HTTP::Post.new(url)
    request.body = JSON.dump(json)

    response = http(request)

    if Net::HTTPSuccess === response
      JSON.parse(response.body)
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
    print "Github username: "
    username = $stdin.gets.strip
    print "Github password: "
    password = begin
      `stty -echo` rescue nil
      $stdin.gets.strip
    ensure
      `stty echo` rescue nil
    end
    puts ""

    request = Net::HTTP::Post.new("/authorizations")
    request.body = JSON.dump({
      :scopes => [:gist],
      :note => "The jist gem",
      :note_url => "https://github.com/ConradIrwin/jist"
    })
    request.basic_auth(username, password)

    response = http(request)

    if Net::HTTPCreated === response
      File.open(File.expand_path("~/.jist"), 'w') do |f|
        f.write JSON.parse(response.body)['token']
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
  # @param [Net::HTTP::Request] request
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
