use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Eesh',
    'VERSION_FROM' => 'Eesh.pm', # finds $VERSION
    'LIBS'	=> ['-L/usr/X11R6/lib -lX11'],   # e.g., '-lm' 
    'DEFINE'	=> '',     # e.g., '-DHAVE_SOMETHING' 
    'INC'	=> '',     # e.g., '-I/usr/include/other' 
    'OBJECT'    => '$(BASEEXT)$(OBJ_EXT) alert.o comms.o file.o globals.o lists.o memory.o setup.o',
);


sub MY::postamble {
'eesh:
	cp enlightenment*/eesh/*.{o,h} .
	cp enlightenment*/econfig.h .
'
}
