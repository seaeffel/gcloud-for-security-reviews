# Org Policy Review

## Listing Org Policies configured at Folder Level 0.

    for i in $(gcloud resource-manager folders list --organization=ORG_ID | grep -o '[[:digit:]]*' | grep -v "ORG_ID" | awk '$0~length($0)==12' | awk '{print $1}' | awk 'NR>1'); do echo FOLDER: $i && echo "--" && gcloud resource-manager org-policies list --folder=$i && echo ""; done
    
The 'gcloud resource-manager folders list command' needed to obtain a list of Folder IDs is a bit messy due to the naming convention of the folders in the GCP environment that I was working on. In order to obtain the list of folder IDs, i needed to pipe the following onto the gcloud command;

### 1. Pick out strings that are only digits
    
    grep -o '[[:digit:]]*'
    
### 2. Remove the "org ID" results
    
    grep -v "ORG_ID"

### 3. Extract only numeric fields of length 12 
    
    awk '$0~length($0)==12'
    
The above was necessary as numbers in the project_id column were being displayed.

The 'gcloud resource-manager folders list' command was a little more complex than usually necessary due to the naming convention of the folders which meant that the output of the command in column format would be skewed due to the name of some folders being displayed in multiple columns. If there were no spaces in the names of the folders then you could attempt this which would print the third column only i.e. the column with the folder IDs.

    gcloud resource-manager folders list --organization=ORG_ID | awk '{print $3}' | awk 'NR>1')
    
So that the command to list the org-policies configured at folder level 0 would be;

    for i in $(gcloud resource-manager folders list --organization=ORG_ID | awk '{print $3}' | awk 'NR>1'); do echo FOLDER: $i && echo "--" && gcloud resource-manager org-policies list --folder=$i && echo ""; done

# Resource Management

## Identifying enabled APIs

To identify which project has a specific API enabled, run the following (here the Web Scanner API was investigated);

    for i in $(gcloud projects list | awk '{print $1}' | awk 'NR>1'); do echo PROJECT: $i && echo "--" && gcloud services list --project=$i --filter="(websecurityscanner.googleapis.com)" && echo ""; done

  
# IAM Review

## To investigate which users have permissions assigned directly to them: 
  
    for i in $(gcloud projects list | awk '{print $1}' | awk 'NR>1'); do echo PROJECT: $i && echo "--" && gcloud asset search-all-iam-policies --scope=projects/$i | grep user\: && echo ""; done
    
Note: This command doesn't list users that have permissions on the project that have been inherited from IAM policies configured at parent folder or the organisation level. This only describes user <> role bindings configured at the project level.

## To find which IAM policies a certain user has in a project:

    gcloud asset search-all-iam-policies --scope=projects/<PROJECT NAME> --query="policy:"<EMAIL ADDRESS>"
    
## To find which IAM policies a certain user has in the organisation:

    gcloud asset search-all-iam-policies --scope=organizations/<ORG NUMBER> --query="policy:"<EMAIL ADDRESS>"
    
## Which resources are publicly shared?

    gcloud asset search-all-iam-policies --scope=organizations/<ORG NUMBER> --query="policy:(allUsers OR allAuthenticatedUsers)"
    
## Are there deleted accounts in policies?

    gcloud asset search-all-iam-policies --scope=organizations/<ORG NUMBER> --query="policy:deleted"
    
## Does (USER EMAIL) have the owner role?

    gcloud asset search-all-iam-policies --scope=organizations/<ORG NUMBER> --query="policy:roles/owner <USER EMAIL>"
    
## What is the IAM policy for a given resource type?

    gcloud asset search-all-iam-policies --scope=organizations/<ORG NUMBER> --query="policy:roles/owner resource://cloudresourcemanager.googleapis.com/projects"
    
## Are there any gmail accounts in the GCP estate?

    gcloud asset search-all-iam-policies --scope=organizations/<ORG NUMBER> --query="policy:(*gmail*)"
    
Note: The above command does not search object-level permissions for gmail accounts.

# Network Security

## Identifying which subnets have VPC Flow Logs enabled

### At Project Level

    gcloud compute networks subnets list --format="table[box,title=FlowLoggingDisabled](name,enableFlowLogs,logConfig.enable:label=logging)"
  
Note: If any entry is blank or 'False', it means VPC Flow Logs are not enabled. If an entry is True, it means they are enabled.
By default, VPC Flow Logs are disabled. The output of the command above displays a table with all subnets which are not logging VPC Flow Logs. This might appear confusing as there may be a couple which explicitly state that VPC Flow Logs are disabled however this has been defined as a parameter in the code. The subnets that do not show anything in the last two columns do not have VPC Flow Logs turned on but since the default is to have them off, and reference to this is not defined in the code, the output is blank.

### Entire GCP estate

     for i in $(gcloud projects list | awk '{print $1}' | awk 'NR>1'); do echo PROJECT: $i && echo "--" && gcloud conmpute networks subnets list --filter='logConfig.enable=True' --format="table[box,title=FlowLoggingDisabled](name,enableFlowLogs,logConfig.enable:label=logging)" --project=$i && echo ""; done
  
Note: To list all subnets in all projects, rmeove the filter so that the output shows all subnets and whether or not they are logging VPC Flow Logs.

## Are firewall rules being logged?

### At project level

     gcloud compute firewall-rules list --filter='logConfig.enable=true'
  
### Entire GCP Estate

    for i in $(gcloud projects list | awk '{print $1}' | awk 'NR>1'); do echo PROJECT: $i && echo "--" && gcloud compute firewall-rules list --filter='logConfig.enable=true' && echo ""; done

Note: To identify which firewall rules are not loggin change the filter to logConfig=false

## Identify all VMs with a specific network tag

Note: Firewall rules on GCP are configured with network tags which are applied to virtual machines so that firewall rules are configured to apply to VMs that are specified. In order to identify the VM that are tagged with a specific network tag, these commands cam be used.

## Command to list the virtual machines of a specific network tag in a single project:

    gcloud compute instances list --filter="tags.item=<insert network tag>"
   
  
