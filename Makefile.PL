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
# Contributor(s):
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
use strict;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my %config;

while($_ = shift) {
    my ($key, $val) = split(/=/, $_, 2);
    $config{$key} = $val;
}

my $DEBUG = delete $config{DEBUG};

if (delete $config{CHARLIE}) {
    $config{LIBS} = "-L$ENV{CHARLIE_HOME}/lib -lsablot -lexpat";
    $config{INC} = '-I$(CHARLIE_HOME)/include';
}

if ($^O eq 'MSWin32') {
    $config{LIBS} ||= 'sablot.lib expat.lib';
    $config{INC} ||= '';

    if ($config{LIBS} !~ /sablot.lib/) {
	$config{LIBS} .= ' sablot.lib';
    }
    
    if ($config{LIBS} !~ /expat.lib/) {
	$config{LIBS} .= ' expat.lib';
    }
} else {
    $config{LIBS} ||= '-L/usr/local/lib -L/usr/lib -lsablot -lexpat';
    $config{INC} ||= '-I/usr/local/include -I/usr/include';

    if ($config{LIBS} !~ /\-lsablot/) {
	$config{LIBS} .= ' -lsablot';
    }
    
    if ($config{LIBS} !~ /\-lexpat/) {
	$config{LIBS} .= ' -lexpat';
    }
}


have_library('expat', 'main', '') || die <<DEATH;
You do not appear to have libexpat in the library search path.
Either install expat from http://expat.sourceforge.net/ or
re-run as:
  \$ $^X Makefile.PL LIBS='-L/path/to/expat/lib -lexpat -lsablot'

DEATH

my $olibs;
if ($^O eq 'MSWin32') {
    $olibs = "expat.lib";
} else {
    $olibs = '-lexpat -lm';
}
have_library('sablot', 'main', $olibs) || die <<DEATH;
You do not appear to have libsablot in the library search path.
Either install sablotron from http://www.gingerall.com/ or
re-run as:
  \$ $^X Makefile.PL LIBS='-L/path/to/sablot/lib -lexpat -lsablot'

DEATH

WriteMakefile(
    NAME	=> 'XML::Sablotron',
    VERSION_FROM => 'Sablotron.pm', 
    DEFINE	=> '-DPERL_POLLUTE',
    clean     => {'FILES' => "log.xsl", },
    %config,
);

use Config;
use Symbol;

use vars qw/$LINK/;

BEGIN {
    if ($^O eq 'MSWin32') {
	$LINK = "$Config{cc} %s $Config{ldflags} conftest.c %s %s"
    } else {
	$LINK = "$Config{ld} -o conftest $Config{ccflags} -I$Config{incpath} %s $Config{ldflags} conftest.c %s %s";
    }
}

sub rm_f {
    my @files = @_;
    my @realfiles;
    foreach (@files) {
        push @realfiles, glob($_);
    }
    if (@realfiles) {
        chmod(0777, @realfiles);
        unlink(@realfiles);
    }
}

sub xsystem {
    my $command = shift;
    if ($DEBUG) {
        print $command, "\n";
        if (system($command) != 0) {
            die "system call to '$command' failed";
        }
        return 1;
    }
    open(OLDOUT, ">&STDOUT");
    open(OLDERR, ">&STDERR");
    open(STDOUT, ">/dev/null");
    open(STDERR, ">/dev/null");
    my $retval = system($command);
    open(STDOUT, ">&OLDOUT");
    open(STDERR, ">&OLDERR");
    if ($retval != 0) {
        die "system call to '$command' failed";
    }
    return 1;
}

sub backtick {
    my $command = shift;
    if ($DEBUG) {
        print $command, "\n";
        my $results = `$command`;
        chomp $results;
        if ($? != 0) {
            die "backticks call to '$command' failed";
        }
        return $results;
    }
    open(OLDOUT, ">&STDOUT");
    open(OLDERR, ">&STDERR");
    open(STDOUT, ">/dev/null");
    open(STDERR, ">/dev/null");
    my $results = `$command`;
    my $retval = $?;
    open(STDOUT, ">&OLDOUT");
    open(STDERR, ">&OLDERR");
    if ($retval != 0) {
        die "backticks call to '$command' failed";
    }
    chomp $results;
    return $results;
}

sub remove_l {
    my $str = shift;
    my @flds = split /\s+/, $str;
    return join " ", grep {/^-L/} @flds;
}

sub try_link0 {
    my ($src, $opt) = @_;
    my $cfile = gensym();
    open($cfile, ">conftest.c") || die "Cannot write to file conftest.c";
    print $cfile $src;
    close($cfile);
    xsystem(sprintf($LINK, $config{INC}, remove_l($config{LIBS}), $opt));
}

sub try_link {
    my $result = eval {
        try_link0(@_);
    };
    warn $@ if $DEBUG && $@;
    rm_f("conftest*");
    return $result;
}

sub have_library {
    my ($lib, $func, $other_libs) = @_;
    printf("checking for %s() in -l%s... ", $func, $lib);

    my $result;
    if ($func) {
        if ($^O eq 'MSWin32') {
	    my $libs = "${lib}.lib $other_libs";
            $result = try_link(<<"SRC", $libs);
#include <windows.h>
#include <winsock.h>
int main() { return 0; }
int t() { ${func}(); return 0; }
SRC
            unless ($result) {
                $result = try_link(<<"SRC", $libs);
#include <windows.h>
#include <winsock.h>
int main() { return 0; }
int t() { void ((*p)()); p = (void ((*)()))${func}; return 0; }
SRC
            }
        }
        else {
	    my $libs = "-l$lib $other_libs";
            $result = try_link(<<"SRC", $libs);
int main() { return 0; }
int t() { ${func}(); return 0; }
SRC
        }
    }

    unless ($result) {
        print "no\n";
        return 0;
    }

    if ($func ne "main") {
        $config{DEFINE} .= uc(" -Dhave_$func");
    }

    print "yes\n";
    return 1;
}

__END__
