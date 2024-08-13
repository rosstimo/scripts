#!/bin/bash

# Initialize variables for long options and debug flag
source_path=""
destination_path=""
name=""
debug=0
debug_messages=""

# Function to display usage information
usage() {
  echo
  echo "Usage: $0 [options]"
  echo ""
  echo "Options:"
  echo "  -h, --help              Show this help message and exit."
  echo "  -[a-zA-Z]               Process short options."
  echo "  --source PATH           Specify the source path."
  echo "  --destination PATH      Specify the destination path."
  echo "  --name NAME             Specify the name."
  echo "  --debug                 Enable debug mode."
  echo ""
  exit 1
}

# Function to display an error message
error_msg() {
  echo
  echo "Error: $1" >&2
  usage
}

# Function append newline and argument to debug_messages
debug_message() {
  new_message=$1
  debug_messages="${debug_messages}\n${new_message}"
}


# Function to process short options
process_short_opts() {
  local opts=$1
  for (( i=0; i<${#opts}; i++ )); do
    case "${opts:$i:1}" in
      h)
        usage
        ;;
      a)
        # [ $debug -eq 1 ] && echo "Option -a triggered"
        debug_message "Option -${opts:$i:1} triggered and matched"
        ;;
      b)
        # [ $debug -eq 1 ] && echo "Option -b triggered"
        debug_message "Option -${opts:$i:1} triggered and matched"
        ;;
      c)
        # [ $debug -eq 1 ] && echo "Option -c triggered"
        debug_message "Option -${opts:$i:1} triggered and matched"
        ;;
      [a-zA-Z])
        # [ $debug -eq 1 ] && echo "Option -${opts:$i:1} triggered"
        debug_message "Option -${opts:$i:1} triggered"
        ;;
      *)
        error_msg "Invalid option: -${opts:$i:1}"
        ;;
    esac
  done
}

# Check if no arguments are provided
if [ $# -eq 0 ]; then
  usage
fi

# Iterate over all arguments
while [ "$#" -gt 0 ]; do
  case "$1" in
    --help)
      usage
      ;;
    --debug)
      debug=1
      shift
      ;;
    -[a-zA-Z]*)  # Match short options
      process_short_opts "${1:1}"
      shift
      ;;
    --source)  # Long option for source path
      if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
        source_path="$2"
        shift 2
      else
        error_msg "source requires a path"
      fi
      ;;
    --destination)  # Long option for destination path
      if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
        destination_path="$2"
        shift 2
      else
        error_msg "destination requires a path"
      fi
      ;;
    --name)  # Long option for name
      if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
        name="$2"
        shift 2
      else
        error_msg "name requires a value"
      fi
      ;;
    *)
      error_msg "Unsupported argument: $1"
      ;;
  esac
done

# Output the values of long options only if debug is enabled
if [ $debug -eq 1 ]; then
    echo -e $debug_messages
    echo "Source Path: $source_path"
    echo "Destination Path: $destination_path"
    echo "Name: $name"
fi

exit 0
