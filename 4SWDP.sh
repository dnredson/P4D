#!/bin/bash
docker run -itd --name h1  --network="none" --privileged -v shared:/codes --workdir /codes dnredson/net
docker run -itd --name h2   --network="none" --privileged -v shared:/codes  --workdir /codes dnredson/net
docker run -itd --name sw1  --network="none" --privileged -v shared:/codes  --workdir /codes dnredson/p4d
docker run -itd --name sw2  --network="none" --privileged -v shared:/codes  --workdir /codes dnredson/p4d
docker run -itd --name sw3  --network="none" --privileged -v shared:/codes  --workdir /codes dnredson/p4d
docker run -itd --name sw4  --network="none" --privileged -v shared:/codes  --workdir /codes dnredson/p4d

sudo ip link add veth1 type veth peer name veth2
sudo ip link add veth3 type veth peer name veth4
sudo ip link add veth5 type veth peer name veth6
sudo ip link add veth7 type veth peer name veth8
sudo ip link add veth9 type veth peer name veth10

PIDSW1=$(docker inspect -f '{{.State.Pid}}' sw1)
PIDSW2=$(docker inspect -f '{{.State.Pid}}' sw2)
PIDSW3=$(docker inspect -f '{{.State.Pid}}' sw3)
PIDSW4=$(docker inspect -f '{{.State.Pid}}' sw4)
PIDH1=$(docker inspect -f '{{.State.Pid}}' h1)
PIDH2=$(docker inspect -f '{{.State.Pid}}' h2)


sudo ip link set veth1 netns $PIDSW1
sudo ip link set veth2 netns $PIDH1
sudo ip link set veth3 netns $PIDSW1
sudo ip link set veth4 netns $PIDSW2
sudo ip link set veth5 netns $PIDSW2
sudo ip link set veth6 netns $PIDSW3
sudo ip link set veth7 netns $PIDSW3
sudo ip link set veth8 netns $PIDSW4
sudo ip link set veth9 netns $PIDSW4
sudo ip link set veth10 netns $PIDH2

#Host 1
sudo nsenter -t $PIDH1 -n ip addr add 10.0.1.2/24 dev veth2
sudo nsenter -t $PIDH1 -n ip link set dev veth2 address 00:00:00:00:01:02
sudo nsenter -t $PIDH1 -n ip link set veth2 up

#SWITCH 1
#Port 1
sudo nsenter -t $PIDSW1 -n ip addr add 10.0.1.1/24 dev veth1
sudo nsenter -t $PIDSW1 -n ip link set dev veth1 address 00:00:00:00:01:01
sudo nsenter -t $PIDSW1 -n ip link set veth1 up
#Port 2
sudo nsenter -t $PIDSW1 -n ip addr add 10.0.2.1/24 dev veth3
sudo nsenter -t $PIDSW1 -n ip link set dev veth3 address 00:00:00:00:02:01
sudo nsenter -t $PIDSW1 -n ip link set veth3 up

#SWITCH 2
#Port 1
sudo nsenter -t $PIDSW2 -n ip addr add 10.0.2.2/24 dev veth4
sudo nsenter -t $PIDSW2 -n ip link set dev veth4 address 00:00:00:00:02:02
sudo nsenter -t $PIDSW2 -n ip link set veth4 up
#Port 2
sudo nsenter -t $PIDSW2 -n ip addr add 10.0.3.1/24 dev veth5
sudo nsenter -t $PIDSW2 -n ip link set dev veth5 address 00:00:00:00:03:01
sudo nsenter -t $PIDSW2 -n ip link set veth5 up

#SWITCH 3
#Port 1
sudo nsenter -t $PIDSW3 -n ip addr add 10.0.3.2/24 dev veth6
sudo nsenter -t $PIDSW3 -n ip link set dev veth6 address 00:00:00:00:03:02
sudo nsenter -t $PIDSW3 -n ip link set veth6 up
#Port 2
sudo nsenter -t $PIDSW3 -n ip addr add 10.0.4.1/24 dev veth7
sudo nsenter -t $PIDSW3 -n ip link set dev veth7 address 00:00:00:00:04:01
sudo nsenter -t $PIDSW3 -n ip link set veth7 up

#SWITCH 4
#Port 1
sudo nsenter -t $PIDSW4 -n ip addr add 10.0.4.2/24 dev veth8
sudo nsenter -t $PIDSW4 -n ip link set dev veth8 address 00:00:00:00:04:02
sudo nsenter -t $PIDSW4 -n ip link set veth8 up
#Port 2
sudo nsenter -t $PIDSW4 -n ip addr add 10.0.5.1/24 dev veth9
sudo nsenter -t $PIDSW4 -n ip link set dev veth9 address 00:00:00:00:05:01
sudo nsenter -t $PIDSW4 -n ip link set veth9 up

