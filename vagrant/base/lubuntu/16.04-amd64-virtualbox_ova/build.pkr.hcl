source "virtualbox-ovf" "lubuntu-1604-amd64" {
  source_path = "lubuntu-16.04.ova"
  checksum = "sha256:4995b499a79308ad0a1fa51c2052de43dfaa8015c36bea2408fbbebbf515ecba"

  communicator = "ssh"
  ssh_username = "vagrant"
  ssh_password = "vagrant"
  shutdown_command = "sudo -i -S shutdown -P now"
  vboxmanage = [
          ["modifyvm", "{{.Name}}", "--memory", "2048"],
          ["modifyvm", "{{.Name}}", "--cpus", "2"],
          ["modifyvm", "{{.Name}}", "--vram", "128"],
          ["modifyvm", "{{.Name}}", "--graphicscontroller", "vmsvga"],
  ]

  guest_additions_url = "https://download.virtualbox.org/virtualbox/6.1.18/VBoxGuestAdditions_6.1.18.iso"
  guest_additions_sha256 = "904432eb331d7ae517afaa4e4304e6492b7947b46ecb8267de7ef792c4921b4c"
  guest_additions_path = "VBoxGuestAdditions.iso"
  guest_additions_mode = "upload"
}

build {
    name = "lubuntu-1604-amd64"
    sources = [ "source.virtualbox-ovf.lubuntu-1604-amd64" ]

    post-processor "vagrant" {
      keep_input_artifact = true
      compression_level = 9
      output = "{{.BuildName}}_{{.Provider}}.box"
    }
}
