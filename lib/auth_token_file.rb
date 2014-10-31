module Gist
  module AuthTokenFile

    def self.filename
      if ENV.key?(URL_ENV_NAME)
        File.expand_path "~/.gist.#{ENV[URL_ENV_NAME].gsub(/[^a-z.]/, '')}"
      else
        File.expand_path "~/.gist"
      end
    end

    def self.read
      File.read(filename).chomp
    end

    def self.write(token)
      File.write filename, token,
        :mode => 'w',
        :perm => 0600
    end

  end
end
