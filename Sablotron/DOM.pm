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
# The Original Code is the XML::Sablotron::DOM module.
# 
# The Initial Developer of the Original Code is Ginger Alliance Ltd.
# Portions created by Ginger Alliance are 
# Copyright (C) 1999-2000 Ginger Alliance Ltd.
# All Rights Reserved.
# 
# Contributor(s): Albert.N.Micheev
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

package XML::Sablotron::DOM;

#require 5.005_62;
use strict;
use Carp;

require XML::Sablotron;

require Exporter;
require DynaLoader;

my @_constants = qw ( ELEMENT_NODE ATTRIBUTE_NODE TEXT_NODE 
		      CDATA_SECTION_NODE ENTITY_REFERENCE_NODE
		      ENTITY_NODE PROCESSING_INSTRUCTION_NODE
		      COMMENT_NODE DOCUMENT_NODE DOCUMENT_TYPE_NODE
		      DOCUMENT_FRAGMENT_NODE NOTATION_NODE 
		      
		      SDOM_OK INDEX_SIZE_ERR HIERARCHY_ERR 
		      WRONG_DOCUMENT_ERR NO_MODIFICATION_ALLOWED_ERR
		      NOT_FOUND_ERR INVALID_NODE_TYPE_ERR
		      QUERY_PARSE_ERR QUERY_EXECUTION_ERR NOT_OK );

use vars qw(@ISA %EXPORT_TAGS @EXPORT_OK @EXPORT
	   );
@ISA = qw(Exporter DynaLoader);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use XML::Sablotron::DOM ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.

my @_functions = qw ( parse 
		      parseBuffer 
		      parseStylesheet 
		      parseStylesheetBuffer);

%EXPORT_TAGS = ( 'all' => [ @_constants, @_functions ],
		     'constants' => \@_constants,
		     'functions' => \@_functions,
		   );

@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

@EXPORT = qw(createNode);

#constants for node types
use constant ELEMENT_NODE => 1;
use constant ATTRIBUTE_NODE => 2;
use constant TEXT_NODE => 3;
use constant CDATA_SECTION_NODE => 4;
use constant ENTITY_REFERENCE_NODE => 5;
use constant ENTITY_NODE => 6;
use constant PROCESSING_INSTRUCTION_NODE => 7;
use constant COMMENT_NODE => 8;
use constant DOCUMENT_NODE => 9;
use constant DOCUMENT_TYPE_NODE => 10;
use constant DOCUMENT_FRAGMENT_NODE => 11;
use constant NOTATION_NODE => 12;
use constant OTHER_NODE => 13; #not in spec

#constants for error codes
use constant SDOM_OK => 0;
use constant INDEX_SIZE_ERR => 1;
use constant HIERARCHY_ERR => 3;
use constant WRONG_DOCUMENT_ERR => 4;
use constant NO_MODIFICATION_ALLOWED_ERR => 7;
use constant NOT_FOUND_ERR => 8;
use constant INVALID_NODE_TYPE_ERR => 9;
use constant QUERY_PARSE_ERR => 10;
use constant QUERY_EXECUTION_ERR => 11;
use constant NOT_OK => 12;

# executable prt of the module
bootstrap XML::Sablotron::DOM $XML::Sablotron::VERSION;

1;

########################## Node #######################
package XML::Sablotron::DOM::Node;

sub equals {
    my ($self, $other) = @_;
    return $self->{_handle} == $other->{_handle};
}

sub removeChild {
    my ($self, $child, $sit) = @_;
    $self->_removeChild($child, $sit);
    return $child;
}

sub replaceChild {
    my ($self, $new, $old, $sit) = @_;
    $self->_replaceChild($new, $old, $sit);
    return $old;
}

sub DESTROY {
    my $self = shift;
    $self->_clearInstanceData();
}


#################### Document ####################
package XML::Sablotron::DOM::Document;
use vars qw( @ISA );
@ISA = qw( XML::Sablotron::DOM::Node );

#constructors
#sub new {
#    my ($class, %params) = @_;
#    $class = ref $class || $class;
#    my $self = {};
#    bless $self, $class;
#    $self->{_handle} = $self->_getNewDocumentHandle($params{SITUATION});
#    return $self;
#}

sub new {
    my ($class, %params) = @_;
    my $self =  _new($class, $params{SITUATION});
    $self->{_autodispose} = $params{AUTODISPOSE};
    return $self;
}

sub freeDocument {
    my ($self) = @_;
    $self->_freeDocument() if $self->{_handle};
}

