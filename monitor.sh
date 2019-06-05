#!/usr/bin/env bash

echo "Author: Morema Thabo Mafantiri"
echo "Student ID: S1719032"
USAGE="usage: $0 [ -s | -k] "

#start initiates the  monitor script process
start(){
    watch -n 15 -d ls -l ~/.trashCan #shows a list of files in the trashCan and highlights any changes made.
}

#do_kill terminates current user’s monitor script processes
#It assumes there is no other process that ends with watch besides the monitor process.
do_kill(){
    process_id=$(ps -A | grep "watch$" | awk '{print $1}') #finds process id of the only watch process running.
    kill ${process_id}
    exit 0
}

while getopts :sk args #options
do
  case ${args} in
        s) start;;
        k) do_kill;;
        \?) echo "$USAGE";;
  esac
done
shift $((OPTIND-1))

