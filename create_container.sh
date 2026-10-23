if [ $# -eq 0 ]
	then
		echo "USAGE: $(basename "$0") <wgconf-file>"
		echo "Please provide a wireguard configuration file as a commandline argument"
		exit
fi

wg_ipv4=$(cat $1 | grep Address | cut -d " " -f3 | cut -d , -f1)
wg_ipv6=$(cat $1 | grep Address | cut -d " " -f3 | cut -d , -f2)

echo "Creating network namespace 'container' from $1"
echo "ipv4 address: $wg_ipv4"
echo "ipv6 address: $wg_ipv6"

sudo ip netns add container

sudo ip link add wg0 type wireguard
sudo ip link set wg0 netns container

sudo ip -n container addr add $wg_ipv4 dev wg0
sudo ip -n container addr add $wg_ipv6 dev wg0

sudo ip netns exec container wg setconf wg0 ./$1

sudo ip -n container link set wg0 up
sudo ip -n container route add default dev wg0
