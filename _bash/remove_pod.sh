#!/bin/bash

set -euo pipefail

source ./_constants.sh
source ./_functions.sh


main() {
  log_info "Stopping and removing ${PROJECT} pods..."
  pod_ps "${PROJECT}"
  pod_cleanup "${PROJECT}-${YAML_DB}" \
              "${PROJECT}-${YAML_INIT}" \
              "${PROJECT}-${YAML_MAIN}"
  log_info "Stopping and removing ${PROJECT} pods...done"
}

main "$@"
