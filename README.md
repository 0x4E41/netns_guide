# Wireguard network namespace container
Network namespaces is a linux feature which allows users to create a seperate network-stack within the operating system. This guide will cover the creation of a network namespace container connected to a wireguard tunnel, allowing us to route the traffic of selected programs through the wireguard interface. 

The script `create_container.sh` summarizes all the commands.

---

First, we need to obtain a wireguard VPN configuration file. We will be working with the file `wg0.conf`, obtained from `mullvad.net`.

```
[Interface]
# Device: Sacred Squid
PrivateKey = <private-key>
Address = <ipv4-address>[,<ipv6-address>]
DNS = <dns>

[Peer]
PublicKey = <public-key>
AllowedIPs = 0.0.0.0/0,::0/0
Endpoint = <endpoint>
```

Then, comment out the lines containing `Address` and `DNS`. 
```
[Interface]
# Device: Sacred Squid
PrivateKey = <private-key>
#Address = <address>
#DNS = <dns>

[Peer]
PublicKey = <public-key>
AllowedIPs = 0.0.0.0/0,::0/0
Endpoint = <endpoint>
```
Now create the network namespace `container`.
```
sudo ip netns add container
```

Then, we create a Wireguard interface and move it to our new `container` namespace.
```
sudo ip link add wg0 type wireguard
sudo ip link set wg0 netns container
```
Finally, we assign the interface the `<ipv4-address>` (and `<ipv6-address>` if available) from the configuration file above, pass the configuration file, and set the wireguard interface as default in our new `container` network namespace.
```
sudo ip -n container addr add <ipv4-address> dev wg0
sudo ip -n container addr add <ipv6-address> dev wg0 # if you have an ipv6 address in your wg0.conf file
sudo ip netns exec container wg setconf wg0 ./wg0.conf
sudo ip -n container route add default dev wg0
```

Now, to run the `<app>` application through the wireguard interface:
```
sudo ip netns exec container sudo HOME="/home/<user>" XDG_RUNTIME_DIR="/run/user/<uid>"  -u $USER <app>
```
Where `<user>` and `<uid>` correspond to your linux username and user id respectively.
You can obtain `<user>` and `<uid>` (which is typically `1000`) with `echo $USER $UID`.

---

For example, after creating the network namespace `container` we can run firefox inside this contianer with:
```
sudo ip netns exec container sudo HOME="/home/nawaf" XDG_RUNTIME_DIR="/run/user/1000" -u $USER firefox
```
Now, all of the traffic to and from firefox would run through the wireguard tunnel.