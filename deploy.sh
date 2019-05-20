#!/bin/bash

# This file is part of deployWWW (https://github.com/U8NWXD/deployWWW).
# You may not use this file except in compliance with the license in
# LICENSE.txt, which can be found at the project link above. This
# project comes with ABSOLUTELY NO WARRANTY. See LICENSE.txt for
# details.

# abort on errors
set -e

# Set Constants
GITHUBREMOTE=""
SUHOST="myth.stanford.edu"
REMOTE_WWW="~/WWW/site"
REMOTE_REPO="~/Documents/git_hosted/site.git"
BUILD_DIR=_site

print_help() {
    echo "Usage: deploy.sh [-h] (-g username [-t] | -s sunet [-r repo_dir] [-w www_path] | -k keybase_username) [-b build_dir]"
    echo "  -g: Use GitHub Pages"
    echo "  -s: Use Stanford AFS Web Hosting"
    echo "  -t: Use HTTPS to connect to GitHub repository"
    echo "  -r: Store the remote repository at the specified path"
    echo "  -w: Put the compiled HTML files at the specified path"
    echo "  -k: Host in Keybase public folder"
    echo "  -b: Get the built website from the specified path"
}

TYPE=""  # Can be github, suafs, or keybase
USE_SSH=true

while getopts ":hg:ts:r:w:k:b:" opt; do
    case $opt in
        g)
            TYPE="github"
            USERNAME=$OPTARG
            ;;
        s)
            TYPE="suafs"
            USERNAME=$OPTARG
            ;;
        k)
            TYPE="keybase"
            USERNAME=$OPTARG
            ;;
        r)
            if [ $TYPE != "suafs" ]; then
                echo "Option -r only valid when using Stanford AFS"
                print_help
                exit 1
            fi
            REMOTE_REPO=$OPTARG
            ;;
        w)
            if [ $TYPE != "suafs" ]; then
                echo "Option -w only valid when using Stanford AFS"
                print_help
                exit 1
            fi
            REMOTE_WWW=$OPTARG
            ;;
        b)
            BUILD_DIR=$OPTARG
            ;;
        t)
            if [ $TYPE != "github" ]; then
                echo "Option -t only valid when using GitHub Pages"
                print_help
                exit 1
            fi
            USE_SSH=false
            ;;
        h)
            print_help
            exit 0
            ;;
        \?)
            echo "Invalid Option: -$OPTARG"
            print_help
            exit 1
            ;;
        :)
            echo "Option -$OPTARG requires an argument"
            print_help
            exit 1
            ;;
    esac
done

if [ $TYPE == "" ]; then
    echo "You must choose a hosting option."
    print_help
    exit 1
fi

USERNAME=$(echo "$USERNAME" | tr '[:upper:]' '[:lower:]')

if [ $TYPE == "github" ]; then
    if $USE_SSH; then
        GITHUBREMOTE="git@github.com:$USERNAME/$USERNAME.github.io.git"
    else
        GITHUBREMOTE="https://github.com/$USERNAME/$USERNAME.github.io.git"
    fi
    # Jekyll needs a base url in the config file so the paths work
    BASE_URL=${GITHUBREMOTE##*/}
    BASE_URL="https://${BASE_URL%.*}"
elif [ $TYPE == "suafs" ]; then
    BASE_URL="https://www.stanford.edu/~$USERNAME/site"
elif [ $TYPE == "keybase" ]; then
    BASE_URL="https://$USERNAME.keybase.pub"
else
    echo "You must select a remote host."
    print_help
    exit 1
fi

# Insert the base url into the config file
# How to escape BASE_URL: https://unix.stackexchange.com/a/265269
sed -i ".bak" -e "s/baseurl: null/baseurl: ${BASE_URL//\//\\/}/g" _config.yml

# Build HTML
jekyll build

# Restore the original config file
mv _config.yml.bak _config.yml

git -C "$BUILD_DIR" init
git -C "$BUILD_DIR" add -A
git -C "$BUILD_DIR" commit --no-gpg-sign -m 'deploy'

if [ $TYPE == "github" ]; then
    git -C "$BUILD_DIR" push -f "$GITHUBREMOTE" master:master
elif [ $TYPE == "suafs" ]; then
    # Create git repo if it doesn't already exist
    if ! ssh -l "$USERNAME" "$SUHOST" ls "$REMOTE_REPO" >/dev/null 2>&1; then
        ssh -l "$USERNAME" "$SUHOST" mkdir -p "$REMOTE_REPO"
        ssh -l "$USERNAME" "$SUHOST" git init --bare "$REMOTE_REPO"
    fi
    # Clone git repo if it hasn't already been cloned
    if ! ssh -l "$USERNAME" "$SUHOST" ls "$REMOTE_WWW" >/dev/null 2>&1; then
        ssh -l "$USERNAME" "$SUHOST" mkdir -p "$REMOTE_WWW"
        ssh -l "$USERNAME" "$SUHOST" git clone "$REMOTE_REPO" "$REMOTE_WWW"
    fi
    SUREMOTE="ssh://$USERNAME@$SUHOST/afs/.ir/users/${USERNAME:0:1}/${USERNAME:1:1}/$USERNAME/${REMOTE_REPO:2}"
    git -C "$BUILD_DIR" push -f "$SUREMOTE" master:master
	ssh -l "$USERNAME" "$SUHOST" git -C "$REMOTE_WWW" pull -f
elif [ $TYPE == "keybase" ]; then
    cp -r "$BUILD_DIR/" "/keybase/public/$USERNAME/"
else
    echo "Invalid destination chosen."
    print_help
fi
