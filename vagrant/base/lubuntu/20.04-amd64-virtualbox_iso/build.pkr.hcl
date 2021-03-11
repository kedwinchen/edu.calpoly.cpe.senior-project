source "virtualbox-iso" "lubuntu-2004-amd64" {
  guest_os_type = "Ubuntu_64"
  iso_url = "https://cdimage.ubuntu.com/lubuntu/releases/20.04.2/release/lubuntu-20.04.2-desktop-amd64.iso"
  iso_checksum = "sha256:7f3c4465618e17104f0c76e5646c7caccb4161bc01a102ed04d34b1b4f1e4208"

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
        "<tab><wait><tab><wait><tab><wait><tab><wait>",
        "<tab><wait><tab><wait><tab><wait><tab><wait>",
        "<tab><wait><tab><wait><tab><wait><tab><wait>",
        "<esc><f6><esc>",
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
        "fb=false ",
        "auto-install/enable=true ",
        "debconf/priority=critical ",
        "console-setup/ask_detect=false ",
        "debconf/frontend=noninteractive ",
        "ipv6.disable_ipv6=1 net.ifnames=0 biosdevname=0 preseed/url=http://{{.HTTPIP}}:{{.HTTPPort}}/ubuntu2004.cfg<wait> ",
        " --- <enter>"
  ]

  guest_additions_url = "https://download.virtualbox.org/virtualbox/6.1.18/VBoxGuestAdditions_6.1.18.iso"
  guest_additions_sha256 = "904432eb331d7ae517afaa4e4304e6492b7947b46ecb8267de7ef792c4921b4c"
  guest_additions_path = "VBoxGuestAdditions.iso"
  guest_additions_mode = "upload"
}

build {
    name = "lubuntu-2004-amd64"
    sources = [ "source.virtualbox-iso.lubuntu-2004-amd64" ]
}
