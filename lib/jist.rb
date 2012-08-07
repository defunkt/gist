require 'net/https'
require 'cgi'
require 'json'

# It just gists.
module Jist
  extend self

  VERSION = '0.9.2'

  # Which clipboard commands do we support?
  CLIP_COMMANDS = %w(xclip xsel pbcopy putclip)

  # Exception tag for errors raised while gisting.
  module Error; end

  # Upload a gist to https://gist.github.com
  #
  # @param [String] content  the code you'd like to gist
  # @param [Hash] options  more detailed options
  #
  # @option options [String] :description  the description
  # @option options [String] :filename  ('a.rb') the filename
  # @option options [Boolean] :public  (false) is this gist public
  # @option options [Boolean] :anonymous  (false) is this gist anonymous
  # @option options [String] :access_token  (`File.read("~/.jist")`) The OAuth2 access token.
  # @option options [String] :update  the URL or id of a gist to update
  # @option options [Boolean] :copy  (false) Copy resulting URL to clipboard, if successful.
  #
  # @return [Hash]  the decoded JSON response from the server
  # @raise [Jist::Error]  if something went wrong
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
  # @option options [Boolean] :anonymous  (false) is this gist anonymous
  # @option options [String] :access_token  (`File.read("~/.jist")`) The OAuth2 access token.
  # @option options [String] :update  the URL or id of a gist to update
  # @option options [Boolean] :copy  (false) Copy resulting URL to clipboard, if successful.
  #
  # @return [Hash]  the decoded JSON response from the server
  # @raise [Jist::Error]  if something went wrong
  #
  # @see http://developer.github.com/v3/gists/
  def multi_gist(files, options={})
    json = {}

    json[:description] = options[:description] if options[:description]
    json[:public] = !!options[:public]
    json[:files] = {}

    files.each_pair do |(name, content)|
      raise "Cannot gist empty files" if content.to_s.strip == ""
      json[:files][File.basename(name)] = {:content => content}
    end

    existing_gist = options[:update].to_s.split("/").last
    if options[:anonymous]
      access_token = nil
    else
      access_token = (options[:access_token] || File.read(File.expand_path("~/.jist")) rescue nil)
    end

    url = "/gists"
    url << "/" << CGI.escape(existing_gist) if existing_gist.to_s != ''
    url << "?access_token=" << CGI.escape(access_token) if access_token.to_s != ''

    request = Net::HTTP::Post.new(url)
    request.body = JSON.dump(json)
    request.content_type = 'application/json'

    retried = false

    begin
      response = http(request)
      if Net::HTTPSuccess === response
        on_success(response.body, options)
      else
        raise "Got #{response.class} from gist: #{response.body}"
      end
    rescue => e
      raise if retried
      retried = true
      retry
    end

  rescue => e
    raise e.extend Error
  end

  # Log the user into jist.
  #
  # This method asks the user for a username and password, and tries to obtain
  # and OAuth2 access token, which is then stored in ~/.jist
  #
  # @raise [Jist::Error]  if something went wrong
  # @see http://developer.github.com/v3/oauth/
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
    request.content_type = 'application/json'
    request.basic_auth(username, password)

    response = http(request)

    if Net::HTTPCreated === response
      File.open(File.expand_path("~/.jist"), 'w') do |f|
        f.write JSON.parse(response.body)['token']
      end
      puts "Success! https://github.com/settings/applications"
    else
      raise "Got #{response.class} from gist: #{response.body}"
    end
  rescue => e
    raise e.extend Error
  end

  # Run an HTTP operation against api.github.com
  #
  # @param [Net::HTTPRequest] request
  # @return [Net::HTTPResponse]
  def http(request)
    connection = Net::HTTP.new("api.github.com", 443)
    connection.use_ssl = true
    connection.verify_mode = OpenSSL::SSL::VERIFY_NONE
    connection.open_timeout = 10
    connection.read_timeout = 10
    connection.start do |http|
      http.request request
    end
  rescue Timeout::Error
    raise "Could not connect to https://api.github.com/"
  end

  # Called after an HTTP response to gist to perform post-processing.
  #
  # @param [String] body  the HTTP-200 response
  # @param [Hash] options  any options
  # @option options [Boolean] :copy  copy the URL to the clipboard
  # @return [Hash]  the parsed JSON response from the server
  def on_success(body, options={})
    json = JSON.parse(body)

    if options[:copy]
      Jist.copy(json['html_url'])
    end

    json
  end

  # Copy a string to the clipboard.
  #
  # @param [String] content
  # @return content
  # @raise [RuntimeError] if no clipboard integration could be found
  #
  # This method was heavily inspired by defunkt's Gist#copy,
  # @see https://github.com/defunkt/gist/blob/bca9b29/lib/gist.rb#L178
  def copy(content)

    command = CLIP_COMMANDS.detect do |cmd|
      system("type #{cmd} >/dev/null 2>&1")
    end

    if command
      IO.popen(command, 'r+') { |clip| clip.print content }
    else
      raise "Could not find copy command, tried: #{CLIP_COMMANDS}"
    end
  end
end