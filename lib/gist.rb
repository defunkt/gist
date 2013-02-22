require 'open-uri'
require 'net/https'
require 'optparse'
require 'ostruct'

require 'base64'

require 'highline/import'

require 'gist/json'    unless defined?(JSON)
require 'gist/manpage' unless defined?(Gist::Manpage)
require 'gist/version' unless defined?(Gist::Version)

# You can use this class from other scripts with the greatest of
# ease.
#
#   >> Gist.read(gist_id)
#   Returns the body of gist_id as a string.
#
#   >> Gist.write(content)
#   Creates a gist from the string `content`. Returns the URL of the
#   new gist.
#
#   >> Gist.copy(string)
#   Copies string to the clipboard.
#
#   >> Gist.browse(url)
#   Opens URL in your default browser.
module Gist
  extend self

  DEFAULT_GITHUB_API_BASE_URL   = 'https://api.github.com'
  DEFAULT_CREDENTIAL_CONFIG_KEY = 'github'

  if ENV['HTTPS_PROXY']
    PROXY = URI(ENV['HTTPS_PROXY'])
  elsif ENV['HTTP_PROXY']
    PROXY = URI(ENV['HTTP_PROXY'])
  else
    PROXY = nil
  end
  PROXY_HOST = PROXY ? PROXY.host : nil
  PROXY_PORT = PROXY ? PROXY.port : nil

  # access for options
  # returns OpenStruct object containing global options
  def options()
    @options ||= OpenStruct.new({
      :debug             => false,
      :gist_api_url      => nil,
      :gist_extension    => defaults["extension"],
      :private_gist      => defaults["private"],
      :browse_enabled    => defaults["browse"],
      :embed_enabled     => nil,
      :description       => nil,
      :setup_credentials => false
    })
  end

  # creates the OptionParser object
  # returns OptionParser
  def option_parser()
    @option_parser ||= OptionParser.new do |opts|
      opts.banner = "Usage: gist [options] [filename or stdin] [filename] ...\n" +
        "Filename '-' forces gist to read from stdin."

      opts.separator ''
      opts.separator "Posting Options:"

      opts.on('-a', '--api-url URL', 'API URL to connect to') { |url| options.gist_api_url = url }
      opts.on('-p', '--[no-]private', 'Make the gist private') { |priv| options.private_gist = priv }
      t_desc = 'Set syntax highlighting of the Gist by file extension'
      opts.on('-t', '--type [EXTENSION]', t_desc) { |extension| options.gist_extension = '.' + extension }
      opts.on('-d','--description DESCRIPTION', 'Set description of the new gist') { |d| options.description = d }
      opts.on('-o','--[no-]open', 'Open gist in browser') { |o| options.browse_enabled = o }
      opts.on('-e', '--embed', 'Print javascript embed code') { |o| options.embed_enabled = o }

      opts.separator ''
      opts.separator "Configuration Options:"

      opts.on('-s', '--setup-credentials', 'Setup API Provider credentials') do
        raise OptionParser::InvalidOption, 'Cannot setup credentials without a TTY' unless $stdin.tty?
        options.setup_credentials = true
      end
      opts.on('', '--add-provider URL', 'Adds an API Provider URL') do |url|
        raise OptionParser::InvalidOption, 'Cannot add a provider without a TTY' unless $stdin.tty?
        raise OptionParser::InvalidOption, "Bad Provider API URL" unless URI::DEFAULT_PARSER.regexp[:ABS_URI] =~ url
        add_provider_url(url)
        exit 0
      end
      opts.on('', '--set-default-provider [URL]', 'Sets the default API Provider URL') do |url|
        raise OptionParser::InvalidOption, 'Cannot set default provider without a TTY' unless $stdin.tty?
        set_default_provider(url)
        exit 0
      end

      opts.separator ''
      opts.separator "General Options:"
      opts.on('-D', '--debug', 'Debug enabled') { options.debug = true }
      opts.on('-m', '--man', 'Print manual') { Gist::Manpage.display("gist") }
      opts.on('-v', '--version', 'Print version') { $stderr.puts Gist::Version; exit 0; }
      opts.on('-h', '--help', 'Display this screen')  { $stderr.puts opts; exit 0 }
    end
  end

  # Prints the usage and exits
  def usage()
    $stderr.puts option_parser
    exit 1
  end

  # Parses command line arguments and does what needs to be done.
  def execute(*args)
    set_config('gist.api-url', DEFAULT_GITHUB_API_BASE_URL) if !config('gist.api-url')
    set_config('gist.default-url', DEFAULT_GITHUB_API_BASE_URL) if !config('gist.default-url')

    begin
      option_parser.parse!(args)

      if $stdin.tty? && options.setup_credentials
        api_url # make sure API URL selection happens, if need be
        setup_credentials
        exit 1
      end

      if $stdin.tty? && args[0] != '-'
        # Run without stdin.
        usage if args.empty?

        files = args.inject([]) { |list, file|
          # Check if arg is a file. If so, grab the content.
          abort "Can't find #{file}" unless File.exists?(file)

          list.push({
            :input     => File.read(file),
            :filename  => file,
            :extension => file.include?('.') ? File.extname(file) : options.gist_extension
          })
        }
      else
        # Read from standard input.
        input = $stdin.read
        files = [{:input => input, :extension => options.gist_extension}]
      end

      url = write(files, options.private_gist, options.description)
      browse(url) if options.browse_enabled
      $stdout.puts copy(to_embed(url)) if options.embed_enabled
      $stdout.puts copy(url) unless options.embed_enabled
    rescue Interrupt
      $stderr.puts "\nQuit."
      exit 1
    rescue OptionParser::InvalidOption => e
      warn e; puts
      usage
      exit 1
    rescue StandardError => e
       options.debug ? warn(e) : raise(e)
    end
  end

  # Create a javascript embed code
  def to_embed(url)
    %Q[<script src="#{url}.js"></script>]
  end

  def request(url)
    raise ArgumentError, "Missing required block" unless block_given?

    url = URI.parse(url) unless url.kind_of? URI

    if PROXY_HOST
      proxy = Net::HTTP::Proxy(PROXY_HOST, PROXY_PORT)
      http  = proxy.new(url.host, url.port)
    else
      http = Net::HTTP.new(url.host, url.port)
    end

    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_PEER

    if url.host == URI.parse(DEFAULT_GITHUB_API_BASE_URL).host
      http.ca_file = ca_cert
    end

    request = yield url
    authenticate(request) if request['Authorization'].nil?

    http.start{|h| h.request(request) }
  end

  # Create a gist on gist.github.com
  def write(files, private_gist = false, description = nil)
    response = request(create_url) do |url|
      Net::HTTP::Post.new(url.path).tap {|req|
        req.body = JSON.generate(data(files, private_gist, description))
      }
    end

    case response
      when Net::HTTPUnauthorized
        $stderr.puts "Invalid credentials connecting to #{api_url}"
        false
      when Net::HTTPCreated, Net::HTTPOK
        JSON.parse(response.body)['html_url']
      else
        raise StandardError, "#{response.code} #{response.message}"
    end
  end

  # Given a gist id, returns its content.
  def read(gist_id)
    response = request(gist_url % gist_id) { |url| Net::HTTP::Get.new(url.path) }
    case response
      when Net::HTTPOK
        data = JSON.parse(response.body)
        data['files'].map{|name, content| content['content'] }.join("\n\n")
      else
        warn "#{response.code}: #{response.message}"
        nil
    end
  end

  # Given a url, tries to open it in your browser.
  # TODO: Linux
  def browse(url)
    if RUBY_PLATFORM =~ /darwin/
      `open #{url}`
    elsif RUBY_PLATFORM =~ /linux/
       `#{ENV['BROWSER']} #{url}`
    elsif ENV['OS'] == 'Windows_NT' or
      RUBY_PLATFORM =~ /djgpp|(cyg|ms|bcc)win|mingw|wince/i
      `start "" "#{url}"`
    end
  end

  # Tries to copy passed content to the clipboard.
  def copy(content)
    cmd = case true
    when system("type pbcopy > /dev/null 2>&1")
      :pbcopy
    when system("type xclip > /dev/null 2>&1")
      :xclip
    when system("type putclip > /dev/null 2>&1")
      :putclip
    end

    if cmd
      IO.popen(cmd.to_s, 'r+') { |clip| clip.print content }
    end

    content
  end

