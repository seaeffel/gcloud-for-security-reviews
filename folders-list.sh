#credit to https://stackoverflow.com/questions/63851466/how-to-get-all-the-gcp-folders-from-an-organization-with-gcloud
#This script lists all the folder IDs for all folders in your organization.
#TO DO: Develop this to use the folder ID outputs as input to list org-policies
#!/usr/bin/env bash

: "${ORGANIZATION=ORG_ID}"

# gcloud format
FORMAT="csv[no-heading](name,displayName.encode(base64))"

# Enumerates Folders recursively
folders()
{
  LINES=("$@")
  for LINE in ${LINES[@]}
  do
    # Parses lines of the form folder,name
    VALUES=(${LINE//,/ })
    FOLDER=${VALUES[0]}
    # Decodes the encoded name
    NAME=$(echo ${VALUES[1]} | base64 --decode)
    echo "Folder: ${FOLDER} (${NAME})"
    folders $(gcloud resource-manager folders list \
      --folder=${FOLDER} \
      --format="${FORMAT}")
  done
}

# Start at the Org
echo "Org: ${ORGANIZATION}"
LINES=$(gcloud resource-manager folders list \
  --organization=${ORGANIZATION} \
  --format="${FORMAT}")

# Descend
folders ${LINES[0]}
