#!/bin/bash

VERSION="1.0.0"
NAME="kids"
LICENSE="MIT"
MAINTAINER="opensource@zhihu.com"
URL="https://github.com/zhihu/kids"
DESCRIPTION="kids is a log aggregation system"
DAEMON_USER="root"
DAEMON_GROUP="root"
TYPE="deb"

CONF_FILE="kids.conf"
KIDS_BIN="../src/kids"
KIDS_AFTER_INSTALL="kids.after_install"
KIDS_BEFORE_REMOVE="kids.before_remove"
KIDS_INIT="kids"

BUILD_DIR="build"

function usage {
  echo "Usage: $0 [-b binary]"
  echo "-b binary    kids binary, default to ../src/kids"
  exit 1
}

function parse_args {
  while getopts ":f:" opt; do
    case $opt in
      b)
        KIDS_BIN="$OPTARG"
        ;;
      *)
        usage
        ;;
    esac
  done
  if [ ! -x "$KIDS_BIN" ]; then
    usage
  fi
}

function prepare_dir {
  mkdir -p $BUILD_DIR
  cd $BUILD_DIR
  mkdir -p usr/local/bin
  mkdir -p etc
  mkdir -p data/data/kidsbuf
  mkdir -p data/data/kids/logs
  cd ..
  cp $KIDS_BIN  $BUILD_DIR/usr/local/bin/
  cp $CONF_FILE $BUILD_DIR/etc/kids.conf
  DIR=(usr etc data)
}

function collect_script {
  ok="yes"
  for file in after_install before_remove; do
    if [ -f $file ]; then
      if [ ! -x $file ]; then
        echo "'$file' exsists but not executable!"
        ok="no"
      fi
      OPTS+=(--$file "$file")
    fi
  done
}

function package {
  OPTS+=(--name "$NAME" "--force" -s "dir" -t "$TYPE")
  OPTS+=(-C "$BUILD_DIR" --version "$VERSION" --maintainer "\"$MAINTAINER\"")
  OPTS+=(--license "\"$LICENSE\"" --description "\"$DESCRIPTION\"" --url "\"$URL\"")
  OPTS+=(--deb-init `pwd`/$KIDS_INIT)

  OPTS+=(--deb-user "$DAEMON_USER" --deb-group "$DAEMON_GROUP")
  OPTS=("${OPTS[@]}" "${DIR[@]}")
  echo "fpm ${OPTS[@]}"
  fpm "${OPTS[@]}"
}

function cleanup {
  echo  "clean up..."
  rm -rf $BUILD_DIR
}

parse_args "$@"
prepare_dir
collect_script
package
cleanup
