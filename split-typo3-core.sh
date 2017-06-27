#!/bin/bash

# Go to current dir
cd "$(dirname "$0")"

# Create data dir if not exists
[[ -d data ]] || mkdir data

BASEREMOTE=git://git.typo3.org/Packages/TYPO3.CMS.git
BASEREPO=TYPO3.CMS
DATADIR=data/

# Initial clone or update pull
if [[ -d ${DATADIR}${BASEREPO} ]]; then
    git -C ${DATADIR}${BASEREPO} pull
else
    git clone $BASEREMOTE ${DATADIR}${BASEREPO}
fi

# New working dir
cd ${DATADIR}${BASEREPO} || exit 1

# temp uncomment
#EXTENSIONS=`ls typo3/sysext`
EXTENSIONS="saltedpasswords sys_note"

for EXTENSION in ${EXTENSIONS}; do
    echo "Splitting extension ${EXTENSION}"

    # Split operation itself creating commit objects and giving last SHA1 commit hash
    SHA1=`./../../splitsh-lite/splitsh-lite --prefix=typo3/sysext/${EXTENSION}`

    # Remove old branch if exists
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

    git branch -D split-${EXTENSION}-master;
done

