```
#credit from https://stackoverflow.com/questions/63851466/how-to-get-all-the-gcp-folders-from-an-organization-with-gcloud
#!/usr/bin/env bash

: "${ORGANIZATION=ORG_ID}"

# gcloud format
FORMAT="csv[no-heading](name,displayName.encode(base64))"
FORMAT_PRJ="table[box,title='Folder ${NAME} Project List'] \
(createTime:sort=1,name,projectNumber,projectId:label=ProjectID,parent.id:label=Parent)"

# Enumerates Folders recursively
folders()
# project()
{
  LINES=("$@")
  for LINE in ${LINES[@]}
  do
    # Parses lines of the form folder,name
    VALUES=(${LINE//,/ })
    FOLDER=${VALUES[0]}

    # Decodes the encoded name
    NAME=$(echo ${VALUES[1]} | base64 --decode)
    printf "Folder: ${FOLDER} (${NAME})\n\n"

    printf "Project: Project info: \n\n"
    project=$(gcloud projects list \
      --filter parent.id:${FOLDER} \
      --format="${FORMAT_PRJ}")

    if [ -z "$project" ]
    then
      printf "Folder: ${FOLDER} - ${NAME} has no sub-projects\n\n"
    else
      printf "Parent FolderID: ${FOLDER}\t Parent Name(s): ${NAME}\n${project} \n\n"
    fi

    folders $(gcloud resource-manager folders list \
      --folder=${FOLDER} \
      --format="${FORMAT}")

  done
}

# Start at the Org
printf "Org: ${ORGANIZATION}\n\n"
LINES=$(gcloud resource-manager folders list \
  --organization=${ORGANIZATION} \
  --format="${FORMAT}")

# Descend
folders ${LINES[0]```
