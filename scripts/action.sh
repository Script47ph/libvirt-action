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
destroy_depend() {
    sudo yum remove -y genisoimage terraform qemu-kvm libvirt
}
config_libvirt() {
    if groups|grep libvirt &>/dev/null && groups|grep kvm &>/dev/null
    then
        echo user already exist in libvirt and kvm groups! skipped..
    else
        sudo usermod -aG libvirt $USER
        sudo usermod -aG kvm $USER
        newgrp libvirt
    fi
    sudo sed -i "s,#unix_sock_group,unix_sock_group,g" /etc/libvirt/libvirtd.conf
    sudo sed -i "s,#unix_sock_rw_perms,unix_sock_rw_perms,g" /etc/libvirt/libvirtd.conf
    if sudo grep ^user /etc/libvirt/qemu.conf &>/dev/null
    then
        echo user and group already exists! skipped..
    else
        echo "user = \"$(whoami)\"" | sudo tee -a /etc/libvirt/qemu.conf
        echo 'group = "libvirt"' | sudo tee -a /etc/libvirt/qemu.conf
    fi
    mkdir -p $HOME/.config/libvirt/
    echo 'uri_default = "qemu:///system"' > $HOME/.config/libvirt/libvirt.conf
    sudo systemctl restart libvirtd.service
}
destroy_libvirt() {
    if groups|grep libvirt &>/dev/null && groups|grep kvm &>/dev/null
    then
        echo user exist in libvirt and kvm groups. deleting..
        sudo gpasswd -d $USER libvirt
        sudo gpasswd -d $USER kvm
    else
        echo user doesn\'t exist in libvirt and kvm groups. exiting..
    fi
    sudo sed -i "s,^unix_sock_group,#unix_sock_group,g" /etc/libvirt/libvirtd.conf
    sudo sed -i "s,^unix_sock_rw_perms,#unix_sock_rw_perms,g" /etc/libvirt/libvirtd.conf
    if sudo grep ^user /etc/libvirt/qemu.conf &>/dev/null
    then
        echo user and group exists. deleting..
        sudo sed -i "s,^user =,#user =,g" /etc/libvirt/qemu.conf
        sudo sed -i "s,^group =,#group =,g" /etc/libvirt/qemu.conf
    else
        echo user and group doesn\'t exist. exiting..
    fi
    rm -rf $HOME/.config/libvirt/
    sudo systemctl restart libvirtd.service
}
config_pool() {
    items=($POOL)
    for i in ${items[@]}
    do
        if virsh pool-list --name|grep $i &>/dev/null
        then
            echo pool $i already exist! skipped..
        else
            mkdir -p $POOLDIR/$i
            virsh pool-define-as --name $i --type dir --target $POOLDIR/$i
            virsh pool-start $i
            virsh pool-autostart $i
            virsh pool-info $i
        fi
    done
}
destroy_pool() {
    items=($POOL)
    for i in "${items[@]}"
    do
        if virsh pool-list --name|grep $i &>/dev/null
        then
            echo pool $i exist. deleting..
            virsh pool-destroy $i
            virsh pool-undefine $i
        else
            echo pool $i doesn\'t exist. exiting..
        fi
    done
}
config_img() {
    if virsh vol-list $POOL_IMG|grep -i $TESTING_IMG &>/dev/null
    then
        echo testing image $TESTING_IMG already exist! skipped..
    else
        wget -s $TESTING_IMG_URL -O $POOLDIR/$POOL_IMG/$TESTING_IMG
        virsh pool-refresh $POOL_IMG
    fi
}
destroy_img() {
    if virsh vol-list $POOL_IMG|grep -i $TESTING_IMG &>/dev/null
    then
        echo testing image $TESTING_IMG exist. deleting..
        sudo rm -rf $POOLDIR/$POOL_IMG/$TESTING_IMG
    else
        echo testing image $TESTING_IMG doesn\'t exist! exiting..
    fi
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

$NETWORK_RAW
    
EOF
    terraform init
    terraform validate
    if virsh net-list --name|grep $(grep name cluster-network.tf | cut -d'"' -f2) &>/dev/null
    then
        echo network exist! skipped..
    else
        terraform apply -auto-approve
    fi
}