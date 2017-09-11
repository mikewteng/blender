OPC opc;
float t;
void draw()
{
  t++;
  setGradient(int(t - 100), 0, int(t), height, color(0), color(0,255,0), 1);
  if (t == width){
 t=0; 
}
}

float amplitude = 30;
float fillGap = 2.5;

void setup(){
  t=0;
  size(640, 360);
  background(0);
  opc = new OPC(this, "127.0.0.1", 7890);
  float spacing = width / 70.0;
  opc.ledGrid(0,64,8,width/2,height/2,spacing,spacing,0,true);
  

  // Make the status LED quiet
  opc.setStatusLed(true);
  // To efficiently set all the pixels on screen, make the set() 
  // calls on a PImage, then write the result to the screen.
 
} //<>//
void setGradient(int x, int y, float w, float h, color c1, color c2, int axis ) {

  noFill();

 
  
    for (int i = x; i <= x+w; i++) {
      float inter = map(i, x, x+w, 0, 1);
      color c = lerpColor(c1, c2, inter);
      stroke(c);
      line(i, y, i, y+h);
    }
  
}