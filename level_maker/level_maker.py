import sys, collections, math
import numpy as np

from scipy import misc, interpolate
from skimage.draw import line_aa

class Loc:
    def __init__(self,x,y):
        self.x=x
        self.y=y
    def __str__(self):
        return "(" + str(self.x) + "," + str(self.y) + ")"
    x = 0
    y = 0

    def clone( self ):
        return Loc( self.x, self.y )

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
def distance_flood_2( in_image, tracking_color ):
    width = in_image.shape[1]
    height = in_image.shape[0]
    loop_count = 0

    #find tracking color
    x_v = np.tile( np.arange(width), height )
    y_v = np.repeat( np.arange(height), width )
    is_color = np.logical_and((in_image[y_v,x_v,0] == tracking_color[0]),
                (in_image[y_v,x_v,1] == tracking_color[1]),
                (in_image[y_v,x_v,2] == tracking_color[2]))

    interest_list_x_v = x_v[is_color]
    interest_list_y_v = y_v[is_color]

    flood_map = np.full((height,width), float( "inf" ))
    flood_map[interest_list_y_v,interest_list_x_v] = 0

    loop_count = 0
    while( len(interest_list_x_v) > 0 ):

        def propogate_improvement(from_x_v,from_y_v,to_x_v,to_y_v,too_far_v):
            not_too_far_v = ~too_far_v
            from_x_v = from_x_v[not_too_far_v]
            from_y_v = from_y_v[not_too_far_v]
            to_x_v   = to_x_v[not_too_far_v]
            to_y_v   = to_y_v[not_too_far_v]

            suggested_value_v = flood_map[from_y_v,from_x_v] + 1
            is_color_v = np.logical_and( (in_image[to_y_v,to_x_v,0] == tracking_color[0]),
                (in_image[to_y_v,to_x_v,1] == tracking_color[1]),
                (in_image[to_y_v,to_x_v,2] == tracking_color[2]))
            suggested_value_v[is_color_v] = 0
            is_improvement_v = suggested_value_v < flood_map[to_y_v,to_x_v]
            good_to_y_v = to_y_v[is_improvement_v]
            good_to_x_v = to_x_v[is_improvement_v]
            good_suggested_value_v = suggested_value_v[is_improvement_v]

            flood_map[good_to_y_v,good_to_x_v] = good_suggested_value_v
            return good_to_x_v,good_to_y_v


        interest_list_y_up_v = interest_list_y_v-1
        good_up_x_v   , good_up_y_v    = propogate_improvement( interest_list_x_v, interest_list_y_v, interest_list_x_v      , interest_list_y_up_v  , interest_list_y_up_v    < 0       )
        interest_list_x_left_v = interest_list_x_v-1
        good_left_x_v , good_left_y_v  = propogate_improvement( interest_list_x_v, interest_list_y_v, interest_list_x_left_v , interest_list_y_v     , interest_list_x_left_v  < 0       )
        interest_list_y_down_v = interest_list_y_v+1
        good_down_x_v , good_down_y_v  = propogate_improvement( interest_list_x_v, interest_list_y_v, interest_list_x_v      , interest_list_y_down_v, interest_list_y_down_v  >= height )
        interest_list_x_right_v = interest_list_x_v+1
        good_right_x_v, good_right_y_v = propogate_improvement( interest_list_x_v, interest_list_y_v, interest_list_x_right_v, interest_list_y_v     , interest_list_x_right_v >= width  )

        good_x_v = np.concatenate((good_up_x_v,good_left_x_v,good_down_x_v,good_right_x_v))
        good_y_v = np.concatenate((good_up_y_v,good_left_y_v,good_down_y_v,good_right_y_v))
        if len(good_x_v) > 0:
            good_yx = np.dstack((good_y_v,good_x_v))
            good_yx = np.reshape(good_yx, (-1,2) ) #remove extra dimenson
            good_yx = np.unique( good_yx, axis=0 )
            interest_list_x_v = good_yx[:,1]
            interest_list_y_v = good_yx[:,0]
        else:
            interest_list_x_v = good_x_v
            interest_list_y_v = good_y_v

        loop_count += 1
        print( "interest list len: " + str(len(interest_list_x_v)) + " loop_count " + str( loop_count ) )
    return flood_map

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

