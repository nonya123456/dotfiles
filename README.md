# dotfiles

Personal configuration files for macOS and Linux.

## Install

```sh
git clone https://github.com/nonya123456/dotfiles ~/dotfiles
cd ~/dotfiles
./install.sh
```

The install script symlinks configs into `$HOME`.

## vscode

```sh
ln -sf ~/dotfiles/vscode/settings.json ~/Library/Application\ Support/Code/User/settings.json
ln -sf ~/dotfiles/vscode/keybindings.json ~/Library/Application\ Support/Code/User/keybindings.json
```

## Skills

Install the skills in `skills/` with [`skills`](https://github.com/vercel-labs/skills):

```sh
npx skills add nonya123456/dotfiles -g
```

## Dependencies

### Neovim

- [`tree-sitter`](https://github.com/tree-sitter/tree-sitter) CLI

### GDScript (optional)

- [GDScript-formatter](https://github.com/GDQuest/GDScript-formatter) — install and add to `$PATH` for format-on-save in `.gd` files
- Godot must be running with the project open for LSP features (connects to `localhost:6005`)
