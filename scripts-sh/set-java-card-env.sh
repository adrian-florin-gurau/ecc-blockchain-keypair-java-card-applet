#!/usr/bin/env bash

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  echo "This script must be sourced, not executed, so variables remain in your current shell."
  echo
  echo "Run:"
  echo "  source ./scripts-sh/set-java-card-env.sh"
  echo
fi

export JAVA_HOME="${JAVA_HOME:-/c/Program Files/Java/jdk-17}"
export PATH="$JAVA_HOME/bin:$PATH"
export JC_HOME_TOOLS="${JC_HOME_TOOLS:-/c/Users/adrian/Desktop/java_card_devkit_tools-bin-v26.0-b_705-04-MAY-2026}"
export JAVACARD_HOME="${JAVACARD_HOME:-$JC_HOME_TOOLS}"
export JC_HOME_SIMULATOR="${JC_HOME_SIMULATOR:-/c/Users/adrian/Desktop/java_card_devkit_simulator-win-bin-v26.0-b_788-05-MAY-2026}"

echo "JAVA_HOME=$JAVA_HOME"
echo "JAVACARD_HOME=$JAVACARD_HOME"
echo "JC_HOME_TOOLS=$JC_HOME_TOOLS"
echo "JC_HOME_SIMULATOR=$JC_HOME_SIMULATOR"
echo
echo "Environment configured for this shell session."

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  echo
  echo "Note: because this was executed directly, the environment above will not persist."
fi
