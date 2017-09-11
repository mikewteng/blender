import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import java.util.*; 
import java.io.*; 
import java.net.*; 
import java.util.Arrays; 

import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.File; 
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 

public class blender extends PApplet {

OPC opc; //<>//
//import java.util.Date;


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
public void buildImg() {
  img.loadPixels();
  float w = 0;
  for (int y=0; y<img.height; y++) {
    for (int x=0; x<img.width; x++) {
      int index = x + y * img.width;
      if (x >= (.75f*(img.width/2))) {
        if (x <= (img.width/2)) {
          w = (w + 4);
        } else {
          w = (w-4);
        }
      } else {
        w = 0;
      }
      float b = (w>0)? map(w, 0, (img.width/2), 0, 100):1;//brightness percentage
      int c = color((360 - h), s, b);
      // println(hex(c));
      img.pixels[index] = c;
    }
  }
  img.updatePixels();
}
public void getJSON() {
  try {
    json = loadJSONObject(url);
    int dt = json.getInt("dt");
    Date mydate = new java.util.Date(dt * 1000L);//date of reading
    JSONObject coord = json.getJSONObject("coord");
    JSONObject sys = json.getJSONObject("sys");
    Loc = json.getString("name") +", "+ sys.getString("country");
    JSONObject wind =  json.getJSONObject("wind");
    knots = (1.94384f) * (wind.getFloat("speed"));//in m/s (1.94384)
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
public void setup() {
  try {
    configFile = new Properties();
    String dp = dataPath("config.properties");
    FileInputStream f = new FileInputStream(dp);
    configFile.load(f);
   // println(configFile);
  } 
  catch(Exception e) {
    e.printStackTrace();
  }
  /*
    REFERENCE FOR CONFIG FILE PARSING
   AREA = configFile.getProperty("AREA");
   
   overlayY = Integer.parseInt(configFile.getProperty("OVERLAY_Y"));
   overlayX = Integer.parseInt(configFile.getProperty("OVERLAY_X"));
   */
  //stroke(255);
  //fill(255);
  lon=configFile.getProperty("lon");
  lat=configFile.getProperty("lat");
  mAngle=Float.parseFloat(configFile.getProperty("mAngle"));

  //if angle is passed as arg use it...
  if (args != null) {
    for (int arrg=0; arrg<args.length; arrg++) {
      println(args[arrg]);
    }
    println(args[0]);
    mAngle =PApplet.parseFloat(args[0]);
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
  background(1, 1, 1);
  
  colorMode(HSB, 360, 100, 100);
  newx=width/2*-1;
  //  knots=round(5);//get from api
  //  cardinal=(deg+60)*TWO_PI/360;//get from api lights are offset 60 deg from north
  h = map(knots, 0, 30, 117, 360);//maps knots from green(117 deg. hue to red 365 deg. hue) //<>//
  s=100;
  b=0; //<>//
  img = createImage(1280, 1280, RGB); //<>//
  thread("buildImg");  
  opc = new OPC(this, "127.0.0.1", 7890);
  float spacing = width / 20.0f;
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
public void draw() {
  // strokeWeight(5);
  //line(width / 4,height / 2,3 * width / 4, height / 2);

  if (frameCount % (round(frameRate)*300)==0) {//every 5 minutes no matter the frame rate
    println("get new data");
    thread("getJSON");
    thread("buildImg");
  }
  newx = (newx<width/2)?newx+round(round(knots)*(1/(frameRate/15.00f))):(-1 * ((width / 2) - 50));
  translate(width/2, height/2);
  rotate(cardinal);//in rad
  translate(-img.width/2, -img.height/2);
  image(img, newx, 0);
}
/*
 * Simple Open Pixel Control client for Processing,
 * designed to sample each LED's color from some point on the canvas.
 *
 * Micah Elizabeth Scott, 2013
 * This file is released into the public domain.
 */




public class OPC
{
  Socket socket;
  OutputStream output;
  String host;
  int port;

  int[] pixelLocations;
  byte[] packetData;
  byte firmwareConfig;
  String colorCorrection;
  boolean enableShowLocations;

  OPC(PApplet parent, String host, int port)
  {
    this.host = host;
    this.port = port;
    this.enableShowLocations = true;
    parent.registerMethod("draw",this);
  }

  // Set the location of a single LED
  public void led(int index, int x, int y)  
  {
    // For convenience, automatically grow the pixelLocations array. We do want this to be an array,
    // instead of a HashMap, to keep draw() as fast as it can be.
    if (pixelLocations == null) {
      pixelLocations = new int[index + 1];
    } else if (index >= pixelLocations.length) {
      pixelLocations = Arrays.copyOf(pixelLocations, index + 1);
    }

    pixelLocations[index] = x + width * y;
  }
  
  // Set the location of several LEDs arranged in a strip.
  // Angle is in radians, measured clockwise from +X.
  // (x,y) is the center of the strip.
  public void ledStrip(int index, int count, float x, float y, float spacing, float angle, boolean reversed)
  {
    float s = sin(angle);
    float c = cos(angle);
    for (int i = 0; i < count; i++) {
      led(reversed ? (index + count - 1 - i) : (index + i),
        (int)(x + (i - (count-1)/2.0f) * spacing * c + 0.5f),
        (int)(y + (i - (count-1)/2.0f) * spacing * s + 0.5f));
    }
  }

  // Set the location of several LEDs arranged in a grid. The first strip is
  // at 'angle', measured in radians clockwise from +X.
  // (x,y) is the center of the grid.
  public void ledGrid(int index, int stripLength, int numStrips, float x, float y,
               float ledSpacing, float stripSpacing, float angle, boolean zigzag)
  {
    float s = sin(angle + HALF_PI);
    float c = cos(angle + HALF_PI);
    for (int i = 0; i < numStrips; i++) {
      ledStrip(index + stripLength * i, stripLength,
        x + (i - (numStrips-1)/2.0f) * stripSpacing * c,
        y + (i - (numStrips-1)/2.0f) * stripSpacing * s, ledSpacing,
        angle, zigzag && (i % 2) == 1);
    }
  }

  // Set the location of 64 LEDs arranged in a uniform 8x8 grid.
  // (x,y) is the center of the grid.
  public void ledGrid8x8(int index, float x, float y, float spacing, float angle, boolean zigzag)
  {
    ledGrid(index, 8, 8, x, y, spacing, spacing, angle, zigzag);
  }

  // Should the pixel sampling locations be visible? This helps with debugging.
  // Showing locations is enabled by default. You might need to disable it if our drawing
  // is interfering with your processing sketch, or if you'd simply like the screen to be
  // less cluttered.
  public void showLocations(boolean enabled)
  {
    enableShowLocations = enabled;
  }
  
  // Enable or disable dithering. Dithering avoids the "stair-stepping" artifact and increases color
  // resolution by quickly jittering between adjacent 8-bit brightness levels about 400 times a second.
  // Dithering is on by default.
  public void setDithering(boolean enabled)
  {
    if (enabled)
      firmwareConfig &= ~0x01;
    else
      firmwareConfig |= 0x01;
    sendFirmwareConfigPacket();
  }

  // Enable or disable frame interpolation. Interpolation automatically blends between consecutive frames
  // in hardware, and it does so with 16-bit per channel resolution. Combined with dithering, this helps make
  // fades very smooth. Interpolation is on by default.
  public void setInterpolation(boolean enabled)
  {
    if (enabled)
      firmwareConfig &= ~0x02;
    else
      firmwareConfig |= 0x02;
    sendFirmwareConfigPacket();
  }

  // Put the Fadecandy onboard LED under automatic control. It blinks any time the firmware processes a packet.
  // This is the default configuration for the LED.
  public void statusLedAuto()
  {
    firmwareConfig &= 0x0C;
    sendFirmwareConfigPacket();
  }    

  // Manually turn the Fadecandy onboard LED on or off. This disables automatic LED control.
  public void setStatusLed(boolean on)
  {
    firmwareConfig |= 0x04;   // Manual LED control
    if (on)
      firmwareConfig |= 0x08;
    else
      firmwareConfig &= ~0x08;
    sendFirmwareConfigPacket();
  } 

  // Set the color correction parameters
  public void setColorCorrection(float gamma, float red, float green, float blue)
  {
    colorCorrection = "{ \"gamma\": " + gamma + ", \"whitepoint\": [" + red + "," + green + "," + blue + "]}";
    sendColorCorrectionPacket();
  }
  
  // Set custom color correction parameters from a string
  public void setColorCorrection(String s)
  {
    colorCorrection = s;
    sendColorCorrectionPacket();
  }

  // Send a packet with the current firmware configuration settings
  public void sendFirmwareConfigPacket()
  {
    if (output == null) {
      // We'll do this when we reconnect
      return;
    }
 
    byte[] packet = new byte[9];
    packet[0] = 0;          // Channel (reserved)
    packet[1] = (byte)0xFF; // Command (System Exclusive)
    packet[2] = 0;          // Length high byte
    packet[3] = 5;          // Length low byte
    packet[4] = 0x00;       // System ID high byte
    packet[5] = 0x01;       // System ID low byte
    packet[6] = 0x00;       // Command ID high byte
    packet[7] = 0x02;       // Command ID low byte
    packet[8] = firmwareConfig;

    try {
      output.write(packet);
    } catch (Exception e) {
      dispose();
    }
  }

  // Send a packet with the current color correction settings
  public void sendColorCorrectionPacket()
  {
    if (colorCorrection == null) {
      // No color correction defined
      return;
    }
    if (output == null) {
      // We'll do this when we reconnect
      return;
    }

    byte[] content = colorCorrection.getBytes();
    int packetLen = content.length + 4;
    byte[] header = new byte[8];
    header[0] = 0;          // Channel (reserved)
    header[1] = (byte)0xFF; // Command (System Exclusive)
    header[2] = (byte)(packetLen >> 8);
    header[3] = (byte)(packetLen & 0xFF);
    header[4] = 0x00;       // System ID high byte
    header[5] = 0x01;       // System ID low byte
    header[6] = 0x00;       // Command ID high byte
    header[7] = 0x01;       // Command ID low byte

    try {
      output.write(header);
      output.write(content);
    } catch (Exception e) {
      dispose();
    }
  }

  // Automatically called at the end of each draw().
  // This handles the automatic Pixel to LED mapping.
  // If you aren't using that mapping, this function has no effect.
  // In that case, you can call setPixelCount(), setPixel(), and writePixels()
  // separately.
  public void draw()
  {
    if (pixelLocations == null) {
      // No pixels defined yet
      return;
    }
 
    if (output == null) {
      // Try to (re)connect
      connect();
    }
    if (output == null) {
      return;
    }

    int numPixels = pixelLocations.length;
    int ledAddress = 4;

    setPixelCount(numPixels);
    loadPixels();

    for (int i = 0; i < numPixels; i++) {
      int pixelLocation = pixelLocations[i];
      int pixel = pixels[pixelLocation];

      packetData[ledAddress] = (byte)(pixel >> 16);
      packetData[ledAddress + 1] = (byte)(pixel >> 8);
      packetData[ledAddress + 2] = (byte)pixel;
      ledAddress += 3;

      if (enableShowLocations) {
        pixels[pixelLocation] = 0xFFFFFF ^ pixel;
      }
    }

    writePixels();

    if (enableShowLocations) {
      updatePixels();
    }
  }
  
  // Change the number of pixels in our output packet.
  // This is normally not needed; the output packet is automatically sized
  // by draw() and by setPixel().
  public void setPixelCount(int numPixels)
  {
    int numBytes = 3 * numPixels;
    int packetLen = 4 + numBytes;
    if (packetData == null || packetData.length != packetLen) {
      // Set up our packet buffer
      packetData = new byte[packetLen];
      packetData[0] = 0;  // Channel
      packetData[1] = 0;  // Command (Set pixel colors)
      packetData[2] = (byte)(numBytes >> 8);
      packetData[3] = (byte)(numBytes & 0xFF);
    }
  }
  
  // Directly manipulate a pixel in the output buffer. This isn't needed
  // for pixels that are mapped to the screen.
  public void setPixel(int number, int c)
  {
    int offset = 4 + number * 3;
    if (packetData == null || packetData.length < offset + 3) {
      setPixelCount(number + 1);
    }

    packetData[offset] = (byte) (c >> 16);
    packetData[offset + 1] = (byte) (c >> 8);
    packetData[offset + 2] = (byte) c;
  }
  
  // Read a pixel from the output buffer. If the pixel was mapped to the display,
  // this returns the value we captured on the previous frame.
  public int getPixel(int number)
  {
    int offset = 4 + number * 3;
    if (packetData == null || packetData.length < offset + 3) {
      return 0;
    }
    return (packetData[offset] << 16) | (packetData[offset + 1] << 8) | packetData[offset + 2];
  }

  // Transmit our current buffer of pixel values to the OPC server. This is handled
  // automatically in draw() if any pixels are mapped to the screen, but if you haven't
  // mapped any pixels to the screen you'll want to call this directly.
  public void writePixels()
  {
    if (packetData == null || packetData.length == 0) {
      // No pixel buffer
      return;
    }
    if (output == null) {
      // Try to (re)connect
      connect();
    }
    if (output == null) {
      return;
    }

    try {
      output.write(packetData);
    } catch (Exception e) {
      dispose();
    }
  }

  public void dispose()
  {
    // Destroy the socket. Called internally when we've disconnected.
    if (output != null) {
      println("Disconnected from OPC server");
    }
    socket = null;
    output = null;
  }

  public void connect()
  {
    // Try to connect to the OPC server. This normally happens automatically in draw()
    try {
      socket = new Socket(host, port);
      socket.setTcpNoDelay(true);
      output = socket.getOutputStream();
      println("Connected to OPC server");
    } catch (ConnectException e) {
      dispose();
    } catch (IOException e) {
      dispose();
    }
    
    sendColorCorrectionPacket();
    sendFirmwareConfigPacket();
  }
}
  public void settings() {  size(640, 640); }
  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "--present", "--window-color=#666666", "--hide-stop", "blender" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}
