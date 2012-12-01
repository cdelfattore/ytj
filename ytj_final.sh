#!/bin/bash

# Christopher Del Fattore
# Brian Castellaneta
# Jordan Digiovanni 

#variables for use in the script
keep=""
ifl=""
quiet=""
YT="http://www.youtube.com/"

#Afunction for extracting the youtube links from the results file
cleanup(){
#create the needed files
touch result.mod
touch links

#substitute all '/' for '!' for use later
cat result.html | awk '{gsub("/","!")}1' > result.mod

#iterate through the file and print all instances of whate we are looking for
#then use sed to remove any unnecessary text and finally save it to the links file
awk '{for(i=1;i<=NF;i++){if($i~/^href="!watch?/){print $i}}}' result.mod | sed "s/^href=*//g" | sed "s/^href=//g" | sed "s/\"//g"| sed "s/\!//g" > links

#clean up 
rm result.mod

}

#a function used when there are no search results
fail(){
cclive -q -O no.play "http://www.youtube.com/watch?v=xFGfWrJR5Ck"  & 
sleep 2s
mplayer -vo null no.play &> /dev/null &
wait $!
kill $$
rm no.play
}

#a function used to handle command line arguments
options() {

#if there are no args or any of them are equal to '-h' we display the usage menu
if [ $# -eq 0 -o "$1" = "-h" -o "$2" = "-h" -o "$3" = "-h" -o "$4" = "-h" ];then
  echo "Usage: ytj [OPTIONS] [URL]"
  echo "Available OPTIONS:"
  echo " -h: display a usage statement (also displayed if ytj is   called with no arguments)"
  echo " -k: keep downloaded video files (default behavior is to delete all downloaded flv files after they have been played."
  echo " -l:(I'm feeling lucky) download and play only the first search result."
  echo " -q: will silence the script so that it will not ask for user input"
  kill $$
fi
#if any of them are equal to '-k' we set the keep variable
if [ "$1" = "-k" -o "$2" = "-k" -o "$3" = "-k" -o "$4" = "-k" ];then

  keep="T"
fi
#if any of them are equal to '-l' we set the ifl variable
if [ "$1" = "-l" -o "$2" = "-l" -o "$3" = "-l" -o "$4" = "-l" ];then

  ifl="T"
fi
#if any of them are equal to '-q' we set the quiet variable
if [ "$1" = "-q" -o "$2" = "-q" -o "$3" = "-q" -o "$4" = "-q" ];then

  quiet="T"
fi
}

options $@

#create a directory on the user's desktop and move to it
dir=~/Desktop/videos
mkdir $dir
cd $dir

#store the search term in a file
echo "${@: -1:1}" > file;

# replace the spaces if any with + (plus signs)
addplus=`sed 's/  */+/g' file`;

# remove the tempary file called file
rm file;

wget -O result.html  "http://www.youtube.com/results?search_query=$addplus%2C+video&lclk=video";

#call the function to extract links
cleanup

#Test for results

[ -s links ]

if [ $? -ne 0 ];then
echo "No results found!"
fail
fi 

#Because the links file has duplicates wwe just skip every other link
count=0
# time to download the videos
while read line
do
check=$(( $count % 2 ))
 if [ $check -eq 0 ];then
   #this line goes out and downloads the videos
   cclive -q  "$YT$line" & 
   #echo "line -- $YT$line"
   #echo "check = $check"
   #if the "im feeling lucky" option is selected it will break the lop after       downloading the first video
   if [ "$ifl" != "" ];then
      break
   fi
        
 fi
 count=$((count+1))
done <links
#sleep for 10s to allow cclive to download some of the file
sleep 10s

#a warning to the user that they can stop the script when asked to skip a video only if unsilenced
if [ "$quiet" = "" ];then
echo "To exit early type \"stop\" when prompted to skip"
fi

#for all files in our newly created video folder
for file in *
do
    #if one of the files is one we creted skip it
    if [ "$file" = "links" -o "$file" = "result.html" ]; then
	echo "" #echo "skipping file"
    else

      if [ "$quiet" != "" ];then
	
	  nohup mplayer -vo null "$file" &> /dev/null &
          wait $!

	else

	  #else play it, tell us the name, and inform us we can skip it
          mplayer -vo null "$file" &> /dev/null &
	  echo "Now Playing: $file"
          echo "skip file? [Enter any character for yes else just press Enter]"
	  #read in the users choice
          read choice
	  #typing stop will kill the script
            if [ "$choice" = "stop" ]; then
	      #this command kills the newly backgrounded process and exits the loop
	      kill -9 $! &> /dev/null
              break
            elif [ -n "$choice" ]; then
	      #this kills the newly backgrounded process and continues
	      kill -9 $! &> /dev/null
            else
	      #continue the loop and wait for this instance of mplayer to finish before continuing with the loop
	      echo "Continuing..."
	      wait $!
            fi

      fi

    fi
done

#remove any existing temporary files
rm result.html
#rm links
#if the keep files option is select the videos folder we created will be saved
if [ "$keep" != "" ];then
	echo "keeping files..."
   else
	echo "Stopping cclive"
        killall cclive
   	rm -r $dir

fi


