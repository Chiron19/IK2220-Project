Script(print "Test IDS if running?????")

elementclass IPChecksumFixer{ $print |
        input
        ->SetIPChecksum
        -> class::IPClassifier(tcp, -)

        class[0] -> Print(TCP, ACTIVE $print) -> SetTCPChecksum -> output
        class[1] -> Print(OTH, ACTIVE $print) -> output
}

//Use before passing to ToDevice
elementclass FixedForwarder{ 
         input
        ->Strip(14)
        ->SetIPChecksum
        ->CheckIPHeader
        ->IPChecksumFixer(0)
        ->Unstrip(14)
        ->output
}


switchInput, switchOutput, serverInput, serverOutput :: AverageCounter
switchARP, switchIP, serverARP, serverIP, httpPacket, putOptions, postOptions, toInsp, switchDrop, serverDrop :: Counter

fromSWITCH :: FromDevice(ids-eth2, METHOD LINUX, SNIFFER false);
fromSERVER :: FromDevice(ids-eth1, METHOD LINUX, SNIFFER false);
toSWITCH :: Queue -> switchOutput -> ToDevice(ids-eth2, METHOD LINUX);
toSERVER :: Queue -> serverOutput-> ToDevice(ids-eth1, METHOD LINUX);
toINSP :: Queue -> ToDevice(ids-eth3, METHOD LINUX);

serverPacketType, clientPacketType :: Classifier(
			
	12/0806,		//ARP
        12/0800,		//IP
         -
 );


classify_HTTP_others:: IPClassifier(
		
		psh,		//set for HTTP 
		-	        //OTHERS, or NON-HTTP	
		
);


classify_HTTPmethod :: Classifier(
		//66/474554,		// GET
		66/505554,	        // PUT
		66/504f5354,		// POST				   
		-			
);
					
					
classify_PUT_keywords :: Classifier(
		0/636174202f6574632f706173737764,		//cat/etc/passwd  [0x63', '0x61', '0x74', '0x2f', '0x65', '0x74', '0x63', '0x2f', '0x70', '0x61', '0x73', '0x73', '0x77', '0x64']。
		0/636174202f7661722f6c6f67,    		    //cat/var/log ['0x63', '0x61', '0x74', '0x2f', '0x76', '0x61', '0x72', '0x2f', '0x6c', '0x6f', '0x67'] 
		0/494E53455254,                  		//INSERT ['0x49', '0x4e', '0x53', '0x45', '0x52', '0x54']
		0/555044415445,                  		//UPDATE ['0x55', '0x50', '0x44', '0x41', '0x54', '0x45']
		0/44454C455445,                  		//DELETE ['0x44', '0x45', '0x4c', '0x45', '0x54', '0x45']
		-
);
                    
                    
search_PUT_keywords :: Search("\r\n\r\n")


//Check Client Packet Type
fromSWITCH -> switchInput -> clientPacketType;
clientPacketType[0] -> switchARP -> toSERVER;      											//ARP
clientPacketType[1] -> switchIP -> FixedForwarder -> Strip(14) ->  /*Print(CLIENT_IP_PACKETS, -1)->*/ classify_HTTP_others;		//ip packets
clientPacketType[2] -> switchDrop -> Discard;												//others

//Check HTTP vs NON HTTP
classify_HTTP_others[1] -> Unstrip(14) -> toSERVER;                			        		                //non-http 
classify_HTTP_others[0] -> httpPacket -> Unstrip(14) -> /*Print(TO_HTTP_CLASSIFIER, -1) ->*/ classify_HTTPmethod;		//http

//Check HTTP Method
classify_HTTPmethod[0] -> putOptions -> search_PUT_keywords;			//PUT, so we check keywords
classify_HTTPmethod[1] -> postOptions -> toSERVER;		                //POST, pass on to server
classify_HTTPmethod[2] -> toInsp-> toINSP;    			                //Others, passed to INSP

//If PUT, search for PUT data
search_PUT_keywords[0] -> /*Print(AFTER_SEARCH, -1) ->*/ classify_PUT_keywords;
search_PUT_keywords[1] -> toINSP;

//If Harmful keywords found, sent to INSP, otherwise send to SERVER
classify_PUT_keywords[0] -> UnstripAnno() -> toInsp-> toINSP;
classify_PUT_keywords[1] -> UnstripAnno() -> toInsp-> toINSP;
classify_PUT_keywords[2] -> UnstripAnno() -> toInsp-> toINSP;
classify_PUT_keywords[3] -> UnstripAnno() -> toInsp-> toINSP;
classify_PUT_keywords[4] -> UnstripAnno() -> toInsp-> toINSP;
classify_PUT_keywords[5] -> /*Print(BEFORE_UNSTRIPAnnoToServer, -1) ->*/  UnstripAnno() -> Print(AFTER_UNSTRIP_TO_SERVER, -1) -> toSERVER;

//For the Server Side, check packet type forward accordingly
fromSERVER -> serverInput -> serverPacketType;
serverPacketType[0] -> serverARP -> toSWITCH;
serverPacketType[1] -> serverIP -> FixedForwarder -> toSWITCH;
serverPacketType[2] -> serverDrop -> Discard;

 DriverManager(pause , print > /home/ik2220/version1/click_results/ids.report  " 

      =================== IDS Report ===================
      Input Packet rate (pps): $(add $(switchInput.rate) $(serverInput.rate))

      Output Packet rate (pps): $(add $(switchOutput.rate) $(serverOutput.rate))

      Total # of   input packets:  $(add $(switchInput.count) $(serverInput.count))
      Total # of   output packets:  $(add $(switchOutput.count) $(serverOutput.count))

      Total # of   IP  packets:  $(add $(switchIP.count) $(serverIP.count))
      Total # of   ARP  packets:  $(add $(switchARP.count) $(serverARP.count)) 
      Total # of   HTTP packets:  $(httpPacket.count) 

      Total # of   PUT packets:  $(putOptions.count)
      Total # of   POST packets:  $(postOptions.count) 

      Total # of   to INSP packets: $(toInsp.count)
      Total # of   dropped packets:  $(add $(switchDrop.count) $(serverDrop.count))
    =================================================

 " );
