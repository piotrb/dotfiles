set -e -o pipefail

which -s task

task --version 2>/dev/null | grep "Task version" -q
