class Map
{
    String name;
    int left, top;
    String bg_pos;
    String rarity;
    color bgColor;
    
    PImage image;
    
    public Map(JSONObject json, String nname)
    {
        name = nname;
        left = round(json.getInt("left") * horScale);
        top  = round(json.getInt("top") * vertScale);
        bg_pos = str(json.getInt("bg_pos"));
        rarity = json.getString("rarity");
        bgColor = rarityColors.get(rarity);
        
        image = mapImagesAll.get(json.getInt("bg_pos") -2, -2, 52, 52);
    }
}