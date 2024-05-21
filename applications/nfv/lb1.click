// Counters
clientInputCount, serverInputCount, clientOutputCount, serverOutputCount :: AverageCounter;
arpReqCount, arpReqCount1, arpQueCount, arpQueCount1, ipCount, ipCount1, icmpCount,
icmpCount1, dropCount, dropCount1, dropCount2, dropCount3 :: Counter;

// Devices
fromClient :: FromDevice(lb-eth2, METHOD LINUX, SNIFFER false);
fromServer :: FromDevice(lb-eth1, METHOD LINUX, SNIFFER false);

toServerDevice :: ToDevice(lb-eth1, METHOD LINUX);
toClientDevice :: ToDevice(lb-eth2, METHOD LINUX);

clientClassifier, serverClassifier :: Classifier(
    12/0806 20/0001, //ARP requrest
    12/0806 20/0002, //ARP respond
    12/0800,    //IP
    -           //others
);

ipPacketClassifierClient :: IPClassifier(
    dst 100.0.0.45 and icmp, //ICMP
    dst 100.0.0.45 port 80 and tcp, //tcp
    -   //others
);

ipPacketClassifierServer :: IPClassifier(
    dst 100.0.0.45 and icmp type echo, //ICMP to lb
    src port 80 and tcp, //tcp
    -   //others
);



arpQuerierClient :: ARPQuerier(100.0.0.45, lb-eth2);
arpQuerierServer :: ARPQuerier(100.0.0.45, lb-eth1);
arpRespondClient :: ARPResponder(100.0.0.45 lb-eth2);
arpRespondServer :: ARPResponder(100.0.0.45 lb-eth1);

toClient :: Queue -> clientOutputCount -> toClientDevice;
toServer :: Queue -> serverOutputCount -> toServerDevice;

ipPacketClient :: GetIPAddress(16) -> CheckIPHeader -> [0]arpQuerierClient -> toClient;
ipPacketServer :: GetIPAddress(16) -> CheckIPHeader -> [0]arpQuerierServer -> toServer;

roundRobin :: RoundRobinIPMapper(
    100.0.0.45 - 100.0.0.40 - 0 1,
    100.0.0.45 - 100.0.0.41 - 0 1,
    100.0.0.45 - 100.0.0.42 - 0 1
);

ipRewrite :: IPRewriter (roundRobin);

ipRewrite[0] -> ipPacketServer;
ipRewrite[1] -> ipPacketClient;

// Packet Routing and Processing
fromClient -> clientInputCount -> clientClassifier;

clientClassifier[0] -> arpReqCount -> arpRespondClient -> toClient;
clientClassifier[1] -> arpQueCount -> [1]arpQuerierClient;
clientClassifier[2] -> ipCount -> Strip(14) -> CheckIPHeader -> ipPacketClassifierClient;
clientClassifier[3] -> dropCount1 -> Discard;

ipPacketClassifierClient[0] -> icmpCount -> ICMPPingResponder -> ipPacketClient;
ipPacketClassifierClient[1] -> [0]ipRewrite;
ipPacketClassifierClient[2] -> dropCount -> Discard;

//from server
fromServer -> serverInputCount -> serverClassifier;

serverClassifier[0] -> arpReqCount1 -> arpRespondServer -> toServer;
serverClassifier[1] -> arpQueCount1 -> [1]arpQuerierServer;
serverClassifier[2] -> ipCount1 -> Strip(14) -> CheckIPHeader -> ipPacketClassifierServer;
serverClassifier[3] -> dropCount2 -> Discard;

ipPacketClassifierServer[0] -> icmpCount1 -> ICMPPingResponder -> ipPacketServer;
ipPacketClassifierServer[1] -> [0]ipRewrite;
ipPacketClassifierServer[2] -> dropCount3 -> Discard;

//Report
DriverManager(wait, print > ./click_results/lb.report "
    ==============lb.report===============
    Input Packet Rate (pps):  $(add $(clientInputCount.rate) $(serverInputCount.rate))
    Output Packet Rate (pps):  $(add $(clientOutputCount.rate) $(serverOutputCount.rate))

    Total # of input packet:  $(add $(clientInputCount.count) $(serverInputCount.count))
    Total # of output packet:  $(add $(clientOutputCount.count) $(serverOutputCount.count))

    Total # of ARP requests:  $(add $(arpReqCount.count) $(arpReqCount1.count))
    Total # of ARP responses:  $(add $(arpQueCount.count) $(arpQueCount1.count))

    Total # of service packets:  $(add $(ipCount.count) $(ipCount1.count))
    Total # of ICMP packets:  $(add $(icmpCount.count) $(icmpCount.count))
    Total # of dropped packets:  $(add $(dropCount.count) $(dropCount1.count) $(dropCount2.count) $(dropCount3.count))
    ======================================",
stop);