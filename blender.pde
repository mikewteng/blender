OPC opc;
import java.util.*;
import java.io.*;
//mounting angle this is degrees off north to offset the grid

//properties file
Properties configFile;
Date mydate;
color[] palette = {color(0,0,0), color(255,255,255), color(0,0,0)};
PGraphics renderer;
//PShape compass;
float steps=25;
float windAngle;
float radius,origin,offset,ox,oy,dx,dy,st,deg,cardinal,knots,WSO,h;
int frmRate=1;
float mAngle = 0;//60;
String Loc="";
String lat = "43.988";
String lon = "-77.339";
String apikey = "fbd1afc4de45a8f5da9eb9309af9b3b4";
String url="";
PImage img;
int newx,s,b;
JSONObject json;
void getJSON() {
  try {
    frmRate = round(frameRate) * 300;
    json = loadJSONObject(url);
    int dt = json.getInt("dt");
    mydate = new java.util.Date(dt * 1000L);//date of reading
 //   JSONObject coord = json.getJSONObject("coord");
    JSONObject sys = json.getJSONObject("sys");
    Loc = json.getString("name") +", "+ sys.getString("country");
    JSONObject wind =  json.getJSONObject("wind");
    knots = (1.94384) * (wind.getFloat("speed"));//in m/s (1.94384)
    deg = wind.getFloat("deg");
    cardinal = (deg + mAngle)*TWO_PI/360;
   /* println(mydate);
    println("lat:" + lat);
    println("lon:" + lon);
    println(coord);
    println(Loc);
    println(deg+" Degrees");
    println(knots +" Kn");
    */
  }
  catch(Exception ex) {
   // println(ex);
    knots=1;
    cardinal=1;
  }
}
void getConfigJSON(){
 json = loadJSONObject("http://192.168.1.23:5000");
 lon=(json.getJSONArray("lon")).getString(0);
 lat=(json.getJSONArray("lat")).getString(0);
  url="http://api.openweathermap.org/data/2.5/weather?lat="+ lat +"&lon="+ lon +"&APPID="+ apikey;
  getJSON();
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

  //lon=configFile.getProperty("lon");
  //lat=configFile.getProperty("lat");
    mAngle=Float.parseFloat(configFile.getProperty("mAngle"));
//  url="http://api.openweathermap.org/data/2.5/weather?lat="+ lat +"&lon="+ lon +"&APPID="+ apikey;
 // getJSON();
    getConfigJSON();
    size(640, 640);
    colorMode(HSB, 360, 100, 100);
    h = map(knots, 0, 30, 117, 360);//maps knots from green(117 deg. hue to red 365 deg. hue)
    s=100;
    b=100;
    palette[0]=color(360-h-10,s,40);
    palette[1]=color((360-h),s,b);
    palette[2]=color((360-h-10),s,40); 
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
    for (int ind = 0; ind<2; ind++) {
      opc.ledStrip((ind * 16), 16, (width / 2), vpos, spacing, radians(180), ((ind % 2)>0));
      vpos += vspace;
    }
  //opc.ledGrid(0 ,64 ,6 ,(width / 2) + (32 * spacing),height/2,spacing,height/8,0,false);
}
void draw() {
  surface.setTitle(String.format("City:%s Wind Dir:%.1f Deg. Speed:%.1f kn at %s",
  Loc, deg, knots,mydate));
  if (frameCount % frmRate<1) {//every 5 minutes no matter the frame rate
    thread("getConfigJSON");
  }
  renderGradient();
//legend for speed
  stroke(0);
  textAlign(CENTER);
  textSize(5);
  fill(color(360-map(0, 0, 30, 117, 360),s,b));
  rect(0, 0, 10, 20);
  fill(color(360-map(10, 0, 30, 117, 360),s,b));
  rect(10, 0, 10, 20);
  fill(0);
  text("10",15,13);
  fill(color(360-map(12.5, 0, 30, 117, 360),s,b));
  rect(20, 0, 10, 20);
  fill(color(360-map(15, 0, 30, 117, 360),s,b));
  rect(30, 0, 10, 20);
  fill(color(360-map(17.5, 0, 30, 117, 360),s,b));
  rect(40, 0, 10, 20);
 fill(color(360-map(20, 0, 30, 117, 360),s,b));
  rect(50,0,10,20);
  fill(0);
  text("20",55,13);
  fill(color(360-map(22.5, 0, 30, 117, 360),s,b));
  rect(60, 0, 10, 20);
  fill(color(360-map(25, 0, 30, 117, 360),s,b));
  rect(70, 0, 10, 20);
  fill(color(360-map(27.5, 0, 30, 117, 360),s,b));
  rect(80, 0, 10, 20);
 fill(color(360-map(30, 0, 30, 117, 360),s,b));
  rect(90,0,10,20);
    fill(0);
  text("30",95,13);
  textSize(15);
  textAlign(LEFT);
  fill(255);
  text(String.format("City:%s Wind Dir:%.1f Deg. Speed:%.1f kn at %s ",
    Loc, deg, knots, mydate),105,18);
  

}
void renderGradient(){
  renderer.beginDraw();
  renderer.loadPixels();
  windAngle=deg-90;
  h = map(knots, 0, 30, 117, 360);//maps knots from green(117 deg. hue to red 365 deg. hue)
  s=100;
  b=100;
  palette[0]=color(360-h-10,s,40);
  palette[1]=color((360-h),s,b);
  palette[2]=color((360-h-10),s,40); 
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