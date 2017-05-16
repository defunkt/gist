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

To read a gist and print it to STDOUT

    gist -r GIST_ID
    gist -r 374130

‌See `gist --help` for more detail.

## Authentication

To associate and manage uploaded gists with your GitHub account, `gist` needs an
authentication token, with at least the "gist" permission. The token can be
obtained using `gist --login`. Alternately, you may generate a personal access
token through https://github.com/settings/tokens and save it in `~/.netrc`.

### Authenticating with `gist --login`

Gist can login to your GitHub account. It doesn't store your Github username or
password, it just uses them to get an OAuth2 token (with the "gist" permission).

    $ gist --login
    Obtaining OAuth2 access_token from github.
    GitHub username: ConradIrwin
    GitHub password:
    2-factor auth code:
    Success! https://github.com/settings/tokens

This token is stored in `~/.gist` and used for all future gisting. The generated
token will be listed in https://github.com/settings/tokens, and can also be
revoked from there.

### Credentials in `~/.netrc`

Gist can make use of a personal token stored in `~/.netrc`. Github credentials
stored in this file are matched by the hostname, and can be shared among
different tools, like `git`, and `curl`.

The `~/.netrc` file should be unreadable by anyone except the owner. To store
your gist token in `~/.netrc`, use the format:

    machine github.com
      password PERSONAL_ACCESS_TOKEN

You may also maintain a separate token exclusively for gisting by associating
the token with the hostname `gist.github.com`, and setting the environment
variable `GITHUB_URL=https://gist.github.com`.

### Uploading anonymous gists

Independently of the authentication mechanism used, you can always upload gists
anonymously by using the `-a` option.

    gist -a a.rb

### GitHub Enterprise

If you'd like `gist` to use your locally installed [GitHub Enterprise](https://enterprise.github.com/),
you need to export the `GITHUB_URL` environment variable (usually done in your `~/.bashrc`).

    export GITHUB_URL=https://github.internal.example.com/

Once you've done this and restarted your terminal (or run `source ~/.bashrc`), gist will
automatically use github enterprise instead of the public github.com

When using `gist --login` your token for GitHub Enterprise will be stored in
`.gist.<protocol>.<server.name>[.<port>]` (e.g.
`~.gist.https.github.internal.example.com` for the GITHUB_URL example above)
instead of `~/.gist`. The token can also be stored in `~/.netrc` with an
appropriate entry for the host. For instance, for the example above,

    machine github.internal.example.com
      password GITHUB_ENTERPRISE_TOKEN

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
