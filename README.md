# sh-wx-grab
Shell script for retrieving the weather forecast and weather story for a particular forecast zone

Makes use of the following utilities:
- ImageMagick - extracts PDF document pages and writes .png files (https://imagemagick.org/)
- jq - used to extract content from json in a bash script (https://stedolan.github.io/jq/)
- https://gist.github.com/gilcreque/649485 - used to get basics of RTF file writing from shell script

Uses the following services:
- NWS API Web Service - provides the current forecast (https://www.weather.gov/documentation/services-web-api)
- NWS website - daily 'weather story' download