define($PORT1 lb-eth1, $PORT2 lb-eth2)

Script(print "Click LB on $PORT1 $PORT2")
Script(print "Test LB if running?????")

// Element Definitions

elementclass IPChecksumFixer { $print |
    input ->
    SetIPChecksum ->
    class::IPClassifier(tcp, -)

    class[0] -> Print(TCP, ACTIVE $print) -> SetTCPChecksum -> output
    class[1] -> Print(OTH, ACTIVE $print) -> output
}

elementclass FixedForwarder {
    input ->
    Strip(14) ->
    SetIPChecksum ->
    CheckIPHeader ->
    IPChecksumFixer(0) ->
    Unstrip(14) ->
    output
}

// Counters

clientInputCount, serverInputCount, clientOutputCount, serverOutputCount :: AverageCounter
ArpReqSrvCount, ArpReqExtCount, ArpRspSrvCount, ArpRspExtCount :: Counter
dropFromExtEthCount, dropFromExtIPCount, dropFromSvrEthCount, dropFromSvrIPCount :: Counter
Lb1servedFromExtCount, Lb1servedFromSrvCount, IcmpFromExtCount, IcmpFromIntCount :: Counter


// Devices

fromClient :: FromDevice(lb-eth2, METHOD LINUX, SNIFFER false)
fromServer :: FromDevice(lb-eth1, METHOD LINUX, SNIFFER false)
toServerDevice :: ToDevice(lb-eth1, METHOD LINUX)
toClientDevice :: ToDevice(lb-eth2, METHOD LINUX)

// Queues

toServer :: Queue -> serverOutputCount -> toServerDevice
toClient :: Queue -> clientOutputCount -> toClientDevice

// Classifiers

ClientClassifier, ServerClassifier :: Classifier(
    12/0806 20/0001,    // ARP request
    12/0806 20/0002,    // ARP response
    12/0800,            // IP
    -                   // Others
);

ipPacketClassifierClient :: IPClassifier(
    dst 100.0.0.45 and icmp,        // ICMP
    dst 100.0.0.45 port 80 and tcp, // TCP
    -                               // Others
);

ipPacketClassifierServer :: IPClassifier(
    dst 100.0.0.45 and icmp type echo,  // ICMP to lb
    src port 80 and tcp,                // TCP
    -                                   // Others
);                                   


// ARP Queriers and Responders

arpQuerierClient :: ARPQuerier(100.0.0.45, lb-eth2)
arpQuerierServer :: ARPQuerier(100.0.0.45, lb-eth1)
arpRespondClient :: ARPResponder(100.0.0.45 lb-eth2)
arpRespondServer :: ARPResponder(100.0.0.45 lb-eth1)

// IP Packets

ipPacketClient :: GetIPAddress(16) -> CheckIPHeader -> [0]arpQuerierClient -> toClient
ipPacketServer :: GetIPAddress(16) -> CheckIPHeader -> [0]arpQuerierServer -> toServer

// Round Robin IP Mapper and IP Rewriter

roundRobin :: RoundRobinIPMapper(
    100.0.0.45 - 100.0.0.40 - 0 1,
    100.0.0.45 - 100.0.0.41 - 0 1,
    100.0.0.45 - 100.0.0.42 - 0 1
);

ipRewrite :: IPRewriter(roundRobin)

ipRewrite[0] -> ipPacketServer
ipRewrite[1] -> ipPacketClient

// Packet Routing and Processing

fromClient -> clientInputCount -> ClientClassifier

ClientClassifier[0] -> ArpReqExtCount -> arpRespondClient -> toClient     // ARP request
ClientClassifier[1] -> ArpRspExtCount -> [1]arpQuerierClient              // ARP response
ClientClassifier[2] -> Lb1servedFromExtCount -> FixedForwarder -> Strip(14) -> CheckIPHeader -> ipPacketClassifierClient  // IP
ClientClassifier[3] -> dropFromExtEthCount -> Discard                       // Others

// icmp
ipPacketClassifierClient[0] -> IcmpFromExtCount -> ICMPPingResponder -> ipPacketClient

// permited ip packet, lb apply
ipPacketClassifierClient[1] -> [0]ipRewrite
ipPacketClassifierClient[2] -> dropFromExtIPCount -> Discard

fromServer -> serverInputCount -> ServerClassifier

ServerClassifier[0] -> ArpReqSrvCount -> arpRespondServer -> toServer         // ARP request
ServerClassifier[1] -> ArpRspSrvCount -> [1]arpQuerierServer                  // ARP response
ServerClassifier[2] -> Lb1servedFromSrvCount -> FixedForwarder -> Strip(14) -> CheckIPHeader -> ipPacketClassifierServer  // IP
ServerClassifier[3] -> dropFromSvrEthCount -> Discard                           // Others

ipPacketClassifierServer[0] -> IcmpFromIntCount -> ICMPPingResponder -> ipPacketServer
ipPacketClassifierServer[1] -> [0]ipRewrite
ipPacketClassifierServer[2] -> dropFromSvrIPCount -> Discard

// Report
DriverManager(wait, print > ./results/lb.report "
=================== LB1 Report ===================
Input Packet Rate (pps):    $(add $(clientInputCount.rate) $(serverInputCount.rate))
Output Packet Rate (pps):   $(add $(clientOutputCount.rate) $(serverOutputCount.rate))

Total # of  input packets:  $(add $(clientInputCount.count) $(serverInputCount.count))
Total # of  output packets: $(add $(clientOutputCount.count) $(serverOutputCount.count))

Total # of  ARP requests:   $(add $(ArpReqExtCount.count) $(ArpReqSrvCount.count))
Total # of  ARP responses:  $(add $(ArpRspExtCount.count) $(ArpRspSrvCount.count))

Total # of  service packets:    $(add $(Lb1servedFromSrvCount.count) $(Lb1servedFromExtCount.count))
Total # of  ICMP packets:       $(add $(IcmpFromIntCount.count) $(IcmpFromExtCount.count))
Total # of  dropped packets:    $(add $(dropFromSvrEthCount.count) $(dropFromSvrIPCount.count) $(dropFromExtEthCount.count) $(dropFromExtIPCount.count))
=================================================
")