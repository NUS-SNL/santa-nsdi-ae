#!/bin/bash

# Base command and directory
BASE_CMD="./pcap_to_tput.sh"
BASE_FILE="pcap_9_flow_2"
BASE_DIR="~/eval/pcap_9_flow_2/"

# Replacement parameters
NUMBERS=(3 4 5)
REPLACEMENTS=("scatter" "scatter_2")

# Function to replace and execute commands
run_command() {
    local cmd=$1
    local file=$2
    local dir=$3

    echo "Running: $cmd $file $dir"
    eval "$cmd $file $dir"
}

run_command "$BASE_CMD" "$BASE_FILE" "$BASE_DIR"

# First set of replacements (replacing 2 with 3, 4, 5)
for num in "${NUMBERS[@]}"; do
    FILE_REPLACED=${BASE_FILE/2/$num}
    DIR_REPLACED=${BASE_DIR/2/$num}
    run_command "$BASE_CMD" "$FILE_REPLACED" "$DIR_REPLACED"
done

# Second set of replacements (replacing 'flow_2' with 'scatter' and 'scatter_2')
for replacement in "${REPLACEMENTS[@]}"; do
    FILE_REPLACED=${BASE_FILE/flow_2/$replacement}
    DIR_REPLACED=${BASE_DIR/flow_2/$replacement}
    run_command "$BASE_CMD" "$FILE_REPLACED" "$DIR_REPLACED"
done
