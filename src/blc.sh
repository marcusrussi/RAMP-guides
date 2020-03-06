#!/usr/bin/env bash

num=$(($RANDOM%9999))
python -m SimpleHTTPServer $num 2> /dev/null > /dev/null &
PID=$!

blc --filter-level 1 \
    --input "http://0.0.0.0:$num/$1" |
  aha | wkhtmltopdf --quiet - $2
  # ./src/ansi2html.sh > report.html

kill $PID

