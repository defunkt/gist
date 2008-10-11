Gist: The Script
================

Works great with Gist: The Website.

Installation
------------

    curl http://github.com/defunkt/gist/tree/master%2Fgist.rb?raw=true > gist &&
    chmod 755 gist &&
    sudo mv gist /usr/local/bin/gist

Use
---

    cat file.txt | gist
    echo secret | gist --private  # or -p
    gist 1234 > something.txt


Ninja vs Shark
--------------

![Ninja vs Shark](http://github.com/defunkt/gist/tree/master%2Fbattle.png?raw=true)
