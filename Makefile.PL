#
# The contents of this file are subject to the Mozilla Public
# License Version 1.1 (the "License"); you may not use this file
# except in compliance with the License. You may obtain a copy of
# the License at http://www.mozilla.org/MPL/
# 
# Software distributed under the License is distributed on an "AS
# IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or
# implied. See the License for the specific language governing
# rights and limitations under the License.
# 
# The Original Code is the XML::Sablotron module.
# 
# The Initial Developer of the Original Code is Ginger Alliance Ltd.
# Portions created by Ginger Alliance are 
# Copyright (C) 1999-2000 Ginger Alliance Ltd. 
# All Rights Reserved.
# 
# Contributor(s): Matt Sergeant
# 
# Alternatively, the contents of this file may be used under the
# terms of the GNU General Public License Version 2 or later (the
# "GPL"), in which case the provisions of the GPL are applicable 
# instead of those above.  If you wish to allow use of your 
# version of this file only under the terms of the GPL and not to
# allow others to use your version of this file under the MPL,
# indicate your decision by deleting the provisions above and
# replace them with the notice and other provisions required by
# the GPL.  If you do not delete the provisions above, a recipient
# may use your version of this file under either the MPL or the
# GPL.
# 

use ExtUtils::MakeMaker;
use English;
use Config;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

$expat_libpath = '';
$expat_incpath = '';

my @replacement_args;

foreach (@ARGV) {
  if (/^EXPAT(LIB|INC)PATH=(.+)/) {
    if ($1 eq 'LIB') {
      $expat_libpath = $2;
    }
    else {
      $expat_incpath = $2;
    }
  }
  else {
    push(@replacement_args, $_);
  }
}

@ARGV = @replacement_args;

unless ($expat_libpath) {
  # Test for existence of libexpat
  my $found = 0;
  foreach (split(/\s+/, $Config{libpth})) {
    if (-f "$_/libexpat." . $Config{so}) {
      $found = 1;
      last;
    }
  }

  unless ($found) {
    die <<'Expat_Not_Installed;';

Expat must be installed prior to building XML::Sablotron and I can't find
it in the standard library directories. You can download expat from:

http://sourceforge.net/projects/expat/

If expat is installed, but in a non-standard directory, then use the
following options to Makefile.PL:

    EXPATLIBPATH=...  To set the directory in which to find libexpat

For example:

    perl Makefile.PL EXPATLIBPATH=/home/me/lib EXPATINCPATH=/home/me/include

Note that if you build against a shareable library in a non-standard location
you may (on some platforms) also have to set your LD_LIBRARY_PATH environment
variable at run time for perl to find the library.

Expat_Not_Installed;
  }
}

#the same thing for sablotron
$sablot_libpath = '';
$sablot_incpath = '';

@replacement_args = ();

foreach (@ARGV) {
  if (/^SABLOT(LIB|INC)PATH=(.+)/) {
    if ($1 eq 'LIB') {
      $sablot_libpath = $2;
    }
    else {
      $sablot_incpath = $2;
    }
  }
  else {
    push(@replacement_args, $_);
  }
}

@ARGV = @replacement_args;

unless ($sablot_libpath) {
  # Test for existence of libexpat
  my $found = 0;
  foreach (split(/\s+/, $Config{libpth})) {
    if (-f "$_/libsablot." . $Config{so}) {
      $found = 1;
      last;
    }
  }

  unless ($found) {
    die <<'Sablot_Not_Installed;';

Sablot must be installed prior to building XML::Sablotron and I can't find
it in the standard library directories. You can download Sablotron from:

http://www.gingerall.cz

If Sablotron is installed, but in a non-standard directory, then use the
following options to Makefile.PL:

    SABLOTLIBPATH=...  To set the directory in which to find libexpat

    SABLOTINCPATH=...  To set the directory in which to find expat.h

For example:

    perl Makefile.PL SABLOTLIBPATH=/home/me/lib SABLOTINCPATH=/home/me/include

Note that if you build against a shareable library in a non-standard location
you may (on some platforms) also have to set your LD_LIBRARY_PATH environment
variable at run time for perl to find the library.

Sablot_Not_Installed;
  }
}

$libs = "-lsablot -lexpat";
unless ($^O eq 'MSWin32') {
    $libs = "$libs -lm";
}

$libs = "-L$expat_libpath $libs"
  if $expat_libpath;
$libs = "-L$sablot_libpath $libs"
  if $sablot_libpath;

$inc = "-I$expat_incpath"
  if $expat_incpath;
$inc = "-I$sablot_incpath $inc"
  if $sablot_incpath;

push(@extras, INC => $inc) if $inc;

push(@extras, CAPI => 'TRUE')
    if ($PERL_VERSION >= 5.005 and $OSNAME eq 'MSWin32');

WriteMakefile(
	      NAME	=> 'XML::Sablotron',
	      AUTHOR    => 'Pavel Hlavnicka (pavel@gingerall.cz)',
	      ABSTRACT  => 'Sablotron XSLT processor wrapper',
	      VERSION_FROM => 'Sablotron.pm', 
	      DEFINE	=> '-DPERL_POLLUTE',
	      clean     => {'FILES' => "log.xsl", },
	      dist	=> {COMPRESS => 'gzip', SUFFIX => 'tar.gz'},
	      DIR       => [qw( Sablotron )],
	      LIBS      => $libs, 
	      @extras,
);


__END__

