#!/bin/bash
install_libvirt() {
    #check dependency
    os_check=$(grep ^ID= /etc/os-release | cut -d'"' -f2)
    if $os_check == "centos|redhat|rhel|rocky|alma"
    then
        sudo yum update -y
        if rpm -q libvirt &>/dev/null
        then 
            echo "libvirt is installed."
        else 
            sudo yum install qemu-kvm libvirt -y
        fi
    else
        echo "your os not supported yet."
    fi
}

# Main
install_libvirt