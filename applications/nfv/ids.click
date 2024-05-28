define($PORT1 ids-eth1, $PORT2 ids-eth2)

Script(print "Click IDS on $PORT1 $PORT2")
Script(print "Test IDS if running?????")

elementclass IPChecksumFixer { $print |
    input ->
    SetIPChecksum ->
    class::IPClassifier(tcp, -)

    class[0] -> Print(TCP, ACTIVE $print) -> SetTCPChecksum -> output
    class[1] -> Print(OTH, ACTIVE $print) -> output
}

// Use before passing to ToDevice
elementclass FixedForwarder {
    input ->
    Strip(14) ->
    SetIPChecksum ->
    CheckIPHeader ->
    IPChecksumFixer(0) ->
    Unstrip(14) ->
    output
}

// Counter Definition
switchInput, switchOutput, serverInput, serverOutput :: AverageCounter
switchARP, switchIP, serverARP, serverIP, httpPacket, putOptions, postOptions, toInsp, switchDrop, serverDrop :: Counter

fromSWITCH :: FromDevice(ids-eth2, METHOD LINUX, SNIFFER false);
fromSERVER :: FromDevice(ids-eth1, METHOD LINUX, SNIFFER false);
toSWITCH :: Queue -> switchOutput -> ToDevice(ids-eth2, METHOD LINUX);
toSERVER :: Queue -> serverOutput-> ToDevice(ids-eth1, METHOD LINUX);
toINSP :: Queue -> toInsp -> ToDevice(ids-eth3, METHOD LINUX);

serverPacketType, clientPacketType :: Classifier(
    12/0806,    // ARP
    12/0800,    // IP
    -           // Other
);

classify_HTTP_others :: IPClassifier(
    tcp and psh and dst port 80,    // HTTP
    -                               // others
);

classify_HTTPmethod :: Classifier(
    0/474554,       // GET
    0/505554,       // PUT
    0/504f5354,     // POST	   
    -               // Other		
);

classify_PUT_keywords :: Classifier(
    0/636174202f6574632f706173737764,   // cat /etc/passwd
    0/636174202f7661722f6c6f67,         // cat /var/log
    0/494E53455254,                     // INSERT
    0/555044415445,                     // UPDATE
    0/44454C455445,                     // DELETE
    -
);

search_PUT_keywords :: Search("\r\n\r\n")

// Check Client Packet Type
fromSWITCH -> switchInput -> clientPacketType;

clientPacketType[0] -> switchARP -> toSERVER;           // ARP
clientPacketType[1] -> switchIP 
                    -> FixedForwarder 
                    // -> Print(CLIENT_IP_PKT_IDS, -1) 
                    -> Strip(14) 
                    -> classify_HTTP_others; // ip packets
clientPacketType[2] -> switchDrop -> Discard;           // others

// Check HTTP vs Non-HTTP
classify_HTTP_others[0] -> httpPacket
                        -> StripIPHeader()
                        -> StripTCPHeader()
                        // -> Print(HTTP_TO_CLASSIFIER, -1)
                        -> classify_HTTPmethod;   // http
classify_HTTP_others[1] // -> Print(NON_HTTP_TO_SERVER, -1)
                        -> Unstrip(14) -> toSERVER;     // non-http

// Check HTTP Method
classify_HTTPmethod[0] -> UnstripTCPHeader() -> UnstripIPHeader() -> Unstrip(14) -> toINSP;                     // GET, pass to INSP
classify_HTTPmethod[1] -> putOptions -> search_PUT_keywords;                                                    // PUT, check keywords
classify_HTTPmethod[2] -> postOptions -> UnstripTCPHeader() -> UnstripIPHeader() -> Unstrip(14) -> toSERVER;    // POST, pass to server
classify_HTTPmethod[3] -> UnstripTCPHeader() -> UnstripIPHeader() -> Unstrip(14) -> toINSP;                     // Others, pass to INSP

// If PUT, search for PUT data
search_PUT_keywords[0] -> classify_PUT_keywords; // strip to 2 CRLF pattern (where HTTP header ends)
search_PUT_keywords[1] -> UnstripAnno() -> UnstripTCPHeader() -> UnstripIPHeader() -> Unstrip(14) -> toINSP;  // If no 2 CRLF pattern, pass to INSP

// If Harmful keywords found, sent to INSP, otherwise send to SERVER
classify_PUT_keywords[0] -> UnstripAnno() -> UnstripTCPHeader() -> UnstripIPHeader() -> Unstrip(14) -> toINSP;
classify_PUT_keywords[1] -> UnstripAnno() -> UnstripTCPHeader() -> UnstripIPHeader() -> Unstrip(14) -> toINSP;
classify_PUT_keywords[2] -> UnstripAnno() -> UnstripTCPHeader() -> UnstripIPHeader() -> Unstrip(14) -> toINSP;
classify_PUT_keywords[3] -> UnstripAnno() -> UnstripTCPHeader() -> UnstripIPHeader() -> Unstrip(14) -> toINSP;
classify_PUT_keywords[4] -> UnstripAnno() -> UnstripTCPHeader() -> UnstripIPHeader() -> Unstrip(14) -> toINSP;
classify_PUT_keywords[5] -> /*Print(BEFORE_UNSTRIPAnnoToServer, -1) ->*/  UnstripAnno() -> UnstripTCPHeader() -> UnstripIPHeader() -> Unstrip(14) -> /*Print(AFTER_UNSTRIP_TO_SERVER, -1) ->*/ toSERVER;


// Check Server Packet Type
fromSERVER -> serverInput -> serverPacketType;

serverPacketType[0] -> serverARP -> toSWITCH;
serverPacketType[1] -> serverIP -> FixedForwarder -> toSWITCH;
serverPacketType[2] -> serverDrop -> Discard;

DriverManager(wait, print > ./results/ids.report "
=================== IDS Report ===================
Input Packet rate (pps):    $(add $(switchInput.rate) $(serverInput.rate))
Output Packet rate (pps):   $(add $(switchOutput.rate) $(serverOutput.rate))

Total # of  input packets:  $(add $(switchInput.count) $(serverInput.count))
Total # of  output packets: $(add $(switchOutput.count) $(serverOutput.count))

Total # of  IP  packets:    $(add $(switchIP.count) $(serverIP.count))
Total # of  ARP  packets:   $(add $(switchARP.count) $(serverARP.count)) 
Total # of  HTTP packets:   $(httpPacket.count) 

Total # of  PUT packets:    $(putOptions.count)
Total # of  POST packets:   $(postOptions.count) 

Total # of  to INSP packets:    $(toInsp.count)
Total # of  dropped packets:    $(add $(switchDrop.count) $(serverDrop.count))
=================================================
"
);