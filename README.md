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

‌For FreeBSD, gist lives in ports

    pkg install gist


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

To read a gist and print it to STDOUT

    gist -r GIST_ID
    gist -r 374130

‌See `gist --help` for more detail.

## Login

If you want to associate your gists with your GitHub account, you need to login
with gist. It doesn't store your username and password, it just uses them to get
an OAuth2 token (with the "gist" permission).

    gist --login
    Obtaining OAuth2 access_token from GitHub.
    GitHub username: ConradIrwin
    GitHub password:
    2-factor auth code:
    Success! https://github.com/settings/tokens

This token is stored in `~/.gist` and used for all future gisting. If you need to
you can revoke it from https://github.com/settings/tokens, or just delete the
file. 

#### Password-less login

If you have a complicated authorization requirement you can manually create a
token file by pasting a GitHub token with only the `gist` permission into a
file called `~/.gist`. You can create one from https://github.com/settings/tokens

This file should contain only the token (~40 hex characters), and to make it
easier to edit, can optionally have a final newline (\n or \r\n).

For example, one way to create this file would be to run:

    echo MY_SECRET_TOKEN > ~/.gist

### GitHub Enterprise

If you'd like `gist` to use your locally installed [GitHub Enterprise](https://enterprise.github.com/),
you need to export the `GITHUB_URL` environment variable (usually done in your `~/.bashrc`).

    export GITHUB_URL=http://github.internal.example.com/

Once you've done this and restarted your terminal (or run `source ~/.bashrc`), gist will
automatically use GitHub Enterprise instead of the public github.com

Your token for GitHub Enterprise will be stored in `.gist.<protocol>.<server.name>[.<port>]` (e.g.
`~/.gist.http.github.internal.example.com` for the GITHUB_URL example above) instead of `~/.gist`.

If you have multiple servers or use Enterprise and public GitHub often, you can work around this by creating scripts
that set the env var and then run `gist`. Keep in mind that to use the public GitHub you must unset the env var. Just
setting it to the public URL will not work. Use `unset GITHUB_URL`

### Token file format

If you cannot use passwords, as most Enterprise installations do, you can generate the token via the web interface
and then simply save the string in the correct file. Avoid line breaks or you might see:
```
$ gist -l
Error: Bad credentials
```

# Library

‌You can also use Gist as a library from inside your ruby code:

    Gist.gist("Look.at(:my => 'awesome').code")

If you need more advanced features you can also pass:

* `:access_token` to authenticate using OAuth2 (default is `File.read("~/.gist")).
* `:filename` to change the syntax highlighting (default is `a.rb`).
* `:public` if you want your gist to have a guessable url.
* `:description` to add a description to your gist.
* `:update` to update an existing gist (can be a URL or an id).
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

## Docker Image

[GistGem](https://hub.docker.com/r/natac13/gistgem) is a Docker image which was created to utilize this gem.

**Usage**

```
docker container run --rm -i --mount type=bind,source=/home/[username]/.gist,target=/root/.gist natac13/gistgem [command]
```

## Meta-fu

Thanks to @defunkt and @indirect for writing and maintaining versions 1 through 3.
Thanks to @rking and @ConradIrwin for maintaining version 4.

Licensed under the MIT license. Bug-reports, and pull requests are welcome.
