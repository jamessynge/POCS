#!/bin/bash -ex
#
# Create the user that will own /var/panoptes and will execute the
# panoptes software. The user must not already exist. Minimal usage:
#
#    PANUSER=panoptes ./create-panoptes-user.sh
#
# Looks for these environment variables:
#
#     PANUSER: Name of the user to create. Required
#  PANUSER_ID: Id (integer) of the user to create. Not required.
#    PANGROUP: Name of the group to to create for the user. Defaults to PANUSER.
# PANGROUP_ID: Id (integer) of the group to create. Not required.

if [ -z $PANUSER ] ; then
  echo "Environment variable PANUSER is not set"
  exit 1
fi

if [ $PANUSER == $(id -u -n) ] ; then
  echo "PANUSER ($PANUSER) is the current user, so already exists."
  exit 1
fi

if [ $PANUSER == $(id -u $PANUSER) ] ; then
  echo "PANUSER ($PANUSER) already exists."
  exit 1
fi

if [ -n $PANGROUP ] ; then
  


if [ $PANUSER != $user_name ] ; then 
    echo "PANUSER ($PANUSER) doesn't match user_name ($user_name)"
    exit 1
  fi
  if [ -z $group_name ] ; then
    echo "group_name is not set!"
    exit 1
  fi
  if [ -z $group_id ] ; then
    echo "group_id is not set!"
    exit 1
  fi

  groupadd -g $group_id $group_name

  if [ -z $user_name ] ; then
    echo "user_name is not set!"
    exit 1
  fi
  if [ -z $user_id ] ; then
    echo "user_id is not set!"
    exit 1
  fi
