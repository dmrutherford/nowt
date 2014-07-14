#!/bin/bash


#
#                                              .   
#                                            .o8   
#   ooo. .oo.    .ooooo.  oooo oooo    ooo .o888oo 
#   `888P"Y88b  d88' `88b  `88. `88.  .8'    888   
#    888   888  888   888   `88..]88..8'     888   
#    888   888  888   888    `888'`888'      888 . 
#   o888o o888o `Y8bod8P'     `8'  `8'       "888" 
#
#   8888888888888888888888888888888888888888888888
#
#   tpo-a002-1.0.0
#   d m rutherford
#


# VARIABLES

progname=${0##*/}
nowt="$PWD/.nowt"
pending="$nowt/pending"
completed="$nowt/completed"
archive=10


# FUNCTIONS

help() {
    cat <<EO

                                               .   
                                             .o8   
    ooo. .oo.    .ooooo.  oooo oooo    ooo .o888oo 
    \`888P"Y88b  d88' \`88b  \`88. \`88.  .8'    888   
     888   888  888   888   \`88..]88..8'     888   
     888   888  888   888    \`888'\`888'      888 . 
    o888o o888o \`Y8bod8P'     \`8'  \`8'       "888" 

    8888888888888888888888888888888888888888888888

A trackable to-do list for when you need summat doin'.

Commands:
EO
    cat <<EO | column -s\& -t
    -l          &list pending items
    -a "foo"    &add "foo" to the list
    -c n        &mark nth item completed (adds it to the archive)
    -r n        &remove nth item (without archiving)
    -y          &show the archive
    -p [n]      &prune the archive to the n most recent items (10 by default)
    -n          &nuke all traces of nowt (asks for confirmation first)
    -h          &show available commands
EO
    echo ""
}

initnowt() {
    if ! [ -d "$nowt" ]
    then
        mkdir .nowt
    fi
    if [ "$1" = "$pending" ]
    then
        touch "$pending"
    else
        touch "$completed"
    fi
}

deblank() {
    sed '/^$/d' "$1" > "$1.tmp"
    mv "$1.tmp" "$1"
}

deempty() {
    deblank "$1"
    if ! [ -s "$1" ]
    then
        rm "$1"
    fi
}

list() {
    if [ -f "$1" ]
    then
        deempty "$1"
        if [ -f "$1" ]
        then
            cat -n "$1"
        else
            echo "You've done nowt!"
        fi
    else
        if [ "$1" = "$pending" ]
        then
            echo "You've nowt to do!"
        else
            echo "You've done nowt!"
        fi
    fi
}

add() {
    initnowt "$pending"
    echo "$1" >> "$pending"
    echo "'$1' added!"
}

process() {
    task=$(awk -v n=$1 "NR == n { print }" "$pending")
    awk -v n=$1 -v l="" "NR == n { print l; next } { print }" "$pending" > "$pending.tmp"
    mv "$pending.tmp" "$pending"
}

complete() {
    process $1
    echo "$task" >> "$completed"
    echo "'$task' done!"
}

remove() {
    process $1
    echo "'$task' removed!"
}

prune() {
    if [ -f "$completed" ]
    then
        deblank "$completed"
        if [ -z $1 ]
        then
            tail -n $archive "$completed" >> "$completed.tmp"
        else
            tail -n $1 "$completed" >> "$completed.tmp"
        fi
        mv "$completed.tmp" "$completed"
        deempty "$completed"
    fi
}

nuke() {
    if [ -f "$pending" ]
    then
        rm "$pending"
    fi
    if [ -f "$completed" ]
    then
        rm "$completed"
    fi
    if [ -d "$nowt" ]
    then
        rmdir "$nowt"
    fi
}


# COMMANDS

opts=":la:c:r:ypnh"

while getopts $opts opt; do
    case "$opt" in
        l)
            list "$pending"
            exit
            ;;
        a)
            initnowt "$pending"
            add "$2"
            exit
            ;;
        c)
            initnowt
            complete $2
            exit
            ;;
        r)
            remove $2
            exit
            ;;
        y)
            list "$completed"
            exit
            ;;
        p)
            prune $2
            exit
            ;;
        n)
            read -p "Really nuke nowt? [y/N] " -r
            if [[ $REPLY =~ ^[Yy]$ ]]
            then
                nuke
            fi
            exit
            ;;
        h)
            help
            exit
            ;;
        \?)
            echo "The command '$progname -$OPTARG' is invalid."
            echo "Run '$progname -h' for help..."
            exit
            ;;
    esac
done


# FALLBACK

if ! [ -z "$1" ]
then
    initnowt "pending"
    add "$1"
    exit
fi
list "$pending"
exit
