# filter

Command | Description
------- | -----------
[`filter digest-color`](#filter-digest-color) | Color an input stream based on the contents (e.g. hostname)
[`filter histogram`](#filter-histogram) | Generate a small histogram of the input values. It must be a single column 
[`filter identicon`](#filter-identicon) | Convert an input data stream into an identicon (e.g. with hostname)
[`filter pg2md`](#filter-pg2md) | Convert postgres table format outputs to something that can be pasted as markdown

## filter digest-color

([*source*](https://github.com/galaxyproject/gxadmin/search?q=filter_digest-color&type=Code))
filter digest-color -  Color an input stream based on the contents (e.g. hostname)

**SYNOPSIS**

    gxadmin filter digest-color

**NOTES**

Colors entire input stream based on digest of entire input's contents.
Mostly useful for colouring a hostname or some similar value.

    $ echo test | ./gxadmin filter digest-color
    test

(Imagine that it is light blue text on a pink background)

**NOTE** If the output isn't coloured properly, try:

    export TERM=screen-256color


## filter histogram

([*source*](https://github.com/galaxyproject/gxadmin/search?q=filter_histogram&type=Code))
filter histogram -  Generate a small histogram of the input values. It must be a single column 

**SYNOPSIS**

    gxadmin filter histogram

**NOTES**

Generate a histogram of inputs
    $ cat out.txt | ./gxadmin filter histogram
    ( -23.000,  -20.615) n=1
    [ -20.615,  -18.231) n=4
    [ -18.231,  -15.846) n=16    ***
    [ -15.846,  -13.462) n=8     *
    [ -13.462,  -11.077) n=36    *******
    [ -11.077,   -8.692) n=67    *************
    [  -8.692,   -6.308) n=70    **************
    [  -6.308,   -3.923) n=149   *******************************
    [  -3.923,   -1.538) n=115   ***********************
    [  -1.538,    0.846) n=231   ************************************************
    [   0.846,    3.231) n=240   **************************************************
    [   3.231,    5.615) n=161   *********************************
    [   5.615,    8.000) n=159   *********************************
    [   8.000,   10.385) n=196   ****************************************
    [  10.385,   12.769) n=110   **********************
    [  12.769,   15.154) n=121   *************************
    [  15.154,   17.538) n=83    *****************
    [  17.538,   19.923) n=63    *************
    [  19.923,   22.308) n=78    ****************
    [  22.308,   24.692) n=32    ******
    [  24.692,   27.077) n=31    ******
    [  27.077,   29.462) n=14    **
    [  29.462,   31.846) n=2
    [  31.846,   34.231) n=5     *
    [  34.231,   36.615) n=3
    [  36.615,   39.000) n=4
    [  39.000,   41.385) n=1


## filter identicon

([*source*](https://github.com/galaxyproject/gxadmin/search?q=filter_identicon&type=Code))
filter identicon -  Convert an input data stream into an identicon (e.g. with hostname)

**SYNOPSIS**

    gxadmin filter identicon

**NOTES**

Given an input data stream, digest it, and colour it using the same logic as digest-color

    $ echo test | ./gxadmin filter identicon
      ██████
    ██      ██
    ██  ██  ██
      ██████
    ██  ██  ██

(Imagine that it is a nice pink/blue colour scheme)


## filter pg2md

([*source*](https://github.com/galaxyproject/gxadmin/search?q=filter_pg2md&type=Code))
filter pg2md -  Convert postgres table format outputs to something that can be pasted as markdown

**SYNOPSIS**

    gxadmin filter pg2md

**NOTES**

Imagine doing something like:

    $ gxadmin query active-users 2018 | gxadmin filter pg2md
    unique_users  |        month
    ------------- | --------------------
    811           | 2018-12-01 00:00:00
    658           | 2018-11-01 00:00:00
    583           | 2018-10-01 00:00:00
    444           | 2018-09-01 00:00:00
    342           | 2018-08-01 00:00:00
    379           | 2018-07-01 00:00:00
    370           | 2018-06-01 00:00:00
    330           | 2018-05-01 00:00:00
    274           | 2018-04-01 00:00:00
    186           | 2018-03-01 00:00:00
    168           | 2018-02-01 00:00:00
    122           | 2018-01-01 00:00:00

and it should produce a nicely formatted table

