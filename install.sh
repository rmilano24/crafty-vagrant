#!/bin/bash

##
##  This install script handles everything that Crafty Vagrant needs on the
##  local machine. Puppet handles everything on the Vagrant box.
##

## Colours for prettier output + to distinguish this script's output:
color='\033[1;36m';   # Light cyan
NC='\033[0m';     # No color

## Function to prompt for user response:
prompt () {
    while true; do
      echo;
        read -p "$1" yn
        case $yn in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Please answer yes or no.";;
        esac
    done
}

## output in colour:
echo_color() {
  echo -e "${color}$1${NC}";
}

if ! prompt "Do you wish to install Crafty Vagrant? [yn] "; then
  echo_color 'Ok. Install cancelled.';
  exit;
fi

## If Craft isn't present:
if [ ! -d "app/craft" ]; then
  ## Install it!
  bash puppet/makeItCraft.sh
fi

## Install node modules:
echo_color "
## npm install";
npm install;

## Initialise Git submodules:
echo_color "
## git submodule init && git submodule update";
git submodule init && git submodule update;

## Set up Craft stuff:
echo_color "
## Setting up Craft...";

## Activate the htaccess (rename 'htaccess' --> '.htaccess'):
if [ -f "app/public/htaccess" ]; then
  echo "## Activating htaccess...";
  mv app/public/htaccess app/public/.htaccess;
fi

## Replace the default templates + config:
CRAFT_SRC="app/src/craft";

if [ -d $CRAFT_SRC ] && prompt "Replace Craft's default templates + config? [yn] "; then
  echo "Replacing Craft files... (copying from ${CRAFT_SRC})";

  ## Remove existing remplates, if present:
  [ -d "app/craft/templates" ] && rm -r app/craft/templates;

  ## Copy everything from app/src/craft to the app/craft directory,
  ## overwriting existing files:
  cp -R $CRAFT_SRC app;
fi

## Run Grunt, to render CSS / Javascript / etc:
echo_color "
## grunt";
grunt;

## Create the storage/runtime directory for Craft
## (to prevent a PHP error on first visit to craft.dev)
DIR="app/craft/storage/runtime";
if [ ! -f $DIR/.gitignore ]; then
  mkdir -p $DIR/{cache,compiled_templates,logs};
  touch "$DIR/.gitignore";
  touch "$DIR/logs/craft.log";
fi

echo_color "
## Finished!
##
## 'vagrant up' to start the server.
## 'grunt watch' to watch Sass + JS for changes.
##
## If this is a new install, you'll need to install Craft at http://craft.dev/admin/install";
