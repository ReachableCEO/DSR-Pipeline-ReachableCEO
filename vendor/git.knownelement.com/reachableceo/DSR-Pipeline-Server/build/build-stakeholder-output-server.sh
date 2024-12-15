#!/bin/bash

set -euo pipefail

# Expand variables into rendered YAML files. These will be used by pandoc to format the output artifacts
$MO_PATH $YamlInputTemplateFileStakeholderOutput > $BUILDYAML_STAKEHOLDER_OUTPUT

echo "Creating stakeholder report..."

export StakeholderOutputMarkdownInputFile="../../StakeholderJoplin/@DailyStakeholderReports/PostedToDiscourse/DSR-12-10-2024.md"

cd "$(dirname $StakeholderOutputMarkdownInputFile)"

pandoc \
"$StakeholderOutputMarkdownOutputFile" \
--template $PANDOC_TEMPLATE \
--metadata-file="$BUILDYAML_STAKEHOLDER_OUTPUT" \
--from markdown \
--to=pdf \
--output $StakeholderOutputPDFOutputFile

cd -