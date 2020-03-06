#!/usr/bin/env bash

# Random port number between 0 and 9998
num=$(($RANDOM%9999))

# Start an HTTP server for 'blc' to access .html files in this directory,
# make it quiet by redirecting output to /dev/null. Runs in background.
python -m SimpleHTTPServer $num 2> /dev/null > /dev/null &

# Store the PID so we can kill it later
PID=$!

# --filter-level means it will not look for certain kinds of broken links,
#   see 'man blc'
# 'aha' and 'wkhtmltopdf' basically take colorized terminal output and save
# it into a pdf, however, right now the colors aren't working for some reason.
blc --filter-level 1 \
    --input "http://0.0.0.0:$num/$1" |
  aha | wkhtmltopdf --quiet - $2

# End the http server
kill $PID

