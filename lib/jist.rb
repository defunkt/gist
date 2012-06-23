require 'net/https'
require 'multi_json'

# It just gists.
module Jist

  VERSION = '0.2'

  module_function
  # Upload a gist to https://gist.github.com/
  #
  # @param content  the code you'd like to gist
  #
  # @option :description  the description
  # @option :filename  the filename (default 'a.rb')
  # @option :public  to make it a public gist (default private)
  # @option :username  if you wish to log in to github
  # @option :password  (required if username is set)
  #
  # @return Hash  the decoded JSON response from the server
  # @raise Exception  if something went wrong
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

    if options[:username]
      request.basic_auth(options[:username], options[:password])
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
