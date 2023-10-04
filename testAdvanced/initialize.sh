#!/usr/bin/env bash
# -*- coding: utf-8 -*-
# shellcheck disable=SC1091

set -e

source prepare-initializer "$@"

echo Application started.

source configure-runtime-user

source decrypt "$@"

echo \
    "Decrypted content of encrypted folder \"$ENCRYPTED_PATHS\" located at" \
    "\"$DECRYPTED_PATHS\" is:"

tree "$DECRYPTED_PATHS"

echo \
    "Example file content of \"${DECRYPTED_PATHS}secret-configuration.txt\"" \
    "is \"$(cat "${DECRYPTED_PATHS}secret-configuration.txt")\"."

echo First level meta file data are:

ls --all --human-readable -l "$DECRYPTED_PATHS"
