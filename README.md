# My Dev Environment Core

This repo exists as a simple and extensible core bit of functionality that I use to bootstrap my development environment onto new machines.

This simply needs to be cloned and have the `DOTFILES` environment varibale set followed by executing the `bootstrap.sh` script to bootstrap given the dotfiles provided.

The base assumption is that the dotfiles repository will contain a `.flox` directory where that will be activated as part of executing the `start.sh script.

The dotfiles repository should also include an `extensions.sh` directory to perform any specific bootstrap steps for that dotfiles env.
