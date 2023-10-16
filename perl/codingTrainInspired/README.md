This folder will contain various programs inspired by Coding Train videos

The QuadTree (see up one directory) should really be included, but I worked on it before I decided on this separate directory, but couldn't be bothered to move it. ;-)

The equivalent of `sketch.js` will be a reasonably-named `ProjectName.pl`.  Any extra modules will go in the `lib` directory, though if a package/class is small enough, I'll probably just keep it in the sketch instead.  Each project might also have a `ProjectName.README.md`, or I might just keep the notes in the `__END__` or POD `=begin README` sections

Some day, I might write an encapsulating library that links to GD::Image's `gifanimadd()` (much like the win32-based GUI I had started with then abandoned) to give syntax that's more like P5.js.  But that hasn't happened yet, so most of the scripts will have some common GD-boilerplate to begin with.
