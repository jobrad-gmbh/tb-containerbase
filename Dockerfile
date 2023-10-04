# syntax=docker/dockerfile-upstream:master-labs
# region header
# [Project page](https://torben.website/containerbase)

# Copyright Torben Sickert (info["~at~"]torben.website) 16.12.2012

# License
# -------

# This library written by Torben Sickert stand under a creative commons naming
# 3.0 unported license.
# See https://creativecommons.org/licenses/by/3.0/deed.de

# Basic ArchLinux with user-mapping, AUR integration and support for decryption
# of security related files.
# endregion
# region create commands
# Run the following command in the directory where this file lives to build a
# new docker image:

# x86-64 only

# - docker pull archlinux && docker buildx build --build-arg MULTI='' --build-arg MIRROR_AREA_PATTERN='United States' --no-cache --tag ghcr.io/thaibault/containerbase:latest .

# Multi architecture

# - podman pull menci/archlinuxarm && podman build --file https://raw.githubusercontent.com/thaibault/containerbase/main/Dockerfile --no-cache --tag ghcr.io/thaibault/containerbase:latest .
# - docker pull menci/archlinuxarm && docker buildx build --no-cache --tag ghcr.io/thaibault/containerbase:latest .
# endregion
# region start container commands
# Run the following command in the directory where this file lives to start:
# - podman pod rm --force base_pod; podman play kube kubernetes.yaml
# - docker rm --force base; docker compose up
# endregion
           # region configuration
ARG        BASE_IMAGE
           # NOTE: Disabling "MULTI" via "--build-arg MULTI=''" will use
           # official arch image wich only has "x86-64" architecture support
           # yet.
ARG        MULTI=true

FROM       ${BASE_IMAGE:-${MULTI:+'menci/'}archlinux${MULTI:+'arm'}}

LABEL      maintainer="Torben Sickert <info@torben.website>"
LABEL      Description="base" Vendor="thaibault products" Version="1.0"

ENV        APPLICATION_PATH /application/
ENV        ENVIRONMENT_FILE_PATHS "/etc/containerBase/environment.sh ${APPLICATION_PATH}serviceHandler/environment.sh ${APPLICATION_PATH}environment.sh"

ENV        COMMAND 'echo "echo You have to set the \"COMMAND\" environment variable."'
           # NOTE: This value has be in synchronisation with the "CMD" given
           # value.
ENV        INITIALIZING_FILE_PATH /usr/bin/initialize

ENV        DECRYPT false
ENV        DECRYPT_AS_USER true
ENV        DECRYPTED_PATHS /tmp/plain/
ENV        ENCRYPTED_PATHS "${APPLICATION_PATH}encrypted/"
ENV        PASSWORD_SECRET_NAMES encryption_password
ENV        PASSWORD_FILE_PATHS "${APPLICATION_PATH}.encryptionPassword"

ENV        APPLICATION_USER_ID_INDICATOR_FILE_PATH /application/package.json
ENV        DEFAULT_MAIN_USER_GROUP_ID 100
ENV        DEFAULT_MAIN_USER_ID 1000
ENV        INSTALLER_USER_NAME installer
ENV        MAIN_USER_GROUP_NAME users
ENV        MAIN_USER_NAME application

ENV        KNOWN_HOSTS ''

ARG        MIRROR_AREA_PATTERN='default'

ENV        PRIVATE_SSH_KEY ''
ENV        PUBLIC_SSH_KEY ''
           # git@github.com:thaibault/containerbase
ENV        REPOSITORY_URL https://github.com/thaibault/containerbase.git
           # NOTE: Do not set as environment variable to avoid shadowing this
           # argument in inherited image builds.
ARG        BRANCH_NAME

ENV        STANDALONE true

WORKDIR    $APPLICATION_PATH

USER       root
           # endregion
COPY       --link ./scripts/clean-up.sh /usr/bin/clean-up
           # region install needed base packages
           # NOTE: openssl-1.1 is needed by arm pacman but not provided per
           # default.
RUN        pacman \
               --disable-download-timeout \
               --needed \
               --noconfirm \
               --noprogressbar \
               --refresh \
               --sync \
               base \
               openssl-1.1 \
               nawk && \
           clean-up
           # Update mirrorlist if existing
