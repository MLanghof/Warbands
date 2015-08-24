# Warbands
Modeling and predicting warband (and player) behavior in the Path of Exile Warbands league.

## What does this do?

We have lots of warband influence data from the warbands tracker. The goal of this project is to develop and properly tune an algorithm that predicts warband influence change.

Since player behavior is essential in determining warband movement, this means that some level of prediction about player behavior will result from this.

Processing (http://processing.org) is used as the IDE/language.

## If you don't know what warbands are, read this

Path of Exile: https://www.pathofexile.com/  
Warbands league: https://www.pathofexile.com/theawakening/leagues/  
Community-driven warbands tracker: http://nembibi.com/warbands/

### Short summary of Warbands
In the Path of Exile ARPG, there are quest areas you pass through during early leveling, as well as endgame areas called "maps". All areas can be invaded by any of the warbands, which results in certain warband mobs spawning.

There are three types of warbands (Redblade, Brinerot, Mutewind), and each area has a certain level of warband influence on it. Influence levels range from 0 "dots" (no warband) to 4 "dots" (highest warband influence, named unique warband bosses can spawn). Each influence level also corresponds to an area modifier shown when inside the area, different for the various warbands: For example 1 dot redblades would be "Redblade scouts", 4 dot mutewinds would be "Cleansed by the Mutewind", while 4 dot redblades would be "Conquered by the Redblade".
For the quest areas, these influence levels can be seen on the world map at all times (indicated as "dots") and change every 10 minutes, but for maps (which change every hour) there is no way to know them though without entering the map and observing the influence level.

Since chasing and killing warbands (especially 4 dot ones) in these areas has significant benefits for players, being informed of warband populations in maps is advantageous. For this reason, **BulokuChansu** and **BF_Hellion* established a warband tracker at http://nembibi.com/warbands/. The way it works is that people report the warbands they find inside maps in global channel 710. The messages in the channel are scanned by a script, warband reports are sent to the site.

It is known that players hunting down warbands in an area results in a decreased influence for that warband in that area after the next reset. We also know that "adjacent" areas show correlated behavior in warband influence.

For further details, consider this news post by lead developer Chris Wilson: https://www.pathofexile.com/forum/view-thread/1339840
