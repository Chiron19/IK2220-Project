import topology
from time import sleep

def ping(client, server, expected, count=1, wait=1):
    cmd = f"ping {server.IP()} -c {count} -W {wait} >/dev/null 2>&1; echo $?"
    sleep(1)
    ret = client.cmd(cmd)

    if (int(ret) == 0 and expected) or (int(ret) != 0 and expected == False):
        print(client.name, "ping", server.name, f"working as expected, ping {str(expected)}")
    else:
        print(client.name, "ping", server.name, "NOT WORKING AS EXPECTED")

def ping_virtual(client, expected, count=5, wait=1):
    cmd = f"ping 100.0.0.45 -c {count} -W {wait} >/dev/null 2>&1; echo $?"
    sleep(1)
    ret = client.cmd(cmd)

    if (int(ret) == 0 and expected) or (int(ret) != 0 and expected == False):
        print(client.name, "ping", f"working as expected, ping {str(expected)}")
    else:
        print(client.name, "ping", "NOT WORKING AS EXPECTED")

def curl(client, server, method="POST", payload="Group2", port=80, expected=True):
    """
    run curl for HTTP request. Request method and payload should be specified
    Server can either be a host or a string
    return True in case of success, False if not
    """

    if isinstance(server, str) == 0:
        server_ip = str(server.IP())
    else:
        server_ip = server

    cmd = f"curl --connect-timeout 3 --max-time 3 -X {method} -d '{payload}' -v -s {server_ip}:{port}/cgi-bin/index.cgi > /dev/null 2>&1; echo $? "
    ret = client.cmd(cmd).strip()

    if ret == "0" and expected == True:
        print(client.name, "http request", server.name, "successfully")
        return True
    else:
        print(client.name, "http request", server.name, "failed")
        return False

def http_test(client, method, method2, expected):
    cmd = f"curl --connect-timeout 3 --max-time 3 -X {method} -s 100.0.0.45{method2} > /dev/null 2>&1; echo $? "
    ret = client.cmd(cmd).strip()

    if ret == "0" and expected == True or (int(ret) != 0 and expected == False):
        print(client.name, "operates", method, "IDS System works", "correctly")
        return True
    else:
        print(client.name, "operates", method, "Error!!!")
        return False

def http_test_input(client, payload, expected):
    cmd = f"curl --connect-timeout 3 --max-time 3 -X PUT -d '{payload}' -s 100.0.0.45/put > /dev/null 2>&1; echo $? "
    ret = client.cmd(cmd).strip()

    if (int(ret) != 0 and expected == False):
        print(client.name, "IDS System works", "correctly")
        return True
    else:
        print(client.name, "http request", "failed")
        return False
