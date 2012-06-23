Jist is a gem that allows you to publish a [gist](https://gist.github.com) from Ruby.

# Command

The jist gem provides a `jist` command that you can use from your terminal to
upload content to https://gist.github.com/.

It's easy to use. To upload the contents of `a.rb` just:

```shell
$ jist a.rb
https://gist.github.com/0d07bc98c139810a4075
```

By default it reads from STDIN, and you can set a filename with `-f`.

```shell
$ jist -f test.rb <a.rb
https://gist.github.com/7db51bb5f4f35c480fc8
```

Use `-p` and `-d` to add finishing touches:
```shell
$ jist -p -d "Random rbx bug" a.rb
https://gist.github.com/2977722
```

## Login

If you want to associate your gists with your github account, you need to login
with jist. It doesn't store your username and password, it just uses them to get
an OAuth2 token (with the "gist" permission).

```shell
jist --login
Obtaining OAuth2 access_token from github.
Github username: ConradIrwin
Github password:
Success! https://github.com/settings/applications
```

This token is stored in `~/.jist` and used for all future gisting. If you need to
you can revoke it from https://github.com/settings/applications, or just delete the
file.

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

# Installation

As with all ruby gems, you can install Jist (assuming you have ruby and rubygems) with:

```shell
$ gem install jist
```

If you want to use the library in your application, and you're using Bundler. Add the
following to your Gemfile.

```ruby
source :rubygems
gem 'jist'
```

Meta-fu
=======

I wrote this because the `gist` gem is out of action, and has been for many months.

It's licensed under the MIT license, and bug-reports, and pull requests are welcome.
