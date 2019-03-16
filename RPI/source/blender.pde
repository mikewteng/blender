OPC opc;
//import java.util.Date;
import java.util.*;
import java.io.*;
//get knots from API
//mounting angle this is degrees off north to offset the grid

//properties file
Properties configFile;

color[] palette = {color(0,0,0), color(255,255,255), color(0,0,0)};
PGraphics renderer;
//PShape compass;
 float steps=25;
 float windAngle;
  float radius;
  float origin;
  float offset;
  float ox;
  float oy; 
  float dx;
  float dy;
  float st;

float mAngle = 0;//60;
String Loc="";
String lat ="";// "43.988";
String lon ="";// "-77.339";
String apikey = "fbd1afc4de45a8f5da9eb9309af9b3b4";
String url="";
float deg;
float cardinal;
float knots;
float WSO;
PImage img;
int newx;
float h;
int s;
int b;
JSONObject json;
/*
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
}*/
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
    deg = wind.getFloat("deg");
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
 
  try {
    configFile = new Properties();
    String dp = dataPath("config.properties");
    FileInputStream f = new FileInputStream(dp);
    configFile.load(f);
  } 
  catch(Exception e) {
    e.printStackTrace();
  }

  lon=configFile.getProperty("lon");
  lat=configFile.getProperty("lat");
  mAngle=Float.parseFloat(configFile.getProperty("mAngle"));

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
    configFile.setProperty("mAngle", Float.toString(mAngle));
    configFile.setProperty("lat", lat);
    configFile.setProperty("lon", lon);
    try {
      String dp = dataPath("config.properties");
      FileOutputStream f = new FileOutputStream(dp);
      configFile.store(f, null);
    }
    catch(Exception ex) {
    }
  } 
  url="http://api.openweathermap.org/data/2.5/weather?lat="+ lat +"&lon="+ lon +"&APPID="+ apikey;


  getJSON();
 
  size(640, 640);
  colorMode(HSB, 360, 100, 100);
 // newx=width/2*-1;
  h = map(knots, 0, 30, 117, 360);//maps knots from green(117 deg. hue to red 365 deg. hue)
  s=100;
  b=100;
  palette[0]=color(360-h-10,s,40);
  palette[1]=color((360-h),s,b);
  palette[2]=color((360-h-10),s,40);
 // img = createImage(1280, 1280, RGB);
//  buildImg();  
//new rendering engine
  renderer = createGraphics(width, height);
  renderer.beginDraw();
  renderer.loadPixels(); 
  windAngle=deg-90;
  radius=250;
 offset =sqrt(sq(width/2)+sq(height/2));
 origin=offset;
  ox =(width/2)+cos(radians(windAngle))*offset;
  oy =(height/2)+sin(radians(windAngle))*offset; 
  dx = ox + cos(radians(windAngle))*radius;
  dy = oy + sin(radians(windAngle))*radius; 
renderGradient();
  

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
 // opc.setStatusLed(true);
  // To efficiently set all the pixels on screen, make the set() 
  // calls on a PImage, then write the result to the screen.
  //imageMode(CENTER);
}
void draw() {
  
surface.setTitle(String.format("City:%s Wind Dir:%.1f Deg. Speed:%.1f kn",
    Loc, deg, knots));
  if (frameCount % (round(frameRate)*300)==0) {//every 5 minutes no matter the frame rate
    println("get new data");
    thread("getJSON");
    //thread("buildImg");
    //thread("renderGradient");
  }
 //newx = ((newx+40)<width/2)?newx+round(round(knots)*(1/(frameRate/15.00))):(-1 * ((width / 2) - 50));
 // translate(width/2, height/2);
 // rotate(cardinal);//in rad
//  translate(-img.width/2, -img.height/2);
 //image(img, newx, 0);
 
  renderGradient();
 
  stroke(0);
  textAlign(CENTER);
  textSize(5);
  fill(color(360-map(10, 0, 30, 117, 360),s,b));
  rect(0, 0, 10, 20);
  fill(0);
  text("10",5,13);
  fill(color(360-map(12.5, 0, 30, 117, 360),s,b));
  rect(10, 0, 10, 20);
  fill(color(360-map(15, 0, 30, 117, 360),s,b));
  rect(20, 0, 10, 20);
  fill(color(360-map(17.5, 0, 30, 117, 360),s,b));
  rect(30, 0, 10, 20);
 fill(color(360-map(20, 0, 30, 117, 360),s,b));
  rect(40,0,10,20);
  fill(0);
  text("20",45,13);
  fill(color(360-map(22.5, 0, 30, 117, 360),s,b));
  rect(50, 0, 10, 20);
  fill(color(360-map(25, 0, 30, 117, 360),s,b));
  rect(60, 0, 10, 20);
  fill(color(360-map(27.5, 0, 30, 117, 360),s,b));
  rect(70, 0, 10, 20);
 fill(color(360-map(30, 0, 30, 117, 360),s,b));
  rect(80,0,10,20);
    fill(0);
  text("30",85,13);
  textSize(15);
  textAlign(LEFT);
  fill(255);
  text(String.format("City:%s Wind Dir:%.1f Deg. Speed:%.1f kn",
    Loc, deg, knots),95,18);
  

}
void renderGradient(){
  renderer.beginDraw();
  renderer.loadPixels();
  //windspeed offset
  WSO = steps + (round(knots)*(1/(frameRate/15)));
  if(-1*offset<(origin+WSO)){
    origin=origin - WSO;
    ox =(width/2)+ cos(radians(windAngle))*origin;
    oy =(height/2)+ sin(radians(windAngle))*origin;
    dx = ox + cos(radians(windAngle))*radius;
    dy = oy + sin(radians(windAngle))*radius;
    for (int i = 0, y = 0, x; y < height; ++y) {
      for (x = 0; x < width; ++x, ++i) {
        st = project(ox, oy, dx, dy, x, y);
        renderer.pixels[i] = lerpColor(palette, st, RGB);
      }
    }
  }else {
   origin=offset;
  }
  renderer.updatePixels();
  renderer.endDraw();
  image(renderer,0,0);
  
}
color lerpColor(color[] arr, float step, int colorMode) {
  int sz = arr.length;
  if (sz == 1 || step <= 0.0) {
    return arr[0];
  } else if (step >= 1.0) {
    return arr[sz - 1];
  }
  float scl = step * (sz - 1);
  int i = int(scl);
  return lerpColor(arr[i], arr[i + 1], scl - i, colorMode);
}
float project(float originX, float originY,
  float destX, float destY,
  int pointX, int pointY) {
  // Rise and run of line.
  float odX = destX - originX;
  float odY = destY - originY;

  // Distance-squared of line.
  float odSq = odX * odX + odY * odY;

  // Rise and run of projection.
  float opX = pointX - originX;
  float opY = pointY - originY;
  float opXod = opX * odX + opY * odY;

  // Normalize and clamp range.
  return constrain(opXod / odSq, 0.0, 1.0);
}
