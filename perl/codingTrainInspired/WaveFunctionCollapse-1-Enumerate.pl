#!perl

use 5.014; # strict, //, s//r
use warnings;
use autodie;
use FindBin;
use lib "${FindBin::Bin}/lib";
use GDP5;
use GD;

use Carp::Always;   # turn this on during debug...

GDP5::Run('WaveFunctionCollapse1');

our %im;
our @grid;
our %rules = (  # SIMPLE.8: set up rules
    blank   => { up => ['blank','up'],          right => ['blank','right'],     down => ['blank','down'],       left => ['blank','left'] },
    up      => { up => ['right','left','down'], right => ['left','up','down'],  down => ['blank','down'],       left => ['up','right','down'] },
    right   => { up => ['right','left','down'], right => ['left','up','down'],  down => ['right','left','up'],  left => ['blank','left'] },
    down    => { up => ['blank','up'],          right => ['left','up','down'],  down => ['right','left','up'],  left => ['up','right','down'] },
    left    => { up => ['right','left','down'], right => ['blank','right'],     down => ['right','left','up'],  left => ['up','right','down'] },
);


sub DIM() { 3 }
sub SCALE() { 150 }


sub preload {
    print STDERR "preload is running...\n";
    my $img = GD::Image->new(3,3);
    my $bg = $img->colorResolve(31,127,31);
    my $fg = $img->colorResolve(31,255,31);
    $img->setPixel(1,1,$fg);

    # blank -- no fg pixels
    $im{blank} = $img->clone();
    $im{blank}->setPixel(0,0,$bg); $im{blank}->setPixel(1,0,$bg); $im{blank}->setPixel(2,0,$bg);
    $im{blank}->setPixel(0,1,$bg); $im{blank}->setPixel(1,1,$bg); $im{blank}->setPixel(2,1,$bg);
    $im{blank}->setPixel(0,2,$bg); $im{blank}->setPixel(1,2,$bg); $im{blank}->setPixel(2,2,$bg);
    #do { my $n='blank'; open my $fh, '>:raw', "$n.png"; print {$fh} $im{$n}->png(); close($fh); system(1,"mspaint $n.png"); };

    # up: ┴
    $im{up} = $img->clone();
    $im{up}->setPixel(0,0,$bg); $im{up}->setPixel(1,0,$fg); $im{up}->setPixel(2,0,$bg);
    $im{up}->setPixel(0,1,$fg); $im{up}->setPixel(1,1,$fg); $im{up}->setPixel(2,1,$fg);
    $im{up}->setPixel(0,2,$bg); $im{up}->setPixel(1,2,$bg); $im{up}->setPixel(2,2,$bg);
    #do { my $n='up'; open my $fh, '>:raw', "$n.png"; print {$fh} $im{$n}->png(); close($fh); system(1,"mspaint $n.png"); };

    # down: ┬
    $im{down} = $img->clone();
    $im{down}->setPixel(0,0,$bg); $im{down}->setPixel(1,0,$bg); $im{down}->setPixel(2,0,$bg);
    $im{down}->setPixel(0,1,$fg); $im{down}->setPixel(1,1,$fg); $im{down}->setPixel(2,1,$fg);
    $im{down}->setPixel(0,2,$bg); $im{down}->setPixel(1,2,$fg); $im{down}->setPixel(2,2,$bg);
    #do { my $n='down'; open my $fh, '>:raw', "$n.png"; print {$fh} $im{$n}->png(); close($fh); system(1,"mspaint $n.png"); };

    # left: ┤
    $im{left} = $img->clone();
    $im{left}->setPixel(0,0,$bg); $im{left}->setPixel(1,0,$fg); $im{left}->setPixel(2,0,$bg);
    $im{left}->setPixel(0,1,$fg); $im{left}->setPixel(1,1,$fg); $im{left}->setPixel(2,1,$bg);
    $im{left}->setPixel(0,2,$bg); $im{left}->setPixel(1,2,$fg); $im{left}->setPixel(2,2,$bg);
    #do { my $n='left'; open my $fh, '>:raw', "$n.png"; print {$fh} $im{$n}->png(); close($fh); system(1,"mspaint $n.png"); };

    # right: ├
    $im{right} = $img->clone();
    $im{right}->setPixel(0,0,$bg); $im{right}->setPixel(1,0,$fg); $im{right}->setPixel(2,0,$bg);
    $im{right}->setPixel(0,1,$bg); $im{right}->setPixel(1,1,$fg); $im{right}->setPixel(2,1,$fg);
    $im{right}->setPixel(0,2,$bg); $im{right}->setPixel(1,2,$fg); $im{right}->setPixel(2,2,$bg);
    #do { my $n='right'; open my $fh, '>:raw', "$n.png"; print {$fh} $im{$n}->png(); close($fh); system(1,"mspaint $n.png"); };

}

