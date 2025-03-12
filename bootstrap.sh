# ---------------------------------------------------------------
# The activation script here is responsible for bootstrapping the
# requirements for activating our base development environment as
# a virtual environment.
# ---------------------------------------------------------------

# save the path to our dotfiles
DOTFILES="${PWD}/dotfiles"

# clone the target dotfiles directory
if [ ! -d "./dotfiles" ]; then
    git clone $DOTFILES_URL "dotfiles"
fi

# query out our system's info
os_name=$(uname -s)
architecture=$(uname -m)
# save the os-architecture name
OS_ARCHITECTURE="${os_name}-${architecture}"
# check operating system
case "$os_name" in
"Darwin")
    echo "Operating System: macOS (Darwin)"
    OS_VALID=true
    ;;
"Linux")
    echo "Operating System: Linux"
    OS_VALID=true
    ;;
*)
    echo "Operating System: Unknown"
    OS_VALID=false
    ;;
esac
# check architecture
case "$architecture" in
x86_64)
    echo "System architecture: x86_64"
    ARCHITECTURE_VALID=true
    ;;
aarch64)
    echo "System architecture: aarch64"
    ARCHITECTURE_VALID=true
    ;;
*)
    echo "System architecture: Unknown ($architecture)"
    ARCHITECTURE_VALID=false
    ;;
esac

if ! ($OS_VALID && $ARCHITECTURE_VALID); then
    echo "Invalid system: ${OS_ARCHITECTURE}, exiting the environment.";
    exit
fi

echo "Identified system as ${OS_ARCHITECTURE}."

# check if we are in a wsl instance
if [ -v WSL_DISTRO_NAME ]; then
    WSL='true'
    echo "Identified as WSL"
else
    WSL='false'
fi

# Set the flox HOME to keep the user space clean
# The HOME directory of our dev environment
VENV_HOME="${PWD}/dotfiles/.flox/lib/${USER}"
# The .bashrc file that we edit to update the environment (will be automatically on next start)
ORIGINAL_BASHRC=$PWD/dotfiles/.flox/env/.bashrc
# Location of the dev env's .bashrc file
BASHRC=$VENV_HOME/.bashrc
# Files used to choose what variables get forwarded to the dev env
VARIABLES_FILE=$VENV_HOME/.variables
# Var for a local bin for the flox env
LOCAL_FLOX_BIN=$VENV_HOME/.local/bin

# if the modtime of our venv's .bashrc file is newer than the file we
# currently have, then replace the file. this allows us to edit the
# .bashrc file in version control and proliferate these changes across 
# machines. This means that when we want to update the .bashrc file, then
# we should make these changes to the file in the '.flox/env' directory.
# NOTE: for dependencies like conda that requires altering the .bashrc
# file, the installation process will have to rerun in nested environments.
# Unfortuneately, this is something we cannot work around here, but could
# be handled in the nested flox environments with a basic cache and check.
# It would be even better to somehow refer the install to another bash file
# that could be sourced independently of this .bashrc file.
if [ -f $BASHRC ]; then
    if [ "$ORIGINAL_BASHRC" -nt "$BASHRC" ]; then
        rm $BASHRC
        rm $VARIABLES_FILE
    fi
fi
# We need to include the flox dev bin and sbin in the PATH
FLOX_TARGET="${architecture}-${os_name,,}"
FLOX_DEV="${PWD}/dotfiles/.flox/run/${FLOX_TARGET}.dotfiles.dev"
FLOX_BIN=$FLOX_DEV/bin
FLOX_SBIN=$FLOX_DEV/sbin

# Get the PATH to our flox executable
FLOX_PATH="${LOCAL_FLOX_BIN}:${FLOX_BIN}:${FLOX_SBIN}" #:/usr/sbin:/usr/bin

# if the HOME's .bashrc file does not exist, then we run the bootstrap
if [ ! -f $BASHRC ]; then
    mkdir -p $VENV_HOME
    mkdir -p $VENV_HOME/.local

    # Make the bin path if it doesn't exist
    mkdir -p $LOCAL_FLOX_BIN
    
    # Make the expected default XDG Base Directory Specification paths
    # https://specifications.freedesktop.org/basedir-spec/latest/
    mkdir -p $VENV_HOME/.local/share # -> make $XDG_DATA_HOME
    mkdir -p $VENV_HOME/.config # -> $XDG_CONFIG_HOME
    mkdir -p $VENV_HOME/.local/state # -> $XDG_STATE_HOME
    mkdir -p $VENV_HOME/.cache # -> $XDG_CACHE_HOME
    # Create and set the $XDG_RUNTIME_DIR
    XDG_RT_DIR=$VENV_HOME/runtime
    mkdir -p $XDG_RT_DIR
    chmod 700 $XDG_RT_DIR 

    # Create a variables file for the new .bashrc to source to pass over
    # the flox path and set the HOME directory and XDG_RUNTIME_DIR
    touch $VARIABLES_FILE
    echo "export LC_ALL=C" >> $VARIABLES_FILE
    echo "export USER=${USER}" >> $VARIABLES_FILE
    echo "export HOME=${VENV_HOME}" >> $VARIABLES_FILE
    echo "export PATH=${FLOX_PATH}" >> $VARIABLES_FILE
    echo "export XDG_RUNTIME_DIR=${XDG_RT_DIR}" >> $VARIABLES_FILE
    echo "export OS_NAME=${os_name}" >> $VARIABLES_FILE
    echo "export OS_ARCHITECTURE=${OS_ARCHITECTURE}" >> $VARIABLES_FILE
    echo "export ARCHITECTURE=${architecture}" >> $VARIABLES_FILE
    echo "export FLOX_TARGET=${FLOX_TARGET}" >> $VARIABLES_FILE
    echo "export WSL=${WSL}" >> $VARIABLES_FILE
    echo "export DOTFILES=${DOTFILES}" >> $VARIABLES_FILE
    echo "export BASE_HOME=${HOME}" >> $VARIABLES_FILE
    # Copy over the .bashrc file
    cp "$ORIGINAL_BASHRC" "$VENV_HOME"
fi

# if a bootstrap has already been run for this system, we skip execution
BS_LOCK="$PWD/bs.lock"
if [ -f "$BS_LOCK" ]; then
    echo "Bootstrap has already been executed. Delete the bs.lock file to re-run."
else
    # install any extensions specified by the dotfiles
    source "./dotfiles/extensions.sh"

    # Create the bs.lock file to signify the bootstrap has already taken place
    touch "$BS_LOCK"
fi 