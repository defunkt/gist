Jist is a gem that allows you to publish a [gist](https://gist.github.com) from Ruby.

# Command

The jist gem provides a `jist` command that you can use from your terminal.

```shell
$ jist --login  # optional
$ jist a.rb
```

It supports everything that the library supports, the output of `jist --help`
is included below for reference.

```
Jist (v0.3) let's you upload to https://gist.github.com/

Usage: jist [-p] [-d DESC] [-t TOKEN] [-f FILENAME] [FILE]
       jist --login

When used with no arguments, jist creates an anonymous, private, gist, with
no description. The FILENAME defaults to "a.rb" and we read the contents of
STDIN.

If you'd like your gists to be associated with your github account, so that
you can edit them, and find them in future, first use `jist --login` to obtain
an Oauth2 access token. This is stored and used for all future uses of jist.

If you're calling jist from another program that already has an access_token
with the "gist" scope, then pass it using `jist -t`.

If you specify a FILE on the command line, then jist will use that as the
default value for FILENAME too. If not, jist will assume that the file you
provide on STDIN is called "a.rb". The FILENAME is mostly important for
determining which language to use for syntax highlighting.

Making a gist public causes it to have a prettier, guessable url. And adding
a description can provide useful context to people who stumble across your
gist.

        --login                      Authenticate jist on this computer.
    -f, --filename [NAME.EXTENSION]  Sets the filename and syntax type.
    -p, --public                     Makes your gist public.
    -d, --description DESCRIPTION    Adds a description to your gist.
    -t, --token OAUTH_TOKEN          The OAuth2 access_token to use.
    -h, --help                       Show this message.
    -v, --version                    Print the version.
```

# Library

You can also use Jist as a library from inside your ruby code:

```ruby
Jist.gist("Look.at(:my => 'awesome').code")
```

If you need more advanced features you can also pass:

* `:access_token` to authenticate using OAuth2 (default is `File.read("~/.jist")).
* `:filename` to change the syntax highlighting (default is `a.rb`).
* `:public` if you want your gist to have a guessable url.
* `:description` to add a description to your gist.

NOTE: The access_token must have the "gist" scope.

If you'd rather use jist's builtin access_token, then you can force the user to
obtain one by calling:

```ruby
Jist.login!
```

This will take them through the process of obtaining an OAuth2 token, and storing it
in `~/.jist`, where it can later be read by `Jist.gist`

Meta-fu
=======

I wrote this because the `gist` gem is out of action, and has been for many months.

It's licensed under the MIT license, and bug-reports, and pull requests are welcome.
