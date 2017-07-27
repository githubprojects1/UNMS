#!/usr/bin/env bash
set -o nounset
set -o errexit
set -o pipefail

temp="/tmp/unms-install"

args="$*"
version=""
branch="master"

gitRepo="Ubiquiti-App/UNMS"
gitRepoRegex=" --git-repo ([^ ]+)"
if [[ " ${args}" =~ ${gitRepoRegex} ]]; then
  gitRepo="${BASH_REMATCH[1]}"
fi
echo "gitRepo=${gitRepo}"

gitToken=
gitTokenRegex=" --git-token ([^ ]+)"
if [[ " ${args}" =~ ${gitTokenRegex} ]]; then
  gitToken="${BASH_REMATCH[1]}"
  echo "gitToken=*****"
fi

branchRegex=" --branch ([^ ]+)"
if [[ " ${args}" =~ ${branchRegex} ]]; then
  branch="${BASH_REMATCH[1]}"
fi
echo "branch=${branch}"

versionRegex=" --version ([^ ]+)"
if [[ " $args" =~ $versionRegex ]]; then
  version="${BASH_REMATCH[1]}"
fi
echo "version=${version}"

repoUrl="https://api.github.com/repos/${gitRepo}/contents/"

gitHeaders="--header 'Accept: application/vnd.github.v3.raw'"
if [ ! -z "${gitToken}" ]; then
  gitHeaders="${gitHeaders} --header 'Authorization: token ${gitToken}'"
fi

if [ -z "$version" ]; then
  latestVersionUrl="${repoUrl}/latest-version?ref=${branch}"
  if ! version=$(curl -fsS ${gitHeaders} "${latestVersionUrl}"); then
    echo "Failed to obtain latest version info from $latestVersionUrl"
    exit 1
  fi
fi
echo version="$version"

rm -rf $temp
if ! mkdir $temp; then
  echo "Failed to create temporary directory"
  exit 1
fi

cd $temp
echo "Downloading installation package for version $version."
packageUrl="${repoUrl}/unms-$version.tar.gz?ref=${branch}"
if ! curl -sS ${gitHeaders} "${packageUrl}" | tar xz; then
  echo "Failed to download installation package ${packageUrl}"
  exit 1
fi

chmod +x install-full.sh
./install-full.sh $args --version "$version"

cd ~
if ! rm -rf $temp; then
  echo "Warning: Failed to remove temporary directory $temp"
fi
