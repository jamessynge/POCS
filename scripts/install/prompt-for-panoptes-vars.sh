#!/bin/bash

# Order matters here so that the defaults are computed based on preceding vars.
# Note, we could choose to just prompt for PANUSER and maybe PANDIR, and leave
# it at that. For most users this would suffice.
declare -a VARIABLE_NAMES=("PANUSER" "PANDIR" "PANLOG" "POCS" "PAWS" "PIAA")

declare -A VARIABLE_DESCRIPTIONS
VARIABLE_DESCRIPTIONS[PANUSER]="User name of PANOPTES user: "
VARIABLE_DESCRIPTIONS[PANDIR]="Parent directory of PANOPTES files: "
VARIABLE_DESCRIPTIONS[PANLOG]="Directory for log files: "
VARIABLE_DESCRIPTIONS[POCS]="Directory for POCS (Observatory Control) software: "
VARIABLE_DESCRIPTIONS[PAWS]="Directory for PAWS (Website) software: "
VARIABLE_DESCRIPTIONS[PIAA]="Directory for PIAA (Image Analysis) software: "

# Expressions for computing the default value of a variable. In single quotes
# to prevent immediate evaluation.
# PANDIR is based on PANUSER to enable testing (multiple) installs more easily,
# without wiping out the "official" install.
declare -A VARIABLE_DEFAULTS
VARIABLE_DEFAULTS[PANUSER]='panoptes'
VARIABLE_DEFAULTS[PANDIR]='/var/${PANUSER}'
VARIABLE_DEFAULTS[PANLOG]='${PANDIR}/logs'
VARIABLE_DEFAULTS[POCS]='${PANDIR}/POCS'
VARIABLE_DEFAULTS[PAWS]='${PANDIR}/PAWS'
VARIABLE_DEFAULTS[PIAA]='${PANDIR}/PIAA'

# We track whether the variable has been changed by the user. If so,
# then we don't recompute the value from the expression in VARIABLE_DEFAULTS
# when prompting for a value.
declare -A VARIABLE_IS_OVERRIDDEN

function echo_var_default() {
  local -r varname="${1}"
  echo "$(eval echo "${VARIABLE_DEFAULTS[${varname}]}")"
}

function init_variable() {
  local -r varname="${1}"
  local -r dflt="$(echo_var_default ${varname})"
  local value="${!varname:-${dflt}}"
  if [ "${value}" == "${dflt}" ] ; then
    VARIABLE_IS_OVERRIDDEN[${varname}]="false"
  else
    VARIABLE_IS_OVERRIDDEN[${varname}]="true"
  fi
  export "${varname}=${value}"  
}

function init_empty_var() {
  local -r varname="${1}"
  local -r dflt="$(echo_var_default ${varname})"
  local value="${!varname:-${dflt}}"
  echo "Originally ${varname}=${!varname}"
  export "${varname}=${value}"
  echo "After ${varname}=${!varname}"
}

function prompt_for_var() {
  local -r varname="${1}"
  local value="${!varname}"
  local -r dflt="$(echo_var_default ${varname})"
  # The user (or calling environment) hasn't overridden the value, so
  # use the default expression to compute a value.
  if [[ -z "${value}" || "${VARIABLE_IS_OVERRIDDEN[${varname}]}" == "false" ]]
  then
    value="${dflt}"
  fi
  local -r description="${VARIABLE_DESCRIPTIONS[${varname}]}"
  read -e -i "${value}" -p "${description}" input
  if [[ -z "${input}" || "${input}" == "${dflt}" ]]
  then
    VARIABLE_IS_OVERRIDDEN[${varname}]="false"
    export "${varname}=${dflt}"
  else
    VARIABLE_IS_OVERRIDDEN[${varname}]="true"
    export "${varname}=${input}"
  fi
}

function display_var() {
  local -r varname="${1}"
  local -r value="${!varname}"
  local -r description="${VARIABLE_DESCRIPTIONS[${varname}]}"

  echo 
  echo "${description}"
  echo "    ${varname} = ${value}"
}

function for_each_var() {
  local -r command="${1}"
  local varname=""
  for varname in "${VARIABLE_NAMES[@]}"
  do
    "${command}" "${varname}"
  done
}

function initialize_all_vars() {
  for_each_var init_variable
}

function prompt_for_all_vars() {
  for_each_var prompt_for_var
}

function display_all_vars() {
  echo "Variable values:"
  for_each_var display_var
  echo
}

# TODO Remove if unneeded.
# Echos the value of the variable or its default value if the variable is unset or empty.
function get_var_value() {
  local -r varname="${1}"
  local -r dflt="$(echo_var_default ${varname})"
  echo "${!varname:-${dflt}}"
}

# Prompt for Yes or No, with the specified value as default if an empty input is provided.

function confirm() {
  local -r full_prompt="${1}"
  local -r empty_response="${2}"

  while :
  do
    read -r -p "${full_prompt}" confirm_response
    if [ -z "${confirm_response}" ]
    then
      confirm_response="${empty_response}"
    fi
    case "${confirm_response}" in
      [yY][eE][sS]|[yY]) 
        return 0
        ;;
      [nN][oO]|[nN])
        return 1
        ;;
      *)
        echo "Unexpected response: ${confirm_response}"
        echo "Try again, or press Ctrl+C to exit."
    esac
  done
}

function confirm_Y() {
  confirm "$1 [Y/n]: " Y
  test $? == 0
}

function confirm_N() {
  confirm "$1 [y/N]: " N
  test $? == 1
}

function collect_variables() {
  while :
  do
    display_all_vars
    if confirm_N "Do you want to change any variables?"
    then
      return
    else
      prompt_for_all_vars
    fi
  done
}

initialize_all_vars
collect_variables

echo "Collected:"
display_all_vars


