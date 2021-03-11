---
title: "Building the lubuntu base Box (manual procedure)"
date: 2021-03-11T11:47:12-0800
draft: false
---

0. If you really need to build the Box from scratch, follow this guide.
   Otherwise, use the pre-built box from here (also built using these instructions):
   [https://cpslo-kedwin.chen.network/senior-project/files/base/lubuntu-20.04-amd64-virtualbox.box](https://cpslo-kedwin.chen.network/senior-project/files/base/lubuntu-20.04-amd64-virtualbox.box)
1. Follow the [Common Steps](../common), to install the required software.
2. Obtain a copy of the Lubuntu install disc from here:
   [https://cdimage.ubuntu.com/lubuntu/releases/](https://cdimage.ubuntu.com/lubuntu/releases/).
3. Create a new Virtual Machine (hereinafter: "VM"). Suggested specs:

   - VM Name: (something memorable, you will need it later)
   - System > CPU: 2 vCPU
   - System > Memory (RAM): 2048 MiB (2GiB)
   - Display > Video Memory: 256 MiB
   - Storage: 1 x 32 GiB SATA hard drive
   - Network: 1 x NAT
   - USB Controller: 3.0 (xHCI)

4. Install base system. Use `vagrant` as the both the username and password (convention; though may be expected by Vagrant later)
5. Reboot the VM. The following instructions should be taken inside the VM, unless specified otherwise.
6. Make `vagrant` be able to run `sudo` without prompting for a password (convention; though probably expected by Vagrant later)

   1. Open a terminal (usually under `Start Menu > System Tools`)
   2. Run the command: `visudo -f /etc/sudoers.d/99-vagrant`
   3. In the file, input the following content:

      ```
      vagrant ALL=(ALL:ALL) NOPASSWD: ALL
      ```

7. Change the password for `root` to be `vagrant`
   (probably optional; this is just convention used by most publicly available Vagrant boxes)
8. Update the package repository status: `apt-get update`
9. Upgrade the installed packages (may not have installed during the install): `apt-get upgrade -y`
10. Install the following packages (`apt-get install -y <packages>`)

- (needed for Oracle VM VirtualBox Guest Additions)
  - `git`
  - `gcc`
  - `make`
  - `perl`
- `openconnect` (for now, until this can no longer connect to Cal Poly VPN)
- `openssh-server` (need for Vagrant)

11. Update the firewall to allow SSH to pass through (so Vagrant can communicate even if the firewall is enabled)
    by using the command: `ufw allow ssh`
12. Install the Insecure Vagrant SSH Public Key. This key is a well-known SSH key.
    However, this is not a security risk, because the key will be replaced by Vagrant when the machine is brought up by the user for the first time.
    Installing this key is non-optional, as Vagrant will use the corresponding private key to authenticate to the VM
    (Note: it is highly likely that Packer also uses the corresponding private key when this Box is used with the Vagrant builder).

    ```bash
    mkdir -p ~/.ssh/
    wget 'https://raw.githubusercontent.com/hashicorp/vagrant/main/keys/vagrant.pub' -O ~/.ssh/authorized_keys
    chmod 600 ~/.ssh/authorized_keys
    ```

13. Install the VirtualBox Guest Additions:

    1. In VirtualBox, insert the Guest Additions CD Image by navigating to `Devices > Insert Guest CD Image`
    2. In the VM, navigate to where the CD is mounted to. Some typical mount points are listed below:

       - `/media/vagrant/VBox_GAs_<Version>`
       - `/mnt/cdrom`
       - `/media/cdrom`
       - `/run/media/vagrant/VBox_Guest_Additions`

    3. In this folder, there should be a file named like `VBoxLinuxAdditions.run`. Execute it as a program with root privileges:

       ```
       sudo bash VBoxLinuxAdditions.run
       ```

    4. On completion, VirtualBox Guest Additions should be installed.

14. Clean the package cache: `apt-get clean`
15. Shut down the virtual machine. The remaining steps should be taken on the host (outside of the VM).
16. Package the manually configured VM into a Vagrant Box. In a terminal:

    ```bash
    vagrant package --base NAME_OF_VM_IN_VIRTUALBOX --output OUTPUT_FILE.box

    # note: if you do not know the name of the VM, you can find out by running:
    VBoxManage list vms
    ```

17. If you will be building more Boxes on this system, or would like to use this base box directly,
    it is strongly recommended to add the Box to your system's local Vagrant repository:

    ```bash
    vagrant box add --force --name lubuntu OUTPUT_FILE.box
    ```

18. If you expect this Box to be used directly by clients (e.g., students), the Box should be hosted somewhere publicly accessible (e.g., an FTP/HTTP server, S3)
