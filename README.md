# Obsolete

This repository is OBSOLETE, functionality has been merged into intercept at https://bitbucket.typo3.com/projects/INT/repos/intercept/browse

# Usage

## General

* clone this repository to some path (e.g. `path-to` in the examples below)
* when invoking the script, an new working directory `.out` is generated that contains each sub-package
* each sub-package is cloned from the according GitHub repository at https://github.com/TYPO3-CMS/

## Installation

```
git clone https://github.com/lolli42/typo3-core-splitter
git clone https://github.com/TYPO3/TYPO3.CMS.git
typo3-core-splitter/tagger.sh execute --commit 333.333.333 --tag v333.333.333 --repository ./TYPO3.CMS/
```

## Creating new tags

```
tagger.sh execute --commit 333.333.333 --tag v333.333.333 --repository ./TYPO3.CMS/
```

* this outputs a list of the most recent commit in a sub-package concerning the given main commit (`--commit`)
* each of those commits is tagged with the previously identified tag version (`--tag`)
* after all tags are assigned, those are pushed to the according GitHub repositories

## Showing commit hashes for new tags

```
tagger.sh show --commit 333.333.333 --repository ./TYPO3.CMS/
```

* basically the same as above, however without assigning tags and without pushing to GitHub
* the processed output looks like this, showing the closest commit-hash for each sub-package repository

```
a33d09af3a7c1b7b8e6ed73bcada3440579f3af7           git@github.com:TYPO3-CMS/about.git
6f9b8413a71a92850833db9021392764baa6bd56           git@github.com:TYPO3-CMS/backend.git
230cb1b536c44872e4fe4ee4f5265de5ccf10203           git@github.com:TYPO3-CMS/belog.git
35ddb123e73d29420df89292c8fcc631c6f2a366           git@github.com:TYPO3-CMS/beuser.git
...
```
