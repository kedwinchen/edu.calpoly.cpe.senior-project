source "vagrant" "lubuntu" {
  communicator = "ssh"
  box_name = "lubuntu-20.04-amd64-virtualbox"
  source_path = "https://cpslo-kedwin.chen.network/senior-project/files/base/lubuntu-20.04-amd64-virtualbox.box"
  # Packer complains about this being here
  # checksum_type = "sha512"
  # checksum = "271b59a2cd5ddeb24b3385c7233d8084f9c6983409a7b4964b317ac9ca2addbaf0c2669588250f7af665b18896ad47443174b162fedfe91dc048b0108e48e455"
  add_force = true
  provider = "virtualbox"
}

build {
    name = "csc-422-inspection"

    sources = [ "source.vagrant.lubuntu" ]

    provisioner "shell" {
        scripts = fileset(".", "provision.sh")
    }
}
