import java.util.Date; //<>// //<>//
import java.util.Iterator;
import java.util.List;
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

boolean DEBUG = true;

// Unix-timestamp / 3600 = stringname

final int  minTimeslot = 399362;

float horScale = 0.8;
float vertScale = 1.0;

WebSocketClient cc;

//JSONObject maps;
PImage mapImagesAll;
HashMap<String,PImage> mapImages = new HashMap<String, PImage>();    // Using int as key fails for reasons unknown to me ('Error on "Dimensions"')
IntDict rarityColors;

ArrayList<Map> maps;

PeasyCam camera;

void setup()
{
    size(1600, 900, P3D);
    
    camera = new PeasyCam(this, 0, 0, 00, 800);
    
    setupWebsocketConnection();
    
    rarityColors = new IntDict();
    rarityColors.set("normal", color(200, 200, 200));
    rarityColors.set("unique", color(175, 96, 37));
    
    loadMapData();
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
    
    for (Map map : maps)
    {
        fill(map.bgColor);
        rect(map.left - 4, map.top - 4, 52, 52, 10);
        translate(0, 0, 2);
        image(map.image, map.left, map.top);
        translate(0, 0, -2);
    }
    
    popMatrix();
    popStyle();
}

void loadMapData()
{
    JSONObject mapsJson = loadJSONObject("data/maps.txt");
    mapImagesAll = loadImage("data/images.png");
    maps = new ArrayList<Map>();
    
    for (int mapLevel = 68; mapLevel <= 82; mapLevel++)
    {
        JSONObject currentMaps = mapsJson.getJSONObject(str(mapLevel));
        Iterator<String> mapIterator = currentMaps.keyIterator();
        while (mapIterator.hasNext())                                // I want my LINQ :(
        {
            String mapName = mapIterator.next();
            Map map = new Map(currentMaps.getJSONObject(mapName), mapName);
            maps.add(map);
        }
    }
}

void receivedLegacyData(String message)
{
    JSONObject step1 = JSONArray.parse(message.substring(6)).getJSONObject(0);
    String mapsAndTimeslot = step1.getString("success", "");
    if (mapsAndTimeslot != "")
    {
        JSONObject step2 = JSONObject.parse(mapsAndTimeslot);
        int timeslot = step2.getInt("timeslot");
        JSONArray mapArray = step2.getJSONArray("maps");
        saveJSONArray(mapArray, "data/timeslots/" + str(timeslot) + ".txt");
    }
}

void mouseClicked()
{
    //cc.send("5:2+::{\"name\":\"loadLegacy\",\"args\":[399814]}");
    //JSONArray obj = loadJSONArray("data/"+str(minTimeslot)+".txt");
    //saveStrings("data/success.txt", new String[] { obj.getJSONObject(0).getString("success") });
}