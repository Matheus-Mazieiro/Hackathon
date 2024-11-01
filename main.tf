terraform {
  required_providers {
    mgc = {
      source = "magalucloud/mgc"
    }
  }
}

provider "mgc" {
  region = "br-se1"
}

# Criar uma VM na Magalu Cloud
resource "mgc_virtual_machine_instances" "hello_world_instance" {
  name = "judge-pequeno"
  machine_type = {
    name = "BV1-1-10"
  }
  image = {
    name = "cloud-ubuntu-22.04 LTS"
  }
  network = {
    associate_public_ip = true
    delete_public_ip    = true
  }

  ssh_key_name = "ssh-magalu-judge"

  provisioner "remote-exec" {
    inline = [
      "#!/bin/bash",
      "sudo mkfs.ext4 /dev/vdb",
      "sudo mkdir /mnt/vdb",
      "sudo mount /dev/vdb /mnt/vdb",
      "sudo apt update -y",
      "cd /mnt/vdb",
      "sudo apt install -y docker.io docker-compose unzip",
      "sudo wget https://github.com/judge0/judge0/releases/download/v1.13.1/judge0-v1.13.1.zip",
      "sudo unzip judge0-v1.13.1.zip",
      "cd judge0-v1.13.1",
      "sudo sed -i s/^REDIS_PASSWORD=.*/REDIS_PASSWORD=senha1/ ./judge0.conf",
      "sed -i s/^POSTGRES_PASSWORD=.*/POSTGRES_PASSWORD=senha2/ ./judge0.conf",
      "sudo docker-compose up -d db redis",
      "sleep 10s",
      "sudo docker-compose up -d",
      "sleep 5s"
          ]
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("./ssh-magalu")
    host        = self.network.public_address
  }
}

output "public_ip" {
  value = mgc_virtual_machine_instances.hello_world_instance.network.public_address
}


# Create a volume 
resource "mgc_block_storage_volumes" "example_volume" {
  name = "voluejudge"
  size = 50
  type = {
    name = "cloud_nvme"
  }
}

output "example_volume_id" {
  value = mgc_block_storage_volumes.example_volume.id
}



resource "mgc_block_storage_volume_attachment" "attach_example" {
  block_storage_id = mgc_block_storage_volumes.example_volume.id
  virtual_machine_id = mgc_virtual_machine_instances.hello_world_instance.id
}