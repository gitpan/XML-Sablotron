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

use Getopt::Std;

my ($include, $libpth);

my %foo;
getopts('cd:', \%foo);

if ( $foo{c} ) {
    $libpth = "-L$ENV{CHARLIE_HOME}/lib";    
    $include = '-I$(CHARLIE_HOME)/include';
}

if ( $foo{d} ) {
    $libpth = "-L$foo{d}/lib";
    $include = "-I$foo{d}/include";
}

WriteMakefile(
    NAME	=> 'XML::Sablotron',
    VERSION_FROM => 'Sablotron.pm', 
    DEFINE	=> '-DPERL_POLLUTE',
    INC         => $include,
    LIBS	=> ["$libpth -lsablot -lxmlparse -lxmltok"], 
    clean     => {'FILES' => "log.xsl", },
);


__END__

