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

package XML::Sablotron;

use strict;
use Carp;
use vars qw( $VERSION @ISA @EXPORT_OK %EXPORT_TAGS );

require Exporter;
require DynaLoader;

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

$VERSION = '0.43';

my @functions = qw (
SablotProcessStrings 
SablotProcess 
ProcessStrings 
Process 
);

#deprecated export functions
#RegMessageHandler
#UnregMessageHandler
#SablotRegMessageHandler
#SablotUnregMessageHandler

@EXPORT_OK = @functions;
%EXPORT_TAGS = ( all => [@functions] );

BEGIN {

}

############################################################
# function for backward compatibility (non-object functions)
############################################################

sub SablotProcessStrings {
    ProcessStrings(@_);
}

sub SablotProcess {
    Process(@_);
}

#sub SablotRegMessageHandler {
#    RegMessageHandler(@_);
#}

#sub SablotUnregMessageHandler {
#    UnregMessageHandler(@_);

sub new {
    my $class = shift;
    $class = (ref $class) || $class;
    my $self = {};
    bless $self, $class;
    my $foo = new XML::Sablotron::Processor();
    $self->{_processor} = $foo;
    #$self->{_processor}->_setInstanceData();
    return $self;
}

#############################################
# I've choosen this way (no AUTOLOAD)
# to avoid problems in the future
sub RunProcessor {
    my $self = shift;
    return $self->{_processor}->RunProcessor(@_);
}

sub RunProcessorTie {
    my ($self, $t, $d, $o, $params, $args, $tieclass) = @_;
    my (@params, @args);
    eval "require $tieclass;";
    tie @params, $tieclass, $params;
    tie @args, $tieclass, $args;
    my $ret =  $self->{_processor}->RunProcessor($t, $d, $o, \@params, \@args);
    return $ret;
}

sub GetResultArg {
    my $self = shift;
    return $self->{_processor}->GetResultArg(@_);
}

sub RegHandler {
    my $self = shift;
    return $self->{_processor}->RegHandler(@_);
}

sub UnregHandler {
    my $self = shift;
    return $self->{_processor}->UnregHandler(@_);
}

sub FreeResultArgs {
    my $self = shift;
    return $self->{_processor}->FreeResultArgs(@_);
}

sub SetBase {
    my $self = shift;
    return $self->{_processor}->SetBase(@_);
}

sub SetLog {
    my $self = shift;
    return $self->{_processor}->SetLog(@_);
}

sub ClearError {
    my $self = shift;
    return $self->{_processor}->ClearError(@_);
}


DESTROY {
    my $self = shift;
    if (defined $self->{_processor}) {
	#break circular reference in XML::Sablotron::Processor
	$self->{_processor}->_release();
	undef $self->{_processor};
    }
}

bootstrap XML::Sablotron $VERSION;

1;

############################################################
# inner object (holds circular reference)
############################################################
package XML::Sablotron::Processor;

use vars qw( $_unique );

sub new {
    my $class = shift;
    $class = (ref $class) || $class;
    my $self = {};
    bless $self,  $class;
    $self->{_handle} = $self->_createProcessor();
    $self->{_handlers} = []; #confusing names, aren't? :-)
    return $self;
}

my $pkg_template = <<'eof';
sub new {
my $cn = shift;
bless {}, $cn;
}
eof

sub RegHandler {
    my ($self, $type, $ref) = @_;
    my $wrapper;
    if ((ref $ref eq "HASH")) {
	$_unique++;
	my $classname = "sablot_handler_$_unique";
	eval ("package $classname;\n" . $pkg_template);
	no strict;
	foreach (keys %$ref) {
	    *{"${classname}::$_"} = $$ref{$_};
	}
	use strict;
	$wrapper = eval "new $classname()";
    } else {
	$wrapper = $ref;
    }
    
    warn "Trying to register the same handler twice\n"
      if grep {${$_}[0] == $type and ${$_}[1] == $wrapper} 
	@{$self->{_handlers}}; 

    #the trick with @foo is very important for correct refernce counting
    my @foo = ($type, $wrapper);
    push @{$self->{_handlers}}, \@foo;;

    my $ret = $self->_regHandler(@foo);

    return $ret;
}

