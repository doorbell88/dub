#!/bin/bash

# A Program to show the number of files/directories in a given directory,
# and how much memory each one takes


##### CONSTANTS #####

# width of terminal window
WIDTH=$(tput cols)
if [ $WIDTH -gt 170 ];then
	WIDTH=170
fi

# formatting constants
MARGIN=5
LABEL_WIDTH=25
DU_WIDTH=20
GRAPH_WIDTH=$(( WIDTH - LABEL_WIDTH - DU_WIDTH - (3*MARGIN) ))
scale=1

# current directory
# directory=$(pwd)



##### FUNCTIONS #####

# find longest bar length
fit_to_screen() {
	max_bar=$(du -kd0 * | grep -o -E '[0-9]+' | sort -nr | head -n1)
	number_of_bars=$(du -kd0 * | wc -l | grep -o -E '[0-9]+')

	if [ $max_bar -gt $GRAPH_WIDTH ]; then
		scale=$(( (max_bar / GRAPH_WIDTH) ))
	fi
}


#draw a colored bar
draw_bar() {
	current_bar_scaled=$((current_bar_size / scale))
	max_bar_scaled=$((max_bar / scale))

	# draw colored bar (background color)
	tput setab $color
	printf "%0.s " $(seq 0 $current_bar_scaled)
	tput sgr0	# return color to normal

	# add space for disk usage number at right
	printf "%$(( (max_bar_scaled - current_bar_scaled) ))s" ""
}


# get contents of current directory
print_directory_contents() {

	#list of contents in directory and estimated disk usage
	contents=$(du -kd0 *)
	contents_names=$(du -d0 * | sed -E 's/[0-9]+//')

	# separate numbers (disk usage) and strings (content names)
	bar_sizes=$( echo $contents | grep -o -E '[0-9]+' )
	bar_labels=$contents_names


	# MAKE TOP LABEL BAR

	# print the directory searched
	echo -ne "\n$( cd $directory 2>/dev/null | pwd )"
	# --------------------------------------------------
	# print a top line for separation
	echo
	printf "%0.s-" $(seq 1 $WIDTH)
	echo
	# --------------------------------------------------

	#print top label bar
	echo -n "(#)"
	printf "\t%-*.*s\t%-$((max_bar/scale))s\t%s"	\
			${LABEL_WIDTH} ${LABEL_WIDTH} \
			"ITEM"		"RELATIVE SIZE"		"(KB)"

	# --------------------------------------------------
	# print a top line for separation
	echo
	printf "%0.s-" $(seq 1 $WIDTH)
	echo

	# --------------------------------------------------


	# loop through directories and print results
	i=1
	while [ $i -le $number_of_bars ]; do

		# read top line of lists
		current_bar_size=$(echo -e "$bar_sizes" | head -n1)
		current_bar_label=$(echo -e "$bar_labels" | head -n1)

		# delete top line of lists
		bar_sizes=$(echo -e "$bar_sizes" | sed 1d)
		bar_labels=$(echo -e "$bar_labels" | sed 1d)


		# 8 and 9 are not colors... so this is a workaround to use colors 1-7
		color=$(( (i%7) + 1 ))


		# Number entries
		printf "%-*.*s" 3 3 "$i"
		# cuts off extra-long filenames
		printf "%-*.*s\t" ${LABEL_WIDTH} ${LABEL_WIDTH} "$current_bar_label"
		#draw colored bar
		draw_bar
		#print estimated size (from $(du))
		printf "\t%s"  "$current_bar_size"
		echo	#next line


		i=$((i+1))

	done


	# print a bottom line for separation
	printf "%0.s-" $(seq 1 $WIDTH)
	echo -e "\n"

}







##### MAIN #####

# Add option to run script on a different directory
if [ "$1" != "" ]; then
	if [ -d $1 ]; then
		directory=$1
		cd $directory
	else
		echo "  -->  Directory does not exist."
		exit 1
	fi
else
	directory=$PWD
fi

# let user know it is checking (in case it's in a heirearchy that will take a while to $(du) )
echo -e "\n...\nchecking disk space in $( cd $directory 2>/dev/null | pwd )\n..."



fit_to_screen

print_directory_contents



