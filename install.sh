#!/bin/bash

DOTFILES="$HOME/dotfiles"

link() {
    local src="$DOTFILES/$1"
    local dst="$HOME/$1"

    mkdir -p "$(dirname "$dst")"
    rm -rf "$dst"
    ln -sf "$src" "$dst"
    echo "Linked $1"
}

link ".config/hypr"
link ".config/ghostty"
link ".config/nvim"
link ".config/fontconfig"
link ".vimrc"

echo "Done!"
