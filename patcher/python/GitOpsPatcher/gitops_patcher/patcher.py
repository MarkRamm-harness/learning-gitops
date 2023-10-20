import os
import subprocess
import json
import yaml
from gitops_patcher import utils

class GitOpsPatcher:
    def __init__(self, config):
        self.config = config
        self.repo_dir = None

    def clone_repo(self):
        repo_url = f"https://{self.config['git_username']}:{self.config['git_password']}@{self.config['git_repo_url']}"
        self.repo_dir = os.path.basename(self.config['git_repo_url']).replace('.git', '')
        subprocess.run(['git', 'clone', repo_url])
        os.chdir(self.repo_dir)

    def checkout_branch(self, branch_name):
        subprocess.run(['git', 'checkout', '-b', branch_name])

    def patch_file(self, file_path, updates):
        with open(file_path, 'r') as file:
            data = yaml.load(file, Loader=yaml.FullLoader) if file_path.endswith('.yaml') else json.load(file)
        for update in updates:
            utils.update_nested_dict(data, update['path'].split('.'), update['value'])
        with open(file_path, 'w') as file:
            yaml.dump(data, file) if file_path.endswith('.yaml') else json.dump(data, file, indent=2)

    def commit_and_create_pr(self, commit_message, branch_name, pr_title, pr_body):
        subprocess.run(['git', 'add', '.'])
        subprocess.run(['git', 'commit', '-m', commit_message])
        subprocess.run(['git', 'push', 'origin', branch_name])
        subprocess.run(['gh', 'pr', 'create', '--base', 'main', '--head', branch_name, '--title', pr_title, '--body', pr_body])

    def apply_patches(self):
        self.clone_repo()
        self.checkout_branch(self.config['branch_name'])
        for file_info in self.config['files']:
            self.patch_file(file_info['file_path'], file_info['updates'])
        self.commit_and_create_pr(
            self.config['commit_message'],
            self.config['branch_name'],
            self.config['pr_title'],
            self.config['pr_body']
        )

def main():
    config = utils.parse_config('update.yaml')
    patcher = GitOpsPatcher(config)
    patcher.apply_patches()

if __name__ == "__main__":
    main()