sub UnregHandler {
    my ($self, $type, $wrapper) = @_;
    for (my $i = 0; $i <= $#{$self->{_handlers}}; $i++) {
	my $he = ${$self->{_handlers}}[$i];
	if ($$he[0] == $type and $$he[1] = $wrapper) {
	    $self->_unregHandler($$he[0], $$he[1]);
	    splice @{$self->{_handlers}}, $i, 1;
	    last;
	}
    }
}

sub _releaseHandlers {
    my $self = shift;
    my $he; #handler entry
    foreach $he (@{$self->{_handlers}}) {
	$self->_unregHandler($$he[0], $$he[1]);
    }
    @{$self->{_handlers}} = ();
}

DESTROY {
    my $self = shift;
    $self->_releaseHandlers();
    $self->_destroyProcessor();
}


__END__

=head1 NAME

XML::Sablotron - a Perl interface to the Sablotron XSLT processor

=head1 SYNOPSIS

  use XML::Sablotron qw (:all);
  Process(.....);

If you prefer an object approach, you can use the object wrapper:

  $sab = new XML::Sablotron();
  $sab->RunProcessor($template_url, $data_url, $output_url, 
                  \@params, \@arguments);
  $result = $sab->GetResultArg($output_url);

=head1 DESCRIPTION

This package is very simple interface to the Sablotron API. OK, but what
does Sablotron mean? 

Sablotron is an XSLT processor implemented in C++ based on the Expat XML parser.

If want to run this package, you need download and install
Sablotron from the
http://www.gingerall.cz/charlie-bin/get/webGA/act/download.act page. 

You do _not_ need to download Expat, or any other Perl packages to run
the XML::Sablotron package.

=head1 USAGE

=head2 ProcessStrings

C<ProcessStrings($template, $data, $result);>

where...

=over 4

=item  $template 

contains an XSL stylesheet

=item  $data 

contains an XML data to be processed

=item  $result 

is filled with the desired output

=back

This function returns the Sablotron error code.

=head2 Process

This function provides a more general interface to Sablotron. You may
find its usage a little bit tricky but it offers a variety of ways how
to modify the Sablotron behavior.

  Process($template_uri, $data_uri, $result_uri,
          $params, $buffers, $result);

where...

=over 4

=item  $template_uri 

is a URI of XSL stylesheet

=item  $data_uri 

is a URI of processed data

=item  $result_uri 

is a URI of destination buffer. Currently, the arg: scheme
is supported only. Use the value arg:/result. (the name of the
$result variable without "$" sign)

=item  $params 

is a reference to array of global stylesheet parameters

=item  $buffers 

is a reference to array of named buffers

=item  $result 

receives the result. It requires $result_uri to be set to arg:/result.

=back

The following example should make it clear.

  Process("arg:/template", "arg:/data", "arg:/result", 
          undef, 
          ["template", $template, "data", $data], 
          $result);>

does exactly the same as

  ProcessStrings($template, $data, $result);>

Why is it so complicated? Please, see the Sablotron documentation for
details.

This function returns the Sablotron error code.

=head2 RegMessageHandler

This function is deprecated and no longer supported. See the description of
object interface later in this document.

=head2 UnregMessageHandler

This function is deprecated and no longer supported. See the description of
object interface later in this document.

=head1 OBJECT INTERFACE

This is a short intro for people, who like it hot. Skip this preface, 
if you just want to use this package the "ordinary" way.

There are two classes defined to deal with the Sablotron processor object.

C<XML::Sablotron::Processor> is a class implementing an interface to
the Sablotron processor object. Currently, there is no way,
how to create more then one instance of the processor object but the use of
multiple object should be supported soon. Usually, you don't need to
use this class directly (except using handlers but it is a painless
case). 

Implementation of this class contains a circular reference inside Perl
structures, which has to be broken calling the C<_release> method. If
you aren't going to do some strange hacks, you can forget this explanation.

C<XML::Sablotron> is often the only thing you need. It's a wrapper
around the XML::Sablotron::Processor object. The only quest of this class is to
keep track of life-cycle of the processor, so you don't have to deal with
a reference counting inside the processor class. All calls to this class are
redirected to an inner instance of the XML::Sablotron::Processor object.

=head1 XML::Sablotron

=head2 Constructor

The constructor of the XML::Sablotron object takes no arguments, so you can create new
instance simply like this:

  $sab = new XML::Sablotron();

=head2 RunProcessor

