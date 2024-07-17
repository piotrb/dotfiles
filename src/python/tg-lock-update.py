import os
import subprocess
import argparse

# Create an argument parser
parser = argparse.ArgumentParser(description='Process git revision.')
parser.add_argument('--revision', type=str, help='Git revision')

# Parse the arguments
args = parser.parse_args()

# Get the list of modified .terraform.lock.hcl files
if args.revision:
  result = subprocess.run(['git', 'show', '--name-only', '--pretty=', args.revision], stdout=subprocess.PIPE)
else:
  result = subprocess.run(['git', 'status', '--porcelain'], stdout=subprocess.PIPE)

modified_files = [line.split()[-1] for line in result.stdout.decode().split('\n') if '.terraform.lock.hcl' in line]

# Get the root folders of the terraform modules
module_folders = set(os.path.dirname(file) for file in modified_files)

errors = []

# Run "terragrunt providers lock" in each module folder
for folder in module_folders:
  print(f"Updating {folder} ...")

  env = dict(os.environ)
  env['TERRAGRUNT_AUTO_INIT'] = 'true'

  try:
    print("Running 'terragrunt providers lock' ...")
    subprocess.run(['terragrunt', 'providers', 'lock'], cwd=folder, check=True, env=env)
  except subprocess.CalledProcessError as e:
    errors.append(f"could not run 'terragrunt providers lock' in {folder}: {e}")

# Print any errors
if len(errors) > 0:
  print("The following errors occurred:")
  print("\n".join(errors))
  exit(1)
