source "vagrant" "generic-ubuntu" {
  communicator = "ssh"
  source_path = "generic/ubuntu2004"
  add_force = true
  provider = "virtualbox"
}

build {
    name = "csc-422-testing"

    sources = [ "source.vagrant.generic-ubuntu" ]

    provisioner "shell" {
        scripts = fileset(".", "provision.sh")
    }
}