The RunProcessor method is analogous to the Process function.

  $code = $sab->RunProcessor($template_uri, $data_uri, $result_uri,
                             $params, $buffers);

where...

=over 4

=item  $template_uri 

is a URI of XSL stylesheet

=item  $data_uri 

is a URI of processed data

=item  $result_uri 

is a URI of destination buffer

=item  $params 

is a reference to array of global stylesheet parameters

=item  $buffers 

is a reference to array of named buffers

=back

Note the difference between the RunProcessor method and the Process
function. RunProcessor doesn't return the output buffer ($result parameter
is missing).

To obtain the result buffer(s) you have to call the L<"GetResultArg"> method.

Example of use:

  RunProcessor("arg:/template", "arg:/data", "arg:/result", 
          undef, 
          ["template", $template, "data", $data] );

=head2 GetResultArg

Call this function to obtain the result buffer after processing. The goal
of this approach is to enable multiple output buffers. This
little inconvenience of use is not so painful hopefully.

  $result = $sab->GetResultArg($output_url);

This method returns a desired output buffer specified by its url.

The recent example of the RunProcessor method should continue:

  $return = $sab->GetResultArg("result");

=head2 FreeResultArgs

  $sab->FreeResultArgs();

This call frees up all output buffers allocated by Sablotron. You do not
have to call this function as these buffers are managed by the processor
internally.

Use this function to release huge chunks of memory while an instance of
processor stays idle for a longer time, for example.

=head2 RegHandler

Set certain type of an external handler. The processor can use the handler for
miscellaneous tasks such log and error messaging ...

For more details on handlers see the L<"HANDLERS"> section of this
document. 

There are two ways how to call the RegHandler method:

  $sab->RegHandler($type, $handler);

where...

=over 4

=item $type 

is the handler type (see L<"HANDLERS">)

=item $handler 

is an object implementing the handler interface

=back

The second way allows to create anonymous handlers defined as a set of
function calls:

  $sab->RegHandler($type, { handler_stub1 => \&my_proc1,
                          handlerstub2 => \&my_proc2.... });

However, this form is very simple. It disallows to unregister the handler
later. 

For the detailed description of handler interface see the Handlers section.

=head2 UnregHandler

  $sab->UnregHandler($type, $handler);

This method unregisters a registered handler.

Remember, that anonymously registered handlers can't be
unregistered. (Of course, they can be canceled but it's a little bit
tricky).

=head2 SetBase

  $sab->SetBase($base_url);

Call this method to make processor to use the C<$base_url> base URI while
resolving any relative URI within a data or template.

=head2 SetBaseForScheme

  $sab->SetBaseForScheme($scheme, $base);

Like C<SetBase>, but given base URL is used only for specified scheme.

=head2 SetLog

  $sab->SetLog($filename);

This methods sets the log file name.

=head2 ClearError

  $sab->ClearError();

This methods clears the last internal error of processor.

=head1 HANDLERS

Currently, Sablotron supports three flavors of handlers.

=over 4

=item * messages handler (0)

=item * scheme handler (1)

=item * SAX-like output handler (2)

=item * miscellaneous handler (3)

=back

I have to say that in this moment the XML::Sablotron
extension supports only the first two of them.

=head2 General interface format

Call-back functions implementing handlers are of different prototypes
(not a prototypes in the Perl meaning) but the first two parameters are
always the same:

=over

=item $self

