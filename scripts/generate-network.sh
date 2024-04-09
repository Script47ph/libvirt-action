generate_net() {
    cat <<EOF> $TEMPLATE_DIR/cluster-network.tf
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
}