#!/bin/bash -Eeu

# - - - - - - - - - - - - - - - - - - - - - -
ip_address_slow()
{
  if [ -n "${DOCKER_MACHINE_NAME:-}" ]; then
    docker-machine ip ${DOCKER_MACHINE_NAME}
  else
    echo localhost
  fi
}
readonly IP_ADDRESS=$(ip_address_slow)

# - - - - - - - - - - - - - - - - - - - - - -
wait_briefly_until_ready()
{
  local -r name="${1}"
  local -r port="${2}"
  local -r max_tries=80
  echo
  printf "Waiting until ${name} is ready"
  for _ in $(seq ${max_tries})
  do
    if ready ${port}; then
      printf '.OK\n'
      return
    else
      printf '.'
      sleep 0.1
    fi
  done
  printf 'FAIL\n'
  printf "${name} not ready after ${max_tries} tries\n"
  if [ -f "$(ready_response_filename)" ]; then
    printf "$(ready_response)\n"
  fi
  docker logs ${name}
  exit 42
}

# - - - - - - - - - - - - - - - - - - -
ready()
{
  local -r port="${1}"
  local -r path=ready?
  local -r ready_cmd="\
    curl \
      --output $(ready_response_filename) \
      --silent \
      --fail \
      -X GET http://${IP_ADDRESS}:${port}/${path}"
  rm -f "$(ready_response_filename)"
  if ${ready_cmd} && [ "$(ready_response)" = '{"ready?":true}' ]; then
    true
  else
    false
  fi
}

# - - - - - - - - - - - - - - - - - - -
ready_response()
{
  cat "$(ready_response_filename)"
}

# - - - - - - - - - - - - - - - - - - -
ready_response_filename()
{
  printf /tmp/curl-model-ready-output
}

# - - - - - - - - - - - - - - - - - - -
strip_known_warning()
{
  local -r docker_log="${1}"
  local -r known_warning="${2}"
  local stripped=$(echo -n "${docker_log}" | grep --invert-match -E "${known_warning}")
  if [ "${docker_log}" != "${stripped}" ]; then
    >&2 echo "SERVICE START-UP WARNING: ${known_warning}"
  else
    >&2 echo "SERVICE START-UP WARNING NOT FOUND: ${known_warning}"
  fi
  echo "${stripped}"
}

# - - - - - - - - - - - - - - - - - - -
exit_if_unclean()
{
  local -r name="${1}"
  local server_log=$(docker logs "${name}" 2>&1)

  #local -r shadow_warning="server.rb:(.*): warning: shadowing outer local variable - filename"
  #server_log=$(strip_known_warning "${server_log}" "${shadow_warning}")
  #local -r mismatched_indent_warning="application(.*): warning: mismatched indentations at 'rescue' with 'begin'"
  #server_log=$(strip_known_warning "${server_log}" "${mismatched_indent_warning}")

  local -r line_count=$(echo -n "${server_log}" | grep --count '^')
  printf "Checking ${name} started cleanly..."
  # 3 lines on Thin (Unicorn=6, Puma=6)
  # Thin web server (v1.7.2 codename Bachmanity)
  # Maximum connections set to 1024
  # Listening on 0.0.0.0:4568, CTRL+C to stop
  if [ "${line_count}" == '6' ]; then
    printf 'OK\n'
  else
    printf 'FAIL\n'
    echo_docker_log "${name}" "${server_log}"
    exit 42
  fi
}

# - - - - - - - - - - - - - - - - - - -
echo_docker_log()
{
  local -r name="${1}"
  local -r docker_log="${2}"
  echo "[docker logs ${name}]"
  echo "<docker_log>"
  echo "${docker_log}"
  echo "</docker_log>"
}

# - - - - - - - - - - - - - - - - - - -
container_up_ready_and_clean()
{
  local -r port="${1}"
  local -r service_name="${2}"
  local -r container_name="test-${service_name}"
  container_up "${service_name}"
  wait_briefly_until_ready_and_clean "${1}" "${2}"
}

# - - - - - - - - - - - - - - - - - - -
wait_briefly_until_ready_and_clean()
{
  local -r port="${1}"
  local -r service_name="${2}"
  local -r container_name="test-${service_name}"
  wait_briefly_until_ready "${container_name}" "${port}"
  exit_if_unclean "${container_name}"
}

# - - - - - - - - - - - - - - - - - - -
container_up()
{
  local -r service_name="${1}"
  printf '\n'
  augmented_docker_compose \
    up \
    --detach \
    "${service_name}"
}

# - - - - - - - - - - - - - - - - - - - - - - - - - -
saver_cid()
{
  # locally, the container name is model_saver_1
  # on CI the contains name is, eg, project_saver_1_1bebf84ac62f
  docker ps --filter status=running --format '{{.Names}}' | grep "saver"
}

# - - - - - - - - - - - - - - - - - - - - - - - - - -
copy_in_saver_test_data()
{
  local -r SAVER_CID="${1}"
  local -r SRC_PATH=${ROOT_DIR}/test/data/cyber-dojo
  local -r DEST_PATH=/cyber-dojo
  # You cannot docker cp to a tmpfs, so tar-piping instead...
  cd ${SRC_PATH} \
    && tar -c . \
    | docker exec -i ${SAVER_CID} tar x -C ${DEST_PATH}
}

# - - - - - - - - - - - - - - - - - - -
containers_up()
{
  container_up_ready_and_clean "${CYBER_DOJO_MODEL_PORT}"          model-server
  container_up_ready_and_clean "${CYBER_DOJO_MODEL_CLIENT_PORT}"   model-client
  local -r SAVER_CID="$(saver_cid)"
  docker exec "${SAVER_CID}" bash -c 'rm -rf /cyber-dojo/groups/*'
  docker exec "${SAVER_CID}" bash -c 'rm -rf /cyber-dojo/katas/*'
  copy_in_saver_test_data "${SAVER_CID}"
}
