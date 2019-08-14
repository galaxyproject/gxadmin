filter_pg2md() { ## : Convert postgres table format outputs to something that can be pasted as markdown
	handle_help "$@" <<-EOF
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
	EOF
	cat | sed 's/--+--/- | -/g;s/^\(\s\+\)\([^|]\+\) |/\2 \1|/g' | head -n -2
}

filter_identicon(){ ## : Convert an input data stream into an identicon (e.g. with hostname)
	handle_help "$@" <<-EOF
		Given an input data stream, digest it, and colour it using the same logic as digest-color

		    $ echo test | ./gxadmin filter identicon
		      ██████
		    ██      ██
		    ██  ██  ██
		      ██████
		    ██  ██  ██

		(Imagine that it is a nice pink/blue colour scheme)
	EOF

	cat | python -c "$identicon_script"
}

filter_digest-color() { ## : Color an input stream based on the contents (e.g. hostname)
	handle_help "$@" <<-EOF
		Colors entire input stream based on digest of entire input's contents.
		Mostly useful for colouring a hostname or some similar value.

		    $ echo test | ./gxadmin filter digest-color
		    test

		(Imagine that it is light blue text on a pink background)

		**NOTE** If the output isn't coloured properly, try:

		    export TERM=screen-256color
	EOF

	data="$(cat)"
	fg_color=$((16#$(echo "$data" | perl -pe "chomp if eof" | sha256sum | cut -c1-2)))
	bg_color=$((fg_color + 15))

	echo "$(tput setaf $fg_color)$(tput setab $bg_color)${data}$(tput sgr0)"
}

filter_hexdecode() { ## : Deprecated, There is an easier built in postgres function for this same feature
	handle_help "$@" <<-EOF
		This automatically replaces any hex strings (\\x[a-f0-9]+) with their decoded versions. This can allow you to query galaxy metadata, decode it, and start processing it with JQ. Just pipe your query to it and it will replace it wherever it is found.

		    [galaxy@sn04 ~]$ psql -c  'select metadata from history_dataset_association limit 10;'
		                                 metadata
		    ------------------------------------------------------------------------------------------------------------------
		     \\x7b22646174615f6c696e6573223a206e756c6c2c202264626b6579223a205b223f225d2c202273657175656e636573223a206e756c6c7d
		     \\x7b22646174615f6c696e6573223a206e756c6c2c202264626b6579223a205b223f225d2c202273657175656e636573223a206e756c6c7d
		     \\x7b22646174615f6c696e6573223a206e756c6c2c202264626b6579223a205b223f225d2c202273657175656e636573223a206e756c6c7d
		     \\x7b22646174615f6c696e6573223a206e756c6c2c202264626b6579223a205b223f225d2c202273657175656e636573223a206e756c6c7d
		     \\x7b22646174615f6c696e6573223a206e756c6c2c202264626b6579223a205b223f225d2c202273657175656e636573223a206e756c6c7d
		     \\x7b22646174615f6c696e6573223a20333239312c202264626b6579223a205b223f225d2c202273657175656e636573223a20317d
		     \\x7b22646174615f6c696e6573223a20312c202264626b6579223a205b223f225d7d
		     \\x7b22646174615f6c696e6573223a20312c202264626b6579223a205b223f225d7d
		     \\x7b22646174615f6c696e6573223a20312c202264626b6579223a205b223f225d7d
		     \\x7b22646174615f6c696e6573223a20312c202264626b6579223a205b223f225d7d
		    (10 rows)

		    [galaxy@sn04 ~]$ psql -c  'select metadata from history_dataset_association limit 10;'  | gxadmin filter hexdecode
		                                 metadata
		    ------------------------------------------------------------------------------------------------------------------
		     {"data_lines": null, "dbkey": ["?"], "sequences": null}
		     {"data_lines": null, "dbkey": ["?"], "sequences": null}
		     {"data_lines": null, "dbkey": ["?"], "sequences": null}
		     {"data_lines": null, "dbkey": ["?"], "sequences": null}
		     {"data_lines": null, "dbkey": ["?"], "sequences": null}
		     {"data_lines": 3291, "dbkey": ["?"], "sequences": 1}
		     {"data_lines": 1, "dbkey": ["?"]}
		     {"data_lines": 1, "dbkey": ["?"]}
		     {"data_lines": 1, "dbkey": ["?"]}
		     {"data_lines": 1, "dbkey": ["?"]}
		    (10 rows)

		Or to query for the dbkeys uesd by datasets:

		    [galaxy@sn04 ~]$ psql -c  'copy (select metadata from history_dataset_association limit 1000) to stdout' | \\
		        gxadmin filter hexdecode | \\
		        jq -r '.dbkey[0]' 2>/dev/null | sort | uniq -c | sort -nr
		        768 ?
		        118 danRer7
		         18 hg19
		         17 mm10
		         13 mm9
		          4 dm3
		          1 TAIR10
		          1 hg38
		          1 ce10
	EOF

	cat | python -c "$hexdecodelines"
	warning "If you are still using this, consider updating your query to use: convert_from(your-column::bytea, 'UTF8')"
}
