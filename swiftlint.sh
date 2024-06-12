#!/bin/bash
# Copyright (c) 2018 Norio Nomura
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
# Copyright (c) 2022 Jaehong Kang
# Licensed under Apache License v2.0
#
# convert swiftlint's output into GitHub Actions Logging commands
# https://help.github.com/en/github/automating-your-workflow-with-github-actions/development-tools-for-github-actions#logging-commands

function stripPWD() {
  sed -E "s/$(pwd|sed 's/\//\\\//g')\///"
}

function convertToGitHubActionsLoggingCommands() {
  sed -E 's/^(.*):([0-9]+):([0-9]+): (warning|error|[^:]+): (.*)/::\4 file=\1,line=\2,col=\3::\5/'
}

sh -c "git config --global --add safe.directory $PWD"
if ! ${WORKING_DIRECTORY+false};
then
    cd ${WORKING_DIRECTORY}
fi

if ! ${DIFF_BASE+false};
then
    # Find all changed Swift files in the repository
    git branch --track ${GITHUB_BASE_REF} origin/${GITHUB_BASE_REF}
    git branch --track ${GITHUB_HEAD_REF} origin/${GITHUB_HEAD_REF}
    
    changedFiles=$(git --no-pager diff --name-only --relative "${GITHUB_HEAD_REF}" $(git merge-base "${GITHUB_HEAD_REF}" "${GITHUB_BASE_REF}") -- '*.swift')
    echo "changed files $changedFiles"

    if [ -z "$changedFiles" ]
    then
        echo "No Swift file changed"
        exit
    fi
fi

set -o pipefail && swift run $SWIFTLINT_PACKAGE_ARGS --skip-build swiftlint "$@" -- $changedFiles | stripPWD | convertToGitHubActionsLoggingCommands
