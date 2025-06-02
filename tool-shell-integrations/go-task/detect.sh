set -e -o pipefail

which -s task

task --version | grep "Task version" -q
