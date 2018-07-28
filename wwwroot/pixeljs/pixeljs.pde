
class Loc{
    double x;
    double y;
    public Loc(double x, double y){
        this.x = x;
        this.y = y;
    }

    // Adds Loc to a velocity
    Loc plus( Loc other ){
        return new Loc( x + other.x, y + other.y );
    }

    Loc minus( Loc other ){
        return new Loc( x - other.x, y - other.y );
    }

    Loc times( double other ){
        return new Loc( x*other,y*other);
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

    double dotProduct( Loc other ){
        return this.x*other.x+this.y*other.y;
    }

    Loc unitLength(){
        double r = Math.sqrt( Math.pow( this.x, 2 )+Math.pow( this.y, 2 ) );
        return new Loc( this.x/r, this.y/r );
    }
    
    void draw(){
      stroke(255,0,0);
      ellipse((float)x, (float)y, 5.0, 5.0);
    }
}

// Method that returns new location with less typing
Loc l( double x, double y ){
    return new Loc( x, y );
}

// Can't be just line because javascript can't tell it apart.
void lineLoc( Loc a, Loc b ){
    line( (float)a.x, (float)a.y, (float)b.x, (float)b.y );
}

class Line{
    Loc a = l(0,0);
    Loc b = l(0,0);
    
    public Line( Loc newA, Loc newB ){
      a = newA; b = newB;
    }

    Loc aToB(){
        return b.minus(a);
    }

    Loc closestLocTo( Loc other ){
        double myAngle = a.angleTo(b);
        Loc rotated = other.rotateAround(a,-myAngle);
        Loc bRotated = b.rotateAround(a,-myAngle );
        Loc result = l(0,0);
        if( rotated.x < Math.min(a.x,bRotated.x)){
            result = l(Math.min(a.x,bRotated.x),a.y);
        }else if( rotated.x > Math.max(a.x,bRotated.x)){
            result = l(Math.max(a.x,bRotated.x),a.y);
        }else{
            result = l( rotated.x, a.y );
        }
        return result.rotateAround( a, myAngle );
    }

    Loc intersectionWith( Line other ){
        // Line AB represented as a1x + b1y = c1
        double a1 = this.b.y - this.a.y;
        double b1 = this.a.x - this.b.x;
        double c1 = a1*(this.a.x) + b1*(this.a.y);
      
        // Line CD represented as a2x + b2y = c2
        double a2 = other.b.y - other.a.y;
        double b2 = other.a.x - other.b.x;
        double c2 = a2*(other.a.x)+ b2*(other.a.y);
      
        double determinant = a1*b2 - a2*b1;
      
        if (determinant == 0){
            // The lines are parallel. This is simplified
            // by returning a pair of FLT_MAX
            return new Loc(Double.MAX_VALUE, Double.MAX_VALUE);
        }else{
            double x = (b2*c1 - b1*c2)/determinant;
            double y = (a1*c2 - a2*c1)/determinant;
            return new Loc(x, y);
        }
    }
    
    void draw(){
        stroke(255);
        lineLoc(a,b);
    }
}

class Wall extends Line{

    int weight = 5;

    public Wall( Loc a, Loc b, int weight ){
      super( a,b );
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

        Loc new_location = location.plus(velocity);

        Line step_segment = new Line(location,new_location);
        
        step_segment.draw();

        double closest_dist = Double.POSITIVE_INFINITY;
        Line selected_line = null;
        Loc hitPoint = null;

        for( Wall wall : walls ){
            hitPoint = step_segment.intersectionWith( wall );
            
            hitPoint.draw();
            
            if( hitPoint != null ){
                if( location.distanceTo(hitPoint) < closest_dist ){
                    closest_dist = location.distanceTo(hitPoint);
                    selected_line = wall;
                }
            }
        }

        if( hitPoint != null && selected_line != null ){
            new_location = hitPoint;


            Loc wallUnitLength = selected_line.aToB().unitLength();

            double speedAlongWall = velocity.dotProduct( wallUnitLength );
            velocity = wallUnitLength.times( speedAlongWall );
        }


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
            rect( (float)(location.x-size.x/2),(float)(location.y-size.y/2),(float)(size.x),(float)(size.y));
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
    aw(56,41,56,508,7);
    /*
    aw(56,41,810,42,7);
    aw(222,39,222,333,4);
    aw(813,38,618,219,3);
    aw(810,41,810,508,7);
    aw(147,148,99,254,8);
    aw(146,149,193,254,8);
    aw(352,180,551,180,3);
    aw(552,180,552,509,4);
    aw(619,219,759,219,3);
    aw(98,253,194,253,6);
    aw(470,258,394,334,3);
    aw(621,301,764,301,3);
    aw(701,301,701,509,4);
    aw(222,334,396,334,3);
    aw(471,335,394,412,3);
    aw(156,411,57,510,4);
    aw(155,412,395,412,3);
    aw(810,507,56,507,8);*/
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
