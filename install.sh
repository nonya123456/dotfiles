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

case "$(uname -s)" in
    Darwin*)
        link ".config/ghostty"
        link ".config/nvim"
        link ".config/tmux"
        link ".vimrc"
        ;;
    Linux*)
        link ".config/hypr"
        link ".config/fontconfig"
        link ".config/ghostty"
        link ".config/nvim"
        link ".config/tmux"
        link ".vimrc"
        ;;
esac

echo "Done!"