RUN        [[ "$MIRROR_AREA_PATTERN" != default ]] && \
           [ -f /etc/pacman.d/mirrorlist.pacnew ] && \
           mv \
               /etc/pacman.d/mirrorlist.pacnew \
               /etc/pacman.d/mirrorlist \
               &>/dev/null || \
               true; \
           [[ "$MIRROR_AREA_PATTERN" != default ]] && \
           cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.orig && \
           awk \
               '/^## '"${MIRROR_AREA_PATTERN}"'$/{f=1}f==0{next}/^$/{exit}{print substr($0, 2)}' \
               /etc/pacman.d/mirrorlist.orig \
               >/etc/pacman.d/mirrorlist || \
               true
           # && \
           # Update pacman keys (is optional and sometimes not working)
           #rm --force --recursive /etc/pacman.d/gnupg && \
           #pacman-key --init && \
           #pacman-key --populate archlinux && \
           #pacman-key --refresh-keys || \
           #true
           # Update package database to retrieve newest package versions
RUN        pacman \
               --disable-download-timeout \
               --needed \
               --noconfirm \
               --noprogressbar \
               --refresh \
               --sync \
               --sysupgrade && \
           clean-up && \
           # Configure locale.
           sed \
               --regexp-extended \
               --expression 's/#(en_US.UTF-8 UTF-8)/\1/' \
               --in-place \
               /etc/locale.gen && \
           locale-gen && \
           # endregion
           # region install needed packages
           # NOTE: "neovim" is only needed for debugging scenarios.
           pacman \
               --disable-download-timeout \
               --needed \
               --noconfirm \
               --sync \
               --noprogressbar \
               neovim \
               openssh && \
           clean-up
           # endregion
           # region install packages to build other packages
RUN        pacman \
               --disable-download-timeout \
               --needed \
               --noconfirm \
               --noprogressbar \
               --sync \
               base-devel \
               git && \
           clean-up && \
           mkdir --parents /etc/containerBase
           # endregion
           # region retrieve artefacts
COPY       --link ./scripts/clean-up.sh /usr/bin/clean-up
COPY       --link ./scripts/configure-runtime-user.sh /usr/bin/configure-runtime-user
COPY       --link ./scripts/configure-user.sh /usr/bin/configure-user
COPY       --link ./scripts/crypt.sh /usr/bin/crypt
COPY       --link ./scripts/decrypt.sh /usr/bin/decrypt
COPY       --link ./scripts/encrypt.sh /usr/bin/encrypt
COPY       --link ./scripts/initialize.sh /usr/bin/initialize
COPY       --link ./scripts/prepare-initializer.sh /usr/bin/prepare-initializer
COPY       --link ./scripts/retrieve-application.sh /usr/bin/retrieve-application
COPY       --link ./scripts/execute-command.sh /usr/bin/execute-command
COPY       --link ./scripts/run-command.sh /usr/bin/run-command
           # endregion
           # region configure user
RUN        configure-user && \
           # We cannot use yay as root user so we introduce an (unatted)
           # install user.
           # Create specified user with not yet existing name and id.
           # NOTE: Use exotic user id reduce risk of id clashing when mapping
           # to hosts user id at runtime.
           useradd \
               --create-home \
               --no-user-group \
               "${INSTALLER_USER_NAME}" \
               --uid 7777 && \
           echo \
               -e \
               "\n\n%users ALL=(ALL) ALL\n${INSTALLER_USER_NAME} ALL=(ALL) NOPASSWD:/usr/bin/pacman,/usr/bin/rm" \
               >>/etc/sudoers
           # endregion
USER       $INSTALLER_USER_NAME
           # region install and configure yay
RUN        pushd /tmp && \
           git clone https://aur.archlinux.org/yay.git && \
           pushd yay && \
           /usr/bin/makepkg --install --needed --noconfirm --syncdeps && \
           popd && \
           rm --force --recursive yay && \
           popd && \
           rm --force --recursive ~/.cache/go-build && \
           clean-up
           # endregion
USER       root

RUN        retrieve-application
RUN        env >/etc/default_environment
           # region bootstrap application
RUN        mv /usr/bin/initialize "$INITIALIZING_FILE_PATH" &>/dev/null; \
           chmod +x "$INITIALIZING_FILE_PATH"
# NOTE: "/usr/bin/initialize" (without brackets), "$INITIALIZING_FILE_PATH" or
# ["$INITIALIZING_FILE_PATH"] wont work with command line argument forwarding.
ENTRYPOINT ["/usr/bin/initialize"]
           # endregion
# region modline
# vim: set tabstop=4 shiftwidth=4 expandtab filetype=dockerfile:
# vim: foldmethod=marker foldmarker=region,endregion:
# endregion
