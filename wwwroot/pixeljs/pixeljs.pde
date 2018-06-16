
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

// Can't be just line because javascript can't tell it apart.
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

class Wall extends Line{

    int weight = 5;

    public Wall( Loc a, Loc b, int weight ){
        this.a = a;
        this.b = b;
        this.weight = weight;
    }

    void draw(){
        stroke(255);
        strokeWeight(weight);
        lineLoc(a,b);
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

class Pixel extends Movable{
    public Pixel( Loc location ){
        this.location = location;
    }
    void draw(){
        // Call inherited Movable method
        doMove();

        // Draw line to closest wall
        for( Wall wall : walls ){
            stroke(255,0,0); // Change line color to Red
            strokeWeight(1); // Change line weight to 1 px
            Loc closestPoint = wall.closestLocTo( location );
            lineLoc( location, closestPoint );

        // Draw Pixel
        stroke(255);
        fill(255);
        rect(location.x-size.x/2,location.y-size.y/2,size.x,size.y);
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
void aw( int x1, int y1, int x2, int y2, int weight ){
    walls.add( new Wall(l(x1,y1),l(x2,y2), weight) );
}

void setup(){
	size(865,559);
	background(125);
	fill(255);
	frameRate(24);
	textSize(32);
	//textFont("mono.ttf", 32);

    // Create the walls
    aw(226,87,224,342,4);
    aw(245,85,544,86,3);
    aw(363,137,522,137,1);
    aw(601,181,699,202,1);
    aw(420,219,580,349,1);
    aw(318,272,318,418,1);
    aw(181,285,374,285,1);
    aw(677,295,677,318,1);
    aw(676,322,676,362,1);
    aw(675,366,675,385,1);
    aw(65,377,384,377,1);
    aw(543,403,666,406,3);
    aw(594,400,480,423,2);
    aw(613,400,718,427,2);
    aw(476,429,461,460,2);
    aw(725,437,728,464,3);
    aw(462,455,510,491,2);
    aw(728,463,655,497,2);
    aw(494,485,624,502,2);
    aw(558,500,685,490,2);
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
