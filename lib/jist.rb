require 'net/https'
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
  # @option options [String] :username  if you wish to log in to github
  # @option options [String] :password  required if username is set
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

    connection = Net::HTTP.new("api.github.com", 443)
    connection.use_ssl = true
    connection.verify_mode = OpenSSL::SSL::VERIFY_NONE
    connection.read_timeout = 10

    request = Net::HTTP::Post.new("/gists")
    request.body = MultiJson.encode(json)

    username = (options[:username] || `git config jist.username 2>/dev/null`.strip).to_s
    password = (options[:password] || `git config jist.password 2>/dev/null`.strip).to_s
    if username != ""

      request.basic_auth(username, password)
    end
    response = connection.start do |http|
                 http.request(request)
               end

    if Net::HTTPCreated === response
      MultiJson.decode(response.body)
    else
      raise RuntimeError.new "Got #{response.class} from gist: #{response.body}"
    end
  end
end
