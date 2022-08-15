#!/bin/bash


#set -euo pipefail

source ./_constants.sh
source ./_functions.sh


main() {
  log_info "Environment initialization..."
  mkdir -p  "${AIRFLOW_DAGS_PATH}"
  log_info "Creating ${AIRFLOW_DAGS_DIR} directory...done"
  mkdir -p  "${AIRFLOW_LOGS_PATH}"
  log_info "Creating ${AIRFLOW_LOGS_DIR} directory...done"
  mkdir -p  "${AIRFLOW_PLUGINS_PATH}"
  log_info "Creating ${AIRFLOW_PLUGINS_DIR} directory...done"
  echo -e "AIRFLOW_UID=$(id -u)\nAIRFLOW_GID=0" > "${ENV_PATH}"
  log_info "Creating ${ENV_FILE} file...done"
  network_create "${NETWORK}"

  # https://github.com/apache/airflow/issues/14266
  mkdir -p  "${AIRFLOW_IMAGE_PATH}"
  log_info "Creating local airflow image..."
  podman build -f "${AIRFLOW_IMAGE_PATH}/containerfile-airflow" \
         -t apache/airflow
  log_info "Creating local airflow image...done"

  log_info "Environment initialization...done"
}

main "$@"
