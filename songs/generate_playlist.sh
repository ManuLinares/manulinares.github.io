#!/bin/bash

echo "var jsonTrackList = ["

i=1
for f in files/*.ogg
do

	#title=$(basename "$f" | cut -f1 -d".")

	secs=$(soxi -D "$f" | cut -f1 -d".")
	length=$(printf '%02d:%02d\n'  $((secs%3600/60)) $((secs%60)))

	filename=$(basename -- "$f")
	extension="${filename##*.}"
	filename="${filename%.*}"

	echo "{"
	echo "\"track\": $i,"
	echo "\"name\": \""$filename"\","
	echo "\"length\": \"$length\","
	echo "\"file\": \"$filename\""
	echo "},"

	((i=i+1))
done

echo "];"