#to avoid namespace conflict with JavaScript built-in
sub _toString {
    return toString(@_);
}

sub autodispose {
    my ($self, $val) = @_;
    $self->{_autodispose} = $val if defined $val;
    $self->{_autodispose};
}

sub DESTROY {
    my $self = shift;
    $self->freeDocument() if $self->{_autodispose};
    my $foo = $self->_clearInstanceData();
}

#################### Element ####################
package XML::Sablotron::DOM::Element;
use vars qw( @ISA );
@ISA = qw( XML::Sablotron::DOM::Node );

sub setAttributes {
    my ($self, $hash, $sit) = @_;
    while (my ($a, $b) = each %$hash) {
	$self->setAttribute($a, $b, $sit);
    }
}

sub getAttributes {
    my ($self, $sit) = @_;
    my $arr = $self->_getAttributes($sit);
    my $rval = {};
    foreach my $att (@$arr) {
	$$rval{$att->getNodeName($sit)} = $att->getNodeValue($sit);
    }
    return $rval;
}

#################### Attribute ####################
package XML::Sablotron::DOM::Attribute;
use vars qw( @ISA );
@ISA = qw( XML::Sablotron::DOM::Node );

#################### Text ####################
package XML::Sablotron::DOM::Text;
use vars qw( @ISA );
@ISA = qw( XML::Sablotron::DOM::Node );

#################### CDATASection ####################
package XML::Sablotron::DOM::CDATASection;
use vars qw( @ISA );
@ISA = qw( XML::Sablotron::DOM::Node );

#################### EntityReference ####################
package XML::Sablotron::DOM::EntityReference;
use vars qw( @ISA );
@ISA = qw( XML::Sablotron::DOM::Node );

#################### Entity ####################
package XML::Sablotron::DOM::Entity;
use vars qw( @ISA );
@ISA = qw( XML::Sablotron::DOM::Node );

#################### ProcessingInstruction ####################
package XML::Sablotron::DOM::ProcessingInstruction;
use vars qw( @ISA );
@ISA = qw( XML::Sablotron::DOM::Node );

#################### Comment ####################
package XML::Sablotron::DOM::Comment;
use vars qw( @ISA );
@ISA = qw( XML::Sablotron::DOM::Node );

#################### DocumentType ####################
package XML::Sablotron::DOM::DocumentType;
use vars qw( @ISA );
@ISA = qw( XML::Sablotron::DOM::Node );

#################### DocumentFragment ####################
package XML::Sablotron::DOM::DocumentFragment;
use vars qw( @ISA );
@ISA = qw( XML::Sablotron::DOM::Node );

#################### Notation ####################
package XML::Sablotron::DOM::Notation;
use vars qw( @ISA );
@ISA = qw( XML::Sablotron::DOM::Node );


__END__



# Below is stub documentation for your module. You better edit it!

=head1 NAME

XML::Sablotron::DOM - The DOM interface to Sablotron's internal structures

=head1 SYNOPSIS

  use XML::Sablotron::DOM;

  my $situa = new XML::Sablotron::Situation();
  my $doc = new Sablotron::XML::Document(SITUATION => $sit);

  my $e = $doc->createElement($situa, "foo");
  my $t = $doc->createTextNode($situa, "this is my text");

  print $doc->toString();

=head1 DESCRIPTION

Sablotron uses internally the DOM-like data structures to represent
parsed XML trees. In the C<sdom.h> header file is defined a subset of
functions allowing the DOM access to these structures.

=head2 What is it good for

You may find this module useful if you need to

=over 4

=item * access parsed trees

=item * build trees on the fly

=item * pass parsed/built trees into XSLT processor

=back

=head2 Situation

There is one significant extension to the DOM specification. Since
Sablotron os designed to support multithreading processing (and well
reentrant code too), you need create and use special context for error
processing. This context is called the I<situation>.

A instance of this object MUST be passed as the first parameter to
almost all calls in the C<XML::Sablotron::DOM> code.

Some easy-to-use default behavior may be introduced in later releases.

See C<perldoc XML::Sablotron> for more details.

=head1 MEMORY ISSUES

Perl objects representing nodes of the DOM tree live independently on
internal structures of Sablotron. If you create and populate the
document, its structure is not related to the lifecycle of your Perl
variables. It is good for you, but there are two exceptions to this:

=over 4

=item * freeing the document

=item * accessing the node after the document is destroyed

=back

As results from above, you have to force XML::Sablotron::DOM to free
document, if you want. Use

  $doc->freeDocument($sit);

