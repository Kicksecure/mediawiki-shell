mediawiki from the shell
========================

Basic set of scripts to login/out and fetch/edit pages on a mediawiki
site from the command line using curl.


Configuration
-------------

Set the option in wiki-config as required for your site and username.


Usage example
-------------

    $ ./login

    $ ./fetch 'User:MyUser/sandbox' > page.mw
    $ vi page.mw
    $ ./edit 'User:MyUser/sandbox' page.mw

    $ ./fetch 'Main_Page' > mainpage.mw
    $ vi mainpage.mw
    $ ./edit 'Main_Page' mainpage.mw

    $ ./logout


See also
--------

MediaWiki API documentation at:

  http://www.mediawiki.org/wiki/API:Main_page


Credits
-------

Initial example taken from http://www.mediawiki.org/wiki/API:Client_code/Bash

Updated and split into separate scripts by Matthew Newton, October 2014.

