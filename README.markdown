Gist: The Script
================

Works great with Gist: The Website.

Installation
------------

[homebrew](http://mxcl.github.com/homebrew/):

```bash
$ brew install gist
$ gist -h
```

RubyGems:

```bash
$ gem install gist
$ gist -h
```

Old school:

```bash
$ curl -s https://raw.github.com/defunkt/gist/master/gist > gist &&
$ chmod 755 gist &&
$ mv gist /usr/local/bin/gist
```

Ubuntu:

```bash
$ sudo apt-get install ruby
$ sudo apt-get install rubygems
$ sudo apt-get install libopenssl-ruby
$ sudo gem install gist
$ sudo cp /var/lib/gems/1.8/bin/gist /usr/local/bin/
$ gist -h
```

Use
---

```bash
$ gist < file.txt
$ echo secret | gist --private # or -p
$ echo "puts :hi" | gist -t rb
$ gist script.py
$ gist script.js notes.txt
$ pbpaste | gist -p # Copy from clipboard - OSX Only
$ gist -
the quick brown fox jumps over the lazy dog
^D
```

Authentication
--------------
There are two ways to set GitHub user and token info:

Using env vars GITHUB_USER and GITHUB_TOKEN:

```bash
$ export GITHUB_USER="your-github-username"
$ export GITHUB_TOKEN="your-github-token"
$ gist ~/example
```

Or by having your git config set up with your GitHub username and token.

```bash
git config --global github.user "your-github-username"
git config --global github.token "your-github-token"
```

You can find your token under [your account](https://github.com/account).

You can also define github.token to be a command which returns the
actual token on stdout by setting the variable to a command string
prefixed with `!`. For example, the following command fetches the
token from a password item named "github.token" on the Mac OS
Keychain:

```bash
token = !security 2>&1 >/dev/null find-generic-password -gs github.token | ruby -e 'print $1 if STDIN.gets =~ /^password: \\\"(.*)\\\"$/'
```

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

```bash
$ HTTP_PROXY=host:port gist file.rb
```

Manual
------

Visit <http://defunkt.github.com/gist/> or use:

```bash
$ gist -m
```

Bugs
----

<https://github.com/defunkt/gist/issues>
