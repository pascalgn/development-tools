# development-tools

Command line tools helpful for software development.

## Installation

Use `make install` to install the scripts into `$HOME/bin`.
If you want to install them for all users, use `make install PREFIX=/usr/local/bin`.

## Usage

### abbreviate

Abbreviate long lines:

    $ cat access.log | abbreviate

### git-ghpr

Push the current local branch to the matching remote branch and open the GitHub page to create a new pull request:

    $ git ghpr

### git-merge-theirs

Merge another branch, using strategy `theirs` to use all changes from their branch:

    $ git checkout my-branch
    $ git merge -s theirs their-branch

### git-show-merged-branches

Show branches merged into the current branch:

    $ git show-merged-branches

### git-show-unused-branches

Show all branches, sorted by last commit date:

    $ git show-unused-branches

### ide-delete-eclipse-settings and ide-delete-intellij-settings

Delete IDE configuration files, prompting before deleting:

    $ ide-delete-eclipse-settings
    $ ide-delete-intellij-settings

### java-filter-stacktrace

Filter Java stack traces by only showing lines from the `com.example` package:

    $ cat exception.log | java-filter-stacktrace com.example

### mvn-download-artifact

Download a Maven artifact to your local repository:

    $ mvn-download-artifact commons-io:commons-io:2.5

### mvn-parse-log

Show a condensed version of the Maven log output:

    $ mvn clean install &> maven.log
    $ mvn-parse-log maven.log

### mvn-parse-pom

Parse Maven POM files:

    $ mvn-parse-pom.py ~/.m2/repository/commons-io/commons-io/2.5/commons-io-2.5.pom
    commons-io:commons-io:2.5

### mvn-upload-artifact

Upload a Maven artifact to the remote repository:

    $ ls
    commons-io-2.5.pom    commons-io-2.5.jar    commons-io-2.5.jar.sha1
    $ mvn-upload-artifact http://username:password@localhost:8080/ commons-io-2.5.pom

### mvn-upload-repository

Upload multiple artifacts to the remote repository:

    $ mvn-upload-repository http://username:password@localhost:8080/ commons-io/commons-io

## License

All tools are licensed under the MIT License
