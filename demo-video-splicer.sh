
#!/bin/bash
# ·▄▄▄▄  ▄▄▄ .• ▌ ▄ ·.            ▌ ▐·▪  ·▄▄▄▄  ▄▄▄ .          .▄▄ ·  ▄▄▄·▄▄▌  ▪   ▄▄· ▄▄▄ .▄▄▄  
# ██▪ ██ ▀▄.▀··██ ▐███▪▪         ▪█·█▌██ ██▪ ██ ▀▄.▀·▪         ▐█ ▀. ▐█ ▄███•  ██ ▐█ ▌▪▀▄.▀·▀▄ █·
# ▐█· ▐█▌▐▀▀▪▄▐█ ▌▐▌▐█· ▄█▀▄     ▐█▐█•▐█·▐█· ▐█▌▐▀▀▪▄ ▄█▀▄     ▄▀▀▀█▄ ██▀·██▪  ▐█·██ ▄▄▐▀▀▪▄▐▀▀▄ 
# ██. ██ ▐█▄▄▌██ ██▌▐█▌▐█▌.▐▌     ███ ▐█▌██. ██ ▐█▄▄▌▐█▌.▐▌    ▐█▄▪▐█▐█▪·•▐█▌▐▌▐█▌▐███▌▐█▄▄▌▐█•█▌
# ▀▀▀▀▀•  ▀▀▀ ▀▀  █▪▀▀▀ ▀█▄▀▪    . ▀  ▀▀▀▀▀▀▀▀•  ▀▀▀  ▀█▄▀▪     ▀▀▀▀ .▀   .▀▀▀ ▀▀▀·▀▀▀  ▀▀▀ .▀  ▀
# Author: Chris Watkins
# Date: 2023-08-18
# Drop numbered audio and video files into the "original" directory
# The script will concatinate them into a singlke video/audio file.
# drop a thumbnail "intro-png" and it will make a lead that is preapended to your video



# Directory structure
CUR_DIR="$(realpath "./")"
TEMP="$CUR_DIR/temp"
ORIGINAL="$CUR_DIR/original"

# TEMP files
CONCAT="$TEMP/merged-video.mp4"
SPEEDUP="$TEMP/speedup-video.mp4"
VIDEO_TRACK="$TEMP/video-track.mp4"
AUDIO_TRACK="$TEMP/audio-track.mp3"

# OUTPUT FILE
VIDEO="$CUR_DIR/output.mp4"

# the image to convert into a the video clop
IMAGE="$ORIGINAL/intro.png"
INTRO="$TEMP/intro.mp4"

# These are the list files ffmpeg uses as inputs
CODE_LIST="$TEMP/code-list.txt"
AUDIO_LIST="$TEMP/audio-list.txt"
VIDEO_LIST="$TEMP/video-list.txt"

list_files() {
  # Parameters
  directory="$1"
  file_type="$2"
  output_file="$3"
  echo $directory
  
  # Check if the directory exists
  if [ ! -d "$directory" ]; then
    echo "Directory does not exist: $directory"
    return 1
  fi

  # Clear the file if it exists
  echo "" > "$output_file"

  # Loop through files in the directory and write to the output file, order by filename numerically asc
  find "$directory" -type f -name *.$file_type  -exec basename  {} \; | sort -V |  awk -v dir="$directory" -v out="$output_file" -v quote="\047"  '{ print "file "  quote "file:" dir  "/" $0 quote >> out }'

  echo "Files with extension .$file_type have been listed in $output_file"
}

check_last_command_status() {
  if [ $? -ne 0 ]; then
    echo "The last command failed with an error."
    exit
    #return 1
  else
    echo "The last command was successful."
    return 0
  fi
}

echo "Removing temp files"
rm -f "$INTRO"
rm -f "$CONCAT"
rm -f "$SPEEDUP"
rm -f "$VIDEO_TRACK"
rm -f "$AUDIO_TRACK"
rm -f "$VIDEO"
rm -f "$CODE_LIST"
rm -f "$AUDIO_LIST"
rm -f "$VIDEO_LIST"

echo "file 'file:$INTRO'">"$VIDEO_LIST"
echo "file 'file:$SPEEDUP'">>"$VIDEO_LIST"
# creates a list of video files to concat, orders numerically asc
list_files "$ORIGINAL" "mkv" "$CODE_LIST"
check_last_command_status

# creates a list of audio files to concat, orders numerically asc
list_files "$ORIGINAL" "flac" "$AUDIO_LIST"
check_last_command_status



echo "Converting Videos"
# Make a video of the image we have as the intro
ffmpeg -loop 1 -i "$IMAGE" -c:v libx264 -t 15 -pix_fmt yuv420p -vf scale=1920:1080 "$INTRO"
check_last_command_status

# Merge all of the video snipits from development into 1 file
ffmpeg -f concat -safe 0 -i "$CODE_LIST" -an -c copy "$CONCAT"
check_last_command_status

# Speedup that merged video by 4x
ffmpeg -itsscale 0.25 -i "$CONCAT" -c copy "$SPEEDUP"
check_last_command_status

# create a single video from the intro video and the spedup video
ffmpeg -f concat -safe 0 -i "$VIDEO_LIST" -an -c copy "$VIDEO_TRACK"
check_last_command_status


# Take the audio files and merge them into 1
ffmpeg -f concat -safe 0 -i "$AUDIO_LIST" "$AUDIO_TRACK"
check_last_command_status

# layer the new audio track onto of the final video
ffmpeg  -i "$VIDEO_TRACK" -i "$AUDIO_TRACK" -c copy -map 0:v:0 -map 1:a:0 "$VIDEO"
check_last_command_status




