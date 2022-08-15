#!/bin/bash

#########################################
# Description
#########################################

set -euo pipefail

source ./_constants.sh
source ./_functions.sh


main() {
  log_info "Launching ${PROJECT} project..."
  pod_launch -p "${PROJECT}" \
             -n "${NETWORK}" \
             -m "${YAML_PATH}" \
             -t "yaml" \
             -f "${YAML_DB} ${YAML_INIT} ${YAML_MAIN}" \
             -i "$INIT_CONTAINER_FLAG" \
             -I "$INIT_POD_FLAG"
  pod_ps "${PROJECT}"
  log_info "Launching ${PROJECT} project...done"
}

main "$@"

#${YAML_INIT} 
