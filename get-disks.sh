#./bin/bash

source $(dirname "$0")/functions.sh

DISK_LIST=$(lsblk -o name  | grep -w "sd[a-z]")

echo -e ${DISK_LIST[@]}

for disk in ${DISK_LIST[@]}
    do
        echo $disk $(get_disk_size $disk) $(get_disk_type $disk print)
    done

