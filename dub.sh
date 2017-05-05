#!/bin/bash

# A Program to show the number of files/directories in a given directory,
# and how much memory each one takes


##### CONSTANTS #####

TEMP_DIR="/tmp"
TEMP_NAME="dub"
TEMP_RAW=$(mktemp $TEMP_DIR/$TEMP_NAME.XXXXX)
TEMP_EDIT=$(mktemp $TEMP_DIR/$TEMP_NAME.XXXXX)

# width of terminal window
WIDTH=$(tput cols)


###########################################################################
# formatting constants
NUMBER_WIDTH=4
FILESIZE_WIDTH=10
FILESIZE_WIDTH_min=5
BUFFER=2
BUFFER_TOTAL=$((3*BUFFER))
scale=1
ITEM_WIDTH_min=4
BAR_WIDTH_min=4

ITEM_WIDTH=20
ITEM_WIDTH_max=$(( WIDTH - NUMBER_WIDTH - BAR_WIDTH_min - FILESIZE_WIDTH - BUFFER_TOTAL ))

BAR_WIDTH=25
BAR_WIDTH_max=$(( WIDTH - NUMBER_WIDTH - ITEM_WIDTH_min - FILESIZE_WIDTH - BUFFER_TOTAL ))

###########################################################################


##### FUNCTIONS #####

#-------------------------------------------------------------------------------
# clean up nicely
clean_up() {
	rm $TEMP_RAW 2>/dev/null
	rm $TEMP_EDIT 2>/dev/null
}
    
# show usage message
usage() {
	echo
	echo "------------ dub --------------"
	echo "Usage:"
	echo "  dub"
	echo "  dub [directory]"
	echo "  dub [-h | --help]"
	echo
	echo "Options:"
	echo "  -h --help  Show this message."
	echo
}

# display an error message
error_message() {
	echo -e "\nSomething went wrong.  See usage for help.\n"
}

# handle an error gracefully before exiting
error_exit() {
	clean_up
	error_message
	usage
	exit 1
}

# Handle any interrupts gracefully
trap clean_up SIGINT SIGTERM SIGHUP ERR

#-------------------------------------------------------------------------------
# get disk usage
get_du() {
	trap clean_up SIGINT SIGTERM SIGHUP ERR
	du -kd0 * > $TEMP_RAW
	cat $TEMP_RAW > $TEMP_EDIT
}

add_items() {
	return
}

remove_items() {
	return
}

find_longest_item() {
	trap clean_up SIGINT SIGTERM SIGHUP ERR
	#du_list=$(<$TEMP_EDIT)
	du_list=$(ls -F1)
	#max_item_length=$(for line in "${du_list}"; do echo -n "$line" \
	#                  | awk '{$1 = ""; print length($0)}'; done \
	#                  | sort -nr | head -n1)
	max_item_length=$(for line in "${du_list}"; do echo -n "$line" \
	                  | awk '{print length($0)}'; done \
	                  | sort -nr | head -n1)
}

find_longest_bar() {
	trap clean_up SIGINT SIGTERM SIGHUP ERR
	du_list=$(<$TEMP_EDIT)
	max_bar=$(echo "${du_list}" | awk '{print $1}' | sort -nr | head -n1)
	number_of_bars=$(echo "${du_list}" | wc -l | grep -o -E '[0-9]+')
}

find_longest_filesize() {
	trap clean_up SIGINT SIGTERM SIGHUP ERR
	du_list=$(<$TEMP_EDIT)
	FILESIZE_WIDTH=$(for line in "${du_list}"; do echo -n "$line" \
	                 | awk '{print length($1)}'; done \
	                 | sort -nr | head -n1)
	FILESIZE_WIDTH=$((FILESIZE_WIDTH+2))
	if [ $FILESIZE_WIDTH -lt $FILESIZE_WIDTH_min ]; then
		FILESIZE_WIDTH=$FILESIZE_WIDTH_min
	fi
}

