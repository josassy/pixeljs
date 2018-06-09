//import java.util.LinkedList;

class Location{
    int x;
    int y;
    public Location(int x, int y){
        this.x = x;
        this.y = y;
    }
}

// Method that returns new location with less typing
Location l( int x, int y ){
    return new Location( x, y );
}

abstract class Movable{
    Location location = l( 100, 100 );
    abstract public void draw();
    Location size = l( 10, 10 );
}

class Wall{

    Location a;
    Location b;
    int weight = 5;

    public Wall( Location a, Location b ){
        this.a = a;
        this.b = b;
    }

    void draw(){
        stroke(255);
        strokeWeight(weight);
        line(a.x,a.y,b.x,b.y);
    }
}

class Pixel extends Movable{
    public Pixel( Location location ){
        this.location = location;
    }
    void draw(){
        fill(255);
        rect(location.x-size.x/2,location.y-size.y/2,size.x,size.y);
    }
}

String lastString = "";

Pixel pixel = new Pixel( l(100, 100));

ArrayList<Wall> walls = new ArrayList<Wall>();

void setup(){
	size(600,500);
	background(125);
	fill(255);
	frameRate(24);
	textSize(32);
	textFont("mono.ttf", 32);

    // Create the walls
    walls.add(new Wall(l(100,50),l(100,250)));

}

void draw(){  
	background(0);
    pixel.draw();
    for(Wall wall : walls){
        wall.draw();
    }
	fill(0, 102, 153);
	text(lastString, 20,20);
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