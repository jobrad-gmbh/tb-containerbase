#!/usr/bin/env bash
# -*- coding: utf-8 -*-
# region header
# [Project page](https://torben.website/containerbase)

# Copyright Torben Sickert (info["~at~"]torben.website) 16.12.2012

# License
# -------

# This library written by Torben Sickert stand under a creative commons naming
# 3.0 unported license.
# See https://creativecommons.org/licenses/by/3.0/deed.de
# endregion
# shellcheck disable=SC1091,SC2016,SC2034,SC2155
source prepare-initializer "$@" && \

set -e

source decrypt "$@"

if [ -d "${DECRYPTED_PATHS[0]}" ]; then
    source configure-runtime-user "${DECRYPTED_PATHS[0]}:all:follow"
else
    source configure-runtime-user
fi

source execute-command "$(eval "$COMMAND $*")"
# region vim modline
# vim: set tabstop=4 shiftwidth=4 expandtab:
# vim: foldmethod=marker foldmarker=region,endregion:
# endregion
