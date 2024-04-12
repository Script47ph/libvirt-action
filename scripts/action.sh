install_libvirt() {
    #check dependency
    os_check=$(grep ^ID= /etc/os-release | cut -d'"' -f2)
    if [[ $os_check =~ ^(centos|redhat|rhel|rocky|alma)$ ]]
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
install_terraform () {
    if [ -n "$(which terraform 2>/dev/null)" ]
    then
        echo "terraform is installed"
    else
        sudo yum install -y yum-utils
        sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
        sudo yum -y install terraform
    fi
}
install_geniso() {
    if [ -n "$(which mkisofs 2>/dev/null)" ]
    then
        echo "genisoimage is installed"
    else
        sudo yum install -y genisoimage
    fi
}
config_libvirt() {
    if groups|grep libvirt &>/dev/null && groups|grep kvm &>/dev/null
    then
        echo user exist in libvirt and kvm groups! skipped..
    else
        sudo usermod -aG libvirt $USER
        sudo usermod -aG kvm $USER
        newgrp libvirt
    fi
    sudo sed -i "s,#unix_sock_group,unix_sock_group,g" /etc/libvirt/libvirtd.conf
    sudo sed -i "s,#unix_sock_rw_perms,unix_sock_rw_perms,g" /etc/libvirt/libvirtd.conf
    if sudo grep ^user /etc/libvirt/qemu.conf &>/dev/null
    then
        echo user and group exists! skipped..
    else
        echo "user = \"$(whoami)\"" | sudo tee -a /etc/libvirt/qemu.conf
        echo 'group = "libvirt"' | sudo tee -a /etc/libvirt/qemu.conf
    fi
    mkdir -p $HOME/.config/libvirt/
    echo 'uri_default = "qemu:///system"' > $HOME/.config/libvirt/libvirt.conf
    sudo systemctl restart libvirtd.service
}
config_pool() {
    items=(${{ vars.POOL }})
    for i in "${items[@]}"
    do
        if virsh pool-list --name|grep $i &>/dev/null
        then
            echo pool $i exist! skipped..
        else
            mkdir -p $HOME/data/$i
            virsh pool-define-as --name $i --type dir --target $HOME/data/$i
            virsh pool-start $i
            virsh pool-autostart $i
            virsh pool-info $i
        fi
    done
}
config_net() {
    cat <<EOF> cluster-network.tf
provider "libvirt" {
    uri = "qemu:///system"
}

terraform {
    required_version = ">= 0.13"
    required_providers {
    libvirt = {
        source  = "dmacvicar/libvirt"
        version = "0.7.1"
    }
    }
}

${{ vars.NETWORK_RAW }}
    
EOF
}