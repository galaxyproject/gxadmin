# filter

Command | Description
------- | -----------
[`filter digest-color`](#filter-digest-color) | Color an input stream based on the contents (e.g. hostname)
`filter hexdecode` | Deprecated, There is an easier built in postgres function for this same feature
[`filter identicon`](#filter-identicon) | Convert an input data stream into an identicon (e.g. with hostname)
[`filter pg2md`](#filter-pg2md) | Convert postgres table format outputs to something that can be pasted as markdown

## filter digest-color

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


## filter identicon

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

