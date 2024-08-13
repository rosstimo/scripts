#!/bin/bash
#take a file same from standard input and compile it with pdflatex in batch mode

file=$(readlink -f "$1")
dir=${file%/*}
base="${file%.*}"
ext="${file##*.}"

# Check if the file exists
if [ ! -f "$file" ]; then
   # echo "File '$file' does not exist."
  exit 1
fi

cd "$dir" || exit 1
# echo "Compiling '$file' in '$dir'"
# echo "Running pdflatex on '$base'"
#run pdflatex in batch mode
pdflatex -interaction=batchmode --output-directory="$dir" "$base"  > /dev/null

# added delay between the double compile to wait for table of contents file .toc - Tim
#wait for 250ms 
sleep 0.25
#if there is a .bcf file in the directory then run biber on it
if [ -f "$base".bcf ]; then
  # echo "Running biber on '$base'"
  biber --output-directory "$dir" "$base" > /dev/null
fi
#wait for 250ms
sleep 0.25
#run pdflatex again in batch mode
# echo "Running pdflatex on '$base'"
# pdflatex -interaction=batchmode -recorder -file-line-error --output-directory="$dir" "$base" > /dev/null
pdflatex -interaction=batchmode --output-directory="$dir" "$base"  > /dev/null

