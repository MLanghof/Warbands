abstract class Predictor
{
    abstract public Prediction predict(Legacy previous, Legacy current, Map map);
    
    abstract public void train(Legacy previous, Legacy current);
}

class Prediction
{
    private float[] probabilities = new float[MAX_INFLUENCE+1];
    public float confidence = 0;
    
    public Prediction()
    {
    }
    
    public Prediction(float[] nprobabilities)
    {
        arrayCopy(nprobabilities, probabilities);
        confidence = 0;
    }
    
    public void Normalize()
    {
        confidence = 0; //<>//
        for (int i = 0; i <= MAX_INFLUENCE; i++)
            confidence += probabilities[i];
        //println("Normalization sum: " + str(sum));
        if (confidence == 0)
            return;
        for (int i = 0; i <= MAX_INFLUENCE; i++)
            probabilities[i] /= confidence;
    }
}

class SimplePredictor extends Predictor
{
    ArrayList<Situation> past;
    
    public SimplePredictor()
    {
        past = new ArrayList<Situation>();
    }
    
    public Prediction predict(Legacy current, Legacy previous, Map map)
    {
        Prediction p = new Prediction();
        Situation now = new Situation(previous, current);
        for (Situation then : past)
        {
            // If there's a known result for this map at the given time...
            if (then.cur.mapInfluence.hasKey(map.name))
            {
                // Check how similar the situation around the map was now and then and weight the result it had then with it.
                int influence = then.cur.mapInfluence.get(map.name);
                p.probabilities[influence] += alikeness(then, now, map);
            }
        }
        p.Normalize(); //<>//
        return p;
    }
    
    public void train(Legacy then, Legacy thenPre)
    {
        past.add(new Situation(then, thenPre));
    }
    
    private float alikeness(Situation then, Situation now, Map map)
    {
        int comparisons = 0;
        float score = 0;
        float c;
        
        // No comparison of requested map's now and then...
        c = compareLegacies(then.pre, now.pre, map.name);
        comparisons += (c >= 0 ? 1 : 0);
        score += (c >= 0 ? c : 0);
        
        for (Map adjacent : map.adjacent)
        {
            c = compareLegacies(then.cur, now.cur, adjacent.name);
            comparisons += (c >= 0 ? 1 : 0);
            score += (c >= 0 ? c : 0);
            
            c = compareLegacies(then.pre, now.pre, adjacent.name);
            comparisons += (c >= 0 ? 1 : 0);
            score += (c >= 0 ? c : 0);
        }
        //println(str(score) + ", " + str(comparisons));
        return (comparisons > 0 ? score/comparisons : 0);
    }
    
    private float compareLegacies(Legacy legThen, Legacy legNow, String map)
    {
        // If nothing is known about either one of the map situations, we can't compare.
        if (!legThen.mapInfluence.hasKey(map)) return -1;
        if (!legNow.mapInfluence.hasKey(map)) return -1;
        return compareInfluences(legThen.mapInfluence.get(map), legNow.mapInfluence.get(map));
    }
    
    private float compareInfluences(int influenceThen, int influenceNow)
    {
        //println(str(influenceThen) + ", " + str(influenceNow));
        if (influenceToBand(influenceThen) == influenceToBand(influenceNow))
        {
            //println("Matching bands, returning "  + abs(influenceToDots(influenceThen) - influenceToDots(influenceNow)) / 4.0);
            return (4 - abs(influenceToDots(influenceThen) - influenceToDots(influenceNow))) / 4.0;
        }
        return 0;
    }
}

class Situation
{
    Legacy pre, cur;
    public Situation(Legacy npre, Legacy ncur)
    {
        pre = npre;
        cur = ncur;
    }
}