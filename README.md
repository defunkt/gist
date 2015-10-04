gist(1) -- upload code to https://gist.github.com
=================================================

## Synopsis

The gist gem provides a `gist` command that you can use from your terminal to
upload content to https://gist.github.com/.

## Installation

‌If you have ruby installed:

    gem install gist

‌If you're using Bundler:

    source :rubygems
    gem 'gist'

‌For OS X, gist lives in Homebrew

    brew install gist

## Command

‌To upload the contents of `a.rb` just:

    gist a.rb

‌Upload multiple files:

    gist a b c
    gist *.rb

‌By default it reads from STDIN, and you can set a filename with `-f`.

    gist -f test.rb <a.rb

‌Alternatively, you can just paste from the clipboard:

    gist -P

‌Use `-p` to make the gist private:

    gist -p a.rb

‌Use `-d` to add a description:

    gist -d "Random rbx bug" a.rb

‌You can update existing gists with `-u`:

    gist -u GIST_ID FILE_NAME
    gist -u 42f2c239d2eb57299408 test.txt

‌If you'd like to copy the resulting URL to your clipboard, use `-c`.

    gist -c <a.rb

‌If you'd like to copy the resulting embeddable URL to your clipboard, use `-e`.

    gist -e <a.rb

‌And you can just ask gist to open a browser window directly with `-o`.

    gist -o <a.rb

‌To list (public gists or all gists for authed user) gists for user

    gist -l : all gists for authed user
    gist -l defunkt : list defunkt's public gists

‌See `gist --help` for more detail.

## Login

If you want to associate your gists with your GitHub account, you need to login
with gist. It doesn't store your username and password, it just uses them to get
an OAuth2 token (with the "gist" permission).

    gist --login
    Obtaining OAuth2 access_token from github.
    GitHub username: ConradIrwin
    GitHub password:
    2-factor auth code:
    Success! https://github.com/settings/applications

This token is stored in `~/.gist` and used for all future gisting. If you need to
you can revoke it from https://github.com/settings/applications, or just delete the
file.  If you need to store tokens for both github.com and a Github Enterprise instance 
you can save your Github Enterprise token in `~/.gist.github.example.com` where 
"github.example.com" is the URL for your Github Enterprise instance.

‌After you've done this, you can still upload gists anonymously with `-a`.

    gist -a a.rb

# Library

‌You can also use Gist as a library from inside your ruby code:

    Gist.gist("Look.at(:my => 'awesome').code")

If you need more advanced features you can also pass:

* `:access_token` to authenticate using OAuth2 (default is `File.read("~/.gist")).
* `:filename` to change the syntax highlighting (default is `a.rb`).
* `:public` if you want your gist to have a guessable url.
* `:description` to add a description to your gist.
* `:update` to update an existing gist (can be a URL or an id).
* `:anonymous` to submit an anonymous gist (default is false).
* `:copy` to copy the resulting URL to the clipboard (default is false).
* `:open` to open the resulting URL in a browser (default is false).

NOTE: The access_token must have the "gist" scope.

‌If you want to upload multiple files in the same gist, you can:

    Gist.multi_gist("a.rb" => "Foo.bar", "a.py" => "Foo.bar")

‌If you'd rather use gist's builtin access_token, then you can force the user
  to obtain one by calling:

    Gist.login!

‌This will take them through the process of obtaining an OAuth2 token, and storing it
in `~/.gist`, where it can later be read by `Gist.gist`

## GitHub enterprise

‌If you'd like `gist` to use your locally installed [GitHub Enterprise](https://enterprise.github.com/),
you need to export the `GITHUB_URL` environment variable in your `~/.bashrc`.

    export GITHUB_URL=http://github.internal.example.com/

‌Once you've done this and restarted your terminal (or run `source ~/.bashrc`), gist will
automatically use github enterprise instead of the public github.com

## Configuration

‌If you'd like `-o` or `-c` to be the default when you use the gist executable, add an
alias to your `~/.bashrc` (or equivalent). For example:

    alias gist='gist -c'

‌If you'd prefer gist to open a different browser, then you can export the BROWSER
environment variable:

    export BROWSER=google-chrome

If clipboard or browser integration don't work on your platform, please file a bug or
(more ideally) a pull request.

If you need to use an HTTP proxy to access the internet, export the `HTTP_PROXY` or
`http_proxy` environment variable and gist will use it.

## Meta-fu

Thanks to @defunkt and @indirect for writing and maintaining versions 1 through 3.
Thanks to @rking and @ConradIrwin for maintaining version 4.

Licensed under the MIT license. Bug-reports, and pull requests are welcome.
