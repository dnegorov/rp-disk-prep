#./bin/bash

# Get disk type
# return 0 for ssd
# return 1 for hdd
# empty if erorr
function get_disk_type() {
    if [ -n $1 ] && [ -e /sys/block/$1/queue/rotational ]
        then
            cat /sys/block/$1/queue/rotational
        fi
}

