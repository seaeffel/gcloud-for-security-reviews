# Org Policy Review

## Listing Org Policies configured at all folder levels.

Alternatively run the shell script [folders-list.sh](./folders-list.sh), (modify the script in order to output only the folder IDs) save the output locally then run the following command to obtain the org-policies configured at project-level across the organisation.

```for i in $(cat folders.txt | awk 'NR>1'); do echo FOLDER: $i && echo "--" && gcloud resource-manager org-policies list --folder=$i && echo ""; done```

This is very useful in order to identify where org-policies that should be inherited from the organisation level may have been customised to have a different configuration. This type of thing should be investigated to ensure there is a legitimate business justification for not inheriting the policy configuration of a parent resource.

## Listing the configuration of org-policies that are configured at the org-level

```for i in $(gcloud resource-manager org-policies list --organization=ORG_ID| grep constraints/ | awk '{print $2}' ); do echo ORG-POLICY: $i && echo "--" && gcloud resource-manager org-policies describe $i --organization=ORG_ID & echo ""; done```

## Listing the configuration of org-policies that are configured at project level

You will want to ensure you aren't reviewing the org-policies for the 'apps-script' projects as there are alot of them so ensure to add the filter to remove all projects under the APPS_SCRIPT folder.

```for i in $(gcloud projects list --filter="NOT parent.id:APPS_SCRIPT_FOLDER” | grep PROJECT_ID | awk '{print $2}'); do echo PROJECT: $i && echo "--" && gcloud resource-manager org-policies list --project=$i && echo ""; done```

# Resource Management

## Identifying enabled APIs

To identify which project has a specific API enabled, run the following (here the Web Scanner API was investigated);

```for i in $(gcloud projects list --filter=<ORG_ID> |  awk '{print $1}'); do echo "Project -- $i" && gcloud services list --project=$i --filter='cloudkms.googleapis.com' && echo ""; done 2>&1```

  
# IAM Review

## To investigate which users have permissions assigned directly to them: 
  
```for i in $(gcloud projects list | awk '{print $1}' | awk 'NR>1'); do echo PROJECT: $i && echo "--" && gcloud asset search-all-iam-policies --scope=projects/$i | grep user\: && echo ""; done```
    
Note: This command doesn't list users that have permissions on the project that have been inherited from IAM policies configured at parent folder or the organisation level. This only describes user <> role bindings configured at the project level.

## To find which IAM policies a certain user has in a project:

```gcloud asset search-all-iam-policies --scope=projects/<PROJECT NAME> --query="policy:"<EMAIL ADDRESS>"```
    
## To find which IAM policies a certain user has in the organisation:

```gcloud asset search-all-iam-policies --scope=organizations/<ORG NUMBER> --query="policy:"<EMAIL ADDRESS>"```
    
## Which resources are publicly shared?

```gcloud asset search-all-iam-policies --scope=organizations/<ORG NUMBER> --query="policy:(allUsers OR allAuthenticatedUsers)"```
    
## Are there deleted accounts in policies?

```gcloud asset search-all-iam-policies --scope=organizations/<ORG NUMBER> --query="policy:deleted"```
    
## Does (USER EMAIL) have the owner role?

```gcloud asset search-all-iam-policies --scope=organizations/<ORG NUMBER> --query="policy:roles/owner <USER EMAIL>"```

## Who has role X?

```gcloud asset search-all-iam-policies --scope=organizations/<ORG NUMBER> --query="policy:roles/<role>"```
    
## What is the IAM policy for a given resource type?

```gcloud asset search-all-iam-policies --scope=organizations/<ORG NUMBER> --query="policy:roles/owner resource://cloudresourcemanager.googleapis.com/projects"```
    
## Are there any gmail accounts in the GCP estate?

```gcloud asset search-all-iam-policies --scope=organizations/<ORG NUMBER> --query="policy:(*gmail*)"```
    
Note: The above command does not search object-level permissions for gmail accounts.

## Are Project Viewers able to view objects in the project?

