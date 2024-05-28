
from mininet.topo import Topo
from mininet.net import Mininet
from mininet.node import Switch
from mininet.cli import CLI
from mininet.node import RemoteController
from mininet.node import OVSSwitch
from topology import *
import testing
import time
import sys
sys.path.insert(0, '.')
from applications.sdn import click_wrapper


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
    
    insp = net.get('insp')
    lb1 = net.get('lb')
    ids = net.get('ids')
    napt = net.get('napt')

    time.sleep(1)
    
    total_tests = pass_tests = 0

    # Launch ping tests
    # phase 1
    # total_tests += 1; pass_tests += testing.ping(h1, h2, True)
    
    # total_tests += 1; pass_tests += testing.ping(h2, h1, True)
    
    # total_tests += 1; pass_tests += testing.ping(h3, h4, True)
    
    # total_tests += 1; pass_tests += testing.ping(h4, h3, True)

    # total_tests += 1; pass_tests += testing.ping(h3, h1, True)

    # total_tests += 1; pass_tests += testing.ping(h1, h3, False)

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
    
    # phase 2
    print("----------- Basic Ping Test-----------")   
    total_tests += 1; pass_tests += testing.ping(h1, h2, True)
    total_tests += 1; pass_tests += testing.ping(h3, h4, True)
    total_tests += 1; pass_tests += testing.ping(h3, h1, True)
    total_tests += 1; pass_tests += testing.ping(h1, h3, False)
    total_tests += 1; pass_tests += testing.ping(h3, h2, True)
    total_tests += 1; pass_tests += testing.ping(h2, h3, False)
    total_tests += 1; pass_tests += testing.ping(h1, ws1, False)
    total_tests += 1; pass_tests += testing.ping(h3, ws1, False)

    print("----------- Virtual Address Ping Test-----------")
    total_tests += 1; pass_tests += testing.ping_virtual(h1, True)
    total_tests += 1; pass_tests += testing.ping_virtual(h2, True)
    total_tests += 1; pass_tests += testing.ping_virtual(h3, True)
    total_tests += 1; pass_tests += testing.ping_virtual(h4, True)

    print("----------- HTTP method Test-----------")
    # h1 curl -X PUT 100.0.0.45/put
    total_tests += 1; pass_tests += testing.http_test(h1, "GET", "/get", "", False)
    total_tests += 1; pass_tests += testing.http_test(h1, "POST", "/post", "", True)
    total_tests += 1; pass_tests += testing.http_test(h1, "PUT", "/put", "", True)

    print("----------- Linux and SQL code injection Test-----------")
    # h1 curl -X PUT -d 'cat /etc/passwd' -s 100.0.0.45/put
    total_tests += 1; pass_tests += testing.http_test(h1, "PUT", "/put", "cat /etc/passwd ", False)
    total_tests += 1; pass_tests += testing.http_test(h1, "PUT", "/put", "cat /var/log/ ", False)
    total_tests += 1; pass_tests += testing.http_test(h1, "PUT", "/put", "INSERT", False)
    total_tests += 1; pass_tests += testing.http_test(h1, "PUT", "/put", "UPDATE", False)
    total_tests += 1; pass_tests += testing.http_test(h1, "PUT", "/put", "DELETE", False)
    
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
    startup_services(net)
    
    net.get("h3").cmd("ip route add default via 10.0.0.1")
    net.get("h4").cmd("ip route add default via 10.0.0.1")
    net.start()

    run_tests(net)

    # Start the CLI
    CLI(net)

    # You may need some commands before stopping the network! If you don't, leave it empty
    ### COMPLETE THIS PART ###
    for link in net.links:
        net.delLink(link)
        
    click_wrapper.killall_click()

    net.stop()
