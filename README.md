# Usage

## General

* clone this repository to some path (e.g. `path-to` in the examples below)
* when invoking the script, an new working directory `.out` is generated that contains each sub-package
* each sub-package is cloned from the according GitHub repository at https://github.com/TYPO3-CMS/

## Creating new tags

```
path-to/tagger.sh execute --commit 8.7.4 --tag v8.7.4 --repository ./TYPO3.CMS/
```

* this outputs a list of the most recent commit in a sub-package concerning the given main commit (`--commit`)
* each of those commit is tagged with the previously identified tag version (`--tag`)
* after all tags are assigned, those are pushed to the according GitHub repositories

## Showing commit hashes for new tags

```
path-to/tagger.sh execute --commit 8.7.4 --tag v8.7.4 --repository ./TYPO3.CMS/
```

* basically the same as above, however without assigning tags and without pushing to GitHub
