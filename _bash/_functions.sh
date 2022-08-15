#!/bin/bash

set -euo pipefail


#
log() {
  local timestamp
  timestamp=$(date "+%H:%M:%S")
  echo -e "[${timestamp}] ${*}"
}

log_info() {
  log "[INFO]" "==>" "${*}"
}

log_warn() {
  log "[WARN]" "==>" "${*}"
}

log_error() {
  log "[ERROR]" "==>" "${*}"
}

# 
pod_search() {
  podman pod exists "${1}" || echo $?
}

network_search() {
  # for podman 3.1+
  # podman network exists "${1}" || echo $?
  podman network ls \
    | { grep "${1}" || test $? = 1; }
}

network_create() {
  local search
  search=$(network_search "$1")

  if [[ ! "$search" ]]; then # [ [[
    podman network create "${1}" | grep -v -e '^$'
    log_info "Creating ${1} network...done"
  else
    return 0
  fi
}

pod_list_filter() {
  podman pod ps \
    | { grep "${1}" || test $? = 1; }
}

# List pod if exists.
pod_ps() {
  local header
  local row
  header=$(pod_list_filter "POD ID.*")
  row=$(pod_list_filter "${1}.*")

  if [[ $row ]]; then
    echo -e "${header}\n${row}"
  else
    return 0
  fi
}

pod_cleanup() {
  while [[ $# -gt 0 ]]; do # [ [[
    local search
    search=$(pod_search "$1")

    if [[ ! $search ]]; then # (( [[
      log_info "Stopping ${1} pod..."
      podman pod stop "${1}"
      log_info "Stopping ${1} pod...done"
      log_info "Removing ${1} pod..."
      podman pod rm "${1}"
      log_info "Removing ${1} pod...done"
    else
      log_warn "No pod with name ${1} found"
    fi
    shift
  done
}

play_kube() {
  podman play kube "${1}" --network "${2}" \
    | grep -v -e '^$'
}

pod_launch() {
  local project
  local network
  local main_path
  local type
  local init_container_flag
  local init_pod_flag
  local files
  
  while getopts ":p:n:m:t:f:i:I:" opt; do
    case "${opt}" in
      p) project=${OPTARG} ;;
      n) network=${OPTARG} ;;
      m) main_path=${OPTARG} ;;
      t) type=${OPTARG} ;;
      f) files=${OPTARG} ;;
      i) init_container_flag=${OPTARG} ;;
      I) init_pod_flag=${OPTARG} ;;
      :) log_error "You're missing an argument"; exit 1 ;;
      ?) log_error "Invalid flag"; exit 1 ;;
      *) log_error "Unexpected option ${opt}"; exit 1 ;;
    esac
  done

  for file in ${files}; do
    local search
    search=$(pod_search "${project}-${file}")
    #echo "$file"
    # if not exists create pod
    if [[ $search ]] \
         && [[ $file != "${init_pod_flag}" ]]; then # [ [[
      log "Launching ${project}-${file}..."
      play_kube "${main_path}/${file}.${type}" "${network}"
      log "Launching ${project}-${file}...done"
    elif [[ $search ]] \
           && [[ ${file} = "${init_pod_flag}" ]]; then
      log_info "Launching ${project}-${file}..."
      play_kube "${main_path}/${file}.${type}" \
                "${network}"
      #echo "${project}-${file}-start"
      wait_for_container "${project}-${file}-${init_container_flag}"
      log "Launching ${project}-${file}...done"
    else
      log_warn "Name ${project}-${file} is in use:" \
               "pod already exists"
      log_error "Launching cancelled"
      return 1
    fi

  done
}

timeout() {
  log_error "Timeout:" "${*}"
  return 1
}

container_log_tail() {
  podman logs --tail 1 "${1}"
}

grep_output_0() {
  echo "${1}" | { grep "${2}" || test $? = 1; }
}

wait_for_container() {
  local attempts
  local start_time
  local elapsed_time
  local log_tail
  local log_grep

  attempts=$(seq "${TIMEOUT_ATTEMPTS}")
  start_time="${SECONDS}"

  log_info "Waiting for ${1} container..."
  
  for i in ${attempts}; do
    elapsed_time=$(( "${SECONDS}" - "${start_time}" ))
    log_tail=$(container_log_tail "${1}")
    log_grep=$(grep_output_0 "${log_tail}" "${JOB_COMPLETED_LOG}")
    # grep to 1/0 
    #  echo "$i" > dev/null
    if [[ "$log_grep" = "${JOB_COMPLETED_LOG}" ]]; then
      log_info "Finished after ${elapsed_time} sec, attempt:${i}"
      log_info "Waiting for ${1} container...done"
      return 0
    fi
    log_info "Waiting..."
    sleep "${TIMEOUT_SECONDS}"
  done
  timeout "Waiting time for container ${1} has ended"
}
