#! /bin/bash
echo "Author: Morema Thabo Mafantiri"
echo "Student ID: S1719032"

USAGE="usage: $0 [ -l | -d | -w | -k | -t] ,
              $0 [ -r ] file ,
              $0 file [file...]"

trash=~/.trashCan



#trapCtrlC is the function that executes when a trap receives a SIGINIT signal
# It indicates the current total number of regular files in the  trashCan
#and then terminates the script.

#It also prints a warning message if the disk usage in the trashCan directory
#exceeds 1Kbytes.

trapCtrlC(){
    for f in ${trash}/*; do                        # counts the files in the trashCan directory by adding 1 to count for
        if [[ -f ${f} ]]; then                     # every regular file found in the trash can.
            count=$(expr ${count} + 1)
        fi
    done
    echo "There are ${count} regular files in the trash can"
    disk_usage=$(total ${trash})
    if (( ${disk_usage} > 1024 )) ; then            # uses result from the total function to check if the disk usage has exceeded 1KB.
        echo "WARNING! The trash can is using over 1KB of disk space"
    fi
    echo ${disk_usage}
#    exit 130
}

#display total usage in bytes of the trashCan directory for the user of the trashcan
total(){
    sum=0
     for f in $1/*; do
        if [[ -d ${f} ]]; then          # Finds the size of a directory by adding the sizes of files in the directory
            size=$(total ${f})
        else
            size=$(wc -c < ${f})
        fi
        sum=$(expr ${sum} + ${size})
     done
     echo ${sum}

}

#list outputs a list on screen of the contents of the trashCan directory; output shows
#file name, size  and type for each file.
list(){
    if [[ -z "$(ls -A ${1})" ]]; then
        echo "The trash can is empty!"
    else
        echo "----------------------------------------"
        echo "File name      Size(bytes)     Type"
        echo "----------------------------------------"
        for f in ${1}/*; do
            if [[ -d ${f} ]]; then
                echo "$(basename ${f})      $(total ${f})     $(file -b --mime-type  ${f}) "
            else
                echo "$(basename ${f})      $(wc -c < ${f})     $(file -b --mime-type  ${f}) "
            fi
        done
    fi
}

#recover gets a specified file from the trashCan directory and place it in the
#current directory
recover(){
    file=$1
    if (( $# == 0 )); then    #Asks users to specify file to recover if not specified.
        echo "Enter name of the file you want to recover. (Please include the file extension)"
        read file
    fi

    if [[ -f "${trash}/${file}" ]]; then
        echo "Recovered ${file} to $(pwd)"    #Recovers file by moving it to the user's working directory.

        mv ${trash}/${file} $(pwd)
    elif [[ -d "${trash}/${file}" ]]; then    #If the item found is a directory. User gets option to select a file in
    #that directory that they want to recover.
        echo "${file} is a directory. Here's a list of the files it contains"
        list "${trash}/${file}"
        echo "Enter name of the file you want to recover. (Please include the file extension)"
        read file2
        recover "$file/$file2"
    else
        echo "${file} is not in the trash can."   #prints out error message if file not found.
    fi
}

#delete interactively deletes the contents of the trashCan directory.
delete(){
    echo "Would you like to empty the trash can? (Y/N):"
    read response
    case "$response" in
	    n | N)
		    echo "Enter name of file you would like to delete(Please include file extension):"
		    read file
		    if [[ -f "${trash}/${file}" ]]; then
                rm ${trash}/${file}
                echo "${file} deleted permanently"
            else
                echo "${file} is not in the trash can."
            fi
	    ;;
	    Y | *)
		    rm -r ${trash}                  # Empties trash can by recursively deleting it and creating a new
		    mkdir ${trash}                  # ~/.trashCan directory.
		    echo "Trash can is now empty"
	    ;;
	esac
}

#starts the monitor script in a new terminal
watch(){
echo "Monitoring ${trash}"
xterm -e ./monitor.sh -s &  #opens monitor scripts in new terminal. It runs in the background.
}

#stops the monitor process
do_kill(){
bash monitor.sh -k &     #calls the do_kill function in the monitor script to terminate monitor script.
echo "Monitor process has been  terminated."
exit 130
}

#Creates a new ~/.trashCan directory if one does not exist.
if [[ ! -d "$trash" ]]; then
    echo "creating trash can"
    mkdir ${trash}
fi


#Sets up a trap to execute trapCtrlC before safeDel terminates on receipt of SIGINT.
trap trapCtrlC SIGINT

#Provides menu options for when executing the script in "command line switch mode"
while getopts :lr:dtmk args #options
do
  case ${args} in
     l) list ${trash};;
     r) recover $OPTARG;;
     d) delete ;;
     t) total ${trash};;
     m) watch;;
     k) do_kill;;
     :) echo "data missing, option -$OPTARG";;
    \?) echo "$USAGE";;
  esac
done

((pos = OPTIND - 1))
shift ${pos}

PS3='option> '

#Sets up options to be executed when running the script in “menu mode”
if (( $# == 0 ))
then if (( $OPTIND == 1 ))
 then select menu_list in list recover delete total monitor kill exit
      do case ${menu_list} in
         "list") list ${trash};;
         "recover") recover;;
         "delete") delete ;;
         "total") total ${trash};;
         "monitor") watch;;
         "kill") do_kill;;
         "exit") exit 0;;
         *) echo "unknown option";;
         esac
      done
 fi
else mv $@ ${trash}
fi

