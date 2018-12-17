void setup(){
	size(600,500);
	background(125);
	fill(255);
	frameRate(24);
	textSize(32);
	//textFont("mono.ttf", 32);

  String[] fonts = PFont.list();
  for (String font : fonts){
    println  (font);
  }
}

int x = 0;
int y = 100;
int xv = 1;
int yv = 0;
int xa = 0;
int ya = 0;
String lastString = "";

boolean b = true;

void draw(){  
	background(125);
	if( keyCode == UP ) fill(255, 0, 0);
	ellipse(x, y, 50, 50);
	fill(0, 102, 153);
	text(lastString, 20,20);
	xv += xa;
	yv += ya;
	x+=xv;
	y+=yv;
}

void keyPressed(){
	if(keyCode == UP){
		ya = -1;
	}else if(keyCode == DOWN ){
		ya = 1;
	}else if(keyCode == LEFT ){
		xa = -1;
	}else if(keyCode == RIGHT ){
		xa = 1;
	}else{
		lastString = "keyPress " + keyCode;
	}
}

void keyReleased(){
	ya=xa=0;
}
