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
  name = "hello-world-instance"
  machine_type = {
    name = "cloud-bs1.xsmall"
  }
  image = {
    name = "cloud-ubuntu-22.04 LTS"
  }
  network = {
    associate_public_ip = true
    delete_public_ip    = true
  }

  ssh_key_name = "ssh-magalu-judge"

  # Transfere o arquivo em C para a VM
  provisioner "file" {
    source      = "Hello World.cpp"               # Arquivo C local
    destination = "/home/ubuntu/hello.cpp"  # Destino na VM
  }

  # Compilar e executar o programa
  provisioner "remote-exec" {
    inline = [
      "sudo apt update",
      "sudo apt install -y g++",                        # Instala o GCC no Ubuntu
      "g++ /home/ubuntu/hello.cpp -o /home/ubuntu/hello", # Compila o programa
      "/home/ubuntu/hello"                              # Executa o programa
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
