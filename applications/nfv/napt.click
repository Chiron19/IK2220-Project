define($PORT1 napt-eth1, $PORT2 napt-eth2)

Script(print "Click NAPT on $PORT1 $PORT2")
Script(print "Test NAPT if running?????")

// Counters
fromPrz, toPrz, fromDmz, toDmz :: AverageCounter;
arpRespondInt, arpRespondExt, arpQueryInt, arpQueryExt,
icmpExt, icmpInt, tcpInt, dropInt, dropExt, icmpEchoDropInt, icmpEchoDropExt,
icmpReplyDropInt, icmpReplyDropExt :: Counter;

// Device Defination
fromInt :: FromDevice(napt-eth2, METHOD LINUX, SNIFFER false);
fromExt :: FromDevice(napt-eth1, METHOD LINUX, SNIFFER false);
toInt :: Queue -> toPrz -> ToDevice(napt-eth2);
toExt :: Queue -> toDmz -> ToDevice(napt-eth1);

arpReplyInt :: ARPResponder(10.0.0.1 napt-eth2);
arpReplyExt :: ARPResponder(100.0.0.1 napt-eth1);

arpRequestInt :: ARPQuerier(10.0.0.1, napt-eth2);
arpRequestExt :: ARPQuerier(100.0.0.1, napt-eth1);
// [0]arpRequestInt for handeling the response   accept IP packets   https://github.com/kohler/click/wiki/ARPQuerier
// [1]arpRequestInt for sending a packet         accept including Eth-header

ipNAT :: IPRewriter(pattern 100.0.0.1 1024-65535 - - 0 1);
icmpNAT :: ICMPPingRewriter(pattern 100.0.0.1 - - - 0 1);

packetClassifierInt, packetClassifierExt :: Classifier(
    12/0806 20/0001,    //ARP request
    12/0806 20/0002,    //ARP respond
    12/0800,            //IP
    -                   //other
)

ipClassifierInt, ipClassifierExt :: IPClassifier(
    tcp,
    icmp type echo,
    icmp type echo-reply,
    -
)


// CheckIPHeader only forward valid packet

fromInt -> fromPrz -> packetClassifierInt; // when packet come in from prz

packetClassifierInt[0] -> arpQueryInt -> arpReplyInt -> toInt; // tell host its mac add
packetClassifierInt[1] -> arpRespondInt -> [1]arpRequestInt; // knowing the mac update arp table
packetClassifierInt[2] -> Strip(14) -> CheckIPHeader -> ipClassifierInt;
packetClassifierInt[3] -> dropInt -> Discard;

ipClassifierInt[0] -> tcpInt -> ipNAT[0] -> [0]arpRequestExt -> toExt;
ipClassifierInt[1] -> icmpInt -> icmpNAT[0] -> [0]arpRequestExt -> toExt;
ipClassifierInt[2] -> icmpEchoDropInt -> Discard;
ipClassifierInt[3] -> icmpReplyDropInt -> Discard;

fromExt -> fromDmz -> packetClassifierExt; // when packet come in from dmz / pbz

packetClassifierExt[0] -> arpQueryExt -> arpReplyExt -> toExt;
packetClassifierExt[1] -> arpRespondExt -> [1]arpRequestExt;
packetClassifierExt[2] -> Strip(14) -> CheckIPHeader -> ipClassifierExt;
packetClassifierExt[3] -> dropExt -> Discard;

ipClassifierExt[0] -> ipNAT[1] -> [0]arpRequestInt -> toInt;
ipClassifierExt[1] -> icmpEchoDropExt -> Discard;
ipClassifierExt[2] -> icmpExt -> icmpNAT[1] -> [0]arpRequestInt -> toInt;
ipClassifierExt[3] -> icmpReplyDropExt -> Discard;


// Report
DriverManager(wait, print > ./results/napt.report "
===================== NAPT Report ====================
Input Packet Rate (pps):    $(add $(fromPrz.rate) $(fromDmz.rate))
Output Packet Rate (pps):   $(add $(toPrz.rate) $(toDmz.rate))

Total # of  input packets:  $(add $(fromPrz.count) $(fromDmz.count))
Total # of  output packets: $(add $(toPrz.count) $(toDmz.count))

Total # of  ARP requests:   $(add $(arpQueryInt.count) $(arpQueryExt.count))
Total # of  ARP responses:  $(add $(arpRespondInt.count) $(arpRespondExt.count))

Total # of  service packets:    $(add $(tcpInt.count))
Total # of  ICMP packets:       $(add $(icmpInt.count) $(icmpExt.count))
Total # of  dropped packets:    $(add $(dropInt.count) $(dropExt.count) $(icmpEchoDropInt.count) $(icmpEchoDropExt.count) $(icmpReplyDropInt.count) $(icmpReplyDropExt.count))
======================================================",
stop);