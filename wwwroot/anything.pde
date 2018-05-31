void setup(){
  size(600,500);
  background(125);
  fill(255);
  frameRate(24);
  textSize(32);
  textFont("mono.ttf", 32);
}

int x = 0;
int y = 100;
int xv = 1;
int yv = 0;
String lastString = "";

void draw(){  
  background(125);
  fill(255, 0, 0);
  ellipse(x, y, 50, 50);
  fill(0, 102, 153);
  text( lastString, 20,20 );
  x+=xv;
  y+=yv;
}

void keyPressed(){
  if(false){

  }else{
    yv = 10;
    lastString = "keyPress " + value;
  }
}