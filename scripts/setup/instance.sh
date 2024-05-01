config_img() {
    if virsh vol-list $POOL_IMG|grep -i $OS_IMG &>/dev/null
    then
        echo testing image $OS_IMG already exist! skipped..
    else
        wget -q --show-progress $OS_IMG_URL -O $POOLDIR/$POOL_IMG/$OS_IMG
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
config_instance() {
    cd ${{ vars.INSTANCE_DIR }}
    echo "${{ vars.INSTANCE_SPECS }}" > testing-instance.txt
    bash scripts/terraform-gen/tfgen.sh testing testing-instance.txt
    cd testing
    terraform init
    terraform validate
    terraform apply -auto-approve
}
destroy_instance() {
    
}
destroy_net() {
    net_list=$(grep name $NETWORK_DIR/network/cluster-network.tf|cut -d'"' -f2) &>/dev/null
    for i in $net_list
    do
        if virsh net-list --name|grep $i
        then
            echo network exist. deleting..
            virsh net-destroy $i
            virsh net-undefine $i
        else
            echo network doesn\'t exist! exiting..
        fi
    done
    rm -rf $NETWORK_DIR/network/
}
config_net() {
    mkdir -p $NETWORK_DIR/network/
    cat <<EOF> $NETWORK_DIR/network/cluster-network.tf
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
    cd $NETWORK_DIR/network/
    terraform init
    terraform validate
    net_list=$(grep name cluster-network.tf|cut -d'"' -f2) &>/dev/null
    for i in $net_list
    do
        if virsh net-list --name|grep $i
        then
            echo network exist! skipped..
        else
            terraform apply -auto-approve
        fi
    done
}