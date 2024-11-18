#!/bin/bash

remove_last_character () {
    echo "${1::-1}"
}

create_list_with_separator () {
    local list=""
    while read line || [ -n "${line}" ]; do
        list="${list}${line}${2}"
    done < $1

    # Delete trailing separator
    local list=$(remove_last_character $list)
    echo $list
}

set -e

stars_arguments=">=5000"
language="java"
exclude_topics=""
limit=5 #default, can be bigger
dependency_file="build.gradle"
topics_to_exclude="exclude_topics.txt" # Path to file containing topics to exclude. separated by newlines
libraries_to_look="libraries.txt" # Path to file containing libraries to include. separated by newlines

# Read the list of topics to exclude line by line, separated by commas
exclude_topics=$(create_list_with_separator $topics_to_exclude ",")

# Get a initial round of repos, store them in a json file with links and title
gh search repos -L $limit --stars $stars_arguments --json=fullName,url -- -topic:$exclude_topics language:$language > acceptable_repos.json


# For each repo, check if the repo imports a test library in the dependencies file and record it

result_file="results.json"
result=""

while read repo_name; do
    temp="{\"repo\":\"${repo_name}\", \"uses\":["
    skip=1

    while read lib || [ -n "${lib}" ]; do
        echo "doing ${repo_name} for ${lib}"
        res=$(gh search code --filename $dependency_file --repo $repo_name --json textMatches $lib)
        if [[ "$res" != "[]" ]]; then
            temp="${temp}\"${lib}\","
            skip=0
        fi
        sleep 10
    done < $libraries_to_look

    if [[ $skip -ne 1 ]]; then
        temp="${temp::-1}"

        result="${result}${temp}]},"
    fi
    sleep 5
done < <(jq -c -r ".[] .fullName" acceptable_repos.json)

result="${result::-1}"

echo "[${result}]" > $result_file
