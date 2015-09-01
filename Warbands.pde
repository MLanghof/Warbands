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

int drawnTimeslot = maxTimeslot - 20;
Map mouseOverMap;

void setup()
{
    size(1600, 900, P3D);
    
    camera = new PeasyCam(this, 0, 0, 00, 800);
    
    setupWebsocketConnection();
    
    rarityColors.set("normal", color(200, 200, 200));
    rarityColors.set("unique", color(175, 96, 37));
    
    warbands.set("None", 0);
    warbands.set("Redblade", 1);
    warbands.set("Mutewind", 2);
    warbands.set("Brinerot", 3);
    
    loadMapData();
    parseMapAdjacencies();
    
    ellipseMode(CORNER);
    
    textSize(16);
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
    drawMaps(0, str(drawnTimeslot), true); 
    drawArrows(0);
    drawMaps(100, str(drawnTimeslot - 1), false); 
    drawArrows(100);
    
    camera.beginHUD();
    fill(255);
    translate(10, 20);
    
    text("Frame rate: " + frameRate, 0, 0);
    translate(0, 25);
    text("Time slot: " + drawnTimeslot, 0, 0);
    translate(0, 25);
    text("Hovered map: " + (mouseOverMap == null ? "" : mouseOverMap.name), 0, 0);
    translate(0, 25);
    
    if (prediction != null)
    {
        drawPrediction(prediction);
        translate(0, 130);
        text("Confidence: " + prediction.confidence, 10, 40);
    }
    camera.endHUD();
}


void drawMaps(float distance, String timeslot, boolean drawMapImages)
{
    if (!legacyData.containsKey(timeslot))
        return;
    Legacy data = legacyData.get(timeslot);
    
    float t = (drawMapImages ? 1 : 0.3);
    if (drawMapImages) mouseOverMap = null;
    
    pushStyle();
    pushMatrix();
    translate(-width/2, -height/2, -distance);
    strokeWeight(4);
    noStroke();
    
    for (Map map : maps.values())
    {  
        noStroke();
        if (drawMapImages && mouseContained(map.left, map.top, 48, 48))
        {
            mouseOverMap = map;
            stroke(0);
        }
        if (data.mapInfluence.hasKey(map.name))
        {
            int influence = data.mapInfluence.get(map.name);
            int dots = influenceToDots(influence);
            int band = influenceToBand(influence);
            
            fill(warbandColors[band],  80 * t);
            ellipse(map.left - 6, map.top - 5, 56, 56);
            noStroke();
            translate(0, 0, 0.5);
            fill(warbandColors[band], 255 * (band == 0 ? 1 : t));
            arc(map.left - 3, map.top - 2, 50, 50, -PI/2, -PI/2 + HALF_PI * dots);
            translate(0, 0, -0.5);
            
            noTint();
        }
        else
        {
            fill(128, 100 * t);
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

void drawPrediction(Prediction p)
{
    pushStyle();
    pushMatrix();
    float w = 30;
    for (int i = 0; i < MAX_INFLUENCE; i++)
    {
        int dots = influenceToDots(i);
        int band = influenceToBand(i);
        fill(warbandColors[band], (p.probabilities[i]) * 255);
        
        rect(w * dots, w * band, w+0.5, w+0.5);
        fill(0);
        text(round(p.probabilities[i]*100), w * (dots + 0.3), w * (band + 0.7));
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

Prediction prediction;

void mouseClicked()
{
    if (mouseOverMap == null) return;
    
    SimplePredictor p = new SimplePredictor();
    
    for (int i = minTimeslot+2; i < maxTimeslot; i++)
    {
        Legacy cur = legacyData.get(str(i));
        Legacy pre = legacyData.get(str(i-1));
        if (pre == null || cur == null)
            println("NULL LEGACY: " + str(i - minTimeslot));
        p.train(cur, pre);
    }
    
    prediction = p.predict(legacyData.get(str(drawnTimeslot)), legacyData.get(str(drawnTimeslot - 1)), mouseOverMap);
    
    //cc.send("5:2+::{\"name\":\"loadLegacy\",\"args\":[399814]}");
    //JSONArray obj = loadJSONArray("data/"+str(minTimeslot)+".txt");
    //saveStrings("data/success.txt", new String[] { obj.getJSONObject(0).getString("success") });
}

boolean mouseContained(float x, float y, float w, float h)
{
    if (mouseX < screenX(x, y, 0)) return false;
    if (mouseY < screenY(x, y, 0)) return false;
    if (mouseX > screenX(x + w, y + h, 0)) return false;
    if (mouseY > screenY(x + w, y + h, 0)) return false;
    return true;
}

void keyPressed()
{
    if (key == 'w')
        drawnTimeslot++;
    if (key == 's')
        drawnTimeslot--;
}