sub setup {
    createCanvas(DIM * SCALE, DIM * SCALE);
    print STDERR "inside sketch's setup() function => dimensions(@{[join ',', gd->width, gd->height]})\n";

    # SIMPLE.3: initialize each grid object
    for my $r (0 .. DIM-1) {
        for my $c (0 .. DIM-1) {
            $grid[$r][$c] = {
                collapsed => 0,
                options => [qw/blank up right down left/],
            };
        }
    }

    GDP5::frameRate(2);
}

sub draw {
    GDP5::background(127,191,191);

    # # SIMPLE.5: experiment to verify it can draw a collapsed item
    # my $g = $grid[rand DIM][rand DIM];
    # $g->{collapsed} = 1;
    # $g->{options} = [(qw/blank up right down left/)[int rand 5]];

    # # SIMPLE.6.Experiment:
    # $grid[0][2]{options} = [qw/blank right/] unless $grid[0][2]{collapsed};
    # $grid[2][0]{options} = [qw/blank left/] unless $grid[2][0]{collapsed};

    # SIMPLE.6: Look for lowest entropy that hasn't been collapsed
    my @sortGrid = sort { scalar(@{$a->{options}}) <=> scalar(@{$b->{options}}) }
        grep { ! $_->{collapsed} }
        map {my $r = int $_/DIM; my $c = $_%DIM; $grid[$r][$c]} 0 .. DIM**2-1;
    my $n = scalar @{$sortGrid[0]{options}};
    my @filteredGrid = grep { scalar(@{$_->{options}}) == $n } @sortGrid;
    my $chosen = $filteredGrid[rand @filteredGrid]; # choose a random with lowest entropy if there's more than one

    # SIMPLE.6.next: collapse the chosen to one of its potentials
    my @options = @{$chosen->{options}};
    my $pick = $options[rand @options];
    $chosen->{options} = [$pick];
    $chosen->{collapsed} = 1;
    #use Data::Dump; dd { $chosen => $chosen, grid => \@grid };

    # SIMPLE.7: propagate:
    #   _ iterate through every cell, and if it has a neighbor that prevents one of its options, eliminate that option
    #   _ future optimization = use a "@neighbor" array, and only check neighbors of the $chosen;
    #                           if any of @neighbor collapses, then add _its_ neighbors to the array as well
    # I am NOT going to do the second grid ... so mine will actually partially propagate the collapsing
    for my $r (0 .. DIM-1) {
        for my $c (0 .. DIM-1) {
            if(!$grid[$r][$c]{collapsed}) {
                # need to check its neighbors:
                if($r>0) {
                    # TODO: look UP ($r-1)
                }
                if($r<DIM-1) {
                    # TODO: look DOWN ($r+1)
                }
                if($c>0) {
                    # TODO: look LEFT ($c-1)
                }
                if($c<DIM-1) {
                    # TODO: look RIGHT ($c+1)
                }
            }
        }
    }

    # SIMPLE.4: draw each element (collapsed is solid, superposition will be fuzzy)
    for my $r (0 .. DIM-1) {
        for my $c (0 .. DIM-1) {
            if($grid[$r][$c]{collapsed}) {
                my $name = $grid[$r][$c]{options}[0];   # the first element is the only element
                placeTile($name, $r, $c);
            } else {
                placeIndeterminant( $grid[$r][$c], $r, $c );
            }
        }
    }

    # # end SIMPLE.5
    # $g->{collapsed} = 0;
    # $g->{options} = [qw/blank up right down left/];

    my $collapsedCount = 0;
    $collapsedCount++ for grep { $_->{collapsed} } map {my $r = int $_/DIM; my $c = $_%DIM; $grid[$r][$c]} 0 .. DIM**2-1;
    print STDERR "collapsedCount = $collapsedCount with $pick as most recent\n";

    state $count = 0;
    GDP5::noLoop() if ++$count>=DIM**2;#/32 > rand();
}

sub placeTile {
    my ($tileName, $row, $col) = @_;
    gd->copyResized($im{$tileName}, $col*SCALE, $row*SCALE, 0,0, SCALE,SCALE, 3,3); # dest->src,destX,destY,srcX,srcY,destW,destH,srcW,srcH
}

