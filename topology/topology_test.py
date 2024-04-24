
from mininet.topo import Topo
from mininet.net import Mininet
from mininet.node import Switch
from mininet.cli import CLI
from mininet.node import RemoteController
from mininet.node import OVSSwitch
from topology import *
import testing
import time


topos = {'mytopo': (lambda: MyTopo())}


def run_tests(net):
    # You can automate some tests here

    # TODO: How to get the hosts from the net??
    h1 = net.get('h1')
    h2 = net.get('h2')
    h3 = net.get('h3')
    h4 = net.get('h4')
    
    ws1 = net.get('ws1')
    ws2 = net.get('ws2')
    ws3 = net.get('ws3')

    time.sleep(1)

    # Launch ping tests
    testing.ping(h1, h2, True)
    
    testing.ping(h3, h4, True)

    testing.ping(h3, h1, True)

    testing.ping(h1, h3, False)

    testing.ping(h3, h2, True)

    testing.ping(h2, h3, False)

    testing.ping(h1, ws1, False)

    testing.ping(h3, ws1, False)

    # curl
    testing.curl(h1, ws1, expected=True)

    testing.curl(h3, ws1, expected=True)
    
    testing.curl(h1, ws2, expected=True)

    testing.curl(h3, ws2, expected=True)
    
    testing.curl(h1, ws3, expected=True)

    testing.curl(h3, ws3, expected=True)


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

    # Start the network
    net.start()

    startup_services(net)
    run_tests(net)

    # Start the CLI
    CLI(net)

    # You may need some commands before stopping the network! If you don't, leave it empty
    ### COMPLETE THIS PART ###
    for link in net.links:
        net.delLink(link)

    net.stop()
