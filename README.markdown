Gist: The Script
================

Works great with Gist: The Website.

Installation
------------

RubyGem:

    gem install gist

Old school:

    curl -s http://github.com/defunkt/gist/raw/master/gist > gist &&
    chmod 755 gist &&
    mv gist /usr/local/bin/gist

Use
---

    gist < file.txt
    echo secret | gist --private # or -p
    echo "puts :hi" | gist -t rb
    gist script.py

Authentication
--------------

Just have your git config set up with your GitHub username and token.

    git config --global github.user "your-github-username"
    git config --global github.token "your-github-token"

You can find your token under [your account](https://github.com/account).


Proxies
-------

Set the HTTP_PROXY env variable to use a proxy.

    $ HTTP_PROXY=host:port gist file.rb

Manual
------


Visit <http://defunkt.github.com/gist/> or use:

    $ gist -m

Ninja vs Shark
--------------

![Ninja vs Shark](http://github.com/defunkt/gist/tree/master%2Fbattle.png?raw=true)
