#!/bin/bash

function modify_env {
    local ACTION=
    local VAR=
    local SELF=${FUNCNAME[0]}
    local OPTIND
    local OPTARG
    local OPTERR
    local USAGE

    read -r -d '' USAGE <<HELP
USAGE: $SELF -a action -v variable [-- elements...]
OPTIONS:
    -a
        The action to perform.
    -v
        The variable that will be modified by action.
    elements
        The elements that will be acted upon by action.

ACTIONS:
    add
        Add the specified elements. If the elements are already present in the
        list, they are brought to the front.
    del
        Delete the specified elements.
    list
        Show all the elements of the list in variable.

ENVIRONMENT:
    FS
        $SELF uses bash's field separator, FS, to split and join the list.
HELP

    while getopts a:v:s: OPT ; do
        case "$OPT" in
            a) ACTION=$OPTARG ;;
            v) VAR=$OPTARG ;;
        esac
    done
    shift $(( $OPTIND - 1 ))

    if [ -z "$VAR" ] ; then echo "$USAGE" && return 1 ; fi
    case "$ACTION" in
        add)
            $SELF -a del -v "$VAR" -- "$@" && \
            export $VAR=$(tokens $@ | untokens):${!VAR} && \
            return 0 ;;
        del)
            for E in "$@"; do
                export $VAR=$( (IFS=$FS tokens ${!VAR}) | filter test "$E" != | untokens)
            done && return 0 ;;
        list) tokens $(IFS=$FS ; echo ${!VAR}) && return 0 ;;
        *)
            echo "$USAGE" && return 1 ;;
    esac
    return 1
}

function path {
    local USAGE
    read -r -d '' USAGE <<HELP
USAGE: path -arl [paths...]
OPTIONS:
    -a  Add to PATH
        If paths... already exist in PATH, they are brought to the front
    -r  Remove from PATH
    -l  List paths in PATH, one per line
HELP
    local action=$1
    shift 1
    local FS=:
    case $action in
    -a)
        modify_env -a add -v PATH -- "$@" && return $? ;;
    -r)
        modify_env -a del -v PATH -- "$@" && return $? ;;
    -l)
        modify_env -a list -v PATH && return $? ;;
    *)
        echo "$USAGE" && return 1
    esac
    return 1
}

