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
        link ".config/alacritty"
        link ".config/ghostty"
        link ".config/nvim"
        link ".config/tmux"
        link ".vimrc"
        link ".claude/skills"
        link ".config/opencode/skills"
        ;;
    Linux*)
        link ".config/alacritty"
        link ".config/hypr"
        link ".config/waybar"
        link ".config/fontconfig"
        link ".config/ghostty"
        link ".config/nvim"
        link ".config/tmux"
        link ".vimrc"
        link ".claude/skills"
        link ".config/opencode/skills"
        ;;
esac

echo "Done!"