scale_items() {
	trap clean_up SIGINT SIGTERM SIGHUP ERR
	if [ $max_item_length -gt $ITEM_WIDTH_max ]; then     # Too big
		ITEM_WIDTH=$ITEM_WIDTH_max
	elif [ $max_item_length -lt $ITEM_WIDTH_min ]; then   # Too small
		ITEM_WIDTH=$ITEM_WIDTH_min
	else                                                  # Just right
		ITEM_WIDTH=$max_item_length
	fi

    # Ensure ITEM_WIDTH is at least as big as ITEM_WIDTH_min
    if [ $ITEM_WIDTH -lt $ITEM_WIDTH_min ]; then
        ITEM_WIDTH=$ITEM_WIDTH_min
    fi
}

scale_bars() {
	trap clean_up SIGINT SIGTERM SIGHUP ERR

    # if bars need to be scaled back, scale them
	if [ $max_bar -gt $BAR_WIDTH_max ]; then
		BAR_WIDTH=$(( WIDTH - NUMBER_WIDTH - ITEM_WIDTH - FILESIZE_WIDTH - BUFFER_TOTAL ))
		scale=$(( max_bar / BAR_WIDTH ))

        # avoid dividing by zero
        if [ $scale -lt 1 ]; then
            scale=1
        fi
		
		# Check bar width after scaling, and make sure it doesn't spill over
		BW_check=$(( max_bar / scale ))
		if [ $BW_check -gt $BAR_WIDTH ]; then
			scale=$((scale+1))
		fi
		BAR_WIDTH=$((max_bar / scale))

    # if bars are very small naturally, make the BAR_WIDTH small
	elif [ $max_bar -le $BAR_WIDTH ]; then
		BAR_WIDTH=$max_bar
		scale=1
	else
		BAR_WIDTH=$max_bar
		scale=1
	fi

    # Ensure BAR_WIDTH is at least as big as BAR_WIDTH_min
    if [ $BAR_WIDTH -lt $BAR_WIDTH_min ]; then
        BAR_WIDTH=$BAR_WIDTH_min
    fi
}

# find longest bar length
fit_to_screen() {
	trap clean_up SIGINT SIGTERM SIGHUP ERR
	# find length of longest filesize, so scaling of everything else works out
	find_longest_filesize

	# if terminal is super small, make spaces smaller
	STAGE=$(( NUMBER_WIDTH + ITEM_WIDTH_min + BAR_WIDTH_min + FILESIZE_WIDTH + BUFFER_TOTAL ))
	if [ $WIDTH -lt $STAGE ]; then
		NUMBER_WIDTH=3
		BUFFER=1
		STAGE=$(( NUMBER_WIDTH + ITEM_WIDTH_min + BAR_WIDTH_min + FILESIZE_WIDTH + BUFFER_TOTAL ))
		if [ $WIDTH -lt $STAGE ]; then
            tput setaf 1
			echo -e "\nTerminal size too small to display.\n"
            tput sgr0
			clean_up
			exit 1
		fi
	fi

	find_longest_item
	find_longest_bar
	scale_items
	scale_bars
}


#-------------------------------------------------------------------------------
# print separator lines
print_separator() {
	STAGE_WIDTH=$(( NUMBER_WIDTH + ITEM_WIDTH + BAR_WIDTH + FILESIZE_WIDTH + BUFFER_TOTAL ))
	printf "%0.s-" $(seq 1 $STAGE_WIDTH)
	echo
}

#print top label bar
print_top_label_bar() {
	write_number "(#)"
	write_item "ITEM"
	write_SIZE "SIZE"
	write_size "(KB)"
}

# write item number
write_buffer() {
	FORMAT="%-${BUFFER}.${BUFFER}s" 
	ARGUMENTS=""
	printf "${FORMAT}" "${ARGUMENTS}"
}
# write item number
write_number() {
	FORMAT="%-${NUMBER_WIDTH}.${NUMBER_WIDTH}s" 
	ARGUMENTS="$1"
	printf "${FORMAT}" "${ARGUMENTS}"
	write_buffer
}

