#!/bin/bash

# Start my instrumented day 

# Create a new blank DSR for the day 
./dsr-joplin-create/dsr-new.sh

# Populate my Joplin note "Todays objectives" section based on Redmine due dates
./dsr-joplin-create/dsr-populate-objectives.sh
