Jist is a gem that allows you to publish a [gist](https://gist.github.com) from Ruby.

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

# Command

The jist gem provides a `jist` command that you can use from your terminal to
upload content to https://gist.github.com/.

It's easy to use. To upload the contents of `a.rb` just:

```shell
$ jist a.rb
https://gist.github.com/0d07bc98c139810a4075
```

Upload multiple files : 
```shell
$ jist a b c
$ jist *.rb
```

By default it reads from STDIN, and you can set a filename with `-f`.

```shell
$ jist -f test.rb <a.rb
https://gist.github.com/7db51bb5f4f35c480fc8
```

Alternatively, you can just paste from the clipboard:

```shell
$ jist -P
https://gist.github.com/6a330a11a0db8e52a6ee
```

Use `-p` to make the gist public and `-d` to add a description.
```shell
$ jist -p -d "Random rbx bug" a.rb
https://gist.github.com/2977722
```

You can update existing gists with `-u`:

```shell
$ jist lib/jist.rb bin/jist -u 42f2c239d2eb57299408
https://gist.github.com/42f2c239d2eb57299408
```

If you'd like to copy the resulting URL to your clipboard, use `-c`.

```shell
$ jist -c <a.rb
https://gist.github.com/7db51bb5f4f35c480fc8
```

If you'd like to copy the resulting embeddable URL to your clipboard, use `--copy-js`.

```shell
$ jist --copy-js <a.rb
<script src="https://gist.github.com/7db51bb5f4f35c480fc8"></script>
```
And you can just ask jist to open a browser window directly with `-o`.

```shell
$ jist -o <a.rb
https://gist.github.com/7db51bb5f4f35c480fc8
```

See `jist --help` for more detail.

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

After you've done this, you can still upload gists anonymously with `-a`.

```shell
jist -a a.rb
https://gist.github.com/6bf7ec379fc9119b1f15
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
* `:update` to update an existing gist (can be a URL or an id).
* `:anonymous` to submit an anonymous gist (default is false).
* `:copy` to copy the resulting URL to the clipboard (default is false).
* `:open` to open the resulting URL in a browser (default is false).

NOTE: The access_token must have the "gist" scope.

If you want to upload multiple files in the same gist, you can:

```ruby
Jist.multi_gist("a.rb" => "Foo.bar", "a.py" => "Foo.bar")
```

If you'd rather use jist's builtin access_token, then you can force the user to
obtain one by calling:

```ruby
Jist.login!
```

This will take them through the process of obtaining an OAuth2 token, and storing it
in `~/.jist`, where it can later be read by `Jist.gist`

GitHub enterprise
==================

If you'd like `jist` to use your locally installed [Github Enterprise](https://enterprise.github.com/),
you need to export the `GITHUB_URL` environment variable in your `~/.bashrc`.

```bash
export GITHUB_URL=http://github.internal.example.com/
```

Once you've done this and restarted your terminal (or run `source ~/.bashrc`), jist will
automatically use github enterprise instead of the public github.com

Configuration
=============

If you'd like `-o` or `-c` to be the default when you use the jist executable, add an
alias to your `~/.bashrc` (or equivalent). For example:

```ruby
alias jist='jist -c'
```

If you'd prefer jist to open a different browser, then you can export the BROWSER
environment variable:

```ruby
export BROWSER=google-chrome
```

If clipboard or browser integration don't work on your platform, please file a bug or
(more ideally) a pull request.

If you need to use an HTTP proxy to access the internet, export the `HTTP_PROXY` or
`http_proxy` environment variable and jist will use it.

Meta-fu
=======

I wrote this because the `gist` gem is out of action, and has been for many months.

It's licensed under the MIT license, and bug-reports, and pull requests are welcome.