def get_walk_value( area, line ):
    width = area.shape[1]
    height = area.shape[0]


    distance = line.length()
    step_v = np.arange( 0, distance, .1 )

    test_x_v = step_v/distance*(line.b.x-line.a.x)+line.a.x
    test_y_v = step_v/distance*(line.b.y-line.a.y)+line.a.y

    test_x_v = np.maximum( 0, np.minimum( width-1.001,  test_x_v ) )
    test_y_v = np.maximum( 0, np.minimum( height-1.001, test_y_v ) )

    left_v = np.floor( test_x_v ).astype(int)
    right_v = left_v + 1
    top_v  = np.floor( test_y_v ).astype(int)
    bottom_v = top_v + 1

    top_right_value_v    = area[ top_v   , right_v ]
    top_left_value_v     = area[ top_v   , left_v  ]
    bottom_right_value_v = area[ bottom_v, right_v ]
    bottom_left_value_v  = area[ bottom_v, left_v  ]

    top_value_v    = ( test_x_v-left_v )*( top_right_value_v   -top_left_value_v    )+top_left_value_v
    bottom_value_v = ( test_x_v-left_v )*( bottom_right_value_v-bottom_left_value_v )+bottom_left_value_v

    value_v        = ( test_y_v-top_v  )*( bottom_value_v      -top_value_v         )+top_value_v

    sumz = np.sum(value_v)

    bad_steps = (value_v == 0).any()

    if not bad_steps:
        #return sumz/len(step_v) + .6*distance
        return sumz/len(step_v) * .1*distance
    else:
        return sumz/len(step_v) - .01*distance


def get_walk_value_old( area, line ):
    sumz = 0
    step = 0
    count = 0
    bad_steps = 0
    good_steps = 0
    distance = line.length()
    width = area.shape[1]
    height = area.shape[0]
    while step < distance:
        test = Loc( step/distance*(line.b.x-line.a.x)+line.a.x, step/distance*(line.b.y-line.a.y)+line.a.y )
        if test.x < 0 or test.y < 0 or test.x > width-1 or test.y > height-1: return -float("inf")
        value = area[int(test.y),int(test.x)]
        if value == 0:
            bad_steps += 1
        else:
            good_steps += 1

        sumz += value
        count += 1
        step += 1
    
    if bad_steps == 0:
        return sumz/count + .5*distance
    else:
        return sumz/count - .01*distance

def optimize( best_in, already_improved, test_function ):
    did_improvement = already_improved
    best_out = test_function(best_in)
    speed = 5
    count_out = 100
    max_improve = 100
    while count_out > 0 and max_improve > 0 and abs(speed) > .001:
        test_in = best_in + speed
        test_out = test_function(test_in)
        if test_out > best_out:
            best_out = test_out
            best_in = test_in
            speed *= 2
            count_out = 100
            did_improvement = True
            max_improve += 1
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

    def clone( self ):
        return Line( self.a.clone(), self.b.clone(), self.weight )

    def get_line_command( self ):
        return "    aw(" + str(int(self.a.x)) + "," + str(int(self.a.y)) + "," + str(int(self.b.x)) + "," + str(int(self.b.y)) + "," + str(int(self.weight)) + ");"

    def contains( self, loc, extra_weight=1 ):
        closest_point = self.closest_loc_to( loc )
        return closest_point.distance_to( loc ) <= self.weight*.5*extra_weight

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

    def get_average_weight( self, image ):
        sumz = 0
        count = 0
        distance = self.length()
        width = image.shape[1]
        height = image.shape[0]
        while count < distance:
            test = Loc( count/distance*(self.b.x-self.a.x)+self.a.x, count/distance*(self.b.y-self.a.y)+self.a.y )
            if test.x < 0 or test.y < 0 or test.x > width-1 or test.y > height-1: 
                pass
            else:
                sumz += image[int(test.y),int(test.x)]
                count += 1
        return sumz/count

    def length( self ):
        return self.a.distance_to( self.b )
    
    def move_a_x( self, nv ):
        return Line( Loc( nv, self.a.y ), self.b, self.weight )
    def move_a_y( self, nv ):
        return Line( Loc( self.a.x, nv ), self.b, self.weight )
    def move_b_x( self, nv ):
        return Line( self.a, Loc( nv, self.b.y ), self.weight )
    def move_b_y( self, nv ):
        return Line( self.a, Loc( self.b.x, nv ), self.weight )
    def move_b_length( self, nv ):
        return Line( self.a, Loc( nv/self.length()*(self.b.x-self.a.x)+self.a.x,
                                  nv/self.length()*(self.b.y-self.a.y)+self.a.y ), self.weight )
    def move_a_length( self, nv ):
        return Line( Loc( nv/self.length()*(self.a.x-self.b.x)+self.b.x,
                          nv/self.length()*(self.a.y-self.b.y)+self.b.y ), self.b, self.weight )
    
        

    def __str__(self):
        return str(self.a) + " to " + str(self.b) + " w" + str(self.weight)


    
