// Element Definitions

elementclass IPChecksumFixer { $print |
    input ->
    SetIPChecksum ->
    class::IPClassifier(tcp, udp, -)

    class[0] -> Print(TCP, ACTIVE $print) -> SetTCPChecksum -> output
    class[1] -> Print(UDP, ACTIVE $print) -> SetUDPChecksum -> output
    class[2] -> Print(OTH, ACTIVE $print) -> output
}

elementclass FixedForwarder {
    input ->
    Print(BEFORESTRIP, -1) ->
    Strip(14) ->
    Print(BEFORECHECKSUM, -1) ->
    SetIPChecksum ->
    CheckIPHeader ->
    IPChecksumFixer(0) ->
    Unstrip(14) ->
    output
}

// Counters

avgCntToExt, avgCntFromExt, avgCntToInt, avgCntFromInt :: AverageCounter
cntArpReqSrv, cntArpReqExt, cntArpRspSrv, cntArpRspExt :: Counter
cntDropFromExtEth, cntDropFromExtIP, cntDropFromSvrEth, cntDropFromSvrIP :: Counter
cntLbServedFromExt, cntLbServedFromSrv, cntIcmpFromExt, cntIcmpFromInt :: Counter

// Devices

fromExt :: FromDevice(lb-eth2, METHOD LINUX, SNIFFER false)
fromInt :: FromDevice(lb-eth1, METHOD LINUX, SNIFFER false)
toIntDevice :: ToDevice(lb-eth1, METHOD LINUX)
toExtDevice :: ToDevice(lb-eth2, METHOD LINUX)

// Queues

toInt :: Queue -> avgCntToInt -> toIntDevice
toExt :: Queue -> avgCntToExt -> toExtDevice

// Classifiers

ExtClassifier, IntClassifier :: Classifier(
    12/0806 20/0001, // ARP request
    12/0806 20/0002, // ARP response
    12/0800,         // IP
    -                // Others
)

ipPacketClassifierExt :: IPClassifier(
    dst 100.0.0.45 and icmp,        // ICMP
    dst 100.0.0.45 port 80 and tcp, // TCP
    -                               // Others
)

ipPacketClassifierInt :: IPClassifier(
    dst 100.0.0.45 and icmp type echo,  // ICMP to lb
    src port 80 and tcp,                // TCP
    -                                   // Others
)

// ARP Queriers and Responders

arpQuerierExt :: ARPQuerier(100.0.0.45, lb-eth2)
arpQuerierInt :: ARPQuerier(100.0.0.45, lb-eth1)
arpRespondExt :: ARPResponder(100.0.0.45 lb-eth2)
arpRespondInt :: ARPResponder(100.0.0.45 lb-eth1)

// IP Packets

ipPacketExt :: GetIPAddress(16) -> Print(TOEXT_GETIPADDRESS16, -1, ACTIVE 1) -> CheckIPHeader -> Print(TOEXT_CHECKHEADER, -1, ACTIVE 1) ->
[0]arpQuerierExt -> Print(ARPQUERIER, -1, ACTIVE 1) -> toExt

ipPacketInt :: GetIPAddress(16) -> Print(TOINT_GETIPADDRESS16, -1, ACTIVE 1) -> CheckIPHeader -> 
[0]arpQuerierInt -> Print(TOINT_AFTERARP, -1, ACTIVE 1) -> toInt

// Round Robin IP Mapper and IP Rewriter

roundRobin :: RoundRobinIPMapper(
    100.0.0.45 - 100.0.0.40 - 0 1,
    100.0.0.45 - 100.0.0.41 - 0 1,
    100.0.0.45 - 100.0.0.42 - 0 1
)

ipRewrite :: IPRewriter(roundRobin)

ipRewrite[0] -> ipPacketInt
ipRewrite[1] -> ipPacketExt

// Packet Routing and Processing

fromExt -> avgCntFromExt -> ExtClassifier

ExtClassifier[0] -> cntArpReqExt -> arpRespondExt -> toExt                // ARP request
ExtClassifier[1] -> cntArpRspExt -> [1]arpQuerierExt                      // ARP response
ExtClassifier[2] -> cntLbServedFromExt -> FixedForwarder -> Strip(14) -> CheckIPHeader -> ipPacketClassifierExt    // IP
ExtClassifier[3] -> cntDropFromExtEth -> Discard                          // Others

// icmp
ipPacketClassifierExt[0] -> cntIcmpFromExt -> Print(CLASSIFIED_Ext_PING, -1) -> ICMPPingResponder -> ipPacketExt

// permited ip packet, lb apply
ipPacketClassifierExt[1] -> [0]ipRewrite
ipPacketClassifierExt[2] -> cntDropFromExtIP -> Discard

fromInt -> avgCntFromInt -> IntClassifier

IntClassifier[0] -> cntArpReqSrv -> arpRespondInt -> toInt                // ARP request
IntClassifier[1] -> cntArpRspSrv -> [1]arpQuerierInt                      // ARP response
IntClassifier[2] -> cntLbServedFromSrv -> FixedForwarder -> Strip(14) -> CheckIPHeader -> ipPacketClassifierInt    // IP
IntClassifier[3] -> cntDropFromSvrEth -> Discard                          // Others

ipPacketClassifierInt[0] -> cntIcmpFromInt -> ICMPPingResponder -> ipPacketInt
ipPacketClassifierInt[1] -> [0]ipRewrite
ipPacketClassifierInt[2] -> cntDropFromSvrIP -> Discard

// Report
DriverManager(wait, print > ./click_results/lb.report "
    =================== LB1 Report ===================
    Input Packet rate (pps): $(add $(avgCntToExt.rate) $(avgCntToInt.rate))
    Output Packet rate (pps): $(add $(avgCntFromExt.rate) $(avgCntFromInt.rate))

        
    Total number of input packets: $(add $(avgCntToExt.count) $(avgCntToInt.count))
    Total number of output packets: $(add $(avgCntFromExt.count) $(avgCntFromInt.count))

    Total number of ARP requests: $(add $(cntArpReqExt.count) $(cntArpReqSrv.count))
    Total number of ARP responses: $(add $(cntArpRspExt.count) $(cntArpRspSrv.count))

    Total number of service packets: $(add $(cntLbServedFromSrv.count) $(cntLbServedFromExt.count))
    Total number of ICMP report: $(add $(cntIcmpFromInt.count) $(cntIcmpFromExt.count))
    Total number of dropped packets: $(add $(cntDropFromSvrEth.count) $(cntDropFromSvrIP.count) $(cntDropFromExtEth.count) $(cntDropFromExtIP.count))
    =================================================
")