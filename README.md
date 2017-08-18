In order to try out the XDP functionality, it would be nice to have a
playground. This could be useful if you are worried about experimental kernels
(not sure why you're reading this, but hey...) or if you don't have the required
hardware to run XDP.

This repo thus provides a vagrant based vm for you to try it out. We'll simply
install the necessary kernel and some userspace tools to be able to load your
program. Note that the vm will use an e1000 driver, which won't show much
performance difference from the normal stack. Trust us that it would perform
much better on real hardware.

Host prerequisites:
* libvirt
* vagrant
* vagrant-libvirt

**On Debian (tested on Ant testbed):** 
`apt-get install qemu-kvm libvirt libvirt-dev libvirt-clients libvirt-daemon-system`

**Debian 8 native vagrant distribution doesn't support libvirt provider**:
Download and install the latest release for Debian 64-bit here: https://www.vagrantup.com/downloads.html

Install vagrant plugins: 
```
vagrant plugin install vagrant-reload
vagrant plugin install vagrant-libvirt
vagrant plugin install vagrant-mutate
```

(If someone tries this on non-libvirt vagrant, file a /issue and we can
simplify the prerequisites.)

For convenience, there is a pre-built 4.8 rc kernel which includes the e1000
patch from [git:ast/xdp](http://git.kernel.org/cgit/linux/kernel/git/ast/bpf.git/commit/?h=xdp&id=e643c99556770a6b77c1330bcd9d28d578026788). Feel free to build your own, or if you're reading
this from the future, likely 4.9 will have support for it.

Bring the vagrant box up, with userspace tools (bcc) and custom kernel

```
git clone https://github.com/iovisor/xdp-vagrant
cd xdp-vagrant
```

**If you're using ant testbed, you need to set up the https proxy:** 
* uncomment the following line in setup-apt.sh:
`echo "https_proxy=http://192.168.0.1:8123" | tee -a /etc/environment`

If you get an error *libvirt provider is not supported*, there are two ways to solve it:

1 Use alternative vagrant box:

* uncomment the following line in Vagrantfile: `config.vm.box = "rboyer/ubuntu-trusty64-libvirt"`
* and comment original line: `#config.vm.box = "ubuntu/trusty64" # Ubuntu 14.04`

2 If option 1 doesn't work conver the box to libvirt-compatible:

* convert the original vagrant box to libvirt provider: `vagrant mutate ubuntu/trusty64 libvirt`
* delete the original box: `vagrant box remove --provider virtualbox ubuntu/trusty64`
* check the box list and remove others if necessary: `vagrant box list`

Bring the VM up: `vagrant up`
*Note that some apt errors above are expected*

If you modify any of the provisioning scripts (*.sh) you need to reload box and re-run provisioning:
`vagrant reload --provision`

Finally, all the provisioning scripts should complete successfully and you should see `pyroute2 installed` message.

SSH to the VM: 

```
vagrant ssh
uname -r
```

**confirm that the running kernel is something like 4.7.0-07282016-torvalds+**

You should find that the vm has two interfaces, we'll use the second one for
testing and the first one for ssh.

```
vagrant@vagrant-ubuntu-trusty-64:~$ ip -4 a
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    inet 192.168.121.153/24 brd 192.168.121.255 scope global eth0
3: eth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    inet 192.168.50.4/24 brd 192.168.50.255 scope global eth1
```

Let's start a udp packet performance stress test. Run this from the host in
another shell:

```
./setup-pktgen.sh
MAC=ETH1_MAC_INSIDE_THE_VM
IP=ETH1_IP_INSIDE_THE_VM
VNET=TAP_DEVICE_OF_ETH1_OUTSIDE_THE_VM (e.g. virbr2)
sudo ./pktgen_sample03_burst_single_flow.sh -i $VNET -d $IP -m $MAC -t 1 -b 1 -c 0
```

Now, simply try out the sample xdp script. This comes from the libbcc-examples
package:

```
sudo /usr/share/bcc/examples/networking/xdp/xdp_drop_count.py eth1
Printing drops per IP protocol-number, hit CTRL+C to stop
17: 179118 pkt/s
17: 509420 pkt/s
```
```
