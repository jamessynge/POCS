#!/bin/bash -ex

WINDOW="${1}"
echo "Running $(basename "${0}") at $(date), WINDOW=${WINDOW}"

if [ ! -f "${HOME}/AUTOMATED-SETUP-POCS-ENABLED" ] ; then
  echo "Did not find ${HOME}/AUTOMATED-SETUP-POCS-ENABLED file at $(date)."
  echo
  echo "Disabled automated running of bin/pocs_shell."

  tmux send-keys -t "${WINDOW}" "# Did not find ${HOME}/AUTOMATED-SETUP-POCS file at $(date)." C-m
  sleep 0.5s
  tmux send-keys -t "${WINDOW}" "# Disabled automated running of bin/pocs_shell." C-m
else
  tmux send-keys -t "${WINDOW}" "date" C-m
  sleep 0.5s
  tmux send-keys -t "${WINDOW}" "cd ${POCS}" C-m
  sleep 0.5s
  tmux send-keys -t "${WINDOW}" "bin/pocs_shell" C-m
  sleep 10s
  tmux send-keys -t "${WINDOW}" "setup_pocs" C-m
  sleep 20s
  tmux send-keys -t "${WINDOW}" "display_config" C-m
  sleep 1s

  if [ -f "${HOME}/AUTOMATED-RUN-POCS-ENABLED" ] ; then
    tmux send-keys -t "${WINDOW}" "run_pocs" C-m
  else
    echo "Did not find ${HOME}/AUTOMATED-RUN-POCS-ENABLED file at $(date)."
    echo
    echo "Disabled automated run_pocs command in bin/pocs_shell."
  fi
fi

echo "Done at $(date)"

