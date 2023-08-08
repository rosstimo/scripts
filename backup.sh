#!/bin/sh

# posix complient shell script to take a list of file paths from the standard input 
# and copy them to the same path and file name but with `~' appended to the end of the file name.

usage()
{
	echo "usage: $0 [-f] [-m]"
	echo "       $0 [-f] [-m] < file"
	echo "       $0 [-f] [-m] file1 file2 ..."
}

# -f to force overwrite.
# -m to move instead of copy.
force=
move=
while getopts "fm" opt; do
	case "$opt" in
		f) force=1 ;;
		m) move=1 ;;
		*) usage; exit 1 ;;
	esac
done

shift $((OPTIND - 1))

if [ $# -eq 0 ]; then
	files=$(cat -)
else
	files=$@
fi

if [ -n "$move" ]; then
	cmd=mv
else
	cmd=cp
fi

if [ -n "$force" ]; then
	cmd="$cmd -f"
fi

for file in $files; do
	$cmd "$file" "$file~"
done
