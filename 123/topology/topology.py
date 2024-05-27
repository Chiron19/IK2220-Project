from mininet.topo import Topo
from mininet.net import Mininet
from mininet.node import Switch
from mininet.cli import CLI
from mininet.node import RemoteController
from mininet.node import OVSSwitch


class MyTopo(Topo):
    def __init__(self):
        # Initialize topology
        Topo.__init__(self)

        # Here you initialize hosts, web servers and switches
        # (There are sample host, switch and link initialization,  you can rewrite it in a way you prefer)
        ### COMPLETE THIS PART ###

        # Initialize hosts
        h1 = self.addHost('h1', ip='100.0.0.10/24')

        h2 = self.addHost('h2', ip='100.0.0.11/24')

        # h3 = self.addHost('h3', ip='100.0.0.50/24')
        
        h3 = self.addHost('h3', ip='10.0.0.50/24')

        h4 = self.addHost('h4', ip='10.0.0.51/24')

        ws1 = self.addHost('ws1', ip='100.0.0.40/24')

        ws2 = self.addHost('ws2', ip='100.0.0.41/24')

        ws3 = self.addHost('ws3', ip='100.0.0.42/24')

        insp = self.addHost('insp', ip='100.0.0.30/24')

        # Initial switches
        sw1 = self.addSwitch('sw1', dpid="1")

        sw2 = self.addSwitch('sw2', dpid="2")

        sw3 = self.addSwitch('sw3', dpid="3")

        sw4 = self.addSwitch('sw4', dpid="4")

        fw1 = self.addSwitch('fw1', dpid="5")

        fw2 = self.addSwitch('fw2', dpid="6")

        lb = self.addSwitch('lb', dpid="7")

        ids = self.addSwitch('ids', dpid="8") 

        napt = self.addSwitch('napt', dpid="9")

        # Defining links
        self.addLink(h1, sw1)

        self.addLink(h2, sw1)

        self.addLink(fw1, sw1)

        self.addLink(fw1, sw2)

        self.addLink(fw2, sw2)

        self.addLink(sw4, lb, port2 = 1)

        self.addLink(lb, ids, port1 = 2)

        self.addLink(ids, sw2)

        self.addLink(ids, insp)

        self.addLink(h3, sw3)

        self.addLink(h4, sw3)

        self.addLink(fw2, napt, port2 = 1)

        self.addLink(napt, sw3, port1 = 2)

        self.addLink(ws1, sw4)

        self.addLink(ws2, sw4)

        self.addLink(ws3, sw4)


def startup_services(net):
    # Start http services and executing commands you require on each host...
    ### COMPLETE THIS PART ###
    # for ser in ["ws1", "ws2", "ws3"]:
        
         # net.get(ser).cmd("python3 -m http.server 80 &")
         # print("[{}] Web server start:80".format(ser))

    # pass

    for ser in ["ws1", "ws2", "ws3"]:
        print("[{}] Web server start:80".format(ser))
        net.get(ser).cmd("python3 app.py &")

    for insp in ["insp"]:
        print( "tcpdump on insp start")
        net.get(insp).cmd("tcpdump -i insp-eth0 -w insp.pcap &")



topos = {'mytopo': (lambda: MyTopo())}

if __name__ == "__main__":

    # Create topology
    topo = MyTopo()

    ctrl = RemoteController("c0", ip="127.0.0.1", port=6633)

    # Create the network
    net = Mininet(topo=topo,
                  switch=OVSSwitch,
                  controller=ctrl,
                  autoSetMacs=True,
                  autoStaticArp=True,
                  build=True,
                  cleanup=True)

    startup_services(net)
    # Start the network

    net.get("h3").cmd("ip route add default via 10.0.0.1")
    net.get("h4").cmd("ip route add default via 10.0.0.1")
    net.start()

    # Start the CLI
    CLI(net)

    # You may need some commands before stopping the network! If you don't, leave it empty
    ### COMPLETE THIS PART ###

    # Delete all links
    for link in net.links:
        net.delLink(link)
        
    net.stop()
