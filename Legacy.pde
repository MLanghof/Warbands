

class Legacy
{
    String timeslot;
    IntDict mapInfluence;
    
    int scriptsRunning = 1000;
    
    public Legacy(JSONArray json, String ntimeslot)
    {
        timeslot = ntimeslot;
        mapInfluence = new IntDict();
        for (int i = 0; i < json.size(); i++)
        {
            JSONObject data = json.getJSONObject(i);
            String name = data.getString("name");
            int dots = int(data.getString("dots"));
            int warband = warbands.get(data.getString("band"), -1);
            int reportCount = int(data.getString("reports_on_710"));
            
            // Apparently not all of the data is sane
            if (warband == -1 || dots < 0 || dots > 4)
            {
                println("Data not sane for timeslot " + timeslot + "!");
                println("Warband: \"" + data.getString("band") + "\", dots: " + str(dots));
            }
            
            mapInfluence.set(name, warband * 5 + dots);
            scriptsRunning = min(scriptsRunning, reportCount);
        }
    }
}