# write item
write_item() {
	item_string="${@}"
	item_length=${#item_string}

	# shorten item string, if necessary
	if [ $item_length -gt $ITEM_WIDTH ] && \
	   [ $item_length -gt 10 ] && \
	   [ $ITEM_WIDTH -gt 9 ]; then
		start=$((ITEM_WIDTH-9))
		end="(-5)"
		short_string="${item_string:0:$start}(..)${item_string:$end}"
		item_string="$short_string"
	fi

	FORMAT="%-${ITEM_WIDTH}.${ITEM_WIDTH}s" 
	ARGUMENTS=$item_string
	printf "${FORMAT}" "${ARGUMENTS}"
	write_buffer
}

# write size
write_SIZE() {
	FORMAT="%-${BAR_WIDTH}.${BAR_WIDTH}s " 
	ARGUMENTS="$1"
	printf "${FORMAT}" "${ARGUMENTS}"
	write_buffer
}

#draw a colored bar
draw_bar() {
	trap clean_up SIGINT SIGTERM SIGHUP ERR
	current_bar_scaled=$((current_bar_size / scale))
	max_bar_scaled=$((max_bar / scale))

	# set bar color (background color)
	tput setab $color

	# DRAW COLORED BAR
	# if the current directory is empty, draw blank
	if [ $current_bar_size = 0 ]; then
		tput sgr0	# return color to normal
	fi
	# draw the bar
	printf "%0.s " $(seq 0 $current_bar_scaled)
	tput sgr0	# return color to normal

	# add space for disk usage number at right
	printf "%$(( (max_bar_scaled - current_bar_scaled) ))s" ""

	# add a buffer space
	write_buffer
}

# write size (KB)
write_size() {
	FORMAT="%-.${FILESIZE_WIDTH}s" 
	ARGUMENTS=$1
	printf "${FORMAT}" "${ARGUMENTS}"
}



#-------------------------------------------------------------------------------
# print contents of current directory
print_directory_contents() {
	trap clean_up SIGINT SIGTERM SIGHUP ERR
	#list of contents in directory and estimated disk usage
	contents=$(<$TEMP_EDIT)

	# separate numbers (disk usage) and strings (content names)
	bar_sizes=$(for line in "${contents}"; do echo -n "$line" | awk '{print $1}'; done)
	#items=$(for line in "${contents}"; do echo -n "$line" \
	#        | awk '{$1 = "" ; print $0}' | sed 's/ //'; done)
	items=$(ls -F1)

	# MAKE TOP LABEL BAR
	# print the directory searched
	echo -ne "\n$( cd $directory 2>/dev/null | pwd )"
	# --------------------------------------------------
	# print a top line for separation
	echo
	print_separator
	print_top_label_bar
	echo
	print_separator
	# --------------------------------------------------

	# loop through directories and print results
	i=1
	while [ $i -le $number_of_bars ]; do

		# read top line of lists
		current_bar_size=$(echo -e "$bar_sizes" | head -n1)
		current_item=$(echo -e "$items" | head -n1)

		# delete top line of lists
		bar_sizes=$(echo -e "$bar_sizes" | sed 1d)
		items=$(echo -e "$items" | sed 1d)

		# 8 and 9 are not colors... so this is a workaround to use colors 1-7
		color=$(( (i%7) + 1 ))

		# Number entries
		write_number "$i"
		# write filename or directory name (cuts off extra-long names)
		write_item "$current_item"
		#draw colored bar
		draw_bar
		#print estimated size (from $(du))
		write_size "$current_bar_size"
		echo	#next line

		i=$((i+1))

	done

	# print a bottom line for separation
	print_separator
}



##### MAIN #####

# remove any old temp files
rm "$TEMP_DIR/$TEMP_NAME.?????" 2>/dev/null

# Add option to run script on a different directory
if [ "$1" != "" ]; then
	if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
		usage
		exit
	elif [ -d "$1" ]; then
		directory="$1"
		cd "$directory"
	elif [ "$1" = "-" ]; then
		directory="$OLDPWD"
		cd "$directory"
	else
		echo "  -->  Directory does not exist."
		usage
		clean_up
		exit 1
	fi
else
	directory=$PWD
fi

# let user know it is checking (in case it's in a heirearchy that will take a while to $(du) )
echo -e "\n...\nchecking disk space in $( cd $directory 2>/dev/null | pwd )\n..."

# get disk usage info and scale to terminal
get_du
fit_to_screen

# print bars, once ready with all the information
print_directory_contents

# remove temp files
clean_up
