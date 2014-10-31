module Gist
  class AuthTokenFile

    def filename
      if ENV.key?(URL_ENV_NAME)
        File.expand_path "~/.gist.#{ENV[URL_ENV_NAME].gsub(/[^a-z.]/, '')}"
      else
        File.expand_path "~/.gist"
      end
    end

    def read
      File.read(filename).chomp
    end

  end
end
