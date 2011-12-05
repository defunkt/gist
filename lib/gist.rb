require 'open-uri'
require 'net/https'
require 'optparse'

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

  GIST_URL   = 'https://gist.github.com/%s.txt'
  CREATE_URL = 'https://gist.github.com/gists'

  if ENV['HTTPS_PROXY']
    PROXY = URI(ENV['HTTPS_PROXY'])
  elsif ENV['HTTP_PROXY']
    PROXY = URI(ENV['HTTP_PROXY'])
  else
    PROXY = nil
  end
  PROXY_HOST = PROXY ? PROXY.host : nil
  PROXY_PORT = PROXY ? PROXY.port : nil

  # Parses command line arguments and does what needs to be done.
  def execute(*args)
    private_gist = defaults["private"]
    anonymous_gist = false
    gist_filename = nil
    gist_extension = defaults["extension"]
    browse_enabled = defaults["browse"]
    description = nil

    opts = OptionParser.new do |opts|
      opts.banner = "Usage: gist [options] [filename or stdin] [filename] ...\n" +
        "Filename '-' forces gist to read from stdin."

      opts.on('-p', '--[no-]private', 'Make the gist private') do |priv|
        private_gist = priv
      end

      opts.on('-a', '--anonymous', 'Create an anonymous gist') do |anon|
        anonymous_gist = anon
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

      url = write(files, private_gist, description, anonymous_gist)
      browse(url) if browse_enabled
      puts copy(url)
    rescue => e
      warn e
      puts opts
    end
  end

  # Create a gist on gist.github.com
  def write(files, private_gist = false, description = nil, anonymous_gist = false)
    url = URI.parse(CREATE_URL)

    if PROXY_HOST
      proxy = Net::HTTP::Proxy(PROXY_HOST, PROXY_PORT)
      http  = proxy.new(url.host, url.port)
    else
      http = Net::HTTP.new(url.host, url.port)
    end

    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_PEER
    http.ca_file = ca_cert

    req = Net::HTTP::Post.new(url.path)
    req.form_data = data(files, private_gist, description, anonymous_gist)

    response = http.start{|h| h.request(req) }
    case response
    when Net::HTTPRedirection
      response['Location']
    else
      puts "Creating gist failed: #{response.code} #{response.message}"
      exit(false)
    end
  end

  # Given a gist id, returns its content.
  def read(gist_id)
    open(GIST_URL % gist_id).read
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
  def data(files, private_gist, description, anonymous_gist = false)
    data = {}
    files.each do |file|
      i = data.size + 1
      data["file_ext[gistfile#{i}]"]      = file[:extension] ? file[:extension] : '.txt'
      data["file_name[gistfile#{i}]"]     = file[:filename]
      data["file_contents[gistfile#{i}]"] = file[:input]
    end
    data.merge!({ 'description' => description }) unless description.nil?
    data.merge!(private_gist ? { 'action_button' => 'private' } : {})
    data.merge!(anonymous_gist ? {} : auth)
  end

  # Returns a hash of the user's GitHub credentials if set.
  # http://github.com/guides/local-github-config
  def auth
    user  = config("github.user")
    token = config("github.token")

    if user.to_s.empty? || token.to_s.empty?
      {}
    else
      { :login => user, :token => token }
    end
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
  # => Environement: GITHUB_TOKEN, GITHUB_USER
  #                  like vim gist plugin
  # => git-config(1)
  #
  # return something useful or nil
  def config(key)
    env_key = ENV[key.upcase.gsub(/\./, '_')]
    return env_key if env_key and not env_key.strip.empty?

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
