#!/bin/sh

# input format
helper() {
echo -e "\033[1midx\033[0m: Format an index of words.

\033[1mUsage\033[0m:
    \033[1midx\033[0m [\033[1m-dhprt\033[0m] \033[1mfile\033[0m

\033[1mOptions\033[0m:
\033[1m-d\033[0m    Format from troff output to troff input (default).
\033[1m-h\033[0m    Print this help.
\033[1m-p\033[0m    Format an index from a list of pages.
\033[1m-r\033[0m    Reformat a formatted index (fix errors).
\033[1m-t\033[0m    Format from a list of pages to troff input.

\033[1mFormats\033[0m:
Formatted index   word: page[, page]
List of pages     page: word[, word]
Troff output      word: page
Troff input       a list of macros

See idx(1) for a more complete description."
}

#echo '
#troff output format
#.K< \" one letter keyword defining the index
#.<L n N \" first letter of following indexed words
#.<- \" begin entry
#.	ds <1 word	\" word 1
#.	ds <2 word	\" word 2
#.	ds <n word	\" word n
#.	nr <N x		\" number of words
#.	ds <P y		\" list of pages
#.K>	\" close entry
# '


# Sort file by 1) words, 2) pages.
sorter() {
	# -u: unique, -t: field separator,
	# -f: ignore case, -V numeric order
	#/usr/bin/sort -u -V $1
	#/usr/bin/sort -u -V -f $1
	/usr/bin/sort -t : -k 1,1f -k 2,2V $1
}

# spliter:
# input:	"page: word[, word]"
# output:	"word: page\n[word: page]"
# With:
# words: array of indexed words
spliter() {
/usr/bin/awk '
BEGIN {FS = ": "}
{
	split($2, words, ", ");
	for( i in words) { printf("%s: %s\n", words[i], $1)};
}
END {}
' $*
}

# oneliner
# input: "word: page[\nword: page]"
# output "word: page[, page]"
# Concatenate following pages if needed.
# With:
# term = previous list of words;
# p = number of previous page;
# f = - if it must concatenate list of pages;
# r = 1 if it must print a \n (not on first line).
oneliner() {
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


# deindexer
# input: "word: page[, page]"
# output: word: page[\nword: page]"
# With:
# $1: word, pages: array of pages,
# array: split continuous pages (3-7).
deindexer() {
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

# troffer 
# input: "word: page[, page]"
# output: troff idx format
# With:
# idx: actual index;
troffer() {
/usr/bin/awk '
BEGIN {FS = ": "}
{
	split($1, macro, "> ");
	if (macro[1]!=idx) {printf(".%s<\n", macro[1]); idx=macro[1]}
	printf(".<-\n");
	split(macro[2], entry, ", ");
		for (i in entry) {printf(".	ds <%i %s\n", i, entry[i])};
	printf(".	nr <N %i\n", i);
	printf(".	ds <P %s\n", $2);
	printf(".%s>\n", idx);
}
END {}
' $*
}

if [ "$1" == "-d" ]; then
	# default
	# input: troff output
	# output: troff format
	sorter $2 | oneliner | troffer
elif [ "$1" == "-h" ]; then
	# print help
	helper
elif [ "$1" == "-p" ]; then
	# from pages
	# input: handmade list of pages
	# output: formatted index
	spliter $2 | sorter | oneliner
elif [ "$1" == "-r" ]; then
	# reformat
	# input: formatted index
	# output: formatted index
	deindexer $2 | sorter | oneliner
elif [ "$1" == "-t" ]; then
	# to troff
	# input: manual list of pages
	# output: troff format
	spliter $2 | sorter | oneliner | troffer
else
	# default
	# input: troff output
	# output: troff format
	sorter $1 | oneliner | troffer
fi

