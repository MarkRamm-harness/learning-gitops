# GitOps Patcher

GitOps Patcher is a utility script designed to automate the patching of configuration files in a Git repository based on a specified set of updates or a patch file.

## Usage

1. Prepare your `update.yaml` file following the schema provided below.
2. Ensure `jq` and `yq` are installed on the machine where this script will run.
3. Run the script by executing `./gitops_patcher.sh update.yaml`.

## `update.yaml` Schema

```yaml
pr_details:
  commit_message: "Update application configuration"
  branch_name: "config-update"
  pr_title: "Configuration Update"
  pr_body: "This PR updates the application configuration for better performance."

patch_data:
  patch_file: "path/to/patch_file.json"  # Optional: Contains all the updates
  files:
    - git_ref: "main"
      file_path: "path/to/file1.yaml"
      updates:
        - path: "spec.version"
          value: "2.0.0"
        - path: "metadata.name"
          value: "NewName"
    - git_ref: "development"
      file_path: "path/to/file2.json"
      updates:
        - path: "max_connections"
          value: "1000"
