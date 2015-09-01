boolean setupWebsocketConnection()
{
    Date d = new Date();
    // Request a token
    String url = "http://nembibi.com:5055/socket.io/1/?t=" + d.getTime();
    if (DEBUG)
        println("Requesting token from " + url + "\n");
    String[] result = loadStrings(url);
    
    if (result == null)
        return false;
    
    try {
        String uri = "ws://nembibi.com:5055/socket.io/1/websocket/" + split(result[0], ':')[0] + "";
        if (DEBUG)
            println("Connecting to " + uri + "\n");

        cc = new WebSocketClient(new URI(uri), new Draft_17()) {

            @Override
            public void onMessage(String message)
            {
                // Init message
                if (message.equals("1::"))
                    send("5:1+::{\"name\":\"init\"}");
                
                // Ping
                if (message.equals("2::"))
                    send("2::");    // Pong
                

                if (message.startsWith("6:::")) // there's a "2+" or "1+" after this, still don't know exactly what that means...
                {
                    while (!lastMessage.equals("")) Thread.yield();
                    newData = true;
                    println("THIS SHOULD BE EMPTY: " + lastMessage);
                    lastMessage = message.substring(6);
                }
                
                if (DEBUG) println(message + "\n");
                
                // We don't care about the random updates that arrive.
                // They don't require acknowledgement either.
            }
            
            @Override
            public void onOpen(ServerHandshake handshake)
            {
                if (DEBUG)
                {
                    println("Opened connection: " + handshake.getHttpStatus() + " " + handshake.getHttpStatusMessage());
                    for (Iterator i = handshake.iterateHttpFields(); i.hasNext();)
                    {
                        String field = (String)i.next();
                        println(field + ": " + handshake.getFieldValue(field));
                    }
                    println();
                }
            }

            @Override
            public void onClose(int code, String reason, boolean remote)
            {
                println("Close: " + str(code) + ", " + reason + ", " + str(remote));
                println();
            }

            @Override
            public void onError(Exception ex)
            {
                println("Error: " + ex.getMessage());
            }
        };
        cc.connect();
    } 
    catch ( URISyntaxException ex ) {
        if (DEBUG)
            println("Exception: " + ex.getMessage());
        return false;
    }
    return true;
}

void askForTimeslot(int timeslot)
{
    if (cc == null) return;
    awaitingData = true;
    cc.send("5:2+::{\"name\":\"loadLegacy\",\"args\":["+ str(timeslot) + "]}");
    println("Asking for " + str(timeslot));
}