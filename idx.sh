#!/bin/sh

# idx
# simple tool to build indexes.

# helper
# print short usage
helper() {
echo -e "\033[1midx\033[0m: Format an index of words.

\033[1mUsage\033[0m:
    \033[1midx\033[0m [\033[1m-dhprtw\033[0m] \033[1mfile\033[0m

\033[1mOptions\033[0m:
\033[1m-d\033[0m    From troff output to troff input (default).
\033[1m-h\033[0m    Print this help.
\033[1m-p\033[0m    From a list of words to a list of page.
\033[1m-r\033[0m    Reformat a list of words (fix errors).
\033[1m-t\033[0m    From a list of pages to troff input.
\033[1m-w\033[0m    From a list of page to a list of words.

\033[1mFormats\033[0m:
List of words     word: page[, page [, page-page]]
List of pages     page: word[, word]
Troff output      key> word: page
Troff input:
    .K<           \\\" one letter keyword defining the index
    .ds <P x, m-n \\\" list of pages
    .K> word word \\\" list of words to index

See idx(1) for a more complete description."
}

#troff output format

# wordsorter
# sort a list of words
# Sort file by 1) words, 2) pages.
wordsorter() {
	# -u: unique, -t: field separator,
	# -f: ignore case, -V numeric order
	#/usr/bin/sort -u -V $1
	#/usr/bin/sort -u -V -f $1
	/usr/bin/sort -t : -k 1,1f -k 2,2V $1
}

# pagesorter
# sort a list of pages
# Sort file by 1) page, 2) word.
pagesorter() {
	/usr/bin/sort -t : -k 1,1V -k 2,2f $1
}

# reverser
# expand second field, and print it before the first one
# input:	"page: word[, word]"
# output:	"word: page\n[word: page]"
# With:
# words: array of indexed words
reverser() {
/usr/bin/awk '
BEGIN {FS = ": "}
{
	split($2, words, ", ");
	for( i in words) { printf("%s: %s\n", words[i], $1)};
}
END {}
' $*
}

# pager
# concatenate pages
# input: "word: page[\nword: page]"
# output "word: page[, page [, page-page]]"
# Concatenate following pages if needed.
# With:
# term = previous list of words;
# p = number of previous page;
# f = - if it must concatenate list of pages;
# r = 1 if it must print a \n (not on first line).
pager() {
/usr/bin/awk '
BEGIN { FS = OFS = ": " }
	$1 != term { if (f=="-") {printf("-%i", p); f=0};
				if (r==1) {printf("\n")}; r=1;
				printf("%s: ", $1); term=$1; p="99999"}
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

# worder
# concatenate words
# input: "page: word[\page: word]"
# output "page: word[, word]"
# page = previous page;
# r = 1 if it must print a \n (not on first line).
worder() {
/usr/bin/awk '
BEGIN { FS = OFS = ": " }
	$1 == page { printf(", %s", $2) }
	$1 != page { if (r==1) {printf("\n")}; r=1;
				printf("%s: %s", $1, $2);  page=$1; }
END { printf("\n") }
' $*
}

# expander
# expand second field on different lines
# input: "word: page[, page]"
# output: word: page[\nword: page]"
# With:
# $1: word, pages: array of pages,
# array: split continuous pages (3-7).
expander() {
/usr/bin/awk '
BEGIN { FS = OFS = ": " }
{
	split($2, pages, ", ");
	for( i in pages) {
		split(pages[i], array, "-");
		if(array[2]) {
			for(j=array[1]; j <= array[2]; j++) {
				printf("%s: %s\n", $1, j);
			}
		}
		else { printf("%s: %s\n", $1, array[1]) }
	}
}
END {}
' $*
}

# keyer
# insert a key at the begining of the line
# if there's none.
# input: "word: page[, page]"
# output: "X> word: page[, page]"
keyer() {
/usr/bin/awk '
BEGIN {FS = "> "}
{
	if ($2) { printf ("%s> %s\n", $1, $2) }
	else { printf ("X> %s\n", $1) }
}
END {}
' $*
}

# troffer 
# output to troff
# input: "word: page[, page]"
# output: troff idx format
# With:
# idx: actual index;
troffer() {
/usr/bin/awk '
BEGIN {FS = ": "}
{
	split($1, macro, "> ");
	if (macro[1]!=idx) {printf(".\n.%s<\n", macro[1]); idx=macro[1]}
	printf(".\n.ds <P %s\n", $2);
	printf(".%s> %s\n", macro[1], macro[2]);
}
END {}
' $*
}

# look for args
# -d from troff output to troff format (default)
# -h help
# -p from list of words to list of pages
# -r reformat a list of words
# -t from list of words to troff format
# -w from list of page to list of words
if [ "$1" == "-d" ]; then
	# default
	# input: troff output
	# output: troff format
	wordsorter $2 | pager | troffer
elif [ "$1" == "-h" ]; then
	# print help
	helper
elif [ "$1" == "-p" ]; then
	# to page
	# input: list of words
	# output: list of pages
	#pager $2 | wordsorter #| pager
	expander $2 | reverser | pagesorter | worder
elif [ "$1" == "-r" ]; then
	# reformat
	# input: list of words
	# output: list of words
	expander $2 | wordsorter | pager
elif [ "$1" == "-t" ]; then
	# to troff
	# input: list of words
	# output: troff format
	keyer $2 | expander | wordsorter | pager | troffer
elif [ "$1" == "-w" ]; then
	# to words
	# input: list of pages
	# output: list of words
	reverser $2 | wordsorter | pager
else
	# default
	# input: troff output
	# output: troff format
	wordsorter $1 | pager | troffer
fi

