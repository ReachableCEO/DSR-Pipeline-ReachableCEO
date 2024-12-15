# DailyStakeholderReport-Pipeline

- [DailyStakeholderReport-Pipeline](#dailystakeholderreport-pipeline)
  - [Introduction](#introduction)
  - [Scripts](#scripts)
    - [Start a new day](#start-a-new-day)
      - [Create a new (blank) DSR](#create-a-new-blank-dsr)
      - [Populate the new DSR with objectives for the day](#populate-the-new-dsr-with-objectives-for-the-day)
    - [End the day](#end-the-day)
      - [Collating and Publishing the report](#collating-and-publishing-the-report)
      - [Gathering data for the report](#gathering-data-for-the-report)

## Introduction

I publish a daily stakeholder report to the TSYS Group discourse every day. Up until 11/29 I was performing the publishing step manually. On 11/29 I automated the pdf creation and publishing to discourse procedure.

I also begin work on automated gathering of data going into the new version of the report that is in development.

## Scripts

### Start a new day

Start a new day. See the script: **endstops/start-day.sh**

#### Create a new (blank) DSR

See the script: **dsr-joplin-create/dsr-new.sh**

#### Populate the new DSR with objectives for the day

See the script: **dsr-joplin-create/dsr-populate-objectives.sh**

### End the day

End the day. See the script: **endstops/end-day.sh**

#### Collating and Publishing the report

Publishing the report involves three steps:

1. Exporting the markdown from Joplin (and any attachments (i often take screenshots throughout the day)) I am still doing this manually due to having issues installing the Joplin CLI.

2. Creating a (formatted/styled) PDF from the exported markdown/attachments. See the script: **dsr-publish/create-dsr-pdf.sh**.

3. Uploading the PDF to discourse and creating a new topic in the appropriate category. See the script: **dsr-publish/publish-dsr.sh**

#### Gathering data for the report