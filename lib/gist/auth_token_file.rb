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
      File.open(filename, 'w', 0600) do |f|
        f.write token
      end
    end

  end
end
