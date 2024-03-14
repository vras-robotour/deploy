#!/usr/bin/env bash
set -euo pipefail  # Better error handling and exiting on error

PROJECT_PATH=$(realpath "$(dirname "${BASH_SOURCE[0]}")")

main() {
  echo "Hello this is test1.sh"
  echo "SCRIPTS_PATH: $PROJECT_PATH"

  bash "$PROJECT_PATH/scripts/test2.sh"
}

main "$@"