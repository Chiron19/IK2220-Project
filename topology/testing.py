import topology


def ping(client, server, expected, count=5, wait=3):

    # TODO: What if ping fails? How long does it take? Add a timeout to the command!
    cmd = f"ping {server.IP()} -c {count} -W {wait} >/dev/null 2>&1; echo $?"
    # print(f"Initiating ping test from client {client} to server {server}. Expected success: {expected}") 
    ret = client.cmd(cmd)
    # print(f"ret:{ret}cmd:{cmd} ")
    
    # TODO: Here you should compare the return value "ret" with the expected value
    # (consider both failures
    
    # 逻辑调整：基于 'expect_success' 的布尔值预期和实际的返回码判断
    # True means "everyhing went as expected"

    if (int(ret) == 0 and expected) or (int(ret) !=0 and expected == False):
        print(client.name,"ping",server.name,f"working as expected, ping {str(expected)}")
        return True
        # pass
    else:
        print(f"`{cmd}` on {client} returned {ret} int(ret)= {int(ret)}")
        print(client.name,"ping",server.name,"NOT WORKING AS EXPECTED")
        return False
    # return True 

def curl(client, server, method="GET", payload="", port=80, expected=True):
        """
        run curl for HTTP request. Request method and payload should be specified
        Server can either be a host or a string
        return True in case of success, False if not
        """

        if (isinstance(server, str) == 0):
            server_ip = str(server.IP())
        else:
            # If it's a string it should be the IP address of the node (e.g., the load balancer)
            server_ip = server

        # TODO: Specify HTTP method
        # TODO: Pass some payload (a.k.a. data). You may have to add some escaped quotes!
        # The magic string at the end reditect everything to the black hole and just print the return code
        # cmd = f"curl --connect-timeout 3 --max-time 3 -s {server}:{port} > /dev/null 2>&1; echo $?"
        cmd = f"curl --connect-timeout 3 --max-time 3 -v -s  {server.IP()}:{port} > /dev/null 2>&1; echo $?"
        ret = client.cmd(cmd).strip()
        # print(f"`{cmd}` on {client} returned {ret}")

        # TODO: What value do you expect?
        # True means "everyhing went as expected"
        if ret == "0" and expected == True:
            print(client.name, "http request", server.name, "successfully")
            return True

        else:
            print(client.name, "http request", server.name, "failed")
            return False
        # return True  
