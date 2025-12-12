#!/bin/bash
set -e

if [ -z "$(which setup_robotology_tdd.sh)" ] ; then
    echo "File setup_robotology_tdd.sh not found."
    exit 1
fi

source setup_robotology_tdd.sh

echo "[ -r /usr/share/bash-completion/bash_completion   ] && . /usr/share/bash-completion/bash_completion" >> /root/.bashrc
# Appends a conditional statement to the root user's bashrc file that sources the robotology TDD setup script
# if the file exists at /usr/local/bin/setup_robotology_tdd.sh, enabling the robotology development environment
# on every new interactive bash shell session for the root user
echo "[ -r /usr/local/bin/setup_robotology_tdd.sh   ] && . /usr/local/bin/setup_robotology_tdd.sh" >> /root/.bashrc
echo "[ -r /usr/local/bin/ros_entrypoint.sh   ] && . /usr/local/bin/ros_entrypoint.sh" >> /root/.bashrc
# If a CMD is passed, execute it
exec "$@"
