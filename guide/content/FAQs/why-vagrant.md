---
title: "Why Vagrant?"
date: 2021-03-09T12:51:24-08:00
draft: true
---

After doing some research, I have determined that the simplest method would be to use Vagrant (FOSS, from HashiCorp) for the building, provisioning, and distribution of the environments.
This would mean building a custom Vagrant Box for each course (and possibly for each professor, if their software stack for a class is different).

While currently I am building virtual machines using Vagrant and the result would be similar to a `.ova`, Vagrant would simplify the setup process on the end-user (student) side.
After installing Vagrant and VirtualBox (or another supported virtualization driver), the only setup they need is to download the Vagrantfile (which could be distributed through Canvas) and execute "vagrant up" (which does the hard work of provisioning the VM and the required resources, as well as set up a shared folder between the VM and the host, which will likely be convenient.).
To build a custom Vagrant Box, I am using Packer (another HashiCorp product), though there is also a more manual way to build Vagrant Boxes.

I am currently using full/thick virtual machines because it is easier to have graphical application support (through the VirtualBox console) as compared to Docker.
That being said, Vagrant does support Docker as a backend for Boxes, so this is a possible future expansion route.
