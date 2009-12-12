Gist: The Script
================

Works great with Gist: The Website.

Installation
------------

    curl http://github.com/defunkt/gist/raw/master/gist.rb > gist &&
    chmod 755 gist &&
    mv gist /usr/local/bin/gist

Use
---

    gist < file.txt
    echo secret | gist --private # or -p
    gist 1234 > something.txt


Authentication
--------------

Just have your git config set up with your GitHub username and token.

    git config --global github.user "your-github-username"
    git config --global github.token "your-github-token"

You can find your token under [your account](https://github.com/account).


Ninja vs Shark
--------------

![Ninja vs Shark](http://github.com/defunkt/gist/tree/master%2Fbattle.png?raw=true)
