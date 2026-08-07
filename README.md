# dotfiles

Personal configuration files for macOS and Linux.

## Install

```sh
git clone https://github.com/nonya123456/dotfiles ~/dotfiles
cd ~/dotfiles
./install.sh
```

The install script symlinks configs into `$HOME`.

## Dependencies

### Neovim

- [`tree-sitter`](https://github.com/tree-sitter/tree-sitter) CLI

### GDScript (optional)

- [GDScript-formatter](https://github.com/GDQuest/GDScript-formatter) — install and add to `$PATH` for format-on-save in `.gd` files
- Godot must be running with the project open for LSP features (connects to `localhost:6005`)

## NixOS

```
sudo nixos-rebuild switch --flake .#nonya
```

or

```
rebuild
```
