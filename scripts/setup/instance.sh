config_img() {
    if virsh vol-list $POOL_IMG|grep -i $OS_IMG &>/dev/null
    then
        echo testing image $OS_IMG already exist! skipped..
    else
        wget -q $OS_IMG_URL -O $POOLDIR/$POOL_IMG/$OS_IMG
        virsh pool-refresh $POOL_IMG
    fi
}
destroy_img() {
    if virsh vol-list $POOL_IMG|grep -i $OS_IMG &>/dev/null
    then
        echo testing image $OS_IMG exist. deleting..
        sudo rm -rf $POOLDIR/$POOL_IMG/$OS_IMG
    else
        echo testing image $OS_IMG doesn\'t exist! exiting..
    fi
}
destroy_net() {
    if virsh net-list --name|grep $(grep name cluster-network.tf | cut -d'"' -f2) &>/dev/null
    then
        echo network exist. deleting..
        virsh net-destroy $(grep name cluster-network.tf | cut -d'"' -f2)
        virsh net-undefine $(grep name cluster-network.tf | cut -d'"' -f2)
    else
        echo network doesn\'t exist! exiting..
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