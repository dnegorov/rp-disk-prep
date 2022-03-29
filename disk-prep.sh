#./bin/bash

source $(dirname "$0")/config
source $(dirname "$0")/functions.sh

function get_disk_role() {
    if [[ -n $(echo ${CS_DISK_LIST[@]} | grep $1) ]]
        then
            echo "CS"
        elif [ $1 == $MDS_DISK_NAME ]
            then
                echo "MDS"
        else
            echo "error"
        fi
}

if [[ "${MDS_ENABLE^^}" == "NO" ]] && [[ -n "${MDS_DISK_NAME}" ]]
    then
        MDS_RESERVED_DISK="RESERVED"
    fi

echo -e "\n\n"
echo -e "PARAMETERS:"
echo -e "   Storage name:    " $VSTOR_NMAE
echo -e "   CS names policy: " "by" $CS_NAMES_POLICY
echo -e "   MDS enabled:     " ${MDS_ENABLE^^}
echo -e "   MDS disk name:   " $MDS_DISK_NAME "$MDS_RESERVED_DISK"
echo -e "   CS disk list:    " ${CS_DISK_LIST[@]}
echo -e "\n\n"

# sleep 3s

for disk in $MDS_DISK_NAME ${CS_DISK_LIST[@]}
    do
        echo /dev/$disk $(get_disk_type $disk print) $(get_disk_role $disk)
    done