def mainy( args ):
    image = np.asarray( [[[0,0,0],[0,0,0],[0,0,0]],
                         [[0,0,0],[1,0,0],[1,0,0]],
                         [[0,0,0],[1,0,0],[1,0,0]],
                         [[0,0,0],[0,0,0],[0,0,0]]] )

    flood = distance_flood_2( image, (0,0,0) )
    print( str(flood) )


def main( args ):
    print( "Processing level " + str( args ) )
    
    image = misc.imread( args[0], flatten= 0)
    flood = distance_flood_2( image, (0,0,0) )
    #print( "Loaded image " + str( image ) + " which has shape " + str( image.shape ) )
    #flood =  misc.imread( args[0], flatten= 1)
    
    misc.imsave( "flood.bmp", flood )


    line_image = np.zeros( flood.shape )

    lines = []

    for need in find_needs( flood ):

        top_of_hill = climb_hill( flood, need )

        touches_line = False
        for line in lines:
            #print( "testing how far " + str( top_of_hill) + " is from " + str(line) )
            if line.contains(top_of_hill,5):
                touches_line = True
                #print( "touches!!")
                break

        if not touches_line:
            print( "going for " + str( top_of_hill ))
            distance = 10
            best_score = 0
            best_direction = 0
            if len( lines ) == 4:
                print( "hi" )
            for test_direction in (x*math.pi/100 for x in range(101)):
                walk_value = get_walk_value( flood,  Line( top_of_hill, top_of_hill.add_polar(distance,test_direction ),20 ) )
                #print( "testing direction " + str( test_direction ) + " gets " + str(walk_value) )
                if walk_value > best_score:
                    best_score = walk_value
                    best_direction = test_direction

            best_line = Line( top_of_hill, top_of_hill.add_polar(distance,best_direction), 20 )

            #see if we can optimize
            made_improvement = True
            while made_improvement:
                made_improvement = False
                before_line = best_line.clone()
                best_line.b.x, made_improvement = optimize( best_line.b.x     , made_improvement, lambda test: get_walk_value( flood, best_line.move_b_x(test) ) )
                best_line.b.y, made_improvement = optimize( best_line.b.y     , made_improvement, lambda test: get_walk_value( flood, best_line.move_b_y(test) ) )
                best_line.a.x, made_improvement = optimize( best_line.a.x     , made_improvement, lambda test: get_walk_value( flood, best_line.move_a_x(test) ) )
                best_line.a.y, made_improvement = optimize( best_line.a.y     , made_improvement, lambda test: get_walk_value( flood, best_line.move_a_y(test) ) )
                new_length   , made_improvement = optimize( best_line.length(), made_improvement, lambda test: get_walk_value( flood, best_line.move_a_length( test ) ) )
                best_line.a = best_line.move_a_length(new_length).a
                new_length   , made_improvement = optimize( best_line.length(), made_improvement, lambda test: get_walk_value( flood, best_line.move_b_length( test ) ) )
                best_line.b = best_line.move_b_length(new_length).b
                if made_improvement:
                    print( "improved " + str( before_line ) + " -> " + str( best_line ) )

            #line = Line(top_of_hill,top_of_hill.add_polar(distance,best_direction), flood[int(top_of_hill.y),int(top_of_hill.x)] )
            print( "adding line" + str(len(lines)+1) + " " + str(best_line) )
            best_line.weight = best_line.get_average_weight( flood )*2
            lines.append( best_line )

            best_line.draw_on_image( line_image )
            misc.imsave( "line_image_" + str(len(lines)) + ".bmp", line_image  )


            if len( lines ) > 100:
                break

    misc.imsave( "line_image.bmp", line_image )

    for line in lines:
        #pull in the ends by half the weight
        length = line.length()
        line.b = line.move_b_length( length- line.weight*.5 ).b
        line.a = line.move_a_length( length- line.weight ).a

    for line in lines:
        print( line.get_line_command() )

if(__name__ == '__main__'):
    if len( sys.argv ) < 2:
        sys.argv.append( "level_maker/test2.bmp" )
    

    main(sys.argv[1:])
