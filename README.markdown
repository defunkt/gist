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

PROVIDERS
---------

Gist supports multiple API Providers, or API Endpoints. An example where
this might be necessary is where you have an internal Github Enterprise
server for your company, and you also use github.com.

You can specify each provider as a series of api-url's in the gist section
your git-config file.

When you run gist with multiple providers specified, gist will ask you to
select an API Provider when you attempt to gist a file. You can force the
selection ahead of time by passing the --api-url command line option with
the api-url you wish to use. This is handy when you are piping (or
redirecting) content directly into gist.

Authentication
--------------
Authentication is done using either a username and password combination, or
a OAUTH token. To automate the usage of gist, there are a few ways you can
go about setting up your credentials for unattended usage:T

1. Using env vars GITHUB_USER and GITHUB_PASSWORD:

    ```bash
    $ export GITHUB_USER="your-github-username"
    $ export GITHUB_PASSWORD="your-github-password"
    $ gist ~/example
    ```

2. Or by having your git config set up with your GitHub username and password.

    ```bash
    git config --global github.user "your-github-username"
    git config --global github.password "your-github-password"
    ```

    You can also define github.password to be a command which returns the
    actual password on stdout by setting the variable to a command string
    prefixed with `!`. For example, the following command fetches the
    password from the Mac OS Keychain entry for the GitHub website (if you
    allow your browser to save passwords):

    ```bash
    password = !security find-internet-password -a <your github username> -s github.com -w | tr -d '\n'
    ```

    If you don't allow your browser to save passwords, you can use the following
    to fetch the password from a Keychain entry named "github.password" (you'll
    also need to create the Keychain entry):

    ```bash
    password = !security find-generic-password -gs github.password -w | tr -d '\n'
    ```

3. Use gist to setup your git config for you.

    ```bash
    gist --setup-credentials
    ```

    This will cause gist to ask you a series of questions in order to determine the type
    of setup required. After answering all the questions, you will find that your
    git configuration has all the relevant sections necessary to run without asking you
    for any credentials from here on out.

    **NOTE: It is recommended that you choose _token_ as your preferred credential type due
    to the _password_ type storing your password in clear text in you git configuration file**

Defaults
--------

You can set a few options in your git config (using git-config(1)) to
control the default behavior of gist(1).

* gist.api-url - string|multival - The base API URL for a provider with
  multiple values being valid. Defaults to github, pre-added to your
  git-config for you on first run.

* gist.private - boolean (yes or no) - Determines whether to make a gist
  private by default

* gist.extension - string - Default extension for gists you create.

* gist.browse - boolean (yes or no) - Whether to open the gist in your
  browser after creation. Default: yes

Additionally, gist looks for provider specific options under each provider
section in your git-config. In particular:

* <provider>.login-required - boolean (true or false) - Whether or not
authentication is required for the given provider.

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
