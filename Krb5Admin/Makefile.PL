#
#

use Config;
use ExtUtils::MakeMaker;

use strict;
use warnings;

#
# XXXrcd: we use environment variables to determine the location
#         of the Kerberos libraries because for some reason,
#         ExtUtils::MakeMaker doesn't let me pass new variables
#         on the command line without emitting a warning.
#
#         We also attempt to locate a few of these things automagically.

my $KRB5DIR = $ENV{KRB5DIR};

if (!defined($KRB5DIR)) {
	die "Must have KRB5DIR set before building this Makefile.PL, " . 
	    "this should be done by the parent Makefile.PL.\n";
}

if (!defined($ENV{KRB5TYPE})) {
	die "Must have KRB5TYPE set before building this Makefile.PL, " .
	    "this should be done by the parent Makefile.PL.\n";
}

my $HAVE;
if (defined($ENV{KRB5TYPE})) {
	$HAVE = '-DHAVE_MIT'		if $ENV{KRB5TYPE} eq 'mit';
	$HAVE = '-DHAVE_HEIMDAL'	if $ENV{KRB5TYPE} eq 'heimdal';
}

if (!defined($HAVE)) {
	die "Unrecognised Kerberos type: " . $ENV{KRB5TYPE} .
	    ".  Must be mit or heimdal.\n";
}

if (-f "$KRB5DIR/include/krb5/hdb.h") {
	$HAVE .= ' -DHEIMDAL_INCLUDES_IN_KRB5';
}

# XXXrcd: we still need to deal with this one:
#  $HAVE	.= ' -DHAVE_CTX_IN_KADM5';

my %args;

$args{NAME}	= 'Krb5Admin::C';
$args{OBJECT}	= 'C_wrap.o curve25519-donna.o';

$args{INC}	= "-I${KRB5DIR}/include";

$args{PM}	= { 'C.pm' => '$(INST_LIB)/Krb5Admin/C.pm' };

if ($HAVE eq '-DHAVE_MIT') {
	$args{INC}	.= " -I${KRB5DIR}/include/krb5"		.
			   " -I/var/tmp/krb5-1.4.4/src/include"          .
			   " -I/var/tmp/krb5-1.4.4/src/include/krb5";
}

$args{CCFLAGS}	= $Config{ccflags} . " " . $HAVE;
$args{LIBS}	= "-L${KRB5DIR}/lib -Wl,-R${KRB5DIR}/lib ";

$args{LIBS} .= "-lkrb5 -lkadm5srv";

$args{clean} = { FILES => "C_wrap.c C.pm" };

WriteMakefile(%args);

sub MY::xs_c {
	"C.pm: C_wrap.c\n\n" .
	"C_wrap.c: C.c C.swig C.h \n	swig -perl5 ${HAVE} -const C.swig\n\n";
}
