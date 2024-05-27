  // Counters

  clientInputCount, serverInputCount, clientOutputCount, serverOutputCount :: AverageCounter
  ArpReqSrvCounter, ArpReqExtCounter, ArpRspSrvCounter, ArpRspExtCounter :: Counter
  dropcountFromExtEth, dropcountFromExtIP, dropcountFromSvrEth, dropcountFromSvrIP :: Counter
  Lb1servedFromExtcounter, Lb1servedFromSrvcounter, IcmpFromExtcounter, IcmpFromIntcounter :: Counter

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
						12/0806 20/0001,  // ARP request
						12/0806 20/0002,  // ARP response
						12/0800,          // IP
						   -);                // Others
						
  ipPacketClassifierClient :: IPClassifier(
					   dst 100.0.0.45 and icmp,             // ICMP
					   dst 100.0.0.45 port 80 and tcp,      // TCP
					   -);                                  // Others
					   
  ipPacketClassifierServer :: IPClassifier(
					   dst 100.0.0.45 and icmp type echo,   // ICMP to lb
					   src port 80 and tcp,                 // TCP
					   -);                                   // Others

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
				   100.0.0.45 - 100.0.0.42 - 0 1);

  ipRewrite :: IPRewriter(roundRobin)

  ipRewrite[0] -> ipPacketServer
  ipRewrite[1] -> ipPacketClient

  // Packet Routing and Processing
 fromClient -> clientInputCount -> ClientClassifier

 ClientClassifier[0] -> ArpReqExtCounter -> arpRespondClient -> toClient                // ARP request
 ClientClassifier[1] -> ArpRspExtCounter -> [1]arpQuerierClient                      // ARP response
 ClientClassifier[2] -> Lb1servedFromExtcounter -> Strip(14) -> CheckIPHeader -> ipPacketClassifierClient    // IP
 ClientClassifier[3] -> dropcountFromExtEth -> Discard                          // Others

 // icmp
 ipPacketClassifierClient[0] -> IcmpFromExtcounter -> ICMPPingResponder -> ipPacketClient

 // permited ip packet, lb apply
 ipPacketClassifierClient[1] -> [0]ipRewrite
 ipPacketClassifierClient[2] -> dropcountFromExtIP -> Discard

 fromServer -> serverInputCount -> ServerClassifier

 ServerClassifier[0] -> ArpReqSrvCounter -> arpRespondServer -> toServer                // ARP request
 ServerClassifier[1] -> ArpRspSrvCounter -> [1]arpQuerierServer                      // ARP response
 ServerClassifier[2] -> Lb1servedFromSrvcounter -> Strip(14) -> CheckIPHeader -> ipPacketClassifierServer    // IP
 ServerClassifier[3] -> dropcountFromSvrEth -> Discard                          // Others

 ipPacketClassifierServer[0] -> IcmpFromIntcounter -> ICMPPingResponder -> ipPacketServer
 ipPacketClassifierServer[1] -> [0]ipRewrite
 ipPacketClassifierServer[2] -> dropcountFromSvrIP -> Discard



  // Report
  DriverManager(wait, print > /home/ik2220/version1/click_results/lb.report "
		=================== LB1 Report ===================
		Input Packet rate (pps): $(add $(clientInputCount.rate) $(serverInputCount.rate))
		Output Packet rate (pps): $(add $(clientOutputCount.rate) $(serverOutputCount.rate))

       
		Total number of input packets: $(add $(clientInputCount.count) $(serverInputCount.count))
		Total number of output packets: $(add $(clientOutputCount.count) $(serverOutputCount.count))

		Total number of ARP requests: $(add $(ArpReqExtCounter.count) $(ArpReqSrvCounter.count))
		Total number of ARP responses: $(add $(ArpRspExtCounter.count) $(ArpRspSrvCounter.count))

		Total number of service packets: $(add $(Lb1servedFromSrvcounter.count) $(Lb1servedFromExtcounter.count))
		Total number of ICMP report: $(add $(IcmpFromIntcounter.count) $(IcmpFromExtcounter.count))
		Total number of dropped packets: $(add $(dropcountFromSvrEth.count) $(dropcountFromSvrIP.count) $(dropcountFromExtEth.count) $(dropcountFromExtIP.count))

		=================================================
		"
		)