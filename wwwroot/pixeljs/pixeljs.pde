//processing.js doesn't like Double.MAX_VALUE
float FLOAT_MAX_VALUE = 3.4028234663852886E38;

boolean levelEditMode = false;
EditableThing selectedThing = null;

class Level{
    Pixel pixel = new Pixel();
    ArrayList<Wall> walls = new ArrayList<Wall>();
    ArrayList<MapObject> mapObjects = new ArrayList<MapObject>();
    Level nextLevel = null;
    
    public void reset(){
        pixel.reset();
        for( MapObject mapObject : mapObjects )mapObject.reset();
        for( Wall wall : walls ) wall.reset();
        displayBox.reset();
        isPlaying = true;
    }
    
    public void crash(){
        isPlaying = false;
    }
    
    public String mapConstruct(){
       String result = "";
       result += pixel.mapConstruct();
       for( Wall wall : walls ) result += wall.mapConstruct();
       for( MapObject mapObject : mapObjects ) result += mapObject.mapConstruct();
       return result;
    }

}
Level currentLevel = new Level();

Level firstLevel = currentLevel;

class Loc{
    double x;
    double y;
    public Loc(double x, double y){
        this.x = x;
        this.y = y;
    }
    
    public String toString(){
        return "(" + x + "," + y + ")";
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
    
    Loc copy(){
        return new Loc(this.x, this.y);
    }
}

// Method that returns new location with less typing
Loc l( double x, double y ){
    return new Loc( x, y );
}

// Convert polar coordinates to rectangular coordinates
Loc lAng( double r, double ang ){
    return new Loc( r*Math.cos(ang), r*Math.sin(ang) );
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

    public String toString(){
      return "" + a + "->" + b;
    }

    public boolean isMoreVertical(){
      return Math.abs(this.a.y-this.b.y) > Math.abs(this.a.x-this.b.x); 
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
    
    //This intersection method makes sure it doesn't return a point
    //if the point is off either of the lines.
    Loc intersectionWith( Line other ){
        Loc intersection = this.infiniteIntersectionWith(other);
        
        
        //Check if the point is off this line
        
        //If this is more vertical check along y
        if( this.isMoreVertical() ){
            if( intersection.y < Math.min( this.a.y, this.b.y ) ) return null;
            if( intersection.y > Math.max( this.a.y, this.b.y ) ) return null;
        }else{
            //otherwise check along x
            if( intersection.x < Math.min( this.a.x, this.b.x ) ) return null;
            if( intersection.x > Math.max( this.a.x, this.b.x ) ) return null;
        }
        
        //or the other.
        
        //If other is more vertical check along y
        if( other.isMoreVertical() ){
            if( intersection.y < Math.min( other.a.y, other.b.y ) ) return null;
            if( intersection.y > Math.max( other.a.y, other.b.y ) ) return null;
        }else{
            //otherwise check along x
            if( intersection.x < Math.min( other.a.x, other.b.x ) ) return null;
            if( intersection.x > Math.max( other.a.x, other.b.x ) ) return null;
        }
        
        //if the point isn't off this line or the other then it is a valid
        //intersection
        return intersection;
    }

    // https://www.geeksforgeeks.org/program-for-point-of-intersection-of-two-lines/
    Loc infiniteIntersectionWith( Line other ){
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
            return new Loc(FLOAT_MAX_VALUE, FLOAT_MAX_VALUE);
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

interface EditableThing{
  void delete();
  void trySelect( Loc loc );
  void edit_copy();
}

class Wall extends Line implements EditableThing{

    int weight = 5;

    public Wall( Loc a, Loc b, int weight ){
        super( a,b );
        this.weight = weight;
    }

    void draw(){
        if( levelEditMode && selectedThing == this ){
          stroke(100);
          
          if( mousePressed ){
            Loc pmouse = l(pmouseX,pmouseY);
            Loc mouse = l(mouseX,mouseY);
            Loc moveAmount = mouse.minus(pmouse);
            if( pmouse.distanceTo( a ) < weight*.6 ){
              a = a.plus(moveAmount);;
            }else if( pmouse.distanceTo( b ) < weight*.6 ){
              b = b.plus(moveAmount);
            }else{
              Loc bestHit = this.closestLocTo( pmouse );
              if( bestHit.distanceTo( pmouse ) < weight*.6 ){
                a = a.plus(moveAmount);
                b = b.plus(moveAmount);
              }
            }
          }
        }else{
          stroke(255);
        }
        strokeCap(SQUARE);
        strokeWeight(weight);
        lineLoc(a,b);
    }
    
    void delete(){
      currentLevel.walls.remove(this);
    }
    void edit_copy(){
      Loc middle = a.plus(b).times(.5);
      Loc mouse = l(mouseX,mouseY);
      Loc middleToMouse = mouse.minus(middle);
      Wall newWall = new Wall( a.plus(middleToMouse), b.plus(middleToMouse), weight );
      currentLevel.walls.add(newWall);
    }
    
    void trySelect( Loc loc ){
      Loc bestHit = this.closestLocTo( loc );
      if( bestHit.distanceTo( loc ) < weight*.6 ) selectedThing = this;
    }
    
    void reset(){}
    
    String mapConstruct(){
      return "aw( " + (int)a.x + "," + (int)a.y + "," + (int)b.x + "," + (int)b.y + "," + (int)weight + " );\n";
    }
}

class Door extends Wall{
  Loc startingB = l(0,0);
  
  boolean opening = false;
  double openSpeed = 3;
  Switch switch_ = null;
  
  public Door( Loc a, Loc b, int weight ){
    super(a,b,weight);
    startingB = b.copy();
  }
  
  void draw(){
    if( opening ){
      double length = b.distanceTo(a);
      if( length > openSpeed ){
        b = a.minus(b).unitLength().times(openSpeed).plus(b);
      }else if( length > 0 ){
        b = a.copy();
      }else{
        opening = false;
      }
    }
    super.draw();
  }
 
  void reset(){
    b = startingB.copy();
    opening = false;
  } 
  
  void delete(){
    super.delete();
    if( switch_ != null ) switch_.doors.remove(this);
  }
  
  String mapConstruct(){
    //Let the switches print our add command if we are connected so that the commands come in the right order.
    if(switch_ == null) return "addDoor( " + (int)a.x + "," + (int)a.y + "," + (int)startingB.x + "," + (int)startingB.y + "," + (int)weight + " );\n";
    return "";
  }
  
  void edit_copy(){
      Loc middle = a.plus(startingB).times(.5);
      Loc mouse = l(mouseX,mouseY);
      Loc middleToMouse = mouse.minus(middle);
      Loc newA = a.plus(middleToMouse);
      Loc newStartingB = startingB.plus(middleToMouse);
      //AddDoor takes care of connecting the new switch.
      addDoor( (int)newA.x, (int)newA.y, (int)newStartingB.x, (int)newStartingB.y, (int)weight );
   }
}

abstract class MapObject implements EditableThing{
    Loc location = l( 100, 100 );

    public void draw(){
      if( levelEditMode ){
        if( selectedThing == this ){
          stroke( 230 );
          strokeWeight( 10 );
          ellipse( (float)location.x, (float)location.y, (float)size.x*2, (float)size.y*2 );
          
          //implement drag
          if( mousePressed && contains( l( pmouseX, pmouseY ) ) ){
            location.x += mouseX-pmouseX;
            location.y += mouseY-pmouseY;
            setStartLocation( location );
          }
        }
      }
    }
    Loc size = l( 10, 10 );
    abstract public void activate();

    public void reset(){}
   
    public void setStartLocation( Loc loc ){
      location = loc.copy();
    }
    
    void bumpCheck( MapObject other ){
        if( other.location.distanceTo( this.location ) < (other.size.x+this.size.x)/2 ){
            this.activate();
        }
    }
    
    public void delete(){
      currentLevel.mapObjects.remove(this);
    }
    
    boolean contains( Loc loc ){
      if( loc.x < location.x-size.x*.5 ) return false;
      if( loc.x > location.x+size.x*.5 ) return false;
      if( loc.y < location.y-size.y*.5 ) return false;
      if( loc.y > location.y+size.y*.5 ) return false;
      return true;
    }
    void trySelect( Loc loc ){
      if( contains( loc ) ) selectedThing = this;
    }
    
    void edit_copy(){
      MapObject newCopy = copy();
      newCopy.setStartLocation( l(mouseX,mouseY) );
      newCopy.size = this.size.copy();
      currentLevel.mapObjects.add( newCopy );
    }
    
    abstract MapObject construct_new();
 
    MapObject copy(){
      MapObject n = construct_new();
      n.size = this.size.copy();
      n.location = this.location.copy();
      return n;
    }
    
    abstract String functionName();
    String mapConstruct(){ return functionName() + "(" + (int)location.x + "," + (int)location.y + ");\n"; }
}

class Exit extends MapObject{
  
    public Exit(){
      size = l( 25, 25 );
    }

    public void draw(){
        super.draw();
        fill(0,0,0);
        strokeWeight( 1 );
        ellipse( (float)location.x, (float)location.y, (float)size.x, (float)size.y );
    }
    public void activate(){
        displayBox.addMessage("Congrats, you found the exit!");
        gotoNextLevel();
    }
    public MapObject construct_new() { return new Exit(); }
    public String functionName(){ return "addExit"; }
}


Switch lastSwitch = null;
class Switch extends MapObject{
  ArrayList<Door> doors = new ArrayList<Door>();
  
  public Switch(){
    size = l( 25,25 );
    lastSwitch = this;
  }
  
  public void draw(){
    super.draw();
    strokeWeight( 1 );
    rect( (float)(location.x-size.x*.5), (float)(location.y-size.y*.5), (float)size.x, (float)size.y );
  }
  
  public void activate(){
    displayBox.addMessage( "Congrats, you found a switch!");
    for( Door door : doors )door.opening = true;
  }
  
  public MapObject construct_new(){ return new Switch(); }
  public String functionName(){ return "addSwitch"; }
  
  public String mapConstruct(){
    String result = super.mapConstruct();
    for( Door door: doors ){
      result += "addDoor(" + (int)door.a.x + "," + (int)door.a.y + "," + (int)door.startingB.x + "," + (int)door.startingB.y + "," + (int)door.weight + ");\n"; 
      
    }
    return result;
  }
}
    


class Gold extends MapObject{
    boolean isVisible = true;
    
    public void draw(){
        super.draw();
        if (isVisible){     
        fill(255,214,19);
        strokeWeight( 1 );
        rect( (float)(location.x-size.x*.5), (float)(location.y-size.y*.5), (float)size.x, (float)size.y );
        }
    }
    public void activate(){
        //TODO: score++;
        displayBox.addMessage("You hit Gold! Time +1");
        isVisible = false;
    }  
    public void reset(){
        super.reset();
        isVisible = true;
    }
    
    public MapObject construct_new() { return new Gold(); }
    public String functionName(){ return "addGold"; }
}

Movable lastMovable = null;
abstract class Movable extends MapObject{
    int speed = 10;
    Loc velocity = l(0,0); 
    Loc startLocation = l( 0, 0 ); // Default value of 0,0. Set starting location using setStartLocation().
    
    public Movable(){
      lastMovable = this;
    }
    
    void setStartLocation( Loc newStartLocation ){
        startLocation = newStartLocation;
        location = startLocation.copy();
    }
    
    void reset(){
        location = startLocation.copy(); 
        velocity = l(0,0);
    }
    
    void doMove(){
    
      if( !levelEditMode ){
          Loc newLocation = location.plus(velocity);
          
          
          /*
          //first make sure we don't actually cross any lines.
          Line step = new Line( location, newLocation );
          for( Wall wall : walls ){
            Loc intersection = step.intersectionWith(wall);
            if( intersection != null ){
              //be a bit back so we aren't sitting right on the wall
              newLocation = intersection.plus(location.minus(intersection).unitLength().times(2));
              step = new Line( location, newLocation );
            }
          }
          */
         
          
          //now deal with the thickness of the wall and movable.
          final int numberOfIterations = 5;
          boolean didHit = true;
          for( int i = 0; i < numberOfIterations && didHit; ++i ){
              didHit = false;
              for( Wall wall : currentLevel.walls ){
                  Loc closestPoint = wall.closestLocTo( newLocation );
                  
                  double dist = newLocation.distanceTo(closestPoint);
                  
                  //do we bump into this wall?
                  double overlap = .5*(size.x+wall.weight)-dist;
                  if( overlap > 0 ){
                      //move back till we are not bumping.  
                      newLocation = newLocation.plus( location.minus(closestPoint).unitLength().times(overlap) );
                      didHit = true;
                  }
              }
          }
          
          location = newLocation;
      }
    }
}

abstract class Bot extends Movable{
    double startAngle = 0;
    double angle = 0;
    public Bot(){
        this.speed = 12;
        this.size = l(25,25);
    }
    void setStartAngle( double newAngle ){
        angle = newAngle;
        startAngle = newAngle;
    }
    void activate(){
        displayBox.addMessage("You got hit by a Bot! Press 'r' to restart or ESC to exit.");
        currentLevel.crash();
    }
    void reset(){
        super.reset();
        angle = startAngle;
    }
    String mapConstruct(){ return super.mapConstruct() + "setSpeed( " + speed + " );\n"; }
}

class TriggerBot extends Bot{
    void draw(){
        super.draw();
        //Figure out our trigger line.
        //It extends in the direction we are pointing to
        //the nearest wall or 800.
        Loc otherEnd = this.location.plus( lAng(800,angle) );
        Line triggerLine = new Line( this.location, otherEnd );
        Loc closestWallPoint = null;
        for( Wall wall : currentLevel.walls ){
            Loc intersection = triggerLine.intersectionWith(wall);
            if( (intersection != null) &&
                (closestWallPoint == null ||
                    this.location.distanceTo(intersection) <
                    this.location.distanceTo(closestWallPoint)) ){
                closestWallPoint = intersection;
            }
        }
        if( closestWallPoint != null ) triggerLine = new Line( this.location, closestWallPoint );

        //now check if the pixel is currently going to step over it
        //put a 2x on it to make it just a tad more sensitive.
        Loc pixelNewLocation = currentLevel.pixel.location.plus( currentLevel.pixel.velocity.times(2) );
        Line pixelStep = new Line( currentLevel.pixel.location, pixelNewLocation );

        if( triggerLine.intersectionWith(pixelStep) != null ){
            //Charge!!
            this.velocity = lAng( speed, angle );
            displayBox.addMessage("The bot sees you!");
        }

        doMove();

        //now actually draw the bot. //<>// //<>// //<>//
        fill(211, 0, 24); // red
        noStroke();
        ellipse( (float)location.x, (float)location.y, (float)size.x, (float)size.y );
        Loc lineOtherEnd = lAng(size.x/2,angle).plus( location );
        stroke(255);
        strokeWeight( 2 );
        line( (float)location.x, (float)location.y, (float)lineOtherEnd.x, (float)lineOtherEnd.y );        
    } 
    
    public MapObject construct_new() { return new TriggerBot(); }
    public String functionName(){ return "addTriggerBot"; }
    String mapConstruct(){ return functionName() + "(" + (int)location.x + "," + (int)location.y + "," + angle + ");\nsetSpeed( " + speed + ");\n"; }
}

PathBot lastPathBot = null;
class PathBot extends Bot{
  ArrayList< Loc > path = new ArrayList< Loc >();
  boolean forward = true;
  int index = 1;
  public PathBot(){
    lastPathBot = this;
  }
  void draw(){
    super.draw();
    if( path.size() > 0 ){
      Loc waypoint = this.path.get(this.index);
      //check if we are close enough to our target to turn to the next waypoint.
      while( this.location.distanceTo( waypoint ) < this.speed ){
        if( index == path.size()-1 ) forward = false; //<>//
        if( index == 0 ) forward = true;
        if( forward ){
          index++;
        }else{
          index--;
        }
        waypoint = this.path.get(this.index);
      }
      doMove();
      
      //point our robot at the next location
      this.angle = this.location.angleTo( waypoint );
      this.velocity = lAng( this.speed, this.angle );
    }
    
    
    //now actually draw the bot. //<>// //<>//
    fill(0, 211, 24); // green?  Josiah, change this how you like it.
    noStroke();
    ellipse( (float)location.x, (float)location.y, (float)size.x, (float)size.y );
    Loc lineOtherEnd = lAng(size.x/2,angle).plus( location );
    stroke(255);
    strokeWeight( 2 );
    line( (float)location.x, (float)location.y, (float)lineOtherEnd.x, (float)lineOtherEnd.y );     
  }
  void reset(){
    super.reset();
    index = 1;
    forward = true;
  }
  public MapObject construct_new() { return new PathBot(); }
  
  public String functionName(){ return "addPathBot"; }
    
  String mapConstruct(){
    String result = super.mapConstruct();
    for( Loc waypoint : path ) result += "addPathBotWayPoint(" + (int)waypoint.x + "," + (int)waypoint.y + ");\n";
     return result; 
  }
}

//int score = 0 // THIS IS SUPER BAD DON'T TRY THIS AT HOME
class Pixel extends Movable{      
    
    public Pixel(){
        this.size = l(20,20);
    }
    void draw(){
      super.draw();
        // Call inherited Movable method
        doMove();
        
        if( !levelEditMode )for( MapObject mapObject: currentLevel.mapObjects ) mapObject.bumpCheck( this );
        
        // Draw the score!
        //TODO: draw score in the corner :)

        
        //// Draw line to closest wall
        //for( Wall wall : currentLevel.walls ){
        //    stroke(255,0,0); // Change line color to Red
        //    strokeWeight(1); // Change line weight to 1 px
        //    Loc closestPoint = wall.closestLocTo( location );
        //    lineLoc( location, closestPoint );
        //}
        
        
        // Draw Pixel glow effect
        stroke(255, 10); // 15% opacity
        noFill();

        // Draw transparent boxes with exponential distance from center
        strokeWeight(4);
        rect( (float)(location.x-size.x/2),(float)(location.y-size.y/2),(float)(size.x),(float)(size.y));
        strokeWeight(9);
        rect( (float)(location.x-size.x/2),(float)(location.y-size.y/2),(float)(size.x),(float)(size.y));
        strokeWeight(16);
        rect( (float)(location.x-size.x/2),(float)(location.y-size.y/2),(float)(size.x),(float)(size.y));
        strokeWeight(25);
        rect( (float)(location.x-size.x/2),(float)(location.y-size.y/2),(float)(size.x),(float)(size.y));
                       
        // Draw Pixel
        stroke(255);
        fill(255);
        noStroke();
        rect( (float)(location.x-size.x/2),(float)(location.y-size.y/2),(float)(size.x),(float)(size.y));
        
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
        }else if(keyCode == 'R' ){
            gotoFirstLevel();
        }else if(keyCode == 'L' ){
            currentLevel.reset();
        }else if(keyCode == 'E' ){
            levelEditMode = !levelEditMode;
        }else if(keyCode == ESC && levelEditMode){
            selectedThing = null;
        }else if(keyCode == DELETE && levelEditMode ){
            if(selectedThing != null){
               selectedThing.delete();
               //Don't null selectedThing because it can still be copied.
            }
        }else if(keyCode == 'C' && levelEditMode ){
            if(selectedThing != null)selectedThing.edit_copy();
        }else if(keyCode == 'P' && levelEditMode ){
            println( globalMapConstruct() );
        }else if(keyCode == 33 && levelEditMode ){ //PAGE UP
            Level level = firstLevel;
            while( level != null && level.nextLevel != currentLevel ) level = level.nextLevel;
            currentLevel = level;
        }else if(keyCode == 34 && levelEditMode ){ //PAGE DOWN
          if( currentLevel.nextLevel != null ){
            gotoNextLevel();
          }else{
            makeNextLevel();
          }
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
    void activate(){
      //do nothing.
    }
    public MapObject construct_new() { return new Pixel(); }
    void edit_copy(){
      //do nothing. 
    }
    
    public String functionName(){ return "addPixel"; }
}

String lastString = "";

//Level maker commands.
// Create new Wall object and it to the walls list
void aw( int x1, int y1, int x2, int y2, int weight ){
    currentLevel.walls.add( new Wall(l(x1,y1),l(x2,y2), weight) );
}

//A door is controlled by the switch most recently created.
void addDoor( int x1, int y1, int x2, int y2, int weight ){
  Door newDoor = new Door(l(x1,y1),l(x2,y2), weight);
  currentLevel.walls.add( newDoor );
  if( lastSwitch != null ){
    lastSwitch.doors.add(newDoor);
    newDoor.switch_ = lastSwitch;
  }
}

void addSwitch( int x, int y ){
  Switch newSwitch = new Switch();
  lastSwitch.location = l(x,y);
  currentLevel.mapObjects.add( newSwitch );
}
  



void addPixel ( double x, double y ){
    Pixel pixel = new Pixel();
    pixel.setStartLocation(l(x,y));
    currentLevel.pixel = pixel;
}

//TODO: make these use a Loc parameter
void addExit( int x, int y ){
    Exit exit = new Exit();
    exit.location = l(x,y);
    currentLevel.mapObjects.add( exit );
}

void addGold( double x, double y ){
    Gold gold = new Gold();
    gold.location = l(x,y);
    gold.size = l(10,10);
    currentLevel.mapObjects.add( gold );
}

void addTriggerBot( double x, double y, double angle ){
    TriggerBot bot = new TriggerBot(); //<>//
    bot.setStartLocation( l(x,y) );
    bot.setStartAngle( angle );
    currentLevel.mapObjects.add( bot );
}

void addPathBot( double x, double y ){
  PathBot bot = new PathBot();
  bot.setStartLocation( l(x,y) );
  currentLevel.mapObjects.add( bot );
}

void addPathBotWayPoint( double x, double y ){
  if( lastPathBot != null ) lastPathBot.path.add( l(x,y) );
}

void setSpeed( int speed ){
  if( lastMovable != null ) lastMovable.speed = speed;
}

void gotoFirstLevel(){
    currentLevel = firstLevel;
    currentLevel.reset();
}

void makeNextLevel(){
    Level nextLevel = new Level();
    currentLevel.nextLevel = nextLevel;
    currentLevel = nextLevel;
}

void gotoNextLevel(){
    if( currentLevel.nextLevel != null ){
        currentLevel = currentLevel.nextLevel;
        currentLevel.reset();
    }else{
        //TODO: throw a party?
        // maybe go to the main menu here?
    }
}

String globalMapConstruct(){
  String result = "";
  Level level = firstLevel;
  int levelNumber = 1;
  while( level != null ){
    result += "//LEVEL " + levelNumber++ + "\n";
    if( level != firstLevel ) result += "makeNextLevel();\n";
    result += level.mapConstruct();
    level = level.nextLevel;
    if( level != null ) result += "\n\n";
  }
  result += "gotoFirstLevel();\n";
  return result;
}


void setup(){

    // INITIAL SETUP

      size(1000,800);
      background(125);
      fill(255);
      frameRate(24);
      textSize(32);

    // Initialize DisplayBox with font of choice
    displayBox = new DisplayBox( createFont("Roboto", 20 ));
    
    //INSERT vvvv

    // LEVEL 1
    
    //Test door and switch.
    //make the switch and then the door.  The order connects them.
    addSwitch( 36, 440 );
    addDoor( 497, 484, 592, 484, 10 );
    addSwitch(36,440);
    addDoor( 927,555,1002,555,10 );
    addDoor( 927,572,1002,572,10 );
    addDoor( 927,590,1002,590,10 );

    // Walls around border
    aw(0,0,0,1000,1);
    aw(0,0,1000,0,1);
    aw(0,1000,1000,1000,1);
    aw(1000,0,1000,1000,1);
    
    // console wall
    aw(0,691,1000,691,2);

    // manually typed walls from Illustrator

    // horizontal walls
    aw(0,95,300,95,10);
    aw(90,295,90+400,295,10);
    aw(0,395,400,395,10);
    aw(0,484,500,484,10);
    aw(240,555,600,555,10);
    aw(240,619,600,619,10);

    // vertical walls
    aw(395,0,395,290,10);
    aw(596,90,596,460+90,10);
    aw(145,489,145,489+135,10);
    aw(65,556,65,135+556,10);
    aw(245,560,245,560+54,10);
    aw(596,624,596,624+66,10);
    aw(922,550,922,550+140,10);
    aw(495,290,495,290+110,10);
      
    addExit( 968, 640 );

    addTriggerBot( 150, 130, radians(90) );
    addTriggerBot( 250, 130, radians(90) );
    addTriggerBot( 200, 260, radians(270) );
    addPixel( 50, 45 );
    
    addPathBot( 43, 443 );
    addPathBotWayPoint( 43, 443 );
    addPathBotWayPoint( 545, 439 );
    addPathBotWayPoint( 549, 41 );
    addPathBotWayPoint( 639, 43 );
    addPathBotWayPoint( 438, 39 );
    setSpeed( 10 );
    
    addPathBot( 40, 131 );
    addPathBotWayPoint( 40, 131 );
    addPathBotWayPoint( 40, 345 );
    addPathBotWayPoint( 444, 345 );
    setSpeed( 3 );
    
    // LEVEL 2

    makeNextLevel();

    aw(56,41,56,508,7);
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
    aw(810,507,56,507,8);
    
    addExit( 200, 200 );
    addGold( 315, 225 );
    addTriggerBot( 500, 300, 0 );
    addTriggerBot( 100, 50, 1.2 );
    addPixel( 100, 100 );
    
    // LEVEL 3

    makeNextLevel();
    
    aw(621,301,764,301,3);
    aw(701,301,701,509,4);
    aw(222,334,396,334,3);
    aw(471,335,394,412,3);
    aw(156,411,57,510,4);
    
    addExit( 200, 300 );
    addPixel( 100, 100 );
    
    gotoFirstLevel();
    //INSERT ^^^^
}

// DisplayText at bottom of screen.
public class DisplayBox{
    String displayText = "";
    PFont font;
    ArrayList<DisplayMessage> messages = new ArrayList<DisplayMessage>();

    public DisplayBox(PFont font){
        this.font = font;
    }

    public void addMessage( String message ){
        // If list is too long, remove oldest message from list
        if (messages.size()>=3) {
            messages.remove(0);
        }
        messages.add(new DisplayMessage(message));
    }
    void draw(){
        fill(255);
        textFont(font);

        String displayText = "";
        for (DisplayMessage message : new ArrayList<DisplayMessage>(messages)){
            // Iterate through copy of messages
            if((millis() - message.arrivalTime)/1000 < 3){ 
                displayText = message.ToString() + "\n" + displayText;
                println(displayText);
            }else{
                // If messsage is old, remove from list
                messages.remove(message);
            }
        }
        text(displayText,10,700,600,390);
    }
    void reset(){
        messages.clear();
    }
}

// Represents message in displayBox, stores time it was posted.
public class DisplayMessage{
    String message;
    int arrivalTime;

    public DisplayMessage( String message ){
        this.message = message;
        this.arrivalTime = millis();
    }
    
    public String ToString(){
        return message;
    }
}

boolean isPlaying;
DisplayBox displayBox;
void draw(){  
    if (isPlaying){
        background(0);
        for(Wall wall : currentLevel.walls){
            wall.draw();
        }
        for(MapObject mapObject : currentLevel.mapObjects){
        mapObject.draw();
        }
        currentLevel.pixel.draw(); // Draw last so it is on top of everything else
        fill(0, 102, 153);
        text(lastString,750,780,180);
        displayBox.draw();
    }
}

void mousePressed(){
  Loc mousePos = l( mouseX, mouseY );
  for( MapObject mapObject : currentLevel.mapObjects ) mapObject.trySelect( mousePos ); 
  for( Wall wall : currentLevel.walls ) wall.trySelect( mousePos );
  currentLevel.pixel.trySelect( mousePos );
}



void keyPressed(){
    currentLevel.pixel.keyPressed();
}

void keyReleased(){
    currentLevel.pixel.keyReleased();
}