is a reference to registered object, so you can implement handlers the
common object way. If you register a handler with a hash reference (see
L<RegHandler>, this parameter refers to a hidden object, which is
useless for you.

=item $processor

is reference to the processor, which is actually calling your handler. It
allows you to use one handler for more than one processor.

=back

=head2 Messages handler - overview

The goal of this handler is to deal with all messages produced by
a processor.

Each state reported by the processor is composed of the following data:

=over 4

=item * severity

zero means: not so bad thing; 1 means: OOPS, bad thing

=item * facility

Helps to determine who is reporting in larger systems. Sablotron
always sets this value to 2.

=item * code

An internal Sablotron code.

=back

Each reported event falls into one of predefined categories, which
define the event level. The valid levels include:

=over 4

=item * debug (0)

all stuff

=item * info (1)

informations for curious people

=item * warn (2)

warnings on suspicious things

=item * error (3)

huh, something is wrong

=item * critical (4)

very, very bad day...

=back

The numbers in the parentheses are the internal level codes.

=head2 Messages handler - interface

To define a messages handler, you have to define the following functions (or
methods, depending on kind of registration, see L<"RegHandler">).

=over

=item MHMakeCode($self, $processor, $severity, $facility, $code)

This function is called whenever Sablotron needs display any
message. It helps you to convert the internal codes into your own space of
numbers. After this call Sablotron forgets its code and use the yours.

To understand parameters of this call see: 
L<"Messages handler - overview">

=item MHLog($self, $processor, $code, $level, @fields)

A Sablotron request to log some event.

=over

=item  $code 

is the code previously returned by MHMakeCode

=item  $level 

is the event level (see L<"Messages handler - overview">)

=item  @fields 

are text fields in format of "fldname: following text"

=back

=item MHError($self, $processor, $code, $level, @fields)

is very similar to the MHLog function but it is called only when a bad thing
happens (error and critical levels).

=back

=head2 Messages handler - example

A very simple message handler could look like this:

  sub myMHMakeCode {
      my ($self, $processor, $severity, $facility, $code);
      return $code; #i can deal with internal numbers
  }

  sub myMHLog {
      my ($self, $processor, $code, $level, @fields);
      print LOGHANDLE "[Sablot: $code]\n" . (join "\n", @fields, "");
  }

  sub myMHError {
      myMHlog(@_);
      die "Dying from Sablotron errors, see log\n";
  }

  $sab = new XML::Sablotron();
  $sab->RegHandler(0, { MHMakeCode => \&myMHMakeCode,
                        MHLog => \&myMHLog,
                        MHError => \&myMHError });

That's all, folks.

=head2 Scheme handler - overview

One of great features of Sablotron is the possibility of Scheme
handlers. This feature allows to reference data from any URL
scheme. Every time the processor is asked for some URI
(e.g. using the document() function), it looks for a handler, 
which can resolve the required document.

Sablotron asks the handler for all the document at once. If the handler
refuses this request, Sablotron "opens" a connection to the handler and tries
to read the data "per partes".

A handler can be used for the output buffers as well, so this mechanism also 
supports the "put" method.

=head2 Scheme handler - interface

=over

=item SHGetAll($self, $processor, $scheme, $rest)

This function is called, when the processor is trying to resolve
a document. It supposes, that the MHGetAll function returns the whole document. 

If you're going to use the second way (giving chunks of the document), simply
don't implement this function or return the C<undef> value from it. 

  $scheme parameter holds the scheme extracted from a URI
  $rest holds the rest of the URI

=item SHOpen($self, $processor, $scheme, $rest);

This function is called immediately after SHGet or SHPut is called. Use it
to pass some "handle" (I mean a user data) to the processor. This data will
be a part of each following request (SHGet, SHPut).

=item SHGet($self, $processor, $handle, $size)

This function returns the following chunk of data. The size of the data
MUST NOT be greater then the $size parameter.

$handle is the value previously returned from the SHOpen function.

Return the C<undef> value to say "No more data".

=item SHPut($self, processor, $handle, $data)

This function stores a chunk of data given in the $data parameter.

=item SHClose($self, $processor, $handle)

You can close you internal connections, files, etc. using this function.

=back

=head2 Scheme handler - example

See the test script (test.pl) included in this distribution.

=head2 SAX handler

The SAX-like handler is not yet supported.

=head2 Miscellaneous handler

This handler was introduced in version 0.42 and could be subject of
change in the near future. For the namespace collision with message
handler misc. handler uses prefix 'XS' (like eXtended features).

=over

=item XHDocumentInfo($self, $processor, $contentType, $encoding)

This function is called, when document attributes are specified via
<xsl:output> instruction. C<$contentType> holds value of "media-type"
attribute, C<$encoding> holds value of "ecoding attribute.

Return value of this callback is discarded.

=back

=head2 Miscellaneous handler - example

Suppose template like this:

  <?xml version='1.0'?>
  ...
  <xsl:output media-type="text/html" encoding="iso-8859-2"/>
  ...

In this case XSDocumentInfo callback function is called with values of
"text/html" and "iso-8859-2".

=head1 LICENSE

This package is subject to the MPL (or the GPL alternatively).

The same licensing applies for Sablotron.


=head1 AUTHOR

Pavel Hlavnicka; pavel@gingerall.cz

=head1 SEE ALSO

perl(1).

=cut
