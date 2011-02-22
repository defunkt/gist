Gist: The Script
================

Works great with Gist: The Website.

Installation
------------

[homebrew](http://mxcl.github.com/homebrew/):

    brew install gist
    gist -h

RubyGems:

    gem install gist
    gist -h

Old school:

    curl -s https://github.com/defunkt/gist/raw/master/gist > gist &&
    chmod 755 gist &&
    mv gist /usr/local/bin/gist


Use
---

    $ gist < file.txt
    $ echo secret | gist --private # or -p
    $ echo "puts :hi" | gist -t rb
    $ gist script.py
    $ gist script.js notes.txt
    $ gist -
    the quick brown fox jumps over the lazy dog
    ^D


Authentication
--------------
There are two ways to set GitHub user and token info:

Using env vars GITHUB_USER and GITHUB_TOKEN:

    $ export GITHUB_USER="your-github-username"
    $ export GITHUB_TOKEN="your-github-token"
    $ gist ~/example

Or by having your git config set up with your GitHub username and token.

    git config --global github.user "your-github-username"
    git config --global github.token "your-github-token"

You can find your token under [your account](https://github.com/account).

You can also define github.token to be a command which returns the
actual token on stdout by setting the variable to a command string
prefixed with `!`. For example, the following command fetches the
token from a password item named "github.token" on the Mac OS
Keychain:

    token = !security 2>&1 >/dev/null find-generic-password -gs github.token | ruby -e 'print $1 if STDIN.gets =~ /^password: \\\"(.*)\\\"$/'


Defaults
--------

You can set a few options in your git config (using git-config(1)) to
control the default behavior of gist(1).

* gist.private - boolean (yes or no) - Determines whether to make a gist
  private by default

* gist.extension - string - Default extension for gists you create.

* gist.browse - boolean (yes or no) - Whether to open the gist in your
  browser after creation. Default: yes

Proxies
-------

Set the HTTP_PROXY env variable to use a proxy.

    $ HTTP_PROXY=host:port gist file.rb


Manual
------

Visit <http://defunkt.github.com/gist/> or use:

    $ gist -m

Bugs
----

<https://github.com/defunkt/gist/issues>
