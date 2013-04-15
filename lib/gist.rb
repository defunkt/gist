require 'open-uri'
require 'net/https'
require 'optparse'
require 'cgi'

require 'base64'

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

  GIST_URL   = 'https://api.github.com/gists/%s'
  CREATE_URL = 'https://api.github.com/gists'

  if ENV['HTTPS_PROXY']
    PROXY = URI(ENV['HTTPS_PROXY'])
  elsif ENV['HTTP_PROXY']
    PROXY = URI(ENV['HTTP_PROXY'])
  else
    PROXY = nil
  end
  PROXY_HOST = PROXY ? PROXY.host : nil
  PROXY_PORT = PROXY ? PROXY.port : nil

  module Error;
    def self.exception(*args)
      RuntimeError.new(*args).extend(self)
    end
  end

  # Parses command line arguments and does what needs to be done.
  def execute(*args)
    private_gist = defaults["private"]
    gist_filename = nil
    gist_extension = defaults["extension"]
    browse_enabled = defaults["browse"]
    description = nil
    embed_enabled = nil

    opts = OptionParser.new do |opts|
      opts.banner = "Usage: gist [options] [filename or stdin] [filename] ...\n" +
        "Filename '-' forces gist to read from stdin."
      opts.on("-l", "--login", "Authenticate gist on this computer.") do
        login!
        exit
      end

      opts.on('-p', '--[no-]private', 'Make the gist private') do |priv|
        private_gist = priv
      end

      t_desc = 'Set syntax highlighting of the Gist by file extension'
      opts.on('-t', '--type [EXTENSION]', t_desc) do |extension|
        gist_extension = '.' + extension
      end

      opts.on('-d','--description DESCRIPTION', 'Set description of the new gist') do |d|
        description = d
      end

      opts.on('-o','--[no-]open', 'Open gist in browser') do |o|
        browse_enabled = o
      end

      opts.on('-e', '--embed', 'Print javascript embed code') do |o|
        embed_enabled = o
      end

      opts.on('-m', '--man', 'Print manual') do
        Gist::Manpage.display("gist")
      end

      opts.on('-v', '--version', 'Print version') do
        puts Gist::Version
        exit
      end

      opts.on('-h', '--help', 'Display this screen') do
        puts opts
        exit
      end
    end

    begin

      opts.parse!(args)

      if $stdin.tty? && args[0] != '-'
        # Run without stdin.

        if args.empty?
          # No args, print help.
          puts opts
          exit
        end

        files = args.inject([]) do |files, file|
          # Check if arg is a file. If so, grab the content.
          abort "Can't find #{file}" unless File.exists?(file)

          files.push({
            :input     => File.read(file),
            :filename  => file,
            :extension => (File.extname(file) if file.include?('.'))
          })
        end

      else
        # Read from standard input.
        input = $stdin.read
        files = [{:input => input, :extension => gist_extension}]
      end

      url = write(files, private_gist, description)
      browse(url) if browse_enabled
      puts "Gist URL: #{copy(to_embed(url))}" if embed_enabled
      puts "Gist URL: #{copy(url)}" unless embed_enabled
    rescue => e
      warn e
      puts opts
    end
  end
  
  def login!
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
      :note => "The gist gem",
      :note_url => "https://github.com/brenttaylor/gist"
    })
    request.content_type = "application/json"
    request.basic_auth(username, password)
    
    response = http(URI("https://api.github.com/"), request)

    if Net::HTTPCreated === response
      File.open(File.expand_path("~/.gist"), 'w') do |f|
        f.write JSON.parse(response.body)['token']
      end
      puts "Success."
    else
      raise "Got #{response.class} from gist: #{response.body}"
    end
  rescue => e
    raise e.extend Error
  end

  def http_connection(uri)
    env = ENV['http_proxy'] || ENV['HTTP_PROXY']
    connection = if env
                   proxy = URI(env)
                   NET::HTTP::Proxy(proxy.host, proxy.port).new(uri.host, uri.port)
                 else
                   Net::HTTP.new(uri.host, uri.port)
                 end
    if uri.scheme == "https"
      connection.use_ssl = true
      connection.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end
    connection.open_timeout = 10
    connection.read_timeout = 10
    connection
  end

  def http(url, request)
    http_connection(url).start do |http|
      http.request request
    end
  rescue Timeout::Error
    raise "Could not connect to #{url}."
  end

  # Create a javascript embed code
  def to_embed(url)
    %Q[<script src="#{url}.js"></script>]
  end

  # Create a gist on gist.github.com
  def write(files, private_gist = false, description = nil)
    access_token = File.read(File.expand_path("~/.gist")) rescue nil
    url = "/gists"
    url << "?access_token=" << CGI.escape(access_token) if access_token.to_s != ''


    req = Net::HTTP::Post.new(url)
    req.body = JSON.generate(data(files, private_gist, description))
    req.content_type = 'application/json'

    begin
      response = http(URI("https://api.github.com/"), req)
      if Net::HTTPSuccess === response
        JSON.parse(response.body)['html_url']
      else
        puts "Creating gist failed: #{response.code} #{response.message}"
        exit(false)
      end
    end
  end

  # Given a gist id, returns its content.
  def read(gist_id)
    data = JSON.parse(open(GIST_URL % gist_id).read)
    data["files"].map{|name, content| content['content'] }.join("\n\n")
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

  # Returns default values based on settings in your gitconfig. See
  # git-config(1) for more information.
  #
  # Settings applicable to gist.rb are:
  #
  # gist.private - boolean
  # gist.extension - string
  def defaults
    extension = config("gist.extension")

    return {
      "private"   => config("gist.private"),
      "browse"    => config("gist.browse"),
      "extension" => extension
    }
  end

  # Reads a config value using:
  # => Environment: GITHUB_PASSWORD, GITHUB_USER
  #                 like vim gist plugin
  # => git-config(1)
  #
  # return something useful or nil
  def config(key)
    str_to_bool `git config --global #{key}`.strip
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
