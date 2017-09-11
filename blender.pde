OPC opc; //<>//
//import java.util.Date;
import java.util.*;
import java.io.*;
//get knots from API
//mounting angle this is degrees off north to offset the grid

//properties file
Properties configFile;

float mAngle = 0;//60;
String Loc="";
String lat ="";// "43.988";
String lon ="";// "-77.339";
String apikey = "fbd1afc4de45a8f5da9eb9309af9b3b4";
String url="";
float cardinal;
float knots;
PImage img;
int newx;
float h;
int s;
int b;
JSONObject json;
void buildImg() {
  img.loadPixels();
  float w = 0;
  for (int y=0; y<img.height; y++) {
    for (int x=0; x<img.width; x++) {
      int index = x + y * img.width;
      if (x >= (.75*(img.width/2))) {
        if (x <= (img.width/2)) {
          w = (w + 4);
        } else {
          w = (w-4);
        }
      } else {
        w = 0;
      }
      float b = (w>0)? map(w, 0, (img.width/2), 0, 100):1;//brightness percentage
      color c = color((360 - h), s, b);
      // println(hex(c));
      img.pixels[index] = c;
    }
  }
  img.updatePixels();
}
void getJSON() {
  try {
    json = loadJSONObject(url);
    int dt = json.getInt("dt");
    Date mydate = new java.util.Date(dt * 1000L);//date of reading
    JSONObject coord = json.getJSONObject("coord");
    JSONObject sys = json.getJSONObject("sys");
    Loc = json.getString("name") +", "+ sys.getString("country");
    JSONObject wind =  json.getJSONObject("wind");
    knots = (1.94384) * (wind.getFloat("speed"));//in m/s (1.94384)
    float deg = wind.getFloat("deg");
    cardinal = (deg + mAngle)*TWO_PI/360;
    println(mydate);
    println("lat:" + lat);
    println("lon:" + lon);
    println(coord);
    println(Loc);
    println(deg+" Degrees");
    println(knots +" Kn");
  }
  catch(Exception ex) {
    // println(ex);
    knots=1;
    cardinal=1;
  }
}
void setup() {
  try{
  configFile = new Properties();
    String dp = dataPath("config.properties");
    FileInputStream f = new FileInputStream(dp);
    configFile.load(f);
    println(configFile);
  } catch(Exception e){
     e.printStackTrace(); 
  }
    /*
    REFERENCE FOR CONFIG FILE PARSING
    AREA = configFile.getProperty("AREA");

    overlayY = Integer.parseInt(configFile.getProperty("OVERLAY_Y"));
    overlayX = Integer.parseInt(configFile.getProperty("OVERLAY_X"));
    */
  stroke(255);
  fill(255);

  //if angle is passed as arg use it...
  if (args != null) {
    for (int arrg=0; arrg<args.length; arrg++) {
      println(args[arrg]);
    }
    println(args[0]);
    mAngle =float(args[0]);
    if (args.length==3) {
      lat=args[1];
      lon=args[2];
    }
  } else {
    mAngle=35;
    lat="43.988";
    lon ="-77.339";
  }
  url="http://api.openweathermap.org/data/2.5/weather?lat="+ lat +"&lon="+ lon +"&APPID="+ apikey;


  thread("getJSON");

  background(1, 1, 1);
  size(640, 640);
  colorMode(HSB, 360, 100, 100);
  newx=width/2*-1;
  //  knots=round(5);//get from api
  //  cardinal=(deg+60)*TWO_PI/360;//get from api lights are offset 60 deg from north
  h = map(knots, 0, 30, 117, 360);//maps knots from green(117 deg. hue to red 365 deg. hue)
  s=100;
  b=0;
  img = createImage(1280, 1280, RGB);
  thread("buildImg");  
  opc = new OPC(this, "127.0.0.1", 7890);
  float spacing = width / 20.0;
  float vspace = height /8;
  float vpos = (height / 2) - (3 * vspace);
  for (int ind = 0; ind<6; ind++) {
    opc.ledStrip((ind * 64), 16, (width / 2), vpos, spacing, radians(180), false);
    vpos += vspace;
  }

  //opc.ledGrid(0 ,64 ,6 ,(width / 2) + (32 * spacing),height/2,spacing,height/8,0,false);


  // Make the status LED quiet
  opc.setStatusLed(true);
  // To efficiently set all the pixels on screen, make the set() 
  // calls on a PImage, then write the result to the screen.
  //imageMode(CENTER);
}
void draw() {
  // strokeWeight(5);
  //line(width / 4,height / 2,3 * width / 4, height / 2);

  if (frameCount % (round(frameRate)*300)==0) {//every 5 minutes no matter the frame rate
    println("get new data");
    thread("getJSON");
    thread("buildImg");
  }
  newx = (newx<width/2)?newx+round(round(knots)*(1/(frameRate/15.00))):(-1 * ((width / 2) - 50));
  translate(width/2, height/2);
  rotate(cardinal);//in rad
  translate(-img.width/2, -img.height/2);
  image(img, newx, 0);
}