sub placeIndeterminant {
    my ($gridElement, $row, $col) = @_;
    my $superposition = $im{blank}->clone();

    for my $tileName ( @{ $gridElement->{options} } ) { # ( qw/blank up right down left/ ) { #
        $superposition->copyMerge($im{$tileName}, 0,0, 0,0, 3,3, 20);      # 1/N overlay
    }
    $superposition->copyMerge($im{blank}, 0,0, 0,0, 3,3, 75);      # make it more blank

    gd->copyResized($superposition, $col*SCALE,$row*SCALE, 0,0, SCALE,SCALE, 3,3);
}

=encoding utf8

=head1 INTRODUCTION

In the CodingTrain:WaveFunctionCollapse video, there were three distinct sections:

=over

=item 1. Simple version where he just enumerated all the possible connections

=item 2. Improved version where he was able to auto-generate the possible connections based on a single-index descrption on the side

=item 3. Fancy version with length-3 descriptions to be able to align asymmetric sides

=back

This will be version 1: simple

=head1 NOTES FROM VIDEO

=begin links

        - https://www.youtube.com/watch?v=rI_y2GAlQFM?t=3340 (55:40)
        _ TODO: https://www.youtube.com/watch?v=2SuvO4Gi7uY => WFC and Sudoku!
        - https://github.com/mxgmn/WaveFunctionCollapse
        - https://github.com/CodingTrain/Wave-Function-Collapse
        - https://thecodingtrain.com/challenges/171-wave-function-collapse
        - Take notes during rewatch of video, so I can try to replicate it myself in Perl, like I did for QuadTree
                https://github.com/pryrt/passThru/blob/main/perl/quadTree/notes.md
        - NOTES: moved to C:\usr\local\share\passThru\perl\codingTrainInspired\WaveFunctionCollapse-1-Enumerate.pl

=end links

=head2 Version 1: Simple

            1. preload: loadImage (or create image) for blank, up, right, down, left
            2. global: array for grid storing state, with DIM indicating size of NxN array (though he uses a flattened version)
            3. setup: for each grid[i] = { collapsed: false, options = [BLANK,UP,RIGHT,DOWN,LEFT]}
            4. draw: double-for-loop, draw tile if collapsed, otherwise draw empty rectangle of uncertainty (idx = row*DIM+col)
            5. setup: experiment = grid[0].collapsed=true, .options=[UP], and verify it draws
            6. draw: want to pick cell with least entropy
                - gridCopy, then sort the copy (in Perl, I can just use a fancy sort, without changing array order )
                - sort-by { a.options.length - b.options.length }
                - experiment: in setup, hardcode that grid[2].options = [BLANK,UP]; in draw, make sure sorted shows grid[2] first
                - next: what if two cells have same entropy? pick randomly among them
                    - also hardcode grid[0] with same two options
                    - he codes a fancy algorithm, but onscreen popups suggest the "filter" command, similar to ListUtils::reduce, IIUC
            7. draw: start to propagate the info from collapsed cell to its neighbors
                - he makes a copy of the whole grid, but github issues suggest just looking at immediate neighbors --
                    though really there needs to be a queue, because as each neighbor collapses, it affects more
                    but I'll take notes on his method, and maybe improve later
                - Algo:
                    nextGrid = []
                    double-for(row,col) => index:
                        if grid[index].collapsed:
                            nextGrid[index] = grid[index]
                        else:
                            # pick valid options
                            options = []
                            # look UP
                            # look RIGHT
                            # look DOWN
                            # look LEFT
            8. global: define rules hash:
                BLANK   => [ [BLANK,UP], [BLANK,RIGHT], [BLANK,DOWN], [BLANK,LEFT] ]
                UP      => [ [R,L,D], [L,U,D], [B,D], [U,R,D] ]
                RIGHT   => [ [R,L,D], [L,U,D], [R,L,U], [B,L] ]
                DOWN    => [ [B,U], [L,U,D], [R,L,U], [U,R,D] ]
                LEFT    => [ [R,L,D], [B,R], [R,L,U], [U,R,D] ]
                He eventually changes this structure significantly
            9. back to draw:algo:else:
                options = [B,U,R,D,L]
                # Look UP:
                if(row>0) # skip top row, because cannot look up from there
                    up = grid[col + (row-1)*DIM)]
                    foreach option in up.options
                        valid = rules[options][DOWN]
                        checkValid(options, valid)
            10. New function:
                checkValid(arr, valid)
                    for(i=arr.length-1; i>=0; i--)
                        if !valid.includes(arr[i]) { remove it }
                    implicit return by changing the valid[] array in-memory
            11. back to draw:algo:else:
                    in the #look XXXX: do one for each,
                    #UP => if row>0
                    #RIGHT => if col<DIM-1
                    #DOWN => if row<DIM-1
                    #LEFT => if col>0
                after all those:
                    nextGrid[index] = { options: options, collapsed: false}
                then at end of draw:
                    grid = nextGrid
            12. debugging: first, fixed "tiles" to "grid" (I already fixed above)
            13. debugging: in each of the LOOKs, add to valid, then at the end call checkValid(options,validOptions)
            13. draw: end condition:
                if gridCopy.length ==0 : return

=head2 Rotate Tiles

            Section 2: 39:00ff -- different type of tile
            - Need to be able to rotate tiles.
            - Will keep track of edge type instead of an N^2 array
            1. Tile Class:
                class Tile { constructor(img,edges) {
                    this.img = img
                    this.edges = edges // array: [UP?,RT?,DN?,LT?]
                }}
            2. global: tileImages array
            3. preload: change to tileImages[] and just load blank and up (because up will rotate)
            4. setup:
                tiles[0] = new Tile(tileImages[0], [0,0,0,0])
                tiles[1] = new
                tiles[2] = tiles[1].rotate(1);  # not yet implemented
                tiles[3] = tiles[1].rotate(2);
                tiles[4] = tiles[1].rotate(3);
            5. Tile class -- define rotation:
                rotate(num) {
                    const w = this.img.width
                    const h = this.img.height
                    const newImg = createGraphics(w,h)
                    newImg.imageMode(CENTER);
                    newImg.translate(w/2, h/2);
                    newImg.rotate(HALF_PI*num);
                    newImg.image(this.img, 0,0);
                    const newEdges = [];
                    const len = this.edges.length
                    for(i=0; i<len; i++) {
                        newEdges[i] = this.edges[(i-num+len)%len]
                    }
                    return new Tile(newImg, newEdges)
                }
            6. Tile Class: auto-generate list of valid neighbors
                append to constructor:
                this.up = []
                this.right = []
                this.down = []
                this.left = []
            7. switch setup:grid[i]= to a Cell object instead of a {} object:
                grid[i] = new Cell(tiles.length);
                ...
                class Cell { constructor(num) {
                    this.collapsed=false
                    this.options = []
                    for(i<num) {
                        this.options[i] = i;
                    }
                }}
            8. add comments in setup:
                before tiles[], add         //Loaded and created the tiles
                before for/grid[i]=, add    //create cell for each spot on the grid
                after both, new section
            9. //generate adjacency rules based on edges
                for every tile= tiles[i]:
                    tile.analyze(tiles)
            10. Tile class:
                analyze(tiles) {
                    for(tile of tiles):
                        // connection for up: my UP(0) matches tile's DOWN(2)
                        if tiles.edges[2] == this.edges[0], this.up.push(tile)
                        // connection for right: my.RIGHT == tile.LEFT
                        if tiles.edges[3] == this.edges[1], this.right.push(tile)
                        // connection for down: my.DOWN == tile.UP
                        if tiles.edges[0] == this.edges[2], this.down.push(tile)
                        // connection for left: my.LEFT == tile.RIGHT
                        if tiles.edges[1] == this.edges[3], this.down.push(tile)
                }
            11. change order from 8-9: 1) LOAD & ROTATE, 2) GENERATE, 3) CREATE CELL
            12. Go into the "LOOK" section
                if(j>0) {
                    up = grid[i+(j-1)*DIM]
                    validOptions = []
                    for(let option of up.options)
                        valid = tiles[option].down
                        validOptions = validOptions.concat(valid)
                    checkValid
                }
                ditto for the remainder of the LOOK
            13. debug: just before LOOK UP, change the options initializer to
                new array(titles.length).fill(0).map((x,i) => i)
                    // start with all options
            14. debug: forgot
                    nextGrid[index] = new Cell(options);
                but it required tweaking, to propagate options
                in Cell constructor:
                    if(num instanceof Array)
                        this.options = num; // the array
                    else
                        the old options initializer
                -- also change param from `num` to `value`
            15. debug: checkValue and analyze weren't agreeing on data structure
                change for loop in analyze back to
                    for(i<tiles.length)
                        let tile = tiles[i]
                        // XXX... this.up.push(i) instead of push(tile)
            This is now working (up to finding a dead end) for automatically
                finding adjacencies for a given tile based on the data,
                55:40 (3340sec)

=head2 Getting Fancy

    https://www.youtube.com/watch?v=rI_y2GAlQFM?t=3340 (55:40)

=cut
