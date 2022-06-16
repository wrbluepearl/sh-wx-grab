#!/bin/zsh

# wx-grab.sh

# Version 0.14 - 20210823

# Shell script to download today's weather story, public briefing, and forecast
# Converts the public briefing into .png files for convenient posting on social media
# Retrieves the current forecast for the given zone from the NWS weather API,
# extracts the current and next day's forecasts from the resulting json, and
# writes the whole mess to an RTF file to get formatting that can be copy/pasted into
# a chat window.

# Uses the following folders - these need to exist before script will work
#   weatherDir/forecast - holds the daily forecast.json/forecast.rtf files
#   weatherDir/publicbrief - destination for the daily public briefing PDF files
#   weatherDir/publicbrief/publicbrief-output - .png files for each page of the daily breifing PDF file
#   weatherDir/weatherstory - holds the weather story jpg files

# Makes use of the following utilities:
#   ImageMagick - extracts PDF document pages and writes .png files (https://imagemagick.org/)
#   jq - used to extract content from json in a bash script (https://stedolan.github.io/jq/)
#   https://gist.github.com/gilcreque/649485 - used to get basics of RTF file writing from shell script

# Uses the following services:
#   NWS API Web Service - provides the current forecast (https://www.weather.gov/documentation/services-web-api)
#   NWS website - BGM forecast information

# User-configurable settings here
weatherDir=~/weather	# root directory for weather stuff to be downloaded to
forecastZone=NYZ037		# used to pull the forecast for your location - figuring out what it should be is an exercise for the reader

# Now for the fun...

currentDate=`date +"%Y%m%d"`

# download today's weather story
# This may only work for NWS Binghamton, NY office - I don't know if other forecast offices publish anything like this

weatherStoryFilename=${weatherDir}/weatherstory/${currentDate}-rome-weatherstory.jpg

echo "Downloading today's weather story to ${weatherStoryFilename}"

curl -sSL https://www.weather.gov/images/bgm/weatherstory.jpg -o ${weatherStoryFilename}

# try to download today's weather briefing

publicBriefFilename=${weatherDir}/publicbrief/${currentDate}-rome-publicbrief.pdf
publicBriefPngDir=${weatherDir}/publicbrief/publicbrief-output

echo "Downloading today's public briefing to ${publicBriefFilename}"

responseCode=$(curl -sSL -w '%{http_code}' -o ${publicBriefFilename} https://www.weather.gov/media/bgm/publicbrief.pdf)

# if the response code starts with a 2xx, then we assume the download was successful and we can process the briefing

if [[ "$responseCode" =~ ^2 ]]; then
	echo "Generating png output from public briefing"
	rm -f ${publicBriefPngDir}/*.jpg
	magick -density 100 ${publicBriefFilename} ${publicBriefPngDir}/${currentDate}-rome-publicbrief-%02d.jpg
else
	echo "No public briefing available today."
fi

# Rome, NY is in forecast zone NYZ037, based on lat/long 43.2167,-75.4204
# Whitesboro, NY is in the same zone, so it doesn't matter which one you push in

# We're going to get a little fancier, and generate RTF rather than a plain txt file here.

forecastFilename=${weatherDir}/forecast/${currentDate}-rome-forecast.json
textForecastFilename=${weatherDir}/forecast/${currentDate}-rome-forecast.rtf

# Ripped off the following from a bash RTF generator script
# https://gist.github.com/gilcreque/649485

#Set font face
font="Segoe UI"

#Set font size in pt
fontsize=10.5

#Set document height in inches
height=11 #letter

#Set document width in inches
width=8.5

#Set document orientation
orientation="portrait"

#set document margins in inches
leftm=0.5
rightm=0.5
topm=0.5
bottomm=0.5

#calculate rtf sizes
fontsize=$(echo "$fontsize*2" | bc | sed 's/\.[^.]*$//')
height=$(echo "$height*1440" | bc | sed 's/\.[^.]*$//')
width=$(echo "$width*1440" | bc | sed 's/\.[^.]*$//')
leftm=$(echo "$leftm*1440" | bc | sed 's/\.[^.]*$//')
rightm=$(echo "$rightm*1440" | bc | sed 's/\.[^.]*$//')
topm=$(echo "$topm*1440" | bc | sed 's/\.[^.]*$//')
bottomm=$(echo "$bottomm*1440" | bc | sed 's/\.[^.]*$//')

#start header
printf '%s\n' "{\rtf1\ansi\deff0 {\fonttbl {\f0 $font;}}" > $textForecastFilename
printf '%s\n' "\paperh$height \paperw$width" >> $textForecastFilename
printf '%s\n' "\margl$leftm \margr$rightm \margt$topm \margb$bottomm" >> $textForecastFilename
printf '%s\n' "\f0\fs$fontsize" >> $textForecastFilename

# Begin writing the RTF file with the contents of the forecast json...
echo "Downloading forecast to ${forecastFilename}"

printf '%s\n' "{\b Rome, NY Forecast}\\line" >> ${textForecastFilename}

responseCode=$(curl -sSL -w '%{http_code}' -o ${forecastFilename} https://api.weather.gov/zones/forecast/${forecastZone}/forecast)
if [[ "$responseCode" =~ ^2 ]]; then
	echo "Extracting forecast text"
	for i in {0..3}
	do
		period=`jq ".properties.periods[${i}].name" < ${forecastFilename}`
		period=`sed -e 's/^"//' -e 's/"$//' <<<"$period"` # strip the double quotes at beginning/end of the text
		forecast=`jq ".properties.periods[${i}].detailedForecast" < ${forecastFilename}`
		forecast=`sed -e 's/^"//' -e 's/"$//' <<<"$forecast"`

		printf '%s\n' "{\b ${period}}: ${forecast} \\line" >> ${textForecastFilename}
	done
else
	echo "Error ${responseCode} retrieving forecast"
fi

#close rtf file
printf '%s\n' "}" >> $textForecastFilename

# Delete the JSON file, since we don't really need it anymore...
rm ${forecastFilename}

# Changelog
# 20210601 - Minor cleanup in the code that outputs the .rtf version of the forecast text to remove extraneous spaces,
#            removed warning stuff because that's going into a new script called wx-warning-grab.sh
# 20210729 - Changed the imagemagick command to output zero-padded filenames
# 20210823 - Added line to remove the .json forecast file
