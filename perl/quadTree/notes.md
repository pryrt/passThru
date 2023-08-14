QuadTree
So the region is central.
And the idea _is_ for lookup only within that region.

I'm going to have these notes build things up in the same order he does it,
because his process is pretty logical (and makes more sense than just
trying to study the whole result class).  But that means that I will show the
same pseudocode multiple times, as new concepts get added to the mental app
Actually, no, let's just do numbering to the right to show when things were added
Also, use .param instead of this.param to save typing

https://thecodingtrain.com/challenges/98-quadtree
    part 1: https://youtu.be/OJxEcs0w_kE => make the initial classes, and include
        ability to insert points (but nothing about accessing them later)           ;; steps 1-21
    part 2: https://youtu.be/QQx_NmCIuCY => retrieve list of points                 ;; steps 201-2xx
    part 3: https://youtu.be/z0YFFg_nBjw => he applies it to collision algorithm    ;;
        though unfortunately, he added circular ranges (Circle Class) offline       ;; steps 301
        ... I will have to just look at his code in order to add the circle         ;;
        see https://editor.p5js.org/codingtrain/sketches/g7LnWQ42x for
            the contents of Circle
        or https://github.com/CodingTrain/QuadTree for the community-contributed version

Point Class                                                                         ;;  1: need a Point
    args/params(x,y)                                                                ;;  1
                                                                                    ;;
