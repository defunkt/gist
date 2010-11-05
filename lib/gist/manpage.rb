module Gist
  module Manpage
    extend self

    # Prints a manpage, all pretty and paged.
    def display(name)
      puts manpage(name)
    end

    # Returns the terminal-formatted manpage, ready to be printed to
    # the screen.
    def manpage(name)
      return "** Can't find groff(1)" unless groff?

      require 'open3'
      out = nil
      Open3.popen3(groff_command) do |stdin, stdout, _|
        stdin.puts raw_manpage(name)
        stdin.close
        out = stdout.read.strip
      end
      out
    end

    # Returns the raw manpage. If we're not running in standalone
    # mode, it's a file sitting at the root under the `man`
    # directory.
    #
    # If we are running in standalone mode the manpage will be
    # included after the __END__ of the file so we can grab it using
    # DATA.
    def raw_manpage(name)
      if File.exists? file = File.dirname(__FILE__) + "/../../man/#{name}.1"
        File.read(file)
      else
        DATA.read.split("__CACERT__").first
      end
    end

    # Returns true if groff is installed and in our path, false if
    # not.
    def groff?
      system("which groff > /dev/null")
    end

    # The groff command complete with crazy arguments we need to run
    # in order to turn our raw roff (manpage markup) into something
    # readable on the terminal.
    def groff_command
      "groff -Wall -mtty-char -mandoc -Tascii"
    end

    # All calls to `puts` are paged, git-style.
    def puts(*args)
      page_stdout
      super
    end

    # http://nex-3.com/posts/73-git-style-automatic-paging-in-ruby
    def page_stdout
      return unless $stdout.tty?

      read, write = IO.pipe

      if Kernel.fork
        # Parent process, become pager
        $stdin.reopen(read)
        read.close
        write.close

        # Don't page if the input is short enough
        ENV['LESS'] = 'FSRX'

        # Wait until we have input before we start the pager
        Kernel.select [STDIN]

        pager = ENV['PAGER'] || 'less -isr'
        pager = 'cat' if pager.empty?

        exec pager rescue exec "/bin/sh", "-c", pager
      else
        # Child process
        $stdout.reopen(write)
        $stderr.reopen(write) if $stderr.tty?
        read.close
        write.close
      end
    end
  end
end
