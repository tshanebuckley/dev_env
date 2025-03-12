# bootstrap the environment
source bootstrap.sh

# activate the dev environment
cd ./dotfiles
eval "$(flox activate)"
#flox activate