to to it. Another way is to use the autodispode feature (see the
documentation for the method autodispose and document constructor).

If you will try to access the node, which was previously disposed by
Sablotron (perhaps with the all tree), your Perl code will die with
exception -1. Use C<eval {};> to avoid program termination.

=head1 PACKAGES

The C<XML::Sablotron::DOM> defines several packages. Just will be
created manually in your code; they are mostly returned as a return
values from many functions.

=head1 XML::Sablotron::DOM

The C<XML::Sablotron::DOM> package is almost empty, and serves as a
parent module for the other packages.

By default this module exports no symbols into the callers package. If
want to use some predefined constants or functions, you may use

  use XML::Sablotron::DOM qw( :constants :functions );

=head2 constants

Constants are defined for:

=over 4

=item * node types

C<ELEMENT_NODE, ATTRIBUTE_NODE, TEXT_NODE, CDATA_SECTION_NODE,
ENTITY_REFERENCE_NODE, ENTITY_NODE, PROCESSING_INSTRUCTION_NODE,
COMMENT_NODE, DOCUMENT_NODE, DOCUMENT_TYPE_NODE,
DOCUMENT_FRAGMENT_NODE, NOTATION_NODE, OTHER_NODE>

=item * exception codes

C<SDOM_OK, INDEX_SIZE_ERR, HIERARCHY_ERR, WRONG_DOCUMENT_ERR,
NO_MODIFICATION_ALLOWED_ERR, NOT_FOUND_ERR, INVALID_NODE_TYPE_ERR,
QUERY_PARSE_ERR, QUERY_EXECUTION_ERR, NOT_OK>

=back

=head2 parse

This function parses the document specified by the URI. There is
currently no support for scheme handler for this operation (see
L<XML::Sablotron>) but it will be added soon.

Function returns the XML::Sablotron::DOM::Document object instance.

  XML::Sablotron::DOM::parse($sit, $uri);

=over 4

=item $sit

The situation to be used.

=item $uri

The URI of the document to be parsed.

=back

=head2 parseBuffer

This function parses the literal data specified.

  XML::Sablotron::DOM::parseBuffer($sit, $data);

=over 4

=item $sit

The situation to be used.

=item $data

The string containing the XML data to be parsed.

=back

=head2 parseStylesheet

This function parses the stylesheet specified by the URI. There is
currently no support for scheme handler for this operation (see
L<XML::Sablotron>) but it will be added soon.

Function returns the XML::Sablotron::DOM::Document object instance.

  XML::Sablotron::DOM::parseStylesheet($sit, $uri);

=over 4

=item $sit

The situation to be used.

=item $uri

The URI of the stylesheet to be parsed.

=back

=head2 parseStylesheetBuffer

This function parses the stylesheet given by the literal data.

  XML::Sablotron::DOM::parseStylesheetBuffer($sit, $data);

=over 4

=item $sit

The situation to be used.

=item $data

The string containing the stylesheet to be parsed.

=back

=head1 XML::Sablotron::DOM::Node

This packages is used to represent the Sablotron internal
representation of the node. It is the common ancestor of all other
types. 

=head2 equals

Check if the to perl representations of the node represent the same
node in the DOM document.

B<Synopsis:>

  $node1->equals($node2);

=over 4

=item $node2

The node to be compared to.

=back

=head2 getNodeType

Returns the node type. See L<"XML::Sablotron::DOM"> for more details.

  $node->getNodeType([$situa]);

=over 4

=item $situa

The situation to be used (optional).

=back

=head2 getNodeName

For ELEMENT_NODE and ATTRIBUTE_NODE returns the name of the node. For
other node types return as follows:

TEXT_NODE => "#text", CDATA_SECTION_NODE => #cdata-section,
COMMENT_NODE => "#comment", DOCUMNET_NODE => "#document"

B<Synopsis:>

  $node->getNodeName([$situa]);

=over 4

=item $situa

The situation to be used (optional).

=back

=head2 setNodeName

Sets the name of the node.

B<Exceptions:> 

=over 4

=item NO_MODIFICATION_ALLOWED_ERR 

for TEXT_NODE, CDATA_SECTION_NODE, COMMENT_NODE and DOCUMENT_NODE

=back

B<Synopsis:>

  $node->setNodeName($name [, $situa]);

=over 4

=item $name

The new node name.

=item $situa

The situation to be used (optional).

=back

=head2 getNodeValue

returns the content of TEXT_NODE, CDATA_SECTION_NODE and COMMENT_NODE,
otherwise returns undef.

B<Synopsis:>

  $node->getNodeValue([$situa]);

