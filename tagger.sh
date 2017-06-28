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

TAG=""
COMMIT=""
REPOSITORY="."
EXTENSIONDIRECTORY="typo3/sysext/"
# PACKAGESURLTEMPLATE="/Users/olly/Development/typo3/git/work/packages/%s"
PACKAGESURLTEMPLATE="git@github.com:lolli42/%s.git"
BASENAME=$(basename $0)

function showUsage {
    echo "${BASENAME} <mode> [options]"
    echo "${BASENAME} show --commit <commit> [--repository <repository>]"
    echo "${BASENAME} execute --commit <commit> --tag <tag> [--repository <repository>]"
    echo
    echo "--commit <value>      Git object to be processed in main repository"
    echo "--tag <value>         Name of tag to be created"
    echo "--repository <value>  URI of main repository"
    exit 1
}

if [[ $# -lt 1 ]]
then
    showUsage
fi

MODE=$1
shift

while [[ $# -gt 1 ]]
do
    key="$1"
    case ${key} in
        -c|--commit)
            COMMIT="$2"
            shift
            ;;
        -t|--tag)
            TAG="$2"
            shift
            ;;
        -r|--repository)
            REPOSITORY="$2"
            shift
            ;;
        *)
            showUsage
            ;;
    esac
    shift # past argument or value
done

case ${MODE} in
    show)
        if [[ "${COMMIT}" == "" ]]
        then
            showUsage
        fi
        ;;
    execute)
        if [[ "${COMMIT}" == "" || "${TAG}" == "" ]]
        then
            showUsage
        fi
        ;;
    *)
        showUsage
        ;;
esac

git -C ${REPOSITORY} rev-list HEAD -1 --quiet
if [[ $? -ne 0 ]]
then
    echo "Directory '${REPOSITORY}' is not a GIt repository"
    exit 1
fi


# Fetch list of available extensions
EXTENSIONS=$(ls ${REPOSITORY}/${EXTENSIONDIRECTORY})
EXTENSIONS="saltedpasswords"
for EXTENSION in ${EXTENSIONS}
do
    IFS=""
    PACKAGESURL=$(printf ${PACKAGESURLTEMPLATE} ${EXTENSION})

    # Assert remote package repositories are available
    git -C ${REPOSITORY} remote remove package-${EXTENSION} &> /dev/null
    git -C ${REPOSITORY} remote add package-${EXTENSION} ${PACKAGESURL} || exit 1
    git -C ${REPOSITORY} fetch --quiet package-${EXTENSION} || exit 1

    FOUNDCOMMITHASH="---"
    MAINCOMMITHASHES=$(git -C ${REPOSITORY} rev-list ${COMMIT} ${EXTENSIONDIRECTORY}${EXTENSION})
    MAINTREEHASHES=""

    while read MAINCOMMITHASH
    do
        MAINTREEHASH=$(git -C ${REPOSITORY} ls-tree ${MAINCOMMITHASH} ${EXTENSIONDIRECTORY}${EXTENSION} | awk '{print $3}')
        MAINTREEHASHES=${MAINTREEHASHES}$'\n'${MAINTREEHASH}
    done <<< ${MAINCOMMITHASHES}


    # Iterate over commit- & tree-hashes of package
    while read PACKAGEDATE
    do
        PACKAGECOMMITHASH=$(echo ${PACKAGEDATE} | awk '{print $2}')
        PACKAGETREEHASH=$(echo ${PACKAGEDATE} | awk '{print $3}')

        # echo "${PACKAGECOMMITHASH} ${PACKAGETREEHASH}"

        # Iterate over commit-hashes of main (TYPO3.CMS) repository
        while read MAINTREEHASH
        do
            # Use closest commit-hash having both the same
            # tree-hash in the main and package repository
            if [[ "${MAINTREEHASH}" == "${PACKAGETREEHASH}" ]]
            then
                FOUNDCOMMITHASH="${PACKAGECOMMITHASH}"
                break
            fi
        done <<< ${MAINTREEHASHES}

        if [[ "${FOUNDCOMMITHASH}" != "---" ]]
        then
            break
        fi
    done <<< $(git -C ${REPOSITORY} rev-list --remotes=package-${EXTENSION} --pretty="commit+tree %H %T" | grep "^commit+tree")

    case "${MODE}" in
        show)
            printf "%-50s %s\n" ${FOUNDCOMMITHASH} ${PACKAGESURL}
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
    git -C ${REPOSITORY} push package-${EXTENSION} ${TAG}
done