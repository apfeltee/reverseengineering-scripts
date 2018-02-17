
a set of small scripts that i use for everyday reverse engineering.
do not expect anything groundbreaking here! :-)

These are intended as a rough 'overview' - meaning, you won't necessarily
get a full conclusion of whatever file (or malware) you scan with them.

what's included:

- exestrings.rb

	Prints strings in a PE exe file, similar to what GNU strings does, except
	that, since windows stores text as two byte UTF-16 (i.e., "foo" => "f\0o\0o") it
	gets rid of the nulbytes. Not a pretty way to do it, but it works.

- grepstrings.rb

	Searches files for quote--enclosed strings, i.e. using grepstrings
	on `blah foo "zw0rk b0rk" honk quux` would print "zw0rk b0rk".
	Yes, it's just regular expressions. Can be useful for grepping logs.

- jsnice.rb

	Sends a chunk of uglified javascript to jsnice.org. Since jsnice.org doesn't really have an API,
	nor is their software actually open source, this is probably cheating, and I sincerely hope
	that their service remains free... because it's really darn useful!

- lddx.rb

	Uses the PEDump ruby gem to print imported DLLs.
	I wrote this as a replacement for cygwin's ldd.exe, since cygwin's ldd
	only works on executables that link against cygwin1.dll ...
	but PEDump is mostly system-agnostic, so this is a neat work-around.

- urldump.rb
 
	Deconstructs a large, ugly URL into its base components, and prints them.
	Mostly uses ruby's URL module, with a few tweaks for special cases.
	For example:

		Input:
			https://www.google.de/search?num=100&ei=dVGIWsP8IsWP0gX1466oCg&q=foo+bar+baz&oq=foo+bar+baz&gs_l=psy-ab.3..0l5.2203470.2205177.0.2205305.11.10.0.1.1.0.169.987.7j3.10.0....0...1c.1.64.psy-ab..0.11.984...0i131k1j0i67k1j0i131i67k1j0i10k1.0._ea3t3ss5w0

		Output:

			scheme     =>  "https"
			hostname   =>  "www.google.de"
			port       =>  443
			path       =>  "/search"
			query      =>  {
				"num" = "100"
				"ei" = "dVGIWsP8IsWP0gX1466oCg"
				"q" = "foo bar baz"
				"oq" = "foo bar baz"
				"gs_l" = "psy-ab.3..0l5.2203470.2205177.0.2205305.11.10.0.1.1.0.169.987.7j3.10.0....0...1c.1.64.psy-ab..0.11.984...0i131k1j0i67k1j0i131i67k1j0i10k1.0._ea3t3ss5w0"
			}

	Google is probably not the best example, but you get the idea.

- urlgrep.rb

	Searches files for embedded URIs. This uses ruby's builtin URI regexp, so while
	it's relatively slow, it's really useful to sometimes discover malware that
	phone home.
	In an attempt to somewhat improve speed, urlgrep will read files line-by-line, rather
	than reading the entire file at once, but improvements are very negligible.
	This will likely require a rewrite. Someday. Maybe.


License: Unless noted otherwise, it's GPLv3.
