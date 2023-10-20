
### 2) gitops_patcher.sh:
```bash
#!/bin/bash

# Function to parse YAML input
parse_input() {
  local input_file=$1
  echo "Parsing input file: $input_file"
  
  # Extracting PR details
  COMMIT_MESSAGE=$(cat $input_file | yq eval '.pr_details.commit_message' -)
  BRANCH_NAME=$(cat $input_file | yq eval '.pr_details.branch_name' -)
  PR_TITLE=$(cat $input_file | yq eval '.pr_details.pr_title' -)
  PR_BODY=$(cat $input_file | yq eval '.pr_details.pr_body' -)

  # Extracting patch information
  FILES=$(cat $input_file | yq eval '.patch_data.files' -j)
  PATCH_FILE=$(cat $input_file | yq eval '.patch_data.patch_file' -)
}

# Function to patch a YAML file
patch_yaml_file() {
  local file_path=$1
  local updates=$2

  echo "Patching YAML file: $file_path"

  # Using updates list to update the target file
  for update in $(echo $updates | jq -c '.[]'); do
    local path=$(echo $update | jq -r '.path')
    local value=$(echo $update | jq -r '.value')
    yq eval "$path = \"$value\"" $file_path > temp.yaml && mv temp.yaml $file_path
  done
}

# Function to patch a JSON file
patch_json_file() {
  local file_path=$1
  local updates=$2

  echo "Patching JSON file: $file_path"

  # Using updates list to update the target file
  for update in $(echo $updates | jq -c '.[]'); do
    local path=$(echo $update | jq -r '.path')
    local value=$(echo $update | jq -r '.value')
    jq ".$path = \"$value\"" $file_path > temp.json && mv temp.json $file_path
  done
}

# Main function to control the flow
main() {
  local input_file=$1

  # Parse the input
  parse_input $input_file

  # Clone the repo, checkout a new branch
  git clone https://$GIT_USERNAME:$GIT_PASSWORD@$GIT_REPO_URL
  cd $(basename $GIT_REPO_URL .git)
  git checkout -b $BRANCH_NAME

  # Patch the git files
  if [[ $PATCH_FILE != "null" && -f $PATCH_FILE ]]; then
    jq -s '.[0] * .[1]' */* $PATCH_FILE > temp.json && mv temp.json */*
  else
    for file_info in $(echo $FILES | jq -c '.[]'); do
      local git_ref=$(echo $file_info | jq -r '.git_ref')
      local file_path=$(echo $file_info | jq -r '.file_path')
      local updates=$(echo $file_info | jq -r '.updates')
      git checkout $git_ref
      file_extension="${file_path##*.}"
      if [[ $file_extension == "yaml" ]]; then
        patch_yaml_file "$file_path" "$updates"
      elif [[ $file_extension == "json" ]]; then
        patch_json_file "$file_path" "$updates"
      else
        echo "Unsupported file type: $file_extension"
      fi
    done
  fi

  # Commit, push the changes and create a PR
  git add .
  git commit -m "$COMMIT_MESSAGE"
  git push origin $BRANCH_NAME
  gh pr create --base main --head $BRANCH_NAME --title "$PR_TITLE" --body "$PR_BODY"
}

# Execute the main function with the input file as argument
main $1
