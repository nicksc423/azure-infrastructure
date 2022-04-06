# A public IP allows virtual machines to be whitelisted to access certain external services, such as the cluster API for
# installing helm packages or deploying configurations.
resource "azurerm_public_ip" "runner" {
    name = "${var.runner_name}-public-ip"
    location = var.region
    resource_group_name = var.resource_group.name
    allocation_method = "Static"
}

# Network interface using the above IP.
resource "azurerm_network_interface" "runner" {
    name = "${var.runner_name}-nic"
    location = var.region
    resource_group_name = var.resource_group.name
    internal_dns_name_label = var.runner_name
    ip_configuration {
        name = "nic1"
        subnet_id = azurerm_subnet.subnet.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id = azurerm_public_ip.runner.id
    }
}

# Create the actual runner instance.
resource "azurerm_virtual_machine" "runner" {
    name = var.runner_name
    location = var.region
    resource_group_name = var.resource_group.name
    network_interface_ids = [azurerm_network_interface.runner.id]
    vm_size = var.vm_size
    delete_os_disk_on_termination = true
    storage_image_reference {
        publisher = "Canonical"
        offer = "UbuntuServer"
        sku = "18.04-LTS"
        version = "latest"
    }
    # Reasonably sizable local storage to accommodate larger builds.
    storage_os_disk {
        name = var.runner_name
        caching = "ReadWrite"
        create_option = "FromImage"
        managed_disk_type = "StandardSSD_LRS"
        disk_size_gb = var.runner_disk_size
    }
    os_profile {
        computer_name = var.runner_name
        admin_username = "ubuntu"
        custom_data = <<EOF
#!/bin/bash
set -e -x

# Set hostname
hostname ${var.runner_name}
echo "${var.runner_name}" >> /etc/hostname

# Update packages/repo
export DEBIAN_FRONTEND=noninteractive
add-apt-repository ppa:openjdk-r/ppa
apt-get update
apt-get dist-upgrade -y

# Install jq (json query tool for bash) helps for debugging
apt-get install jq -y

# Install Telegraf for metrics
wget -qO- https://repos.influxdata.com/influxdb.key | sudo apt-key add -
source /etc/lsb-release
echo "deb https://repos.influxdata.com/$${DISTRIB_ID,,} $${DISTRIB_CODENAME} stable" | sudo tee /etc/apt/sources.list.d/influxdb.list
apt-get update && sudo apt-get install telegraf -y

telegraf --input-filter disk --output-filter azure_monitor config > azm-telegraf.conf
cp azm-telegraf.conf /etc/telegraf/telegraf.conf

systemctl stop telegraf
systemctl start telegraf
systemctl enable telegraf

# Install Docker
apt-get install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
apt-key fingerprint 0EBFCD88
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get install -y docker-ce

# Install git-lfs
apt-get install -y git-lfs

# Install GitLab Runner
curl -L https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh | bash
apt-get update
apt-get install -y gitlab-runner
usermod -aG docker gitlab-runner

# Install Azure CLI for debugging
curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# Install kubectl for debugging
apt-get update && sudo apt-get install -y apt-transport-https
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | tee -a /etc/apt/sources.list.d/kubernetes.list
apt-get update
apt-get install -y kubectl
EOF
    }
    os_profile_linux_config {
        disable_password_authentication = true
        ssh_keys {
            key_data = file("admin_key.pub")
            path = "/home/ubuntu/.ssh/authorized_keys"
        }
    }
    # Use the same managed identity as the GitLab host, so we can access Azure resources.
    identity {
        type = "UserAssigned"
        identity_ids = [azurerm_user_assigned_identity.gitlab.id]
    }

    tags = {}

    lifecycle {
      ignore_changes = [os_profile]
    }
}
