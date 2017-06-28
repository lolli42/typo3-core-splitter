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

# Usage: create-tags.sh [repository]

REPOSITORY="."
TAGGER=$(dirname $0)/tagger.sh

if [[ "$1" != "" ]]
then
    REPOSITORY=$1
fi

git -C ${REPOSITORY} rev-list HEAD -1 --quiet
if [[ $? -ne 0 ]]
then
    echo "Directory '${REPOSITORY}' is not a Git repository"
    exit 1
fi


TAGS=$(git -C ${REPOSITORY} tag -l '8.*' 'v8.*')
for TAG in ${TAGS}
do
    NEWTAG=$(echo ${TAG} | sed -e 's/^v//' | sed -e 's/^/v/')
    echo "* creating tag ${TAG} -> ${NEWTAG}"
    ${TAGGER} show --commit ${TAG} --tag ${NEWTAG} --repository ${REPOSITORY}
done