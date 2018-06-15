import sys, collections, math
import numpy as np

from scipy import misc
from skimage.draw import line_aa

class Loc:
    def __init__(self,x,y):
        self.x=x
        self.y=y
    def __str__(self):
        return "(" + str(self.x) + "," + str(self.y) + ")"
    x = 0
    y = 0

    def up( self, amount ):
        return Loc( self.x, self.y-amount)
    def down( self, amount ):
        return Loc( self.x, self.y+amount)
    def left( self, amount ):
        return Loc( self.x-amount, self.y)
    def right( self, amount ):
        return Loc( self.x+amount, self.y)

    def get_eight_edges( self ):
        yield Loc(self.x-1,self.y  )
        yield Loc(self.x-1,self.y-1)
        yield Loc(self.x  ,self.y-1)
        yield Loc(self.x+1,self.y-1)
        yield Loc(self.x+1,self.y  )
        yield Loc(self.x+1,self.y+1)
        yield Loc(self.x  ,self.y+1)
        yield Loc(self.x-1,self.y+1)

    def add_polar( self, r, theta ):
        return Loc( self.x+r*math.cos(theta),self.y+r*math.sin(theta))

    def angle_to( self, other ):
        return math.atan2(other.y-self.y,other.x-self.x)
    

    def distance_to( self, other ):
        return math.sqrt( math.pow( other.x-self.x,2) + math.pow( other.y-self.y,2) )
    

    def rotate_around( self, other, angle ):
        theta = other.angle_to(self) + angle
        r = other.distance_to(self)
        return Loc( int(r*math.cos(theta)+other.x),int(r*math.sin(theta)+other.y) )


def distance_flood( in_image, tracking_color ):

    width = in_image.shape[1]
    height = in_image.shape[0]
    flood_map = np.full((height,width), float( "inf" ))
    interest_list = collections.deque()
    loop_count = 0

    for x,y in ((x,y) for x in range(width) for y in range(height) ):
        if (in_image[y,x] == tracking_color).all():
            interest_list.append( Loc(x,y) )
            flood_map[y,x] = 0
            break

    while len( interest_list) > 0:
        current = interest_list.popleft()
        if flood_map[current.y,current.x] == float("inf"):
            print( "yikes!" )
        for next_point in [current.up(1), current.down(1), current.left(1), current.right(1) ]:
            if next_point.x < 0: continue
            if next_point.y < 0: continue
            if next_point.x >= width: continue
            if next_point.y >= height:  continue
            suggested_value = flood_map[current.y,current.x] + 1
            if (in_image[next_point.y,next_point.x] == tracking_color).all(): suggested_value = 0
            if suggested_value >= flood_map[next_point.y,next_point.x]: continue
            flood_map[next_point.y,next_point.x] = suggested_value
            interest_list.append( next_point )
        loop_count += 1
        if loop_count % 1000 == 0:
            print( "interest list len: " + str(len(interest_list)) + " loop_count " + str( loop_count ) + " current " + str( current ) )
    return flood_map

def find_needs( area ):
    area_shape = area.shape
    for y in range( area_shape[0] ):
        for x in range(area_shape[1] ):
            if area[y,x] != 0:
                yield Loc(x,y)

def climb_hill( area, loc ):
    done = False
    while not done:
        done = True
        for edge in loc.get_eight_edges():
            if edge.x < 0: continue
            if edge.y < 0: continue
            if edge.x > area.shape[1]: continue
            if edge.y > area.shape[0]: continue

            if area[edge.y,edge.x] > area[loc.y,loc.x]:
                loc = edge
                done = False
                continue
    return loc

def get_walk_value( area, start, direction, distance ):
    sumz = 0
    step = 0
    count = 0
    while step < distance:
        test = start.add_polar(step,direction)
        value = area[int(test.y),int(test.x)]
        if value == 0: return 0
        sumz += value
        count += 1
        step += 2
    return sumz/count + .01*distance

def optimize( best_in, test_function ):
    did_improvement = False
    best_out = test_function(best_in)
    speed = .01
    count_out = 100
    while count_out > 0:
        test_in = best_in + speed
        test_out = test_function(test_in)
        if test_out > best_out:
            best_out = test_out
            best_in = test_in
            speed *= 2
            count_out = 100
            did_improvement = True
        else:
            speed *= -.5
            count_out -= 1
    return best_in, did_improvement

