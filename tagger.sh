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
BRANCH=""
WORK=".out"
REPOSITORY="."
EXTENSIONDIRECTORY="typo3/sysext/"
PACKAGESURLTEMPLATE="git@github.com:TYPO3-CMS/%s.git"
BASENAME=$(basename $0)

function showUsage {
    echo "${BASENAME} <mode> [options]"
    echo "${BASENAME} show --commit <commit> [--branch <branch>] [--repository <repository>]"
    echo "${BASENAME} execute --commit <commit> --tag <tag> [--branch <branch>] [--repository <repository>]"
    echo
    echo "--commit <value>      Git object to be processed in main repository"
    echo "--branch <branch>     Branch name to work on in main repository"
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

# Process command line arguments
while [[ $# -gt 1 ]]
do
    key="$1"
    case ${key} in
        -c|--commit)
            COMMIT="$2"
            shift
            ;;
        -b|--branch)
            BRANCH="$2"
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
    shift
done

# Validate required command line arguments per application mode
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

# Determine first branch of the given commit (if not provided as argument)
if [[ "${BRANCH}" == "" ]]
then
    BRANCH=$(git -C ${REPOSITORY} branch -r --contains ${COMMIT} | grep -v origin/HEAD | head -n1 | sed 's/ //g' | sed 's#origin/##')
fi
PACKAGEBRANCH=$(echo ${BRANCH} | sed 's/TYPO3_//' | sed 's/-/./g')

# Ensure main repository does exist and supports at least Git
git -C ${REPOSITORY} rev-list HEAD -1 --quiet
if [[ $? -ne 0 ]]
then
    echo "Directory '${REPOSITORY}' is not a GIt repository"
    exit 1
fi

if [[ ! -d ${WORK} ]]
then
    mkdir -p ${WORK}
fi

# Select proper branch and state of main repository
git -C ${REPOSITORY} fetch --quiet --all
git -C ${REPOSITORY} checkout -b ${BRANCH} origin/${BRANCH} &> /dev/null
git -C ${REPOSITORY} checkout --quiet ${BRANCH}
git -C ${REPOSITORY} reset --quiet --hard origin/${BRANCH}

# Change the internal field separator to newline character
IFS=$'\n'

# Fetch list of available extensions
EXTENSIONS=$(ls -1 ${REPOSITORY}/${EXTENSIONDIRECTORY})
for EXTENSION in ${EXTENSIONS}
do
    # Change the internal field separator
    IFS=""

    PACKAGESURL=$(printf ${PACKAGESURLTEMPLATE} ${EXTENSION})
    WORKREPOSITORY=${WORK}/${EXTENSION}

    if [[ ! -d ${WORKREPOSITORY} ]]
    then
        git clone --quiet ${PACKAGESURL} ${WORKREPOSITORY} || exit 1
    else
        git -C ${WORKREPOSITORY} fetch --quiet --all || exit 1
        git -C ${WORKREPOSITORY} fetch --quiet --tags
    fi

    FOUNDCOMMITHASH="---"
    MAINTREEHASHES=""

    # Resolve tree-hashes of main repository
    while read MAINCOMMITHASH
    do
        MAINTREEHASH=$(git -C ${REPOSITORY} ls-tree ${MAINCOMMITHASH} ${EXTENSIONDIRECTORY}${EXTENSION} | awk '{print $3}')
        MAINTREEHASHES=${MAINTREEHASHES}$'\n'${MAINTREEHASH}
    done <<< $(git -C ${REPOSITORY} rev-list ${COMMIT} ${EXTENSIONDIRECTORY}${EXTENSION})

    # Iterate over commit- & tree-hashes of package
    while read PACKAGEDATE
    do
        PACKAGECOMMITHASH=$(echo ${PACKAGEDATE} | awk '{print $2}')
        PACKAGETREEHASH=$(echo ${PACKAGEDATE} | awk '{print $3}')

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
    done <<< $(git -C ${WORKREPOSITORY} rev-list --all --pretty="commit+tree %H %T" | grep "^commit+tree")

    # Output resolved commit-hash and repository URL
    printf "%-50s %s\n" ${FOUNDCOMMITHASH} ${PACKAGESURL}

    if [[ "${MODE}" == "execute" ]]
    then
        # Create tag, but do not push it yet...
        # If no hash was found, exit and avoid pushing only half of the repositories
        if [[ "${FOUNDCOMMITHASH}" != "---" ]]
        then
            git -C ${WORKREPOSITORY} tag -f ${TAG} ${FOUNDCOMMITHASH}
        else
            echo "Could not determine matching tree hash for extension ${EXTENSION}"
            exit 3
        fi
    fi

done

if [[ "${MODE}" != "execute" ]]
then
    exit 0
fi

# Change the internal field separator to newline character
IFS=$'\n'

# Push tags to remote repositories
for EXTENSION in ${EXTENSIONS}
do
    WORKREPOSITORY=${WORK}/${EXTENSION}
    git -C ${WORKREPOSITORY} push origin ${TAG}
done