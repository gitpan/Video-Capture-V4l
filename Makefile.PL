use ExtUtils::MakeMaker;

if ($^O ne "linux") {
   print "\nFolks, Video4linux, as the name implies, requires linux.\n";
   print "Configuring anyway, but you have been warned!\n\n";
}

WriteMakefile(
    'dist'	=> {
	            PREOP	=> 'pod2text V4l.pm >README; chmod -R u=rwX,go=rX . ;',
	            COMPRESS	=> 'gzip -9v',
	            SUFFIX	=> '.gz',
	           },
    'NAME'	=> 'Video::Capture::V4l',
    'VERSION_FROM' => 'V4l.pm',
    'LIBS'	=> [''],
    'DEFINE'	=> '-D_GNU_SOURCE',
    'INC'	=> '',
);
