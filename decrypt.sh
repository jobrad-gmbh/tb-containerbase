#!/usr/bin/bash
# -*- coding: utf-8 -*-
# [Project page](https://torben.website/containerbase)

# Copyright Torben Sickert (info["~at~"]torben.website) 16.12.2012

# License
# -------

# This library written by Torben Sickert stand under a creative commons naming
# 3.0 unported license.
# See https://creativecommons.org/licenses/by/3.0/deed.de

# Basic ArchLinux with user-mapping, AUR integration and support for decryption
# of security related files.

# 1. Checks if newer initializer is bind into container and exec into to if
#    present.
# 2. Loads environment files if existing.
# 3. Decrypt configured locations if specified.
# region convert environment variables given as string into local arrays
for name in \
    DECRYPTED_PATHS \
    ENCRYPTED_PATHS \
    PASSWORD_FILE_PATHS
do
    if ! [[ "$(declare -p "$name" 2>/dev/null)" =~ 'declare -a' ]]; then
        eval "declare -a ${name}_ARRAY=(\$${name})"
    fi
done
# endregion
# region determine gpgdir
for gpgdir in \
    /tmp/gpgdir \
    /usr/bin/gpgdir \
    /usr/bin/perlbin/site_perl/gpgdir \
    /tmp/gpgdir-nodeps-*/gpgdir
do
    if [ -f "$gpgdir" ]; then
        break
    fi
done
# endregion
# region decrypt security related artefacts needed at runtime
if [[ "$DECRYPT" != false ]]; then
    for index in "${!ENCRYPTED_PATHS_ARRAY[@]}"; do
        if [ -d "${ENCRYPTED_PATHS_ARRAY[index]}" ]; then
            rm \
                --force \
                --recursive \
                "${DECRYPTED_PATHS_ARRAY[index]}" \
                &>/dev/null
            mkdir --parents "${DECRYPTED_PATHS_ARRAY[index]}"
            chown \
                --recursive \
                $MAIN_USER_NAME:$MAIN_USER_GROUP_NAME \
                "${DECRYPTED_PATHS_ARRAY[index]}"

            cp \
                --force \
                --recursive \
                "${ENCRYPTED_PATHS_ARRAY[index]}/"* \
                "${DECRYPTED_PATHS_ARRAY[index]}"

            if [ -s "${PASSWORD_FILE_PATHS_ARRAY[index]}" ]; then
                cp \
                    ${PASSWORD_FILE_PATHS_ARRAY[index]} \
                    /tmp/intermediatePasswordFile
            elif [[ "$DECRYPTION_PASSWORD" != '' ]]; then
                echo -n "$DECRYPTION_PASSWORD" >/tmp/intermediatePasswordFile
            elif [[ "$1" != '' ]]; then
                echo -n "$1" >/tmp/intermediatePasswordFile
            fi

            if [ -s /tmp/intermediatePasswordFile ]; then
                if ! echo "$gpgdir" \
                    --decrypt "${DECRYPTED_PATHS_ARRAY[index]}" \
                    --overwrite-decrypted \
                    --pw-file /tmp/intermediatePasswordFile \
                    --Symmetric \
                    --quiet
                then
                    echo \
                        Mounting \"${ENCRYPTED_PATHS_ARRAY[index]}\" to \
                        \"${DECRYPTED_PATHS_ARRAY[index]}\" failed.

                    exit 1
                fi
            elif ! "$gpgdir" \
                --decrypt "${DECRYPTED_PATHS_ARRAY[index]}" \
                --overwrite-decrypted \
                --Symmetric \
                --quiet
            then
                echo \
                    Mounting \"${ENCRYPTED_PATHS_ARRAY[index]}\" to \
                    \"${DECRYPTED_PATHS_ARRAY[index]}\" failed.

                exit 1
            fi
        fi
    done
fi
# endregion
# region vim modline
# vim: set tabstop=4 shiftwidth=4 expandtab:
# vim: foldmethod=marker foldmarker=region,endregion:
# endregion
