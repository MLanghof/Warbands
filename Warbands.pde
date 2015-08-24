import java.util.Date; //<>//
import java.util.Iterator;
import org.java_websocket.*;
import org.java_websocket.client.*;
import org.java_websocket.drafts.*;
import org.java_websocket.exceptions.*;
import org.java_websocket.framing.*;
import org.java_websocket.handshake.*;
import org.java_websocket.server.*;
import org.java_websocket.util.*;


import java.net.URI;
import java.net.URISyntaxException;

// Unix-timestamp / 3600 = stringname

final int  minTimeslot = 399362;


WebSocketClient cc;

void setup()
{
  size(1000, 600);


  Date d = new Date();
  String url = "http://nembibi.com:5055/socket.io/1/?t=" + d.getTime();
  println(url);

  String[] result = loadStrings(url);

  try {
    String uri = "ws://nembibi.com:5055/socket.io/1/websocket/" + split(result[0], ':')[0] + "";
    println(uri);
    println();

    cc = new WebSocketClient( new URI( uri ), new Draft_17() ) {

      @Override
        public void onMessage( String message ) {
        println("Msg: " + message);
        println();
        if (message.equals("1::"))
          send("5:1+::{\"name\":\"init\"}");
        
        if (message.equals("2::")) //<>//
        {
          send("2::");
          println("echoing 2");
        }
        
        if (message.startsWith("6:::1+"))
        {
          String[] output = new String[] { message.substring(6) };
          saveStrings("data/" + str(minTimeslot) + ".txt", output);
        }
      }

      @Override
        public void onOpen( ServerHandshake handshake ) {
        println("Opened: " + handshake.getHttpStatus() + " " + handshake.getHttpStatusMessage());
        for ( Iterator i = handshake.iterateHttpFields(); i.hasNext(); )
        {
          String field = (String)i.next();
          println(field + ": " + handshake.getFieldValue(field));
          println();
        }
      }

      @Override
        public void onClose( int code, String reason, boolean remote ) {
        println("Close: " + str(code) + ", " + reason + ", " + str(remote));
        println();
      }

      @Override
        public void onError( Exception ex ) {
        println("Error");
      }
    };
    cc.connect();
  } 
  catch ( URISyntaxException ex ) {
    println("Exception");
  }
}


void draw()
{
  //if (frameCount % 100 == 0)
    //cc.send("loadLegacy");//, 399837 + frameCount/100);
  //if (frameCount == 1000)
    //cc.send("5:2+::{\"name\":\"loadLegacy\",\"args\":[399814]}");
}

void mouseClicked()
{
  //cc.send("5:2+::{\"name\":\"loadLegacy\",\"args\":[399814]}");
  JSONArray obj = loadJSONArray("data/"+str(minTimeslot)+".txt");
  
  saveStrings("data/success.txt", new String[] { obj.getJSONObject(0).getString("success") });
}