#!/bin/bash

# Go to current dir this script is in
cd "$(dirname "$0")"

# Create data dir if not exists
[[ -d data ]] || mkdir data || exit 1

# Find out which split binary to use
case "$(uname)" in
    Darwin)
        SPLITTER="splitsh-lite-darwin"
        ;;
    Linux)
        SPLITTER="splitsh-lite-linux"
        ;;
    *)
        echo 'Unknown OS'
        exit 1
        ;;
esac


BASEREMOTE=git://git.typo3.org/Packages/TYPO3.CMS.git
REPODIR=TYPO3.CMS

# Initial clone or update pull
if [[ -d ${REPODIR} ]]; then
    git -C ${REPODIR} pull
else
    git clone $BASEREMOTE ${REPODIR}
fi

# Go to repo checkout
cd ${REPODIR} || exit 1

# temp uncomment
#EXTENSIONS=`ls typo3/sysext`
EXTENSIONS="saltedpasswords sys_note"

for EXTENSION in ${EXTENSIONS}; do
    echo "Splitting extension ${EXTENSION}"

    # Split operation creating commit objects and giving last SHA1 commit hash
    SHA1=`./../${SPLITTER} --prefix=typo3/sysext/${EXTENSION}`

    # Remove old branch if exists from a previous run
    if [[ $(git branch --list split-${EXTENSION}-master | wc -l) -eq 1 ]]; then
        git branch -D split-${EXTENSION}-master;
    fi

    # Add a branch with this SHA1 as HEAD
    git branch split-${EXTENSION}-master ${SHA1}

    # Add target extension remote if needed
    if [[ $(git remote | grep "^${EXTENSION}\$" | wc -l) -eq 0 ]]; then
        echo "Adding remote"
        git remote add ${EXTENSION} git@github.com:lolli42/${EXTENSION}.git
    fi
    # Update remote
    git fetch ${EXTENSION}

    # Push to remote
    git push ${EXTENSION} split-${EXTENSION}-master:master

    # Remove local branch again
    git branch -D split-${EXTENSION}-master;
done

