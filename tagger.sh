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

REPOSITORY=.
EXTENSIONDIRECTORY="typo3/sysext/"
PACKAGESURL="/Users/olly/Development/typo3/git/work/packages/"

if [[ "$1" != "show" && "$1" != "execute" || "$2" == "" || "$3" == "" ]]
then
    echo "Usage $0 <mode> <commit> <tag> [repository]"
    echo
    echo "$0 show abcdef v9.0.0 TYPO3.CMS"
    echo "$0 execute abcdef v9.0.0 TYPO3.CMS"
    exit 1
fi

MODE=$1
COMMITHASH=$2
TAG=$3

if [[ "$4" != "" && -d $4 ]]
then
    REPOSITORY=$4
else
    echo "Directory ${REPOSITORY} not found"
    exit 2
fi

# Fetch list of available extensions
EXTENSIONS=$(ls ${REPOSITORY}/${EXTENSIONDIRECTORY})
EXTENSIONS="sys_note"
for EXTENSION in ${EXTENSIONS}
do
    # Assert remote package repositories are available
    git -C ${REPOSITORY} remote remove package-${EXTENSION} || exit 1
    git -C ${REPOSITORY} remote add package-${EXTENSION} ${PACKAGESURL}${EXTENSION} || exit 1
    git -C ${REPOSITORY} fetch --quiet package-${EXTENSION} || exit 1

    FOUNDCOMMITHASH="---"

    # Iterate over commit- & tree-hashes of package
    while read ITEMTYPE PACKAGECOMMITHASH PACKAGETREEHASH
    do
        # Iterate over commit-hashes of main (TYPO3.CMS) repository
        while read MAINCOMMITHASH
        do
            MAINTREEHASH=$(git -C ${REPOSITORY} ls-tree ${MAINCOMMITHASH} ${EXTENSIONDIRECTORY}${EXTENSION} | awk '{print $3}')

            # Use closest commit-hash having both the same
            # tree-hash in the main and package repository
            if [[ "${MAINTREEHASH}" == "${PACKAGETREEHASH}" ]]
            then
                FOUNDCOMMITHASH="${PACKAGECOMMITHASH}"
                break
            fi
        done <<< $(git -C ${REPOSITORY} rev-list -1 ${COMMITHASH} ${EXTENSIONDIRECTORY}${EXTENSION})

        if [[ "${FOUNDCOMMITHASH}" != "---" ]]
        then
            break
        fi
    done <<< $(git -C ${REPOSITORY} rev-list -1 --pretty="commit+tree %H %T" package-${EXTENSION} | grep "^commit+tree")

    case "${MODE}" in
        show)
            printf "%-50s %s\n" ${FOUNDCOMMITHASH} ${PACKAGESURL}${EXTENSION}
            ;;
        execute)
            if [[ "${FOUNDCOMMITHASH}" != "---" ]]
            then
                git -C ${REPOSITORY} tag -f ${TAG} ${FOUNDCOMMITHASH}
            else
                echo "Could not determine matching tree hash for extension ${EXTENSION}"
                exit 3
            fi
            ;;
    esac

done

if [[ "${MODE}" != "execute" ]]
then
    exit 0
fi

for EXTENSION in ${EXTENSIONS}
do
    # @todo Add signed tags
    git -C ${REPOSITORY} push --quiet package-${EXTENSION} ${TAG}
done