Rectangle Class                                                                     ;;  2: need a Rectangle (both for boundary and for search region
    args/params(x,y,w,h) -- actually use "radius" style width and height,           ;;  2
              -- so the stored params are half the width and height                 ;;  2
              -- the x and y are the _center_ of the rectangle (which               ;;  2
                 makes subdividing easier later on...                               ;;  2
                                                                                    ;;
    contains(point)                                                                 ;;  16: need a .contains function that returns bool based on a point
        return                                                                      ;;  16
            point.x >= .x - .w                                                      ;;  16 originally with >    || 20: for edge cases, switch to
            && point.x <= .x + .w                                                   ;;  16 originally with <    || 20: <= or >= to be inclusive about
            && point.y >= .y - .h                                                   ;;  16 originally with >    || 20: when it lands on the border
            && point.y <= .y + .h                                                   ;;  16 originally with <    ||
                                                                                    ;;
    intersects(range)                                                               ;;  202: intersects: does this rectangle intersect a given range? let the range be another rectangle because that will make it easy
        return NOT (                                                                ;;
            range.x - range.w > .x + .w                                             ;;  202: range's left is beyond this right
            || range.x + range.w < .x + .w                                          ;;  202: or range's right is beyond this left
            || range.y - range.h > .y + .h                                          ;;  202: or range's top is beyond this bottom
            || range.y + range.h < .y + .h                                          ;;  202: or range's bottom is beyond this top
        )                                                                           ;;
                                                                                    ;;
                                                                                    ;;
                                                                                    ;;
                                                                                    ;;
                                                                                    ;;
QuadTree Class                                                                      ;;  3: need the tree structure
    => an instance is just the outside rectangle; and then it will (potentially)    ;;  3
    reference four sub-sections                                                     ;;  3
    args/params = (boundary: instance of Rectangle; capacity n)                     ;;  3: just have boundary || 6: add capacity n
        (.points= [] )                                                              ;;  8: add argument
        (.divided= false )                                                          ;;  12: add argument: don't want to subdivide if it's already been divided
                                                                                    ;;
    insert(point)                                                                   ;;  7: start to write the initial insert() function; realize need argument
        if NOT .boundary.contains(point)                                            ;;  15: if the point doesn't lie somewhere with the boundary of this region,
            return                                                                  ;;  15: just get out of here, and don't insert the point
                                                                                    ;;  15: this implements the logic required for 14 to work
                    false                                                           ;;  21: change to `return false`
                                                                                    ;;
        if .points.length < .capacity                                               ;;  9: if there's enough room in the current instance
            .points.push(point)                                                     ;;  9: store the point in this instance
            return true                                                             ;;  21: successfully added
        else                                                                        ;;  9:
            if not .divided then:                                                   ;;  12: don't want to subdivide if it already has been
                .subdivide                                                          ;;  9: otherwise, subdivide into four new sections
            # now pass the buck, and let all four of the next decide whether        ;;  14: My note: that logic will have to be added in step 15
            # or not to take the point                                              ;;  14:
            return                                                                  ;;  21: return status of trying to insert into any of the quadrants, so OR them together
            .northwest.insert(point)                                                ;;  14: My note: these don't go in the if-not-divided, because
            ||                                                                      ;;  21: ORing them together
            .northeast.insert(point)                                                ;;  14: even if it has already been divided, I need to pass the buck
            ||                                                                      ;;  21: ORing them together
            .southwest.insert(point)                                                ;;  14: (which is how multiple points are going to trickle down
            ||                                                                      ;;  21: ORing them together
            .southeast.insert(point)                                                ;;  14: from the top of the structure into the right place)
                                                                                    ;;  21: The cascaded OR will mean that if the first adds, the second won't
                                                                                    ;;  21:   need to, and so on; if even the fourth quadrant fails,
                                                                                    ;;  21:   it would return false, saying that it failed to insert...
                                                                                    ;;  21:   but I think that should never happen,
            || die "how did it get here?"                                           ;;  21:   so die with an error so I can debug and understand better
                                                                                    ;;
    subdivide()                                                                     ;;  10: make four subsections, nw,ne,se,sw
        tmp x = .boundary.x                                                         ;;  13: need some temp variables because the x/y/w/h are properties of boundary property, so not readable
        tmp y = .boundary.y                                                         ;;  13
        tmp w = .boundary.w                                                         ;;  13
        tmp h = .boundary.h                                                         ;;  13
        .divided = true                                                             ;;  12: mark it as divided (originally in insert.if-not-divided, but I thought it went better here, and after #16 so did his CHAT )
                                                                                    ;;
        nw = new Rectangle(x-w/2, y-h/2, w/2, h/2)                                  ;;  11: need a rectangle for the nw quarter of the current
        .northwest = new QuadTree(nw)                                               ;;  10: make each of the four without argument || 11: add nw argument
                    ,.capacity                                                      ;;  17: add `,.capacity` to each new QuadTree (really in line above)
        ne = new Rectangle(x+w/2, y-h/2, w/2, h/2)                                  ;;  11: need a rectangle for the ne quarter of the current
        .northeast = new QuadTree(ne)                                               ;;  10: make each of the four without argument || 11: add ne argument
                    ,.capacity                                                      ;;  17: add `,.capacity` to each new QuadTree (really in line above)
        sw = new Rectangle(x-w/2, y+h/2, w/2, h/2)                                  ;;  11: need a rectangle for the sw quarter of the current
        .southwest = new QuadTree(sw)                                               ;;  10: make each of the four without argument || 11: add sw argument
                    ,.capacity                                                      ;;  17: add `,.capacity` to each new QuadTree (really in line above)
        se = new Rectangle(x+w/2, y+h/2, w/2, h/2)                                  ;;  11: need a rectangle for the se quarter of the current
        .southeast = new QuadTree(se)                                               ;;  10: make each of the four without argument || 11: add se argument
                    ,.capacity                                                      ;;  17: add `,.capacity` to each new QuadTree (really in line above)
                                                                                    ;;  17: at end of step 17, you can run the app, and the QuadTree should contain
                                                                                    ;;  17: five points: four in this object, and 1 in one of the sub-quadrants
                                                                                    ;;  17: (this is at 25:48 in challenge #98.1)
                                                                                    ;;
    show()                                                                          ;;  18: he added a "show" to the QuadTree for graphical
        rect mode center                                                            ;;  18: but if I'm implementing in a different language, mine will be different
        draw rectangle based on .boundary's .x,.y,.w,.h                             ;;  18
        if(.divided)                                                                ;;  18
            .northwest.show()                                                       ;;  18
            .northeast.show()                                                       ;;  18
            .southwest.show()                                                       ;;  18
            .southeast.show()                                                       ;;  18
                                                                                    ;;  18
        for p in points                                                             ;;  18: note to self: I would probably want to color things differently
            draw point at p.x,p.y                                                   ;;  18: so that it's a different color depending on which boundary I am in,
                                                                                    ;;  18: because it seems weird to me that there can be four points randomly
                                                                                    ;;  18: throughout a rectangle along with quadrants which are storing
                                                                                    ;;  18: the points separately; but maybe that's just the
                                                                                    ;;  18: easiest way to implement; I don't know whether it would affect
                                                                                    ;;  18: the lookup efficiency to have points and divided in the same instance
                                                                                    ;;
    query(range)    , found                                                         ;;  201: want to query on a range || 207: add parameter found
        # let found = []                                                            ;;  203: need to recursively go through everything, so need an array || 207: delete this line, because it's a param instead
        if(!found) found = []                                                       ;;  210: make sure it's got something if the found parameter was not included
        if NOT .boundary.intersects(range)                                          ;;  201: if this tree's boundary does not intersect the given range
            return                                                                  ;;  201: just get out of here
                found                                                               ;;  203: want it to return empty found array if not intersecting...
                                                                                    ;;  207: don't need the return value again..., so delete previous line
        else                                                                        ;;  203:
            for p in .points                                                        ;;  203: else look through
                if range.contains(p)                                                ;;  203: check if the range contains the active point
                    found.push(p)                                                   ;;  203: if it does, add it to the found list
                                                                                    ;;
            if .divided then                                                        ;;  204: also, if it's divided, need to
                found.concat(.northwest.query(range))                               ;;  204:    add results of recursing into each quadrant
                found.concat(.northeast.query(range))                               ;;  204:    add results of recursing into each quadrant
                found.concat(.southwest.query(range))                               ;;  204:    add results of recursing into each quadrant
                found.concat(.southeast.query(range))                               ;;  204:    add results of recursing into each quadrant
                                                                                    ;;  207: refactor the above four lines into calls that just pass in the array to let the inner function handle it
                .northwest.query(range, found)                                      ;;  207:
                .northeast.query(range, found)                                      ;;  207:
                .southwest.query(range, found)                                      ;;  207:
                .southeast.query(range, found)                                      ;;  207:
                                                                                    ;;
            return found                                                            ;;  205: now return everything that was found in this tree or its children
                                                                                    ;;
                                                                                    ;;
App                                                                                 ;;
    boundary = new Rectangle(x,y, w/2, h/2)                                         ;;  4: make the object
    qtree = new QuadTree(boundary, 4)                                               ;;  4 || 6: add `, 4` to creation list
    loop(i: 1 to 5)                                                                 ;;  5: populate it with some points to be stored: start with 1 to 1 to just add a single point
                                                                                    ;;  17: change it to 1 to 5 to test that subdivision works; find bugs to fix in 18
        p = new Point(random x, random y)                                           ;;  5
        qtree = insert(p)                                                           ;;  5 -- here, he talked about capacity, which he then switches to QT class (for step 6), because to insert, you have to first create
                                                                                    ;;
                                                                                    ;;  19: he switches to using random points to view it better
                                                                                    ;;  19: but at this point, it's more about tweaking things, and
                                                                                    ;;  19: not critical to the algorithm, just helping us learn more about it
                                                                                    ;;  19: do a draw loop where he adds points while mouse is pressed.
                                                                                    ;;
                                                                                    ;;  20: edge case: probably need one of the boundaries to have >=
                                                                                    ;;  21: but it will allow it to end up in more than one...
                                                                                    ;;  21: so go back and return values from the insert() method...
                                                                                    ;;
    range = new Rectangle(cx,cy,w,h)                                                ;;  206: now he makes a range rectangle
    draw rectangle(those same points)                                               ;;  206: and draws it
    points = []                                                                     ;;  207: empty array for storing points
    qtree.query(range, points)                                                      ;;  206: then queries the qtree to highlight which points are inside; 207 add , points
                                                                                    ;;  207: the p5.js concat didn't do what he wanted, so refactor
                                                                                    ;;  207: to pass the array during the recursion, so add parameter
                                                                                    ;;  208: then display the points in a different color
                                                                                    ;;
                                                                                    ;;  209: at the very end, he went back and made query _also_ return
                                                                                    ;;  209: the found array, and made query initialize an empty array if none is passed in
                                                                                    ;;  209: so refactored the points/qtree line from above
    points = qtree.query(range)                                                     ;;  209: to this line, and made the changes in 210
                                                                                    ;;
                                                                                    ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;
301: Everything below here is just notes added during the quick runthrough of his collision QuadTree
His flocking uses Particles, his QuadTree uses Points, so he adds a "user data" element to the QuadTree
    so that there can be a link
He makes a fresh QuadTree every time through draw(), so that he doesn't have to worry about clearing it every time
He talked about his circular range around 13:15, but didn't go into the details of implementation
Instead of doing O(n²):
    for(p of particles) {
        for other of particles {
            next if other==p;
            ; DO SOMETHING TIME CONSUMING ; his example is
            if dist(p,other) < visionRadius:                ; where dist() involves sqrt(), so is computationally expensive for thousands of points with millions of comparisions
                highlight (draw a bigger colorful point)
        }
    }
he does O(n log n):
    build qtree                         ; O(n)
    for(p of particles) {               ; O(n)
        range = Circle(...)
        points = qtree.query            ; O(log n)
        for pt in points                ; O(log n)
            other = pt.userdata
            next if other==p
            DO SOMETHING TIME CONSUMING ; his example is
            if(p.intersects(other)):                        ; he did dsq comparison instead of sqrt(dsq), so also saved time that way
                highlight (draw a bigger colorful point)
    }