class Line:
    a = None
    b = None
    weight = 0
    def __init__(self,a,b,weight):
        self.a = a
        self.b = b
        self.weight = weight

    def contains( self, loc ):
        closest_point = self.closest_loc_to( loc )
        return closest_point.distance_to( loc ) <= self.weight*.5

    def closest_loc_to( self, other ):
        myAngle = self.a.angle_to(self.b)
        rotated = other.rotate_around(self.a,-myAngle)
        bRotated = self.b.rotate_around(self.a,-myAngle )
        result = Loc(0,0)
        if rotated.x < min(self.a.x,bRotated.x):
            result = Loc(min(self.a.x,bRotated.x),self.a.y)
        elif rotated.x > max(self.a.x,bRotated.x):
            result = Loc(max(self.a.x,bRotated.x),self.a.y)
        else:
            result = Loc( rotated.x, self.a.y )
        
        return result.rotate_around( self.a, myAngle )

    def draw_on_image( self, image ):
        cc, rr, val = line_aa(int(self.a.x), int(self.a.y), int(self.b.x), int(self.b.y))
        rr = np.maximum(0,np.minimum(image.shape[0]-1,rr))
        cc = np.maximum(0,np.minimum(image.shape[1]-1,cc))
        image[rr, cc] = val * 100


    def __str__(self):
        return str(self.a) + " to " + str(self.b) + " w" + str(self.weight)


    
    


def main( args ):
    print( "Processing level " + str( args ) )
    
    #image = misc.imread( args[0], flatten= 0)
    #flood = distance_flood( image, (0,0,0) )
    #print( "Loaded image " + str( image ) + " which has shape " + str( image.shape ) )
    flood =  misc.imread( args[0], flatten= 1)


    line_image = np.zeros( flood.shape )

    lines = []

    for need in find_needs( flood ):

        top_of_hill = climb_hill( flood, need )

        touches_line = False
        for line in lines:
            #print( "testing how far " + str( top_of_hill) + " is from " + str(line) )
            if line.contains(top_of_hill):
                touches_line = True
                #print( "touches!!")
                break

        if not touches_line:
            print( "going for " + str( top_of_hill ))
            distance = 10
            best_score = 0
            best_direction = 0
            for test_direction in (-x*math.pi/100 for x in range(100)):
                print( "testing direction " + str( test_direction ) )
                walk_value = get_walk_value( flood, top_of_hill, test_direction, distance )
                if walk_value > best_score:
                    best_score = walk_value
                    best_direction = test_direction

            #see if we can optimize
            made_improvement = True
            while made_improvement:
                made_improvement = False
                distance, new_improvement       = optimize( distance      , lambda test_distance:  get_walk_value( flood, top_of_hill,               best_direction, test_distance ) )
                made_improvement = made_improvement or new_improvement
                best_direction, new_improvement = optimize( best_direction, lambda test_direction: get_walk_value( flood, top_of_hill,               test_direction, distance ) )
                made_improvement = made_improvement or new_improvement
                top_of_hill.x, new_improvement  = optimize( top_of_hill.x,  lambda test_x:         get_walk_value( flood, Loc(test_x,top_of_hill.y), best_direction, distance ) )
                made_improvement = made_improvement or new_improvement
                top_of_hill.y, new_improvement  = optimize( top_of_hill.y,  lambda test_y:         get_walk_value( flood, Loc(top_of_hill.x,test_y), best_direction, distance ) )

            #line = Line(top_of_hill,top_of_hill.add_polar(distance,best_direction), flood[int(top_of_hill.y),int(top_of_hill.x)] )
            line = Line(top_of_hill,top_of_hill.add_polar(distance,best_direction), 10 )
            print( "adding line " + str(line) )
            lines.append( line )

            if len( lines ) > 10:
                break


    for line in lines:
        line.draw_on_image( line_image )

    misc.imsave( "line_image.bmp", line_image )

if(__name__ == '__main__'):
    if len( sys.argv ) < 2:
        sys.argv.append( "level_maker/test1.bmp" )
    

    main(sys.argv[1:])
