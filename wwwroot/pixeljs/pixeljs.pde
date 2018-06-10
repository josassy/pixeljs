//import java.util.LinkedList;



class Loc{
    int x;
    int y;
    public Loc(int x, int y){
        this.x = x;
        this.y = y;
    }

    // Adds Loc to a velocity
    Loc plus( Loc other ){
        return new Loc( x + other.x, y + other.y );
    }

    double angleTo( Loc other ){
        return Math.atan2(other.y-this.y,other.x-this.x);
    }
    double distanceTo( Loc other ){
        return Math.sqrt( Math.pow( other.x-this.x,2) + Math.pow( other.y-this.y,2) );
    }

    Loc rotateAround( Loc other, double angle ){
        double theta = other.angleTo(this) + angle;
        double r = other.distanceTo(this);
        return new Loc( (int)(r*Math.cos(theta)+other.x),(int)(r*Math.sin(theta)+other.y) );
    }
}

// Method that returns new location with less typing
Loc l( int x, int y ){
    return new Loc( x, y );
}

//Can't be just line because javascript can't tell it appart.
void lineLoc( Loc a, Loc b ){
    line( a.x, a.y, b.x, b.y );
}

class Line{
    Loc a = l(0,0);
    Loc b = l(0,0);

    Loc closestLocTo( Loc other ){
        double myAngle = a.angleTo(b);
        Loc rotated = other.rotateAround(a,-myAngle);
        Loc bRotated = b.rotateAround(a,-myAngle );
        Loc result = l(0,0);
        if( rotated.x < min(a.x,bRotated.x)){
            result = l(min(a.x,bRotated.x),a.y);
        }else if( rotated.x > max(a.x,bRotated.x)){
            result = l(max(a.x,bRotated.x),a.y);
        }else{
            result = l( rotated.x, a.y );
        }
        return result.rotateAround( a, myAngle );
    }
}

abstract class Movable{
    Loc location = l( 100, 100 );
    abstract public void draw();
    Loc size = l( 10, 10 );
    int speed = 5;
    Loc velocity = l(0,0);

    void doMove(){
        location = location.plus(velocity);
    }
}

class Wall extends Line{

    int weight = 5;

    public Wall( Loc a, Loc b ){
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
    public Pixel( Loc location ){
        this.location = location;
    }
    void draw(){
        doMove();

        fill(255);
        rect(location.x-size.x/2,location.y-size.y/2,size.x,size.y);

        for( Wall wall : walls ){
            Loc closestPoint = wall.closestLocTo( location );
            lineLoc( location, closestPoint );
        }
    }

    void keyPressed(){
        if(keyCode == UP){
            velocity.y = -speed;
        }else if(keyCode == DOWN ){
            velocity.y = speed;
        }else if(keyCode == LEFT ){
            velocity.x = -speed;
        }else if(keyCode == RIGHT ){
            velocity.x = speed;
        }else{
            lastString = "keyPress " + keyCode;
        }
    }

    void keyReleased(){
        if(keyCode == UP || keyCode == DOWN){
            velocity.y = 0;
        }else if(keyCode == LEFT || keyCode == RIGHT ){
            velocity.x = 0;
        }else{
            lastString = "keyReleased " + keyCode;
        }
    }

}

String lastString = "";

Pixel pixel = new Pixel( l(100, 100));

ArrayList<Wall> walls = new ArrayList<Wall>();

// Create new Wall object and it to the walls list
void aw( int x1, int y1, int x2, int y2 ){
    walls.add( new Wall(l(x1,y1),l(x2,y2)) );
}

void setup(){
	size(600,500);
	background(125);
	fill(255);
	frameRate(24);
	textSize(32);
	//textFont("mono.ttf", 32);

    // Create the walls
    aw(150,50,200,250);

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
    pixel.keyPressed();
}

void keyReleased(){
	pixel.keyReleased();
}