private
  # Give an array of file information and private boolean, returns
  # an appropriate payload for POSTing to gist.github.com
  def data(files, private_gist, description)
    i = 0
    file_data = {}
    files.each do |file|
      i = i + 1
      filename = file[:filename] ? file[:filename] : "gistfile#{i}"
      file_data[filename] = {:content => file[:input]}
    end

    data = {"files" => file_data}
    data.merge!({ 'description' => description }) unless description.nil?
    data.merge!({ 'public' => !private_gist })
    data
  end

  def set_default_provider(url)
    if (default = config('gist.default-url'))
      unless yes?("Do you want to change the current default provider (#{default})?")
        $stderr.puts "Nothing to do."
        return
      end
    end

    url ||= normalized_api_urls_from_config unless url || url =~ /\S/

    unless defaults['api-url'].include?(url)
      add_provider_url(url) if yes?("#{url} is not currently listed as a provider - should we add it?")
    end

    set_config('gist.default-url', url)
  end

  def add_provider_url(url)
    if defaults['api-url'].include?(url)
      $stderr.puts "API Provider [#{url}] already included in list of providers."
      exit 1
    end

    add_config('gist.api-url', url)

    if yes?("Should this be the default provider?")
      set_config('gist.default-url', url)
    end

    options.gist_api_url = url
    setup_credentials
  end

  # Loops until the user has entered valid credentials as determiend by
  # a HTTP OK (200) response from the API Provider
  # returns array ([ username, password, response])
  def _auth_loop_request(url)
    begin
      $stdout.puts "Enter your credentials (Control-C to quit)."
      user = ask("Enter username for #{api_url}: ")
      pass = ask("Enter password for #{api_url}: ") { |q| q.echo = '*' }

      response = request(url) do |u|
        yield(u).tap {|request| request.basic_auth(user, pass) }
      end

      break if response.kind_of? Net::HTTPOK
      $stderr.puts "Authentication failed: #{response.code} #{response.message}"
    end while true

    [user, pass, response ]
  end

  # Prompts the user using the given prompt and returns true if the user selects
  # yes, or false others
  # returns boolean
  def yes?(prompt)
    begin
      answer = ask("#{prompt} [y/n]: ") { |q| q.limit = 1; q.case = :downcase }
    end until %w(y n).include? answer
    answer == 'y'
  end

  # Returns a basic auth string of the user's GitHub credentials if set.
  # http://github.com/guides/local-github-config
  #
  # Returns an Array of Strings if auth is found: [user, password]
  # Returns nil if no auth is found.
  def authenticate(request)
    return unless request['Authorization'].nil?

    confkey = credential_config_key

    token   = config("#{confkey}.token")
    user    = config("#{confkey}.user")
    pass    = config("#{confkey}.password")

    if token
      request['Authorization'] = "token #{token}"
    elsif user
      begin
        if $stdin.tty?
          pass = ask("Enter your password for #{api_url}: ") { |q| q.echo = '*' } if !pass
        else
          $stderr.puts "STDIN not a TTY - cannot query for missing password."
          $stderr.puts "Please add #{confkey}.password or #{confkey}.token to your gitconfig"
          exit 1
        end
      rescue Interrupt
        warn "attempting connection without authorization.."
        return
      end
      request.basic_auth(user, pass)
    else
      $stderr.puts "No currently configured username/password or token set for this API Provider."
      exit 1 unless $stdin.tty? && setup_credentials
      authenticate(request)
    end
  end

  # Sets up user's credentials for the given API Provider.
  # returns boolean; true on success, false on failure
  def setup_credentials
    unless yes?('Would you like to configure and store your credentials?')
      $stderr.puts "Unable to proceed without credentials"
      exit 1
    end

    begin
      choice = choose do |menu|
        menu.prompt = 'Which type of credentials would you like to set up? (token is highly recommended) '
        menu.choices(:password, :token, :none)
      end.to_sym
    end until [:password, :token, :none].include? choice

    if choice == :password
      setup_password_credentials
    elsif choice == :token
      setup_token_credentials
    else
      return false
    end
  rescue StandardError => e
    options.debug ? warn(e) : raise(e)
    false
  end

  # Sets up the user's USERNAME and PASSWORD for the given API Provider and stores it
  # in the user's gitconfig
  # return nil
  def setup_password_credentials
    config_key = credential_config_key

    if config("#{config_key}.user") && config("#{config_key}.password")
      $stderr.puts "Password credentials already configured for API Provider #{api_url}"
      unless yes?('Would you like to reconfigure the password for this provider?')
        $stderr.puts 'Nothing to do.'
        exit 1
      end
    end

    username, password, response = _auth_loop_request("#{api_url}/user") { |url|
      Net::HTTP::Head.new(url.path)
    }

    case response
      when Net::HTTPOK
        $stdout.puts "Storing username/password credentials for API Provider #{api_url} with key #{config_key}"
        store_config_credentials(username, :password => password)
      else
        $stderr.puts "Failed to acquire credentials: #{response.code}: #{response.message}"
    end
    nil
  end

  # Sets up the user's OAUTH token for the given API Provider and stores it
  # in the user's gitconfig
  # return nil
  def setup_token_credentials
    config_key         = credential_config_key

    if config("#{config_key}.token")
      $stderr.puts "Token credentials already configured for API Provider #{api_url}"
      unless yes?('Would you like to reconfigure the token for this provider?')
        $stderr.puts 'Nothing to do.'
        exit 1
      end
    end

    token_request_body = {:scopes => %w(repo user gist), :note   => "General oauth"}

    username, _, response = _auth_loop_request("#{api_url}/authorizations") do |url|
      Net::HTTP::Get.new(url.path).tap {|request|
        request.body = JSON.generate(token_request_body)
      }
    end

    case response
      when Net::HTTPOK
        token = JSON.parse(response.body).first['token']
        $stdout.puts "Storing token credentials for API Provider #{api_url} with key #{config_key}"
        store_config_credentials(username, :token => token)
      else
        $stderr.puts "Failed to acquire token: #{response.code}: #{response.message}"
    end
    nil
  end

  # sets the gitconfig section key to use for subsequent credential lookups
  # normalizing on domain name with dots converted to dashes.
  #
  # returns the gitconfig section key (string)
  def set_credential_config_key(url)
    @credential_config_key = URI.parse(url).host.gsub('.', '-')
  end

  # Given a set of API Provider URLs, this method queries the
  # user for the particular URL to use for this session.
  #
  # returns the chosen url (string)
  def select_api_url(urls)
    unless $stdin.tty?
      $stderr.puts "Multiple API Endpoints found but STDIN is not a TTY - cannot request endpoint selection."
      $stderr.puts "Please rerun and specify the api provider you wish to use with --api-url"
      exit 1
    end

    choose do |menu|
      menu.prompt = "\nMultiple API Endpoints found in configuration. Which do you want to use? "
      menu.choices(*urls)
    end
  end

  # Returns the gist url, based off of the git-config option
  # gist.api-url or, if that's not present, the DEFAULT_API_URL
  #
  # Returns a string
  def gist_url
    "#{api_url}/gists/%s"
  end

  # Returns the create url, based off of the git-config option
  # gist.api-url or, if that's not present, the DEFAULT_API_URL
  #
  # Returns a string
  def create_url
    "#{api_url}/gists"
  end

  # Returns the API Provider url, looking at the gist.api-url config
  # to acquire it. If there are multiple API URLs, the user is queried
  # for the particular Provider they wish to use.
  #
  # returns a string
  def api_url
    default = config('gist.default-url')

    @api_url ||= options.gist_api_url
    @api_url ||= default if default && defaults['api-url'].include?(default)
    @api_url ||= normalized_api_urls_from_config
    @api_url.tap { |api_url| set_credential_config_key(api_url) }
  end

  def normalized_api_urls_from_config
    case (url = [config('gist.api-url')].flatten.compact)
      when String, URI then url.to_s
      when Array then url.size == 1 ? url.first : select_api_url(url)
      else DEFAULT_GITHUB_API_BASE_URL
    end
  end

  # Returns default values based on settings in your gitconfig. See
  # git-config(1) for more information.
  #
  # Settings applicable to gist.rb are:
  #
  # gist.default-url - string
  # gist.api-url     - string | array
  # gist.private     - boolean
  # gist.browse      - boolean
  # gist.extension   - string
  def defaults
    extension = config("gist.extension")

    return {
      'default-url' => config('gist.default-url'),
      "api-url"     => [config("gist.api-url")].flatten.compact,
      "private"     => config("gist.private"),
      "browse"      => config("gist.browse"),
      "extension"   => extension
    }
  end

  # Sets a config value
  #
  # => git-config(1)
  #
  # returns true if the key was set successfully, false otherwise
  def set_config(key, value)
    system("git config --global #{key} '#{value}'")
  end

  # Adds, without replacing, a new key/value pair
  #
  # => git-config(1)
  #
  # returns true if the key was added successfully, false otherwise
  def add_config(key, value)
    system("git config --global --add #{key} '#{value}'")
  end

  # Reads a config value using:
  # => Environment: GITHUB_PASSWORD, GITHUB_USER
  #                 like vim gist plugin
  # => git-config(1)
  #
  # return something useful or nil
  def config(key)
    env_key = ENV[key.upcase.gsub(/[\.-]/, '_')]
    return env_key if env_key and not env_key.strip.empty?

    str_to_bool `git config --global --get-all #{key}`.strip
  end

  # Returns the API Provider specific git-config section key
  #
  # return string
  def credential_config_key
    api_url == DEFAULT_GITHUB_API_BASE_URL ?
      DEFAULT_CREDENTIAL_CONFIG_KEY : (@credential_config_key || DEFAULT_CREDENTIAL_CONFIG_KEY)
  end

  # Stores the given credentials under the API Provider specific section
  # of the user's .gitconfig
  #
  # return true on succussful password save
  def store_config_credentials(user, options={})
    set_config("#{credential_config_key}.user", user)
    if (token = options.delete(:token))
      set_config("#{credential_config_key}.token", token)
    elsif (password = options.delete(:password))
      set_config("#{credential_config_key}.password", password)
    else
      warn "no token or password set"
      false
    end
  end

  # Parses a value that might appear in a .gitconfig file into
  # something useful in a Ruby script.
  def str_to_bool(str)
    if str.size > 0 and str[0].chr == '!'
      command = str[1, str.length]
      value = `#{command}`
    else
      value = str
    end

    case value.downcase.strip
    when "false", "0", "nil", "", "no", "off"
      nil
    when "true", "1", "yes", "on"
      true
    when /\n/
      value.strip.split(/\n+/)
    else
      value
    end
  end

  def ca_cert
    cert_file = [
      File.expand_path("../gist/cacert.pem", __FILE__),
      "/tmp/gist_cacert.pem"
    ].find{|l| File.exist?(l) }

    if cert_file
      cert_file
    else
      File.open("/tmp/gist_cacert.pem", "w") do |f|
        f.write(DATA.read.split("__CACERT__").last)
      end
      "/tmp/gist_cacert.pem"
    end
  end

end
