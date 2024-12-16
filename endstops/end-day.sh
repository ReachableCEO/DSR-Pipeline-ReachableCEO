#!/bin/bash

# Wrap up my instrumented day into a (mostly) automated report and publish to discourse

# Gather DSR assets

# My manually entered notations
./dsr-input/dsr-gather-joplin-log.sh

# My gitea data
./dsr-input/dsr-gather-gitea.sh

# My redmine data
./dsr-input/dsr-gather-redmine.sh

# My wakapi data
./dsr-input/dsr-gather-waka-api.sh

# My activity watch data
./dsr-input/dsr-gather-activitywatch.sh

# My habit tracker data
./dsr-input/dsr-gather-habits.sh

# My health/fitnes data 
./dsr-input/dsr-gather-fitness.sh

# My diet data
./dsr-input/dsr-gather-diet.sh

# Produce DSR PDF asset
./dsr-publish/create-dsr-pdf.sh

# Publish DSR to the world
./dsr-publish/publish-dsr.sh