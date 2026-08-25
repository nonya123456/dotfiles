#!/bin/bash

DOTFILES="$HOME/dotfiles"

# link <src> [dst]
link() {
    local src="$DOTFILES/$1"
    local dst="$HOME/${2:-$1}"
    local dir
    dir="$(dirname "$dst")"

    if [ -L "$dir" ]; then
        rm -f "$dir"
    fi

    mkdir -p "$dir"
    rm -rf "$dst"
    ln -sfn "$src" "$dst"
    echo "Linked ${2:-$1}"
}

case "$(uname -s)" in
    Darwin*)
        link ".config/alacritty/darwin" ".config/alacritty"
        link ".config/kitty"
        link ".config/ghostty"
        link ".config/nvim"
        link ".config/tmux"
        link ".vimrc"
        link ".claude/skills"
        ;;
    Linux*)
        link ".config/alacritty/linux" ".config/alacritty"
        link ".config/kitty"
        link ".config/ghostty"
        link ".config/nvim"
        link ".config/tmux"
        link ".vimrc"
        link ".claude/skills"
        ;;
esac

echo "Done!"
