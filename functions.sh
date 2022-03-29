#./bin/bash

# Get disk type
# return: 0 for ssd, 1 for hdd or empty if erorr
# params: disk name "sdb"
# echo $(get_disk_type sdb)
function get_disk_type() {
    if [ -n $1 ] && [ -e /sys/block/$1/queue/rotational ]
        then
            d_type_=$(cat /sys/block/$1/queue/rotational)
        fi
    case $d_type_ in
        1) d_type="hdd";;
        0) d_type="ssd";;
        *) d_type="error"
    esac
    if [[ $2 == "print" ]] 
        then
            echo $d_type
        else
            echo $d_type_
    fi
}

echo $(get_disk_type sda) = $(get_disk_type sda print)
echo $(get_disk_type sdz) = $(get_disk_type sdz print)