=over 4

=item $situa

The situation to be used (optional).

=back

=head2 setNodeValue

Sets the content of the node for TEXT_NODE, CDATA_SECTION_NODE and
COMMENT_NODE. 

B<Exceptions:>

=over 4

=item NO_MODIFICATION_ALLOWED_ERR 

for ELEMENT_NODE, DOCUMENT_NODE

=back

B<Synopsis:>

  $node->setNodeValue($value [, $situa]);

=over 4

=item $value

The new node value.

=item $situa

The situation to be used (optional).


=back

=head2 getParentNode

Returns the parent node, if there is any. Otherwise returns
undef. Undefined value is always returned for the DOCUMENT_NODE.

B<Synopsis:>

  $node->getNodeValue([$situa]);

=over 4

=item $situa

The situation to be used (optional).

=back

=head2 getFirstChild

Get the first child of the node or undef.

B<Synopsis:>

  $node->getFirstChild([$situa]);

=over 4

=item $situa

The situation to be used (optional).

=back

=head2 getLastChild

Get the last child of the node or undef.

B<Synopsis:>

  $node->getLastChild([$situa]);

=over 4

=item $situa

The situation to be used (optional).

=back

=head2 getPreviousSibling

Returns the node immediately preceding the node. Returns undef, if
there is no such node.

B<Synopsis:>

  $node->getPreviousSibling([$situa]);

=over 4

=item $situa

The situation to be used (optional).

=back

=head2 getNextSibling

Returns the node immediately following the node. Returns undef, if
there is no such node.

B<Synopsis:>

  $node->getNextSibling([$situa]);

=over 4

=item $situa

The situation to be used (optional).

=back

=head2 getChildNodes

Returns the reference to the array of all child nodes of given node.

B<Synopsis:>

  $node->getChildNodes([$situa]);

=over 4

=item $situa

The situation to be used (optional).

=back

=head2 getOwnerDocument

Returns the document owning the node. It is always the document, which
created this node. For document itself the return value is undef.

B<Synopsis:>

  $node->getOwnerDocument([$situa]);

=over 4

=item $situa

The situation to be used (optional).

=back

=head2 insertBefore

Makes a new node the child of the node. It is put right before the
reference node. If the reference node is not defined, the new node is
appended to the child list.

B<Exceptions:>

=over 4

=item HIERARCHY_REQUEST_ERR

Raised if the node doesn't allow children of given type.

=item WRONG_DOCUMENT_ERR

Raised if the new node is not owned by the same document as the node.

=back

B<Synopsis:>

  $node->insertBefore($new_node, $ref_node [, $situa]);

=over 4

=item $new_node

The inserted node.

=item $ref_node

The reference node. The new node is to be inserted right before this
node. May be undef; in this case the new node is appended.

=item $situa

The situation to be used (optional).

=back

=head2 appendChild

Appends the new node to the list of children of the node.

B<Exceptions:>

=over 4

=item HIERARCHY_REQUEST_ERR

Raised if the node doesn't allow children of given type.

=item WRONG_DOCUMENT_ERR

Raised if the new node is not owned by the same document as the node.

=back

B<Synopsis:>

  $node->appendChild($child, [$situa]);

=over 4

=item $child

The node to be appended.

=item $situa

The situation to be used (optional).


=back

=head2 removeChild

Remove the child node from the list of children of the node.

B<Exceptions:>

=over 4

=item NOT_FOUND_ERR

Raised if the removed node is not the child of the node.

=back

B<Synopsis:>

  $node->removeChild($child, [, $situa]);

=over 4

=item $child

The node to be removed.

=item $situa

The situation to be used (optional).

=back

=head2 replaceChild

Replace the child node with the new one.

B<Exceptions:>

=over 4

=item HIERARCHY_REQUEST_ERR

Raised if the node doesn't allow children of given type.

=item WRONG_DOCUMENT_ERR

Raised if the new node is not owned by the same document as the node.

=item NOT_FOUND_ERR

Raised if the replaced node is not the child of the node.

=back

B<Synopsis:>

  $node->replaceChild($child, $old_child [, $situa]);

=over 4

=item $child

The new child to be inserted (in the place of the $old_child)

=item $old_child

The node to be replaced.

=item $situa

The situation to be used (optional).

=back

=head2 xql

Executes the XPath expression and returns the ARRAYREF of resulting
nodes.

B<Synopsis:>

  $node->xql($expr [, $situa]);

=over 4

=item $expr

The expression to be replaced.

=item $situa

The situation to be used (optional).

