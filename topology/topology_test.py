
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
    
    total_tests = pass_tests = 0

    # Launch ping tests
    # total_tests += 1; pass_tests += testing.ping(h1, h2, True)
    
    # total_tests += 1; pass_tests += testing.ping(h2, h1, True)
    
    # total_tests += 1; pass_tests += testing.ping(h3, h4, True)
    
    # total_tests += 1; pass_tests += testing.ping(h4, h3, True)

    total_tests += 1; pass_tests += testing.ping(h3, h1, True)

    total_tests += 1; pass_tests += testing.ping(h1, h3, False)

    # total_tests += 1; pass_tests += testing.ping(h3, h2, True)

    # total_tests += 1; pass_tests += testing.ping(h2, h3, False)
    
    # total_tests += 1; pass_tests += testing.ping(h4, h1, True)

    # total_tests += 1; pass_tests += testing.ping(h1, h4, False)

    # total_tests += 1; pass_tests += testing.ping(h4, h2, True)

    # total_tests += 1; pass_tests += testing.ping(h2, h4, False)

    # total_tests += 1; pass_tests += testing.ping(h1, ws1, False)
    
    # total_tests += 1; pass_tests += testing.ping(h2, ws1, False)

    # total_tests += 1; pass_tests += testing.ping(h3, ws1, False)
    
    # total_tests += 1; pass_tests += testing.ping(h4, ws1, False)
    
    # curl
    # total_tests += 1; pass_tests += testing.curl(h1, ws1, expected=True)

    # total_tests += 1; pass_tests += testing.curl(h3, ws1, expected=True)
    
    # total_tests += 1; pass_tests += testing.curl(h1, ws2, expected=True)

    # total_tests += 1; pass_tests += testing.curl(h3, ws2, expected=True)
    
    # total_tests += 1; pass_tests += testing.curl(h1, ws3, expected=True)

    # total_tests += 1; pass_tests += testing.curl(h3, ws3, expected=True)
    
    print(f"Passed {pass_tests}/{total_tests} tests.")


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
