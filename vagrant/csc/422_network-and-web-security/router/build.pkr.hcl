source "vagrant" "lubuntu" {
  communicator = "ssh"
  # box_name = "lubuntu-20.04-amd64-virtualbox"
  # source_path = "https://cpslo-kedwin.chen.network/senior-project/files/base/lubuntu-20.04-amd64-virtualbox.box"
  source_path = "kedwinchen/lubuntu-2004"
  add_force = true
  provider = "virtualbox"
}

build {
  name = "csc-422-router"

  sources = [ "source.vagrant.lubuntu" ]

  provisioner "shell" {
    scripts = fileset(".", "provision.sh")
  }

  post-processor "checksum" {
    checksum_types = ["sha512"]
    output = "CHECKSUMS.{{.ChecksumType}}"
  }
}