#Host 2
sudo nsenter -t $PIDH2 -n ip addr add 10.0.5.2/24 dev veth10
sudo nsenter -t $PIDH2 -n ip link set dev veth10 address 00:00:00:00:05:02
sudo nsenter -t $PIDH2 -n ip link set veth10 up


docker exec sw1 ip link set veth1 promisc on
docker exec sw1 ip link set veth3 promisc on
docker exec sw2 ip link set veth4 promisc on
docker exec sw2 ip link set veth5 promisc on
docker exec sw3 ip link set veth6 promisc on
docker exec sw3 ip link set veth7 promisc on
docker exec sw4 ip link set veth8 promisc on
docker exec sw4 ip link set veth9 promisc on


docker exec h1 ip link set veth2 promisc on
docker exec h2 ip link set veth10 promisc on
docker exec h1 ethtool -K veth2 tx off tx off
docker exec h2 ethtool -K veth10 tx off tx off
docker exec sw1 sh -c 'echo 0 >> /proc/sys/net/ipv4/ip_forward'
docker exec sw2 sh -c 'echo 0 >> /proc/sys/net/ipv4/ip_forward'
docker exec sw3 sh -c 'echo 0 >> /proc/sys/net/ipv4/ip_forward'
docker exec sw4 sh -c 'echo 0 >> /proc/sys/net/ipv4/ip_forward'
echo "Iniciar configuração de rotas"
echo "Rotas estáticas"
#Configurar as rotas no switch para utilizarem o switch na mesma rede como gateway
docker exec h1 route add -net 10.0.5.2 netmask 255.255.255.255 gw 10.0.1.1
docker exec h2 route add -net 10.0.1.2 netmask 255.255.255.255 gw 10.0.5.1

docker exec h1 sh -c 'arp -i veth2 -s 10.0.5.2 00:00:00:00:05:02'
docker exec h1 sh -c 'arp -i veth2 -s 10.0.5.1 00:00:00:00:05:01'
docker exec h1 sh -c 'arp -i veth2 -s 10.0.1.1 00:00:00:00:01:01'

docker exec h2 sh -c 'arp -i veth10 -s 10.0.1.2 00:00:00:00:01:02'
docker exec h2 sh -c 'arp -i veth10 -s 10.0.1.1 00:00:00:00:01:01'
docker exec h2 sh -c 'arp -i veth10 -s 10.0.5.1 00:00:00:00:05:01'

docker exec sw1 sh -c 'arp -i veth3 -s 10.0.5.2 00:00:00:00:05:02'
docker exec sw1 sh -c 'arp -i veth1 -s 10.0.1.2 00:00:00:00:01:02'

docker exec sw2 sh -c 'arp -i veth4 -s 10.0.1.2 00:00:00:00:01:02'
docker exec sw2 sh -c 'arp -i veth5 -s 10.0.5.2 00:00:00:00:05:02'

docker exec sw3 sh -c 'arp -i veth6 -s 10.0.1.2 00:00:00:00:01:02'
docker exec sw3 sh -c 'arp -i veth7 -s 10.0.5.2 00:00:00:00:05:02'

docker exec sw4 sh -c 'arp -i veth8 -s 10.0.1.2 00:00:00:00:01:02'
docker exec sw4 sh -c 'arp -i veth9 -s 10.0.5.2 00:00:00:00:05:02'

#Inicia o BMV2
docker exec sw1 sh -c 'nohup simple_switch  --thrift-port 50001 -i 1@veth1 -i 2@veth3  4SWDP.json &'
docker exec sw2 sh -c 'nohup simple_switch  --thrift-port 50002 -i 1@veth4 -i 2@veth5  4SWDP.json &'
docker exec sw3 sh -c 'nohup simple_switch  --thrift-port 50003 -i 1@veth6 -i 2@veth7  4SWDP.json &'
docker exec sw4 sh -c 'nohup simple_switch  --thrift-port 50004 -i 1@veth8 -i 2@veth9  4SWDP.json &'



#table_add ipv4_lpm ipv4_forward 10.0.1.2/32 => 00:00:00:00:01:02 1
#table_add ipv4_lpm ipv4_forward 10.0.2.2/32 => 00:00:00:00:02:02 2
