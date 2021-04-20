#!/bin/bash

function evil_git_dirty {
    [[ $(git diff --shortstat 2> /dev/null | tail -n1) != "" ]] && echo "*"
}

# Usage: increment_version <version> [<position>]
function increment_version() {
 local v=$1
 if [ -z $2 ]; then 
    local rgx='^((?:[0-9]+\.)*)([0-9]+)($)'
 else 
    local rgx='^((?:[0-9]+\.){'$(($2-1))'})([0-9]+)(\.|$)'
    for (( p=$(grep -o "\."<<<".$v"|wc -l); p<$2; p++)); do
       v+=.0; done; fi
 val=$(echo -e "$v" | perl -pe 's/^.*'$rgx'.*$/$2/')
 echo "$v" | perl -pe s/$rgx.*$'/${1}'$(printf %0${#val}s $(($val+1)))/
}

PARAMS=""

while (( "$#" )); do
    case "$1" in
        -t|--type)
            if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
                REV_TYPE_ARG=$2
                shift 2
            else
                echo "Error: Argument for $1 is missing" >&2
                exit 1
            fi
            ;;
        -*|--*=) # Unsupported flags
            echo "Error: Unsupported flag $1" >&2
            exit 1
            ;;
        *) # Preserve positional arguments
            PARAMS="$PARAMS $1"
            shift
            ;;
    esac
done


if true; then
    echo "Seems like everything has been added..."
    echo "Finding last semver tag..."
    LAST_TAG=$(git describe --abbrev=0 --tags)
    echo "Last tag was: ${LAST_TAG}" 

    case "$REV_TYPE_ARG" in
    major)
        echo "Generating MAJOR revision..."
        NEW_TAG="$(increment_version $LAST_TAG 1).0.0"
        echo "New tag is ${NEW_TAG}"
        ;;
    minor)
        echo "Generating MINOR revision..."
        NEW_TAG="$(increment_version $LAST_TAG 2).0"
        echo "New tag is ${NEW_TAG}"
        ;;
    patch)
        echo "Generating PATCH revision..."
        NEW_TAG=$(increment_version $LAST_TAG 3)
        echo "New tag is ${NEW_TAG}"
        ;;
    "")
        echo "Generating PATCH revision..."
        NEW_TAG=$(increment_version $LAST_TAG 3)
        echo "New tag is ${NEW_TAG}"
        ;;
    *)
        echo "Bogus type flag..."
        exit 1
        ;;
    esac

    echo "Tagging..."
    git tag $NEW_TAG

    echo "Pushing tag to origin..."
    git push origin $NEW_TAG

else
    echo "There are untracked files, please add or stash them first..."
    exit 1
fi
