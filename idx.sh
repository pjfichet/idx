#!/bin/sh

# idx: simple tool to build indexes.
#
# Copyright (C) 2012-2018 Pierre Jean Fichet
# <pierrejean dot fichet at posteo dot net>
# 
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
# 
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

# printhelp
# print short usage
printhelp() {
echo -e "\033[1midx\033[0m: Format an index of words.

\033[1mUsage\033[0m:
    \033[1midx\033[0m [\033[1m-dhprtw\033[0m] \033[1mfile\033[0m

\033[1mOptions\033[0m:
default:			From troff output to troff input.
\033[1m-d\033[0m    From troff output to troff input, by deleting \\004.
\033[1m-h\033[0m    Print this help.
\033[1m-m\033[0m    Mix all lines.
\033[1m-p\033[0m    From a list of words to a list of page.
\033[1m-r\033[0m    Reformat a list of words (fix errors).
\033[1m-t\033[0m    From a list of pages to troff input.
\033[1m-w\033[0m    From a list of page to a list of words.

\033[1mFormats\033[0m:
List of words     word:: page[, page [, page-page]]
List of pages     page:: word[, word]
Troff output      key> word:: page
Troff input:
    .K<           \\\" one letter keyword defining the index
    .ds <P x, m-n \\\" list of pages
    .K> word word \\\" list of words to index

See idx(1) for a more complete description."
}


# sortwords
# sort a list of words
# Sort file by 1) words, 2) pages.
# sep is ":: " so, use first and third field
sortwords() {
	# -u: unique, -t: field separator,
	# -f: ignore case, -V numeric version order
	# -n numeric order
	#sort -t: -k 1,1f -k 3,3V $1
	sort -t: -k 1,1f -k 3,3n $1

}

# sortpages
# sort a list of pages
# Sort file by 1) page, 2) word.
# sep is ":: " so, use first and third field
sortpages() {
	#sort -t: -k 1,1V -k 3,3f $1
	sort -t: -k 1,1n -k 3,3f $1

}

# invertfields
# expand second field, and print it before the first one
# input:	"xxx:: yyy[, zzz]"
# output:	"yyy:: xxx\n[zzz:: xxx]"
# With:
# words: array of indexed words
invertfields() {
awk '
BEGIN {FS = ":: "}
{
	split($2, words, ", ");
	for( i in words) { printf("%s:: %s\n", words[i], $1)};
}
END {}
' $*
}

# catpages
# concatenate pages
# input: "word:: page[\nword: page]"
# output "word:: page[, page [, page-page]]"
# Concatenate following pages if needed.
# With:
# term = previous list of words;
# p = number of previous page;
# f = - if it must concatenate list of pages;
# r = 1 if it must print a \n (not on first line).
catpages() {
awk '
BEGIN { FS = OFS = ":: " }
	$1 != term { if (f=="-") {printf("-%i", p); f=0};
				if (r==1) {printf("\n")}; r=1;
				printf("%s:: ", $1); term=$1; p="99999"}
	$2 < p { if (p!=99999) {printf(", ")};
			printf("%i", $2); p=$2 }
	$2 == p+1 { f="-"; p=$2 }
	$2 > p+1 { if (f=="-") {printf("-%i", p); f=0};
				printf(", %i", $2); p=$2 }
END {
	if (f=="-") {printf("-%i", p); f=0};
	printf("\n")
}
' $*
}

# catwords
# concatenate words
# input: "page:: word[\npage:: word]"
# output "page:: word[, word]"
# page = previous page;
# r = 1 if it must print a \n (not on first line).
catwords() {
awk '
BEGIN { FS = OFS = ":: " }
	$1 == page { printf(", %s", $2) }
	$1 != page { if (r==1) {printf("\n")}; r=1;
				printf("%s:: %s", $1, $2);  page=$1; }
END { printf("\n") }
' $*
}

# splitpages
# expand second field on different lines
# input: "word:: page[, page]"
# output: word:: page[\nword: page]"
# With:
# $1: word, pages: array of pages,
# array: split continuous pages (3-7).
splitpages() {
awk '
BEGIN { FS = OFS = ":: " }
{
	split($2, pages, ", ");
	for( i in pages) {
		split(pages[i], array, "-");
		if(array[2]) {
			for(j=array[1]; j <= array[2]; j++) {
				printf("%s:: %s\n", $1, j);
			}
		}
		else { printf("%s:: %s\n", $1, array[1]) }
	}
}
END {}
' $*
}

# catlines
# mix all entries in a single line,
# even if they don't have the same keyword
# input: list of lines
# output: single line
catlines() {
awk '
BEGIN { FS = OFS = ":: " }
{
	printf( "mixed:: %s\n", $2);
}
END {}
' $*
}


# addkeys
# insert a key at the begining of the line
# if there's none.
# input: "word:: page[, page]"
# output: "X> word:: page[, page]"
addkeys() {
awk '
BEGIN {FS = "> "}
{
	if ($2) { printf ("%s> %s\n", $1, $2) }
	else { printf ("X> %s\n", $1) }
}
END {}
' $*
}

# totroff 
# output to troff
# input: "word:: page[, page]"
# output: troff idx format
# With:
# idx: actual index;
totroff() {
awk '
BEGIN {FS = ":: "}
{
if ($1 != "" ) {
	split($1, macro, "> ");
	if (macro[1]!=idx) {printf(".\n.%s<\n", macro[1]); idx=macro[1]}
	printf(".\n.ds <P %s\n", $2);
	printf(".%s> %s\n", macro[1], macro[2]);
}
}
END {}
' $*
}

# look for args
# -d from troff output to troff format (default)
# -h print help
# -m mix lines
# -p from list of words to list of pages
# -r reformat a list of words
# -t from list of words to troff format
# -w from list of page to list of words
case "$1" in

	# to troff, by deleting \004
	# input: troff output
	# output: troff format
	"-d") tr -d '\004' < $2 | sortwords | catpages | totroff ;;

	# print help
	"-h") printhelp ;;

	# mix lines
	"-m") catlines $2 | splitpages | sortwords | catpages ;;

	# to page
	# input: list of words
	# output: list of pages
	"-p") splitpages $2 | invertfields | sortpages | catwords ;;

	# reformat
	# input: list of words
	# output: list of words
	"-r") splitpages $2 | sortwords | catpages ;;

	# to troff
	# input: list of words
	# output: troff format
	"-t") addkeys $2 | splitpages | sortwords | catpages | totroff ;;

	# to words
	# input: list of pages
	# output: list of words
	"-w") invertfields $2 | sortwords | catpages ;;

	# default
	# input: troff output
	# output: troff format
	*) sortwords $1 | catpages | totroff ;;
esac

