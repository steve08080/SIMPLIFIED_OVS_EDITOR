#!/bin/ba sh

#AUTHOR: https://github.com/steve08080
#VERSION: 1.0
#LAST MODIFIED: 26/02/22

#NOTES:
# - script must be run as root
# - all mirrors will have select_all set to true
# - only one mirror should be created for each bridge

#LINKS:
#OVS: https://www.openvswitch.org/
#GITHUB: https://github.com/steve08080/SIMPLIFIED_OVS_EDITOR

#creates a mirror port for all switch traffic
function create_full_mirror {

  #create and add dedicated mirror port to bridge
  ip tuntap add mode tap vmirror
  ip link set vmirror up
  ovs-vsctl add-port br-$1 vmirror

  #mirror creation and config
  ovs-vsctl \
  -- --id=@m create mirror name=$1mr \
  -- add bridge br-$1 mirrors @m \
  -- --id=@vmirror get port $1vmirror \
  -- set mirror $1mr select_all=true output-port=@vmirror

  printf "mirror created successfully\nPRESS ANY KEY TO CONTINUE"
  read

}

#deletes selected bridge
function delete_bridge {

  ip link set $1 down
  ovs-vsctl del-br $1

}

#creates new bridge with given name
function create_bridge {

  printf "Enter bridge name(c to cancel)\n:br-"
  read br_name

  if [ $br_name != "c" ] && [ $br_name != "C" ];
  then
    ovs-vsctl add-br br-$br_name
  fi

}

#creates a given number of ports for selected bridge
function create_vports {

  echo "How many vports: "
  read vport_num

  while [ $vport_num -gt 0 ]
    do
    ip tuntap add mode tap $1vport$vport_num
    ip link set $1vport$vport_num up
    ovs-vsctl add-port br-$1 $1vport$vport_num
    ((vport_num--))
  done
  printf "vports created successfully\nPRESS ANY KEY TO CONTINUE"
  read

}

#menu for currently selected bridge
function curr_br {

  ip link set br-$1 down
  while :
    do
    printf "\033cSIMPLIFIED_OVS_EDITOR_1.0\n\n"
    printf "Selected bridge: %s\n  0:Back\n  1:Create Vports\n  2:Create Full Mirror\n  3:Delete Bridge\nSelect an option:" "$1"
    read opt

    case "$opt" in

      0)
        break
        ;;
      1)
        create_vports $1
        ;;
      2)
        create_full_mirror $1
        ;;
      3)
        delete_bridge br-$1
        break
        ;;
      *)
        echo "Unrecognized option"
        ;;

    esac
  done
  ip link set br-$1 up

}

#main menu
function br_select {
  declare sel=1
  while [ $sel != "0" ]
    do
    printf "\033cSIMPLIFIED_OVS_EDITOR_1.0\n\n"
    mapfile -t NICs < <(ip a | grep -o br-[^:])
    printf "Existing bridges: %s\nSelect or create bridge:\n  0:Exit Program\n  1:Create Bridge\n  2:Select Bridge\n  3:Show All\n:" "${NICs[*]}"
    read sel

    case $sel in
      0)
        break
        ;;
      1)
        create_bridge
        ;;
      2)
        printf "Enter bridge name\n:br-"
        read sel_br
        for b in ${NICs[@]}
        do
          if [ br-$sel_br == $b ];
          then
            curr_br $sel_br
          fi
        done
        ;;
      3)
        printf "\033cSIMPLIFIED_OVS_EDITOR_1.0\n\n"
        ovs-vsctl show
        echo "PRESS ANY KEY TO RETURN"
        read
        ;;
      *)
        echo "Unrecognized option"
        ;;
    esac
  done
}

br_select
echo "PROGRAM_END"
