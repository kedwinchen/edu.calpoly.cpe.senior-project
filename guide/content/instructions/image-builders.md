---
title: "Image Builders"
date: 2021-03-09T12:25:26-08:00
draft: true
---

## Linux

There are two options available for Linux VMs: Using Packer, and Manually

### Using Packer (automated)

1. Follow the [common procedures](../common)
2. Install Hashicorp Packer
3. Select a Base Box to use (usually, you will want to pick either `kedwinchen/lubuntu` or `generic/centos8`. Though most of the `generic/*` Boxes are good choices -- just be sure it supports the VirtualBox provider)
4. If you are using the template Packer file (`build.pkr.hcl`), you should use the template `provision.sh` script
5. In the shell script, after the `Provisioner Part`, write the shell script to perform all of the steps you would take to set up the environment
6. To distribute the box, run `packer build build.pkr.hcl` inside the directory where the `build.pkr.hcl` (and `provision.sh`) files live
7. It is recommended to either upload the resulting `output-*/package.box` file to the Vagrant Cloud or some other server with high bandwidth.
8. If not uploading to Vagrant Cloud, you should update the `metadata.json` file


### Manually

1. Follow the [common procedures](../common)
2. Create a new VirtualBox Virtual Machine (hereinafter: "VM"), and install the operating system of your choice. Suggested specs:

   - VM Name: (something memorable, you will need it later)
   - System > CPU: 2 vCPU
   - System > Memory (RAM): 2048 MiB (2GiB)
   - Display > Video Memory: 256 MiB
   - Storage: 1 x 32 GiB SATA hard drive
   - Network: 1 x NAT
   - USB Controller: 3.0 (xHCI)

3. Create a user with username `vagrant` and password `vagrant`. This may be expected by Vagrant and other users of the image later (for example, if the Vagrant insecure public key changes).
4. Set the password for `root` to be `vagrant`. This is just convention, and may not be strictly necessary.
5. Allow the `vagrant` user to use `sudo` without a password. This can be done by adding the following to `/etc/sudoers.d/99-vagrant`
    ```
    vagrant ALL=(ALL:ALL) NOPASSWD: ALL
    ```
   ***THIS STEP IS NON-OPTIONAL!*** Other tools down the line (such as Ansible provisioner, and Vagrant itself) expect this to be the case
6. Install the following packages:

    - (needed for Oracle VM VirtualBox Guest Additions)
      - `git`
      - `gcc`
      - `make`
      - `perl`
    - `openconnect` (for now, until this can no longer connect to Cal Poly VPN)
    - `openssh-server` (need for Vagrant)

11. Update the firewall to allow SSH to pass through (so Vagrant can communicate even if the firewall is enabled)
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

14. Package the manually configured VM into a Vagrant Box. In a terminal:

    ```bash
    vagrant package --base NAME_OF_VM_IN_VIRTUALBOX --output OUTPUT_FILE.box

    # note: if you do not know the name of the VM, you can find out by running:
    VBoxManage list vms
    ```

15. If you will be building more Boxes on this system, or would like to use this base box directly,
    it is strongly recommended to add the Box to your system's local Vagrant repository:

    ```bash
    vagrant box add --force --name SOME_NAME_HERE OUTPUT_FILE.box
    ```

16. If you expect this Box to be used directly by clients (e.g., students), the Box should be hosted somewhere publicly accessible (e.g., Vagrant Cloud, an FTP/HTTP server, AWS S3)


## Windows

Microsoft Windows VMs are not currently supported by this guide.

## macOS

Apple macOS VMs are not currently supported by this guide.
