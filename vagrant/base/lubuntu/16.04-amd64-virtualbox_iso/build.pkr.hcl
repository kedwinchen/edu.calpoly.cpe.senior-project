source "virtualbox-iso" "lubuntu-1604-amd64" {
  guest_os_type = "Ubuntu_64"
  iso_url = "https://cdimage.ubuntu.com/lubuntu/releases/16.04/release/lubuntu-16.04.6-desktop-amd64.iso"
  iso_checksum = "sha256:d069c1595b91673648b72664bcaffa8f0dad908e0010332bf847cdaab4f87229"

  communicator = "ssh"
  ssh_username = "root"
  ssh_password = "vagrant"
  shutdown_command = "echo 'vagrant' | sudo -i -S shutdown -P now"
  vboxmanage = [
          ["modifyvm", "{{.Name}}", "--memory", "2048"],
          ["modifyvm", "{{.Name}}", "--cpus", "2"],
          ["modifyvm", "{{.Name}}", "--vram", "128"],
          ["modifyvm", "{{.Name}}", "--graphicscontroller", "vmsvga"],
  ]

  boot_command = [
        "<enter><wait>",
        "<f6><esc>",
        "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>",
        "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>",
        "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>",
        "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>",
        "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>",
        "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>",
        "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>",
        "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>",
        "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>",
        "/casper/vmlinuz ",
        "initrd=/casper/initrd ",
        "auto-install/enable=true ",
        "debconf/priority=critical ",
        "ipv6.disable_ipv6=1 net.ifnames=0 biosdevname=0 preseed/url=http://{{.HTTPIP}}:{{.HTTPPort}}/lubuntu.seed<wait> ",
        "<enter>"
  ]

  guest_additions_url = "https://download.virtualbox.org/virtualbox/6.1.18/VBoxGuestAdditions_6.1.18.iso"
  guest_additions_sha256 = "904432eb331d7ae517afaa4e4304e6492b7947b46ecb8267de7ef792c4921b4c"
  guest_additions_path = "VBoxGuestAdditions.iso"
  guest_additions_mode = "upload"
}

build {
    name = "lubuntu-1604-amd64"
    sources = [ "source.virtualbox-iso.lubuntu-1604-amd64" ]
}
