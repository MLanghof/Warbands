import java.util.Date; //<>// //<>//
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

import peasy.*;

// Unix-timestamp / 3600 = stringname

final int  minTimeslot = 399362;


WebSocketClient cc;

JSONObject maps;
PImage mapImagesAll;
HashMap<String,PImage> mapImages = new HashMap<String, PImage>();    // Using int as key fails for reasons unknown to me ('Error on "Dimensions"')
IntDict rarityColors;

PeasyCam camera;

void setup()
{
    size(1600, 900, P3D);
    
    camera = new PeasyCam(this, 0, 0, 00, 800);
    
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

                if (message.equals("2::"))
                {
                    send("2::");
                    println("echoing 2");
                }

                if (message.startsWith("6:::1+"))
                {
                    JSONObject step1 = JSONArray.parse(message.substring(6)).getJSONObject(0);
                    String mapsAndTimeslot = step1.getString("success", "");
                    if (mapsAndTimeslot != "")
                    {
                        JSONObject step2 = JSONObject.parse(mapsAndTimeslot);
                        int timeslot = step2.getInt("timeslot");
                        JSONArray mapArray = step2.getJSONArray("maps");
                        saveJSONArray(mapArray, "data/" + str(timeslot) + ".txt");
                    }
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

    maps = loadJSONObject("data/maps.txt");
    mapImagesAll = loadImage("data/images.png");
    
    rarityColors = new IntDict();
    rarityColors.set("normal", color(200, 200, 200));
    rarityColors.set("unique", color(175, 96, 37));
}


void draw()
{
    background(100);
    
    translate(20, 20);
    drawMaps(00);
    
    camera.beginHUD();
    text(frameRate, 10, 10);
    camera.endHUD(); //<>//
}

void drawMaps(float distance)
{
    pushStyle();
    pushMatrix();
    translate(-width/2, -height/2, -distance);
    
    noStroke();
    
    for (int mapLevel = 68; mapLevel <= 82; mapLevel++)
    {
        JSONObject currentMaps = maps.getJSONObject(str(mapLevel));
        Iterator<String> mapIterator = currentMaps.keyIterator();
        while (mapIterator.hasNext())                                // I want my LINQ :(
        {
            String mapName = mapIterator.next();
            JSONObject map = currentMaps.getJSONObject(mapName);
            
            int left = round(map.getInt("left") * 0.8);
            int top  = round(map.getInt("top" ) * 1.0);
            String bg_pos = str(map.getInt("bg_pos"));
            
            fill(rarityColors.get(map.getString("rarity")));
            rect(left - 4, top - 4, 52, 52, 10);
            translate(0, 0, 2);
            if (!mapImages.containsKey(bg_pos))
            {
                mapImages.put(bg_pos, mapImagesAll.get(map.getInt("bg_pos") -2, -2, 52, 52));
            }
            image(mapImages.get(bg_pos), left, top);
            translate(0, 0, -2);
        }
    }
    popMatrix();
    popStyle();
}

void mouseClicked()
{
    //cc.send("5:2+::{\"name\":\"loadLegacy\",\"args\":[399814]}");
    JSONArray obj = loadJSONArray("data/"+str(minTimeslot)+".txt");

    saveStrings("data/success.txt", new String[] { obj.getJSONObject(0).getString("success") });
}