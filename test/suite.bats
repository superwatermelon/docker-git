#!/usr/bin/env bats

setup() {
  export TMP="$(pwd)/test/tmp"
  export SSH_REFERENCE_DIR="$TMP/ref/ssh"
  export SSH_DIR="$TMP/ssh"
  export GIT_REFERENCE_DIR="$TMP/ref/git"
  export GIT_DIR="$TMP/git"
  export GIT_UID=1001
  export GIT_GID=1001
  mkdir -p "$SSH_REFERENCE_DIR" "$SSH_DIR" "$GIT_REFERENCE_DIR" "$GIT_DIR"
}

teardown() {
  [[ -d "$TMP" ]] && sudo rm -rf "$TMP"/*
}

run_container_with_ssh_bind_mount() {
  docker run --rm --volume "$SSH_DIR:/etc/ssh" "$IMAGE" -T >/dev/null
}

run_container_with_git_bind_mount() {
  docker run --rm --volume "$GIT_DIR:/var/git" "$IMAGE" -T >/dev/null
}

apply_reference_files() {
  sudo cp -a "$SSH_REFERENCE_DIR/." "$SSH_DIR"
  sudo cp -a "$GIT_REFERENCE_DIR/." "$GIT_DIR"
}

generate_sshd_config() {
  echo "ChallengeResponseAuthentication yes" >"$SSH_REFERENCE_DIR/sshd_config"
  apply_reference_files
}

generate_host_keys() {
  ssh-keygen -q -N '' -C '' -t rsa -f "$SSH_REFERENCE_DIR/ssh_host_rsa_key"
  ssh-keygen -q -N '' -C '' -t dsa -f "$SSH_REFERENCE_DIR/ssh_host_dsa_key"
  ssh-keygen -q -N '' -C '' -t ecdsa -f "$SSH_REFERENCE_DIR/ssh_host_ecdsa_key"
  ssh-keygen -q -N '' -C '' -t ed25519 -f "$SSH_REFERENCE_DIR/ssh_host_ed25519_key"
  apply_reference_files
}

generate_authorized_keys() {
  ssh-keygen -q -N '' -C '' -t rsa -f "$GIT_REFERENCE_DIR/id_rsa"
  mkdir -p "$GIT_REFERENCE_DIR/.ssh"
  cat "$GIT_REFERENCE_DIR/id_rsa.pub" >"$GIT_REFERENCE_DIR/.ssh/authorized_keys"
  sudo chown -R "$GIT_UID:$GIT_GID" "$GIT_REFERENCE_DIR/.ssh"
  sudo chmod 700 "$GIT_REFERENCE_DIR/.ssh"
  sudo chmod 600 "$GIT_REFERENCE_DIR/.ssh/authorized_keys"
  apply_reference_files
}

assert_git_file_unchanged() {
  run sudo diff "$GIT_REFERENCE_DIR/$1" "$GIT_DIR/$1"
  [ "$status" -eq 0 ]
}

assert_ssh_file_unchanged() {
  run sudo diff "$SSH_REFERENCE_DIR/$1" "$SSH_DIR/$1"
  [ "$status" -eq 0 ]
}

assert_file_exists() {
  run /bin/bash -c "[[ -f "$1" ]]"
  [ "$status" -eq 0 ]
}

@test "sshd runs ok" {
  run docker run --rm $IMAGE -T
  [ "$status" -eq 0 ]
}

@test "bind-mount the ssh config volume exposes sshd_config" {
  run_container_with_ssh_bind_mount
  assert_file_exists "$SSH_DIR/sshd_config"
}

@test "bind-mount the ssh config volume exposes ssh_host_rsa_key" {
  run_container_with_ssh_bind_mount
  assert_file_exists "$SSH_DIR/ssh_host_rsa_key"
}

@test "bind-mount the ssh config volume exposes ssh_host_dsa_key" {
  run_container_with_ssh_bind_mount
  assert_file_exists "$SSH_DIR/ssh_host_dsa_key"
}

@test "bind-mount the ssh config volume exposes ssh_host_ecdsa_key" {
  run_container_with_ssh_bind_mount
  assert_file_exists "$SSH_DIR/ssh_host_ecdsa_key"
}

@test "bind-mount the ssh config volume exposes ssh_host_ed25519_key" {
  run_container_with_ssh_bind_mount
  assert_file_exists "$SSH_DIR/ssh_host_ed25519_key"
}

@test "does not overwrite host provided sshd_config" {
  generate_sshd_config
  assert_ssh_file_unchanged "sshd_config"
  run_container_with_ssh_bind_mount
  assert_ssh_file_unchanged "sshd_config"
}

@test "does not overwrite host ssh_host_rsa_key" {
  generate_host_keys
  run_container_with_ssh_bind_mount
  assert_ssh_file_unchanged "ssh_host_rsa_key"
}

@test "does not overwrite host ssh_host_dsa_key" {
  generate_host_keys
  run_container_with_ssh_bind_mount
  assert_ssh_file_unchanged "ssh_host_dsa_key"
}

@test "does not overwrite host ssh_host_ecdsa_key" {
  generate_host_keys
  run_container_with_ssh_bind_mount
  assert_ssh_file_unchanged "ssh_host_ecdsa_key"
}

@test "does not overwrite host ssh_host_ed25519_key" {
  generate_host_keys
  run_container_with_ssh_bind_mount
  assert_ssh_file_unchanged "ssh_host_ed25519_key"
}

@test "bind-mount the git home volume exposes authorized_keys" {
  run_container_with_git_bind_mount
  assert_file_exists "$GIT_DIR/.ssh/authorized_keys"
}

@test "does not overwrite host authorized_keys" {
  generate_authorized_keys
  run_container_with_git_bind_mount
  assert_git_file_unchanged ".ssh/authorized_keys"
}

@test "use git container to create and commit to repositories" {
  generate_host_keys
  generate_authorized_keys
  container="$(docker create \
    --interactive \
    --volume "$SSH_DIR":/etc/ssh \
    --volume "$GIT_DIR":/var/git \
    "$IMAGE")"
  docker start "$container"
  run docker run \
    --volume "$GIT_REFERENCE_DIR":/git \
    --entrypoint /bin/bash \
    --link "$container":git \
    "$IMAGE" -xc '\
      mkdir -p ~/.ssh && \
      cp /git/id_rsa ~/.ssh/id_rsa && \
      ssh-keyscan -t ecdsa git >>~/.ssh/known_hosts && \
      chmod 700 ~/.ssh && \
      chmod 600 ~/.ssh/id_rsa && \
      ssh git@git git init --bare test.git && \
      git clone git@git:test.git ~/test && \
      cd ~/test && \
      touch README.md && \
      git add . && \
      git config user.email "test@git" && \
      git config user.name "Test" && \
      git commit -m "Initial commit" && \
      git push origin master'
  docker rm --force --volumes "$container"
  [ "$status" -eq 0 ]
}