=back

=head1 XML::Sablotron::DOM::Document

Represents the whole DOM document (the "/" root element).

=head2 new

Create the new empty document.

B<Synopsis:>

  $doc = XML::Sablotron::DOM::Document->new([AUTODISPOSE => $ad]);

=over 4

=item $ad

Specifies if the document is to be deleted after the last Perl
reference is dropped,

=back

=head2 autodispose

Reads or set the autodispose flag, This flag causes, that the document
is destroyed after the last Perl reference is undefined.

B<Synopsis:>

  $doc->autodispose([$ad]);

=over 4

=item $ad

Specifies if the document is to be deleted after the last Perl
reference is dropped,

=back

=head2 freeDocument

Disposes all memory allocated by Sablotron for the DOM document. This
is the only way how to do it. See L<"MEMORY ISSUES"> for more details.

B<Synopsis:>

  $doc->freeDocument([$situa]);

=over 4

=item $situa

The situation to be used (optional).

=back

=head2 toString

Serializes the document tree into the string representation.

B<Synopsis:>

  $doc->toString([$situa])

=over 4

=item $situa

The situation to be used (optional).

=back

=head2 cloneNode

Clone the node. The children of the node may be cloned too. The cloned
node may be from another document; cloned nodes are always owned by the
calling document. Parent of the cloned node is not set.

B<Synopsis:>

  $doc->cloneNode($node, $deep [, $situa]);

=over 4

=item $node

The node to be cloned.

=item $deep

If true, all children of the node are cloned too.

=item $situa

The situation to be used (optional).

=back

=head2 createElement

Creates the new ELEMENT_NODE. The parent of the node is not set; the
owner document is set to the document. 

B<Synopsis:>

  $doc->createElement($name [, $situa]);

=over 4

=item $name

The new element name.

=item $situa

The situation to be used (optional).

=back

=head2 createTextNode

Creates the new TEXT_NODE. The parent of the node is not set; the
owner document is set to the document. 

B<Synopsis:>

  $doc->createTextNode($data [, $situa]);

=over 4

=item $data

The initial value of the node.

=item $situa

The situation to be used (optional).

=back

=head2 createCDATASection

Creates the new CDATA_SECTION_NODE. The parent of the node is not set; the
owner document is set to the document. 

B<Synopsis:>

  $doc->createCDATASection($data [, $situa]);

=over 4

=item $data

The initial value of the node.

=item $situa

The situation to be used (optional).

=back

=head2 createComment

Creates the new COMMENT_NODE. The parent of the node is not set; the
owner document is set to the document. 

B<Synopsis:>

  $doc->createComment($data [, $situa]);

=over 4

=item $data

The initial value of the node.

=item $situa

The situation to be used (optional).

=back

=head2 createProcessingInstruction

Creates the new PROCESSING_INSTRUCTION_NODE. The parent of the node is
not set; the owner document is set to the document.

B<Synopsis:>

  $doc->createProcessingInstruction($target, $data [, $situa]);

=over 4

=item $target

The target for the PI.

=item $data

The data for the PI.

=item $situa

The situation to be used (optional).

=back

=head1 XML::Sablotron::DOM::Element

Represents the element of the tree.

=head2 getAttribute

  $hashref = $e->getAttribute($name [, $situa]);

=over 4

=item $name

The name of queried attribute.

=item $situa

The situation to be used (optional).

=back

=head2 setAttribute

  $hashref = $e->setAttribute($name, $value [, $situa]);

=over 4

=item $name

The name of attribute to be set.

=item $value

The value of the new attribute.

=item $situa

The situation to be used (optional).

=back

=head2 getAttributes

  $hashref = $e->getAttributes([$situa]);

=over 4

=item $situa

The situation to be used (optional).

=back

=head2 setAttributes

  $hashref = $e->setAttributes($hashref [, $situa]);

=over 4

=item $hashref

The HASHREF value. Referenced hash contains name/value pair to be used.

=item $situa

The situation to be used (optional).

=back

=head2 removeAttribute

  $hashref = $e->removeAttribute($name [, $situa]);

=over 4

=item $name

The name of attribute to be removed.

=item $situa

The situation to be used (optional).

=back

=head2 toString

Serializes the element and its subtree into the string representation.

B<Synopsis:>

  $e->toString([$situa])

=over 4

=item $situa

The situation to be used (optional).

=back

=head1 AUTHOR

Pavel Hlavnicka, pavel@gingerall.cz; Ginger Alliance LLC;

=head1 SEE ALSO

perl(1).

=cut

