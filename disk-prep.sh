#./bin/bash

source $(dirname "$0")/common.cfg
source $(dirname "$0")/host.cfg
source $(dirname "$0")/functions.sh


function print_cmd(){
    cmd=("$@")
    echo -e ${cmd[@]}
}

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

function set_mount_point(){
    if [[ -n $1 ]] && [[ -n $(get_disk_type $disk print) ]]
        then
            # mount point for MDS always vstor_name-mds
            if [[ $(get_disk_role $1) == "MDS" ]]
                then
                    echo $VSTORAGE_BASE_DIR"/"$VSTOR_NAME"-mds"
                    exit
                fi
            # for CS by disk name
            if [[ ${CS_NAMES_POLICY^^} == "NAME" ]] && [[ $(get_disk_role $1) == "CS" ]]
                then
                    echo $VSTORAGE_BASE_DIR"/"$VSTOR_NAME"-"$1
                    exit
                fi
            # for CS by disk type
            if [[ ${CS_NAMES_POLICY^^} == "TYPE" ]] && [[ $(get_disk_role $1) == "CS" ]]
                then
                    ssd_num=0
                    hdd_num=0
                    for disk in ${CS_DISK_LIST[@]}
                        do
                            if [[ $(get_disk_type $disk print) == "ssd" ]]
                                then
                                    ((ssd_num=ssd_num+1))
                                else
                                    ((hdd_num=hdd_num+1))
                                fi
                            if [[ $disk == $1 ]]
                                then
                                    if [[ $(get_disk_type $1 print) == "ssd" ]]
                                        then
                                            mnt_index=$(printf "ssd%02d" $ssd_num)
                                        fi
                                    if [[ $(get_disk_type $1 print) == "hdd" ]]
                                        then
                                            mnt_index=$(printf "hdd%02d" $hdd_num)
                                        fi
                                    break
                                fi
                        done
                    echo $VSTORAGE_BASE_DIR"/"$VSTOR_NAME"-"$mnt_index
                    exit
                fi
        fi
}

if [[ "${MDS_ENABLE^^}" == "NO" ]] && [[ -n "${MDS_DISK_NAME}" ]]
    then
        MDS_RESERVED_DISK="RESERVED"
    fi

ALERT_COLOR="\033[32;1;7m"
NO_COLOR="\033[0m"
# SAFE MODE BY DEFAULT (print commands only)
RUN="print_cmd"
if [[ ${SCRIPT_GENERATOR^^} == "RUN" ]]
    then
        # RUN ALL COMMANDS
        $RUN=""
        ALERT_COLOR="\033[33;1;5;7m"
    fi

echo -e "\n"
echo -e "# "$(date)
echo -e "#"
echo -e "# PARAMETERS:"
echo -e "#    Storage name:    " $VSTOR_NAME
echo -e "#    Storage path:    " $VSTORAGE_BASE_DIR"/"$VSTOR_NAME
echo -e "#    CS names policy: " "by" $CS_NAMES_POLICY
echo -e "#    MDS enabled:     " ${MDS_ENABLE^^}
echo -e "#    MDS disk name:   " $MDS_DISK_NAME "$MDS_RESERVED_DISK"
echo -e "#    CS disk list:    " ${CS_DISK_LIST[@]}
echo -e "\n"
echo -e "#"$ALERT_COLOR" SCRIPT MODE: " ${SCRIPT_GENERATOR^^} $NO_COLOR
echo -e "\n"



# sleep 3s

fmt='#\x20%-12s%-8s%-6s%-6s%-8s%-s\n'
printf $fmt DISK SIZE TYPE ROLE MOUNT_POINT
for disk in $MDS_DISK_NAME ${CS_DISK_LIST[@]}
    do
        printf $fmt /dev/$disk $(get_disk_size $disk) $(get_disk_type $disk print) $(get_disk_role $disk) $(set_mount_point $disk)
    done
echo -e "\n"

# Generate mount points for vstorage
echo -e "\n# Generate mount points for vstorage"
$RUN mkdir -p $VSTORAGE_BASE_DIR"/"$VSTOR_NAME
for disk in $MDS_DISK_NAME ${CS_DISK_LIST[@]}
    do
        $RUN mkdir -p $(set_mount_point $disk)
    done

# Prepare disks
echo -e "\n# Prepare disks"
for disk in $MDS_DISK_NAME ${CS_DISK_LIST[@]}
    do
        if [[ $(get_disk_type $disk print) == "ssd" ]]
            then
                params=$DISK_PREPARE_PARAM+" --ssd"
            else
                params=$DISK_PREPARE_PARAM
            fi
        $RUN /usr/libexec/vstorage/prepare_vstorage_drive /dev/$disk $params
    done

# Prepare /etc/fstab
echo -e "\n# Prepare /etc/fstab"
for disk in $MDS_DISK_NAME ${CS_DISK_LIST[@]}
    do
        fstab_param=$HDD_FSTAB_TEMPLATE
        if [[ $(get_disk_type $disk print) == "ssd" ]]
            then
                fstab_param=$SSD_FSTAB_TEMPLATE
            fi
        if [[ ${SCRIPT_GENERATOR^^} == "RUN" ]]
            then
                echo -e $(blkid | grep /dev/$disk | awk '{print $2}')"    "$(set_mount_point $disk)"    "$fstab_param >> /etc/fstab
            else
                get_uuid='$(blkid | grep /dev/'$disk" | awk '{print "'$2'"}')"
                $RUN echo -e $get_uuid"    "$(set_mount_point $disk)"    "$fstab_param" >> /etc/fstab"
            fi
    done

# Mount all disks
echo -e "\n# Mount all disks"
$RUN mount -a


