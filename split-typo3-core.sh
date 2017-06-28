#!/bin/bash

# This file is part of the TYPO3 CMS project.
#
# It is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License, either version 2
# of the License, or any later version.
#
# For the full copyright and license information, please read the
# LICENSE.txt file that was distributed with this source code.
#
# The TYPO3 project - inspiring people to share!

#
# OUTDATED! Has been merged to intercept.typo3.com
#


#
# Main split and push function
#
function splitForBranch {
    local LOCALBRANCH="$1"
    local REMOTEBRANCH="$2"
    local SPLITTER="$3"
    local EXTENSIONS="$4"

    echo
    echo
    echo "Handling core branch ${LOCALBRANCH} splitting to target branch ${REMOTEBRANCH}"

    for EXTENSION in ${EXTENSIONS}; do
        echo
        echo "Splitting extension ${EXTENSION}"

        # Split operation creating commit objects and giving last SHA1 commit hash
        SHA1=`./../${SPLITTER} --prefix=typo3/sysext/${EXTENSION} --origin=origin/${LOCALBRANCH}`

        # Add target extension remote if needed
        if [[ $(git remote | grep "^${EXTENSION}\$" | wc -l) -eq 0 ]]; then
            echo "Adding remote"
            git remote add ${EXTENSION} git@github.com:lolli42/${EXTENSION}.git
        fi
        # Update remote
        git fetch ${EXTENSION}

        # Push to remote
        git push ${EXTENSION} ${SHA1}:refs/heads/${REMOTEBRANCH}
    done
}


# Go to current dir this script is in
cd "$(dirname "$0")"

# Create data dir if not exists
[[ -d data ]] || mkdir data || exit 1

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

# temp uncomment
#EXTENSIONS=`ls typo3/sysext`
EXTENSIONS="saltedpasswords sys_note scheduler"

# Handle master branch
splitForBranch "master" "master" "${SPLITTER}" "${EXTENSIONS}"
# Handle TYPO3_8-7 branch that does not stick to convention
splitForBranch "TYPO3_8-7" "8.7" "${SPLITTER}" "${EXTENSIONS}"

# Branches "9.0" "9.1" "10.4" ...
BRANCHESBYCONVENTION=`git branch --no-color -a | grep -v '^*' | sed 's/^ *//' | grep -E 'remotes/origin/[0-9]*\.[0-9]*' | sed 's%remotes/origin%%'`
for BRANCH in ${BRANCHESBYCONVENTION}; do
    splitForBranch ${BRANCH} ${BRANCH} "${SPLITTER}" "${EXTENSIONS}"
done
