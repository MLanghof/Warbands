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

final int minTimeslot = 399362;
int maxTimeslot = (int)((new Date().getTime()) / 1000 / 3600) - 1; // No file exists for current timeslot, afaik 

int currentTimeslot = minTimeslot;
boolean awaitingData = false;
boolean newData = false;
String lastMessage = "";
boolean gotAllFiles = false;

float horScale = 0.8;
float vertScale = 1.0;

WebSocketClient cc;

//JSONObject maps;
PImage mapImagesAll;
HashMap<String,PImage> mapImages = new HashMap<String, PImage>();    // Using int as key fails for reasons unknown to me ('Error on "Dimensions"')
IntDict rarityColors = new IntDict();

IntDict warbands = new IntDict();
int[] warbandColors = new int[] { color(255), color(255, 0, 0), color(0, 255, 0), color (0, 0, 255) };

HashMap<String, Map> maps;
HashMap<String, Legacy> legacyData = new HashMap<String, Legacy>();

PeasyCam camera;

void setup()
{
    size(1600, 900, P3D);
    
    camera = new PeasyCam(this, 0, 0, 00, 800);
    
    //setupWebsocketConnection();
    
    rarityColors.set("normal", color(200, 200, 200));
    rarityColors.set("unique", color(175, 96, 37));
    
    warbands.set("None", 0);
    warbands.set("Redblade", 1);
    warbands.set("Mutewind", 2);
    warbands.set("Brinerot", 3);
    
    loadMapData();
    parseMapAdjacencies();
    
    ellipseMode(CORNER);
}


void draw()
{
    if (!lastMessage.equals(""))
        receivedLegacyData(lastMessage);
    
    if (!(awaitingData || gotAllFiles))
    {
        File f;
        while (true)
        {
            currentTimeslot++;
            
            f = new File(dataPath("timeslots/" + str(currentTimeslot) + ".txt"));
            if (f.exists())
            {
                JSONArray fileData = loadJSONArray(f.getPath());
                legacyData.put(str(currentTimeslot), new Legacy(fileData, str(currentTimeslot)));
            }
            else break;
        }
        println("file path: " + f.getPath());
        if (currentTimeslot <= maxTimeslot)
        {
            awaitingData = true;
            askForTimeslot(currentTimeslot);
        }
        else
            gotAllFiles = true;
    }
    
    background(100);
    
    translate(20, 20);
    /*for (int i = minTimeslot; i < maxTimeslot; i++)
        drawMaps(map(i, minTimeslot, maxTimeslot, 1000, -1000),
            str(i), i == maxTimeslot - 1);
    //frameCount % (maxTimeslot - minTimeslot) + minTimeslot)*/
    drawMaps(0, str(maxTimeslot - 20), true); 
    drawArrows(0);
    
    camera.beginHUD();
    text(frameRate, 10, 10);
    camera.endHUD();
}


void drawMaps(float distance, String timeslot, boolean drawMapImages)
{
    if (!legacyData.containsKey(timeslot))
        return;
    Legacy data = legacyData.get(timeslot);
    
    pushStyle();
    pushMatrix();
    translate(-width/2, -height/2, -distance);
    noStroke();
    
    for (Map map : maps.values())
    {  
        if (data.mapInfluence.hasKey(map.name))
        {
            int influence = data.mapInfluence.get(map.name);
            int dots = influence % 5;
            int band = influence / 5;
            fill(warbandColors[band],  80);
            ellipse(map.left - 6, map.top - 5, 56, 56);
            translate(0, 0, 0.5);
            fill(warbandColors[band]);
            arc(map.left - 3, map.top - 2, 50, 50, -PI/2, -PI/2 + HALF_PI * dots);
            translate(0, 0, -0.5);
            
            noTint();
        }
        else
        {
            fill(128, 100);
            ellipse(map.left - 6, map.top - 4, 56, 56);
            
            //tint(255, 128);
        }
        if (drawMapImages)
        {
            translate(0, 0, 1);
            image(map.image, map.left, map.top);
            translate(0, 0, -1);
        }
    }
    
    popMatrix();
    popStyle();
}

void drawArrows(float distance)
{
    pushStyle();
    pushMatrix();
    translate(-width/2 + 26, -height/2 + 25, -distance - 2);
    
    stroke(0);
    strokeWeight(2);
    for (Map map : maps.values())
    {
        for (Map otherMap : map.adjacent)
            line(map.left, map.top, otherMap.left, otherMap.top);
    }
    
    popMatrix();
    popStyle();
}

void loadMapData()
{
    JSONObject mapsJson = loadJSONObject("data/maps.txt");
    mapImagesAll = loadImage("data/images.png");
    maps = new HashMap<String, Map>();
    
    for (int mapLevel = 68; mapLevel <= 82; mapLevel++)
    {
        JSONObject currentMaps = mapsJson.getJSONObject(str(mapLevel));
        Iterator<String> mapIterator = currentMaps.keyIterator();
        while (mapIterator.hasNext())                                // I want my LINQ :(
        {
            String mapName = mapIterator.next();
            Map map = new Map(currentMaps.getJSONObject(mapName), mapName);
            maps.put(mapName, map);
        }
    }
}

void parseMapAdjacencies()
{
    JSONArray all = loadJSONArray("data/arrows.txt");
    for (int i = 0; i < all.size(); i++)
    {
        JSONArray chain = all.getJSONArray(i);
        Map map1 = maps.get(chain.getString(0));
        for (int j = 1; j < chain.size(); j++)
        {
            Map map2 = maps.get(chain.getString(j));
            
            map1.addAdjacency(map2);
            map2.addAdjacency(map1);
            
            map1 = map2;
        }
    }
}

void receivedLegacyData(String message)
{
    newData = false;
    lastMessage = "";
    JSONObject step1 = JSONArray.parse(message).getJSONObject(0);
    String mapsAndTimeslot = step1.getString("success", "");
    if (mapsAndTimeslot != "")
    {
        JSONObject step2 = JSONObject.parse(mapsAndTimeslot);
        int timeslot = step2.getInt("timeslot");
        println("Received " + str(timeslot));
        if (timeslot == currentTimeslot)
        {
            awaitingData = false;
        }
        else println("Error: Timeslots didn't match!");
        JSONArray mapArray = step2.getJSONArray("maps");
        saveJSONArray(mapArray, "data/timeslots/" + str(timeslot) + ".txt");
        
        legacyData.put(str(timeslot), new Legacy(mapArray, str(timeslot)));
    }
}

void mouseClicked()
{
    //cc.send("5:2+::{\"name\":\"loadLegacy\",\"args\":[399814]}");
    //JSONArray obj = loadJSONArray("data/"+str(minTimeslot)+".txt");
    //saveStrings("data/success.txt", new String[] { obj.getJSONObject(0).getString("success") });
}