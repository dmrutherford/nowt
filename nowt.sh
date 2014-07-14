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
    -n          &nuke all traces of nowt in cwd (asks for confirmation first)
    -e          &show every nowt project under cwd
    -h          &show available commands
EO
    echo ""
}

initnowt() {
    if ! [ -d "$nowt" ]
    then
        mkdir .nowt
    fi
    touch "$pending"
    touch "$completed"
}

deblank() {
    sed '/^$/d' "$1" > "$1.tmp"
    mv "$1.tmp" "$1"
}

isnull() {
    if [ -z "$1" ]
    then
        nullerr=true
    else
        nullerr=false
    fi
}

list() {
    if [ -f "$1" ]
    then
        deblank "$1"
        if [ -s "$1" ]
        then
            cat -n "$1"
            exit
        fi
    fi
    if [ "$1" = "$pending" ]
    then
        echo "You've nowt to do!"
    else
        echo "You've done nowt!"
    fi
}

add() {
    isnull "$1"
    if [ $nullerr = "true" ]
    then
        echo "NULL is not a task"
        exit 1
    fi
    echo "$1" >> "$pending"
    echo "\"$1\" added!"
}

process() {
    task=$(awk -v n=$1 "NR == n { print }" "$pending")
    isnull "$task"
    if [ $nullerr = "true" ]
    then
        total=`wc -l < "$pending"`
        if [ "$1" -gt "$total" ]
        then
            echo "You didn't have that much to do!"
            echo "Pick a lower number..."
            exit 1
        fi
        echo "Task $task has already been processed!"
        echo "Run \"$progname -l\" to clean up the list..."
        exit 1
    fi
    awk -v n=$1 -v l="" "NR == n { print l; next } { print }" "$pending" > "$pending.tmp"
    mv "$pending.tmp" "$pending"
}

complete() {
    process $1
    echo "$task" >> "$completed"
    echo "\"$task\" done!"
}

remove() {
    process $1
    echo "\"$task\" removed!"
}

projects() {
    for project in `find $PWD -name .nowt`
    do
        dirname $project
    done
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

opts=":la:c:r:ypneh"

while getopts $opts opt; do
    case "$opt" in
        l)
            list "$pending"
            exit
            ;;
        a)
            initnowt
            add "$2"
            exit
            ;;
        c)
            initnowt
            complete $2
            exit
            ;;
        r)
            initnowt
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
        e)
            projects
            exit
            ;;
        h)
            help
            exit
            ;;
        \?)
            echo "The command \"$progname -$OPTARG\" is invalid."
            echo "Run \"$progname -h\" for help..."
            exit
            ;;
    esac
done


# FALLBACK

if ! [ -z "$1" ]
then
    initnowt
    add "$1"
    exit
fi
list "$pending"
exit
