#!/bin/bash

# Christopher Del Fattore
# Brian Castellaneta
# Jordan Digiovanni 


#Create a directory on the users desktop and go to it, this is where all our work will be done

keep=""
ifl=""
quiet=""


options() {

if [ $# -eq 0 -o "$1" = "-h" -o "$2" = "-h" -o "$3" = "-h" -o "$4" = "-h" ];then
  echo "Usage: ytj [OPTIONS] [URL]"
  echo "Available OPTIONS:"
  echo " -h: display a usage statement (also displayed if ytj is   called with no arguments)"
  echo " -k: keep downloaded video files (default behavior is to delete all downloaded flv files after they have been played."
  echo " -l:(I'm feeling lucky) download and play only the first search result."
  echo " -q: will silence the script so that it will not ask for user input"
  kill $$
fi

if [ "$1" = "-k" -o "$2" = "-k" -o "$3" = "-k" -o "$4" = "-k" ];then

  keep="T"
fi

if [ "$1" = "-l" -o "$2" = "-l" -o "$3" = "-l" -o "$4" = "-l" ];then

  ifl="T"
fi
if [ "$1" = "-q" -o "$2" = "-q" -o "$3" = "-q" -o "$4" = "-q" ];then

  quiet="T"
fi
}

options $@

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

#Find the links to the videos in result.html and download the videos
#use grep with the following unique regular expression
#this regular expression only takes the lines with the links to the videos that match our
#search results, this regular expressions excludes featured videos and similar videos

grep '<div class="yt-lockup-thumbnail"><a href="/watch?v=' result.html |

#now use sed commands to get ride of the html text beside the link we want
#first use this sed to remove most of the html before the link we need

sed 's/<div  id=""  class="yt-uix-tile yt-lockup-list yt-tile-default yt-grid-box "><div class="yt-lockup-thumbnail">//g' |

#more sed needed, little by little i will have the link to the url of each video

sed 's/class="ux-thumb-wrap yt-uix-sessionlink yt-uix-contextlink contains-addto result-item-thumb"//g' |

# more

sed 's/<span class="video-thumb ux-thumb yt-thumb-default-185 "><span class="yt-thumb-clip"><span class="yt-thumb-clip-inner">//g' |

# you guessed it more!

sed 's/data-sessionlink=".*"><img src="http:\/\/.*<\/span>//g' |

# breakthrough almost done

sed 's/ *data-sessionlink="ved=.*&amp;ei=.*><img.*alt=.*><span class="vertical-align"><\/span><\/span><\/span><\/span><span class="video-time">.*<\/span>//g' |

# last few

sed 's/<a href="\///g' |

sed 's/"//g' | sed 's/^  *//g' | sed 's/^/http:\/\/www\.youtube\.com\//g' > links;

# time to download the videos
while read line
do
#this line goes out and downloads the videos
cclive -q  $line & 
#if the "im feeling lucky" option is selected it will break the lop after downloading the first video
if [ "$ifl" != "" ];then
   break
fi

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
rm links
#if the keep files option is select the videos folder we created will be saved
if [ "$keep" != "" ];then
	echo "keeping files..."
   else
	echo "Stopping cclive"
        killall cclive
   	rm -r $dir

fi


