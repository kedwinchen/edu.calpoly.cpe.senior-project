source "vagrant" "generic-centos7" {
  source_path = "generic/centos7"
  communicator = "ssh"
  provider = "virtualbox"
}

build {
  name = "centos-unix-7-9"
  sources = [ "source.vagrant.generic-centos7" ]

  provisioner "shell" {
    scripts = fileset(".", "provision.sh")
  }

  post-processor "checksum" {
    checksum_types = ["sha512"]
    output = "CHECKSUMS.{{.ChecksumType}}"
  }
}
