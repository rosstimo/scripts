#!/bin/sh

conf="/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME"

# clone the repository
git clone --bare https://github.com/rosstimo/dotfiles.git "$HOME"/.dotfiles

# if any files will be overwritten append the file names with '~'
$conf checkout 2>&1 | \
grep -E "\s+\." | \
awk \{'print $1'\} | \
xargs -pr -I{} mv {} {}~

# verify checkout
$conf checkout

# don't display untracked files
$conf config --local status.showUntrackedFiles no