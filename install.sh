#!/bin/bash

DOTFILES="$HOME/dotfiles"

link() {
    local src="$DOTFILES/$1"
    local dst="$HOME/$1"

    mkdir -p "$(dirname "$dst")"
    ln -sf "$src" "$dst"
    echo "Linked $1"
}

link ".config/hypr"
link ".vimrc"

echo "Done!"
