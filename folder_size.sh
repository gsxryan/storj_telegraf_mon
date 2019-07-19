#!/bin/bash
#
# Get SNO data folder size.
#
# Usage:
# ./folder_size.sh /path/to/storagenode/data/folder
#
# Output:
# StorJHealth,host=K3,path="/path/to/storagenode/data/folder" directory_size_kilobytes=45816232

# du is too slow (>30s) for SNO data folder over a terra byte. (JSON output)
#du -ks "$@" | awk '{if (NR!=1) {printf ",\n"};printf "  { \"directory_size_kilobytes\": "$1", \"path\": \""$2"\" }";}'

# Workaround, get the size of the whole mount point (disk)
# TODO: find a faster way to get the folder size
SIZE=$(df "$@" | awk '{if (NR==2) {print $3;}}')
echo -n StorJHealth,host=$HOSTNAME,path=\""$@"\" directory_size_kilobytes=$SIZE "$(date +'%s%N')"