By default, Viewers inherit roles/storage.legacyObjectReader if buckets are configured with Uniform Bucket Level access considered [Convenience values](https://cloud.google.com/storage/docs/access-control/iam-roles#basic-roles-modifiable). To determine if Viewers of projects are able to view data within the projects run the following command to list the projects;

```gcloud asset search-all-iam-policies --scope=organizations/388347670233 --query="policy:roles/storage.legacyObjectReader" | grep projectViewer```

## Debugging Quota limits

### To identify the number of IAM Bindings (counts the member(s)<>role bindings in an IAM Policy)

```gcloud projects get-iam-policy $PROJECT_ID --format=json | jq '.bindings | length'``` OR
```gcloud organizations get-iam-policy <ORG_ID> --format=json | jq '.bindings | length'```

### To list (non-unique) members of IAM Bindings;

```gcloud projects get-iam-policy $PROJECT_ID --format=json | jq ".bindings[].members" | jq -s flatten```

### To list unique members of IAM Bindings;

```gcloud organizations get-iam-policy <ORG_ID> --format=json | jq ".bindings[].members" | jq -s flatten | sort | uniq -c | sort -nr```

# Cloud Storage 

## To identify the access control of Cloud Storage Buckets in a project

```for i in $(gsutil ls | awk '{print $1}' | awk 'NR>1'); do echo ACL: $i && echo "--" && gsutil ubla get $i&& echo ""; done```

Note: The command above needs to be improved to identify any buckets in the gcp estate that do not have uniform bucket-level access enabled

## To identify which Cloud Storage buckets have a lifecycle policy configured.

The command below can be used for identifying the configuration for buckets in a project.

```for i in $(gsutil ls | awk '{print $1}' | awk 'NR>1'); do echo PROJECT: $i && echo "--" && gsutil lifecycle get $i && echo ""; done```

# Network Security

## Identifying which subnets have VPC Flow Logs enabled

### At Project Level

```gcloud compute networks subnets list --format="table[box,title=FlowLoggingDisabled](name,enableFlowLogs,logConfig.enable:label=logging)"```
  
Note: If any entry is blank or 'False', it means VPC Flow Logs are not enabled. If an entry is True, it means they are enabled.
By default, VPC Flow Logs are disabled. The output of the command above displays a table with all subnets which are not logging VPC Flow Logs. This might appear confusing as there may be a couple which explicitly state that VPC Flow Logs are disabled however this has been defined as a parameter in the code. The subnets that do not show anything in the last two columns do not have VPC Flow Logs turned on but since the default is to have them off, and reference to this is not defined in the code, the output is blank.

### Entire GCP estate

```for i in $(gcloud projects list | awk '{print $1}' | awk 'NR>1'); do echo PROJECT: $i && echo "--" && gcloud compute networks subnets list --filter='logConfig.enable=True' --format="table[box,title=FlowLoggingDisabled](name,enableFlowLogs,logConfig.enable:label=logging)" --project=$i && echo ""; done```
  
Note: To list all subnets in all projects, rmeove the filter so that the output shows all subnets and whether or not they are logging VPC Flow Logs.

## Are firewall rules being logged?

### At project level

```gcloud compute firewall-rules list --filter='logConfig.enable=true'```
  
### Entire GCP Estate

```for i in $(gcloud projects list | awk '{print $1}' | awk 'NR>1'); do echo PROJECT: $i && echo "--" && gcloud compute firewall-rules list --filter='logConfig.enable=true' && echo ""; done```

Note: To identify which firewall rules are not loggin change the filter to logConfig=false

## Identify all VMs with a specific network tag

Note: Firewall rules on GCP are configured with network tags which are applied to virtual machines so that firewall rules are configured to apply to VMs that are specified. In order to identify the VM that are tagged with a specific network tag, these commands cam be used.

## Command to list the virtual machines of a specific network tag in a single project:

```gcloud compute instances list --filter="tags.item=<insert network tag>"```
   
  
