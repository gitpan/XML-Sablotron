/* -*- Mode: C; tab-width: 8; indent-tabs-mode: nil; c-basic-offset: 4 -*-
 * The contents of this file are subject to the Mozilla Public
 * License Version 1.1 (the "License"); you may not use this file
 * except in compliance with the License. You may obtain a copy of
 * the License at http://www.mozilla.org/MPL/
 * 
 * Software distributed under the License is distributed on an "AS
 * IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or
 * implied. See the License for the specific language governing
 * rights and limitations under the License.
 * 
 * The Original Code is the XML::Sablotron::DOM module.
 * 
 * The Initial Developer of the Original Code is Ginfer Alliance Ltd.
 * Portions created by Ginger Alliance are 
 * Copyright (C) 1999-2000 Ginger Alliance Ltd..  
 * All Rights Reserved.
 * 
 * Contributor(s):
 * 
 * Alternatively, the contents of this file may be used under the
 * terms of the GNU General Public License Version 2 or later (the
 * "GPL"), in which case the provisions of the GPL are applicable 
 * instead of those above.  If you wish to allow use of your 
 * version of this file only under the terms of the GPL and not to
 * allow others to use your version of this file under the MPL,
 * indicate your decision by deleting the provisions above and
 * replace them with the notice and other provisions required by
 * the GPL.  If you do not delete the provisions above, a recipient
 * may use your version of this file under either the MPL or the
 * GPL.
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <stdio.h>
#include <sdom.h>
#include <sablot.h>

/************************************************************/
/* globals */
/************************************************************/

/* classes */
/* must match to SDOM_NodeType */
char* __classNames[] = {"", /* zero is not defined */
                        "XML::Sablotron::DOM::Element", 
                        "XML::Sablotron::DOM::Attribute", 
                        "XML::Sablotron::DOM::Text", 
                        "XML::Sablotron::DOM::CDATASection", 
                        "XML::Sablotron::DOM::EntityReference",
                        "XML::Sablotron::DOM::Entity", 
                        "XML::Sablotron::DOM::ProcessingInstruction", 
                        "XML::Sablotron::DOM::Comment", 
                        "XML::Sablotron::DOM::Document", 
                        "XML::Sablotron::DOM::DocumentType", 
                        "XML::Sablotron::DOM::DocumentFragment", 
                        "XML::Sablotron::DOM::Notation"};

/************************************************************/
/* error handling */
/************************************************************/

/* keep sync with SDOM_Exception enumeration */
char* __errorNames[] = {"DOM_OK", /*0*/
                        "INDEX_SIZE_ERR", /*1*/
                        "",
                        "HIERARCHY_REQUEST_ERR", /*3*/
                        "WRONG_DOCUMENT_ERR", /*4*/
                        "", "", 
                        "NO_MODIFICATION_ALLOWED_ERR", /*7*/
                        "NOT_FOUND_ERR", /*8*/
                        /*non spec errors - continued*/
                        "INVALID_NODE_TYPE_ERR", 
                        "QUERY_PARSE_ERR", 
                        "QUERY_EXECUTION_ERR",
                        "NOT_OK"
};

/* check function return value */
#define DE(sit, status) if (status) \
                      croak("XML::Sablotron::DOM(Code=%d, Name=%s, Msg=%s)", \
                            status, __errorNames[status], \
                            SDOM_getExceptionMessage(sit))

/* check the validity of the node */
#define CN(node) if (! node) croak("XML::Sablotron::DOM(Code=-1, Name='INVALID_NODE_ERR')")

/************************************************************/
/* globals for document */
/************************************************************/
#define DOC_HANDLE(doc) (SDOM_Document)SvIV(*hv_fetch((HV*)SvRV(doc), "_handle", 7, 0))

#define SIT_HANDLE(sit) (SablotSituation)SvIV(*hv_fetch((HV*)SvRV(sit), "_handle", 7, 0))

#define SIT_PARAM(cnt) ((items >= cnt) ? ST(cnt - 1) : &PL_sv_undef)

#define SIT_SMART(sit) (SvOK(sit) ? SIT_HANDLE(sit) : __sit)

#define NODE_HANDLE(node) (SDOM_Node)SvIV(*hv_fetch((HV*)SvRV(node), "_handle", 7, 0))


SV* __createNode(SablotSituation situa, SDOM_Node handle)
{
    HV* hash;
    SV* retval;
    SDOM_NodeType type;
    /* check and/or create inner SV* - used for validity checks*/
    SV* inner = (SV*)SDOM_getNodeInstanceData(handle);
    if (!inner) {
        /* printf("+++> creating new inner\n"); */
        inner = newSViv((int)handle);
        /* store inner SV to node */
        SDOM_setNodeInstanceData(handle, inner);
    } else {
        /* printf("---> reusing the inner %d\n", SvIV(inner)); */
    }
    
    /* create new hash and store the handle into it */
    hash = newHV();
    hv_store(hash, "_handle", 7, SvREFCNT_inc(inner), 0);
    /* create blessed reference */
    retval = newRV_noinc((SV*)hash);
    DE( situa, SDOM_getNodeType(situa, handle, &type) );
    sv_bless(retval, gv_stashpv(__classNames[type], 0));

    return retval;
}


/************************************************************/
/* dispose calback */
/************************************************************/

void __nodeDisposeCallback(SDOM_Node node) 
{
    SV* pnode = (SV*)SDOM_getNodeInstanceData(node);
    if ( pnode ) sv_setiv(pnode, 0);
}

/*************************************************************/
/*  get implicit situation */
/*************************************************************/
SablotSituation __sit;


/************************************************************/
/* DOM */
/************************************************************/

MODULE = XML::Sablotron::DOM		PACKAGE = XML::Sablotron::DOM
PROTOTYPES: ENABLE

BOOT:
     SDOM_setDisposeCallback(&__nodeDisposeCallback);
     SablotCreateSituation(&__sit);

SV*
parse(sit, uri)
     SV*      sit
     char*    uri
     CODE:
     SDOM_Document doc;
     SablotSituation situa = SIT_HANDLE(sit);
     DE( situa, SablotParse(situa, uri, &doc) );
     RETVAL = __createNode(situa, doc);
     OUTPUT:
     RETVAL

SV*
parseBuffer(sit, buff)
     SV*      sit
     char*    buff
     CODE:
     SDOM_Document doc;
     SablotSituation situa = SIT_HANDLE(sit);
     DE( situa, SablotParseBuffer(situa, buff, &doc) );
     RETVAL = __createNode(situa, doc);
     OUTPUT:
     RETVAL

SV*
parseStylesheet(sit, uri)
     SV*      sit
     char*    uri
     CODE:
     SDOM_Document doc;
     SablotSituation situa = SIT_HANDLE(sit);
     DE( situa, SablotParseStylesheet(situa, uri, &doc) );
     RETVAL = __createNode(situa, doc);
     OUTPUT:
     RETVAL

SV*
parseStylesheetBuffer(sit, buff)
     SV*      sit
     char*    buff
     CODE:
     SDOM_Document doc;
     SablotSituation situa = SIT_HANDLE(sit);
     DE( situa, SablotParseStylesheetBuffer(situa, buff, &doc) );
     RETVAL = __createNode(situa, doc);
     OUTPUT:
     RETVAL

void
testsit(val)
     SV* val
     CODE:

#     HV* hash;
#     GV* gv;
#     SV* val;
#     hash = gv_stashpv("XML::Sablotron::DOM", 0);
#     gv = (GV*)*hv_fetch(hash, "__sit", 5, 0);
#     val = GvSV(gv);


#************************************************************
#* NODE
#************************************************************

MODULE = XML::Sablotron::DOM	        PACKAGE = XML::Sablotron::DOM::Node

int 
_clearInstanceData(object)
     SV*      object
     CODE:
     SV* inner =  *hv_fetch((HV*)SvRV(object), "_handle", 7, 0);
     if (inner && (SvREFCNT(inner) == 2) ) {
         /* I'm the last one owning the reference to inner handle */
         SvREFCNT_dec(inner);
         if ( SvIV(inner) )
             SDOM_setNodeInstanceData((SDOM_Node)SvIV(inner), NULL);
         RETVAL = 1;
     } else {
         RETVAL = 0;
     }
     OUTPUT:
     RETVAL


int 
getNodeType(object, ...) 
     SV*      object
     CODE:
     SV* sit = SIT_PARAM(2);
     SDOM_NodeType type;
     SDOM_Node node = NODE_HANDLE(object);
     SablotSituation situa = SIT_SMART(sit);
     CN(node);
     DE( situa, SDOM_getNodeType(situa, node, &type) );
     RETVAL = (int)type;
     OUTPUT:
     RETVAL

char*
getNodeName(object, ...)
     SV*      object
     CODE:
     SV* sit = SIT_PARAM(2);
     SDOM_char* name;
     SDOM_Node node = NODE_HANDLE(object);
     SablotSituation situa = SIT_SMART(sit);
     CN(node);
     DE( situa, SDOM_getNodeName(situa, node, (SDOM_char**)&name) );
     RETVAL = (char*)name;
     OUTPUT:
     RETVAL
     CLEANUP:
     if (name) SablotFree(name);

void
setNodeName(object, name, ...)
     SV*      object
     char*    name
     CODE:
     SV* sit = SIT_PARAM(3);
     SDOM_Node node = NODE_HANDLE(object);
     SablotSituation situa = SIT_SMART(sit);
     CN(node);
     DE( situa, SDOM_setNodeName(situa, node, (SDOM_char*)name) );


char*
getNodeValue(object, ...)
     SV*      object
     CODE:
     SV* sit = SIT_PARAM(2);
     SDOM_char* value;
     SDOM_Node node = NODE_HANDLE(object);
     SablotSituation situa = SIT_SMART(sit);
     CN(node);
     DE( situa, SDOM_getNodeValue(situa, node, (SDOM_char**)&value) );
     /* _fix_ the null values, see spec */
     RETVAL = (char*)value; 
     OUTPUT:
     RETVAL
     CLEANUP:
     if (value) SablotFree(value);

void
setNodeValue(object, value, ...)
     SV*      object
     char*    value
     CODE:
     SV* sit = SIT_PARAM(3);
     SDOM_Node node = NODE_HANDLE(object);
     SablotSituation situa = SIT_SMART(sit);
     CN(node);
     /* _fix_ check undef values */
     DE( situa, SDOM_setNodeValue(situa, node, (SDOM_char*)value) );

SV*
getParentNode(object, ...)
     SV*      object
     CODE:
     SV* sit = SIT_PARAM(2);
     SDOM_Node parent;
     SablotSituation situa = SIT_SMART(sit);
     SDOM_Node node = NODE_HANDLE(object);
     CN(node);
     DE( situa, SDOM_getParentNode(situa, node, &parent) );
     if (parent) {
         /* _fix_ check memory leaks */
         RETVAL = __createNode(situa, parent);
     } else {
         RETVAL = &PL_sv_undef;
     }
     OUTPUT:
     RETVAL

SV*
getFirstChild(object, ...)
     SV*      object
     CODE:
     SV* sit = SIT_PARAM(2);
     SablotSituation situa = SIT_SMART(sit);
     SDOM_Node node = NODE_HANDLE(object);
     SDOM_Node child;
     CN(node);
     DE( situa, SDOM_getFirstChild(situa, node, &child) );
     if (child) {
         /* _fix_ check memory leaks */
         RETVAL = __createNode(situa, child);
     } else {
         RETVAL = &PL_sv_undef;
     }
     OUTPUT:
     RETVAL

SV*
getLastChild(object, ...)
     SV*      object
     CODE:
     SV* sit = SIT_PARAM(2);
     SablotSituation situa = SIT_SMART(sit);
     SDOM_Node node = NODE_HANDLE(object);
     SDOM_Node child;
     CN(node);
     DE( situa, SDOM_getLastChild(situa, node, &child) );
     if (child) {
         /* _fix_ check memory leaks */
         RETVAL = __createNode(situa, child);
     } else {
         RETVAL = &PL_sv_undef;
     }
     OUTPUT:
     RETVAL

SV*
getPreviousSibling(object, ...)
     SV*      object
     CODE:
     SV* sit = SIT_PARAM(2);
     SablotSituation situa = SIT_SMART(sit);
     SDOM_Node node = NODE_HANDLE(object);
     SDOM_Node sibling;
     CN(node);
     DE( situa, SDOM_getPreviousSibling(situa, node, &sibling) );
     if (sibling) {
         /* _fix_ check memory leaks */
         RETVAL = __createNode(situa, sibling);
     } else {
         RETVAL = &PL_sv_undef;
     }
     OUTPUT:
     RETVAL

SV*
getNextSibling(object, ...)
     SV*      object
     CODE:
     SV* sit = SIT_PARAM(2);
     SablotSituation situa = SIT_SMART(sit);
     SDOM_Node node = NODE_HANDLE(object);
     SDOM_Node sibling;
     CN(node);
     DE( situa, SDOM_getNextSibling(situa, node, &sibling) );
     if (sibling) {
         /* _fix_ check memory leaks */
         RETVAL = __createNode(situa, sibling);
     } else {
         RETVAL = &PL_sv_undef;
     }
     OUTPUT:
     RETVAL

AV*
getChildNodes(object, ...)
     SV*      object
     CODE:
     SDOM_Node node = NODE_HANDLE(object);
     SDOM_Node foo;
     SV* sit = SIT_PARAM(2);
     SablotSituation situa = SIT_SMART(sit);
     CN( node );
     RETVAL = (AV*)sv_2mortal( (SV*)newAV() );
     DE( situa, SDOM_getFirstChild(situa, node, &foo) );
     while ( foo ) {
         av_push(RETVAL, __createNode(situa, foo));
         DE( situa, SDOM_getNextSibling(situa, foo, &foo) );
     }
     OUTPUT:
     RETVAL

SV*
getOwnerDocument(object, ...)
     SV*      object
     CODE:
     SV* sit = SIT_PARAM(2);
     SablotSituation situa = SIT_SMART(sit);
     SDOM_Node node = NODE_HANDLE(object);
     SDOM_Document doc;
     CN(node);
     DE( situa, SDOM_getOwnerDocument(situa, node, &doc) );
     if (doc) {
         /* _fix_ check memory leaks */
         /* _fix_ check if it works at all (create node etc.) */
         RETVAL = __createNode(situa, doc);
     } else {
         RETVAL = &PL_sv_undef;
     }
     OUTPUT:
     RETVAL

void
insertBefore(object, child, ref, ...)
     SV*      object
     SV*      child
     SV*      ref
     CODE:
     SV* sit = SIT_PARAM(4);
     SDOM_Node refnode;
     SDOM_Node node = NODE_HANDLE(object);
     SablotSituation situa = SIT_SMART(sit);
     CN(node);
     refnode =  (ref == &PL_sv_undef) ? NULL : NODE_HANDLE(ref);
     DE( situa, SDOM_insertBefore(situa, node, 
                           NODE_HANDLE(child), refnode) );


void
appendChild(object, child, ...)
     SV*      object
     SV*      child
     CODE:
     SV* sit = SIT_PARAM(3);
     SDOM_Node node = NODE_HANDLE(object);
     SablotSituation situa = SIT_SMART(sit);
     CN(node);
     DE( situa, SDOM_appendChild(situa, node, NODE_HANDLE(child)) );

void
_removeChild(object, child, ...)
     SV*      object
     SV*      child
     CODE:
     SV* sit = SIT_PARAM(3);
     SDOM_Node node = NODE_HANDLE(object);
     SablotSituation situa = SIT_SMART(sit);
     CN(node);
     DE( situa, SDOM_removeChild(situa, node, NODE_HANDLE(child)) );

void
_replaceChild(object, child, old, ...)
     SV*      object
     SV*      child
     SV*      old
     CODE:
     SV* sit = SIT_PARAM(4);
     SDOM_Node oldnode;
     SDOM_Node node = NODE_HANDLE(object);
     SablotSituation situa = SIT_SMART(sit);
     CN(node);
     if (old == &PL_sv_undef) 
          croak ("XML::Sablotron::DOM(Code=-2, Name='NODE_REQUIRED'");
     oldnode = NODE_HANDLE(old);
     DE( situa, SDOM_replaceChild(situa, node, 
                           NODE_HANDLE(child), oldnode) );

AV*
xql(object, expr, ...)
     SV*      object
     char*    expr
     CODE:
     SV* sit = SIT_PARAM(3);
     int i;
     int len;
     SDOM_NodeList list;
     SDOM_Document doc;
     SablotSituation situa = SIT_SMART(sit);
     SDOM_Node node = NODE_HANDLE(object);
     CN(node);
     SDOM_getOwnerDocument(situa, node, &doc);
     SablotLockDocument(situa, doc ? doc : node); /* _check me_ */
     DE( situa, SDOM_xql(situa, expr, node, &list) );
     RETVAL = (AV*)sv_2mortal((SV*)newAV());
     SDOM_getNodeListLength(situa, list, &len);
     for (i = 0; i < len; i++) {
         SDOM_Node foo;
         SDOM_Node node;
         SDOM_getNodeListItem(situa, list, i, &node);
         av_push(RETVAL, __createNode(situa, node));
     }
     SDOM_disposeNodeList(situa, list);
     OUTPUT:
     RETVAL

#************************************************************
#* DOCUMENT *
#************************************************************

MODULE = XML::Sablotron::DOM	        PACKAGE = XML::Sablotron::DOM::Document

SV*
_new(object, sit)
     SV*      object
     SV*      sit
     CODE:
     SDOM_Document doc;
     SablotSituation situa = SIT_SMART(sit);
     SablotCreateDocument(situa, &doc);
     RETVAL = __createNode(situa, doc);
     OUTPUT:
     RETVAL

void
_freeDocument(object, ...) 
     SV*      object
     CODE:
     SV* sit = SIT_PARAM(2);
     SablotSituation situa = SIT_SMART(sit);
     SDOM_Document doc = DOC_HANDLE(object);
     SablotDestroyDocument(situa, doc);

char*
toString(object, ...)
     SV*      object
     CODE:
     SV* sit = SIT_PARAM(2);
     char* buff;
     SDOM_Document doc = DOC_HANDLE(object);
     SablotSituation situa = SIT_SMART(sit);
     CN( doc );
     SablotLockDocument(situa, doc);
     DE( situa, SDOM_docToString(situa, doc, (SDOM_char**)&buff) );
     RETVAL = buff;
     OUTPUT:
     RETVAL
     CLEANUP:
     if (buff) SablotFree(buff);

SV* 
cloneNode(object, node, deep, ...)
     SV*      object
     SV*      node
     int      deep
     CODE:
     SV* sit = SIT_PARAM(4);
     SDOM_Node cloned;
     SDOM_Document doc = DOC_HANDLE(object);
     SablotSituation situa = SIT_SMART(sit);
     CN(doc);
     DE( situa, SDOM_cloneForeignNode(situa, doc, 
                               NODE_HANDLE(node), deep, &cloned) );
     RETVAL = __createNode(situa, cloned);
     OUTPUT:
     RETVAL

SV*
createElement(object, name, ...)
     SV*      object
     char*    name
     CODE:
     SV* sit = SIT_PARAM(3);
     SDOM_Node handle;
     SDOM_Document doc = DOC_HANDLE(object);
     SablotSituation situa = SIT_SMART(sit);
     CN(doc);
     DE( situa, SDOM_createElement(situa, doc, &handle, name) );
     RETVAL = __createNode(situa, handle);
     OUTPUT:
     RETVAL

SV*
createAttribute(object, name, ...)
     SV*      object
     char*    name
     CODE:
     SV* sit = SIT_PARAM(3);
     SDOM_Node handle;
     SDOM_Document doc = DOC_HANDLE(object);
     SablotSituation situa = SIT_SMART(sit);
     CN(doc);
     DE( situa, SDOM_createAttribute(situa, doc, &handle, name) );
     RETVAL = __createNode(situa, handle);
     OUTPUT:
     RETVAL

SV*
createTextNode(object, value, ...)
     SV*      object
     char*    value
     CODE:
     SV* sit = SIT_PARAM(3);
     SDOM_Node handle;
     SDOM_Document doc = DOC_HANDLE(object);
     SablotSituation situa = SIT_SMART(sit);
     CN(doc);
     DE( situa, SDOM_createTextNode(situa, doc, &handle, value) );     
     RETVAL = __createNode(situa, handle);
     OUTPUT:
     RETVAL

SV*
createCDATASection(object, value, ...)
     SV*      object
     char*    value
     CODE:
     SV* sit = SIT_PARAM(3);
     SDOM_Node handle;
     SDOM_Document doc = DOC_HANDLE(object);
     SablotSituation situa = SIT_SMART(sit);
     CN(doc);
     DE( situa, SDOM_createCDATASection(situa, doc, &handle, value) );     
     RETVAL = __createNode(situa, handle);
     OUTPUT:
     RETVAL

SV*
createEntityReference(object, ...)
     SV*      object
     CODE:
     SV* sit = SIT_PARAM(2);
     SDOM_Node handle;
     SDOM_Document doc = DOC_HANDLE(object);
     SablotSituation situa = SIT_SMART(sit);
     CN(doc);
     /* _fix_ put the API call here */
     RETVAL = __createNode(situa, handle);
     OUTPUT:
     RETVAL

SV*
createEntity(object, ...)
     SV*      object
     CODE:
     SV* sit = SIT_PARAM(2);
     SDOM_Node handle;
     SDOM_Document doc = DOC_HANDLE(object);
     SablotSituation situa = SIT_SMART(sit);
     CN(doc);
     /* _fix_ put the API call here */
     RETVAL = __createNode(situa, handle);
     OUTPUT:
     RETVAL

SV*
createProcessingInstruction(object, target, data, ...)
     SV*      object
     char*    target
     char*    data
     CODE:
     SV* sit = SIT_PARAM(4);
     SDOM_Node handle;
     SDOM_Document doc = DOC_HANDLE(object);
     SablotSituation situa = SIT_SMART(sit);
     CN(doc);
     DE( situa, 
         SDOM_createProcessingInstruction(situa, doc, &handle, target, data) );
     RETVAL = __createNode(situa, handle);
     OUTPUT:
     RETVAL

SV*
createComment(object, value, ...)
     SV*      object
     char*    value
     CODE:
     SV* sit = SIT_PARAM(3);
     SDOM_Node handle;
     SDOM_Document doc = DOC_HANDLE(object);
     SablotSituation situa = SIT_SMART(sit);
     CN(doc);
     DE( situa, SDOM_createComment(situa, doc, &handle, value) );
     RETVAL = __createNode(situa, handle);
     OUTPUT:
     RETVAL

SV*
createDocumentType(object, ...)
     SV*      object
     CODE:
     SV* sit = SIT_PARAM(2);
     SDOM_Node handle;
     SDOM_Document doc = DOC_HANDLE(object);
     SablotSituation situa = SIT_SMART(sit);
     CN(doc);
     /* _fix_ put the API call here */
     RETVAL = __createNode(situa, handle);
     OUTPUT:
     RETVAL

SV*
createDocumentFragment(object, ...)
     SV*      object
     CODE:
     SV* sit = SIT_PARAM(2);
     SDOM_Node handle;
     SDOM_Document doc = DOC_HANDLE(object);
     SablotSituation situa = SIT_SMART(sit);
     CN(doc);
     /* _fix_ put the API call here */
     RETVAL = __createNode(situa, handle);
     OUTPUT:
     RETVAL

SV*
createNotation(object, ...)
     SV*      object
     CODE:
     SV* sit = SIT_PARAM(2);
     SDOM_Node handle;
     SDOM_Document doc = DOC_HANDLE(object);
     SablotSituation situa = SIT_SMART(sit);
     CN(doc);
     /* _fix_ put the API call here */
     RETVAL = __createNode(situa, handle);
     OUTPUT:
     RETVAL


#************************************************************
#* ELEMENT *
#************************************************************

MODULE = XML::Sablotron::DOM	        PACKAGE = XML::Sablotron::DOM::Element

char*
getAttribute(object, name, ...)
     SV*      object
     char*    name
     CODE:
     SV* sit = SIT_PARAM(3);
     SDOM_char* value;
     SDOM_Node node = NODE_HANDLE(object);
     SablotSituation situa = SIT_SMART(sit);
     CN( node );
     /* _fix_ check null values */
     DE( situa, SDOM_getAttribute(situa, node, 
                      (SDOM_char*)name, (SDOM_char**)&value) );
     RETVAL = (char*)value;
     OUTPUT:
     RETVAL
     CLEANUP:
     if (value) SablotFree(value);

void
setAttribute(object, name, value, ...)
     SV*      object
     char*    name
     char*    value
     CODE:
     SV* sit = SIT_PARAM(4);
     SDOM_Node node = NODE_HANDLE(object);
     SablotSituation situa = SIT_SMART(sit);
     CN( node );
     /* _fix_ check null values */
     DE( situa, SDOM_setAttribute(situa, node, 
                      (SDOM_char*)name, (SDOM_char*)value) );
    
void
removeAttribute(object, name, ...)
     SV*      object
     char*    name
     CODE:
     SV* sit = SIT_PARAM(4);
     SDOM_Node node = NODE_HANDLE(object);
     SablotSituation situa = SIT_SMART(sit);
     CN( node );
     /* _fix_ check null values */
     DE( situa, SDOM_removeAttribute(situa, node, (SDOM_char*)name) );

AV* 
_getAttributes(object, ...)
     SV*      object
     CODE:
     SV* sit = SIT_PARAM(2);
     int i;
     int len;
     SDOM_NodeList list;
     SDOM_Node node = NODE_HANDLE(object);
     SablotSituation situa = SIT_SMART(sit);
     CN( node );
     DE( situa, SDOM_getAttributeList(situa, node, &list) );
     RETVAL = (AV*)sv_2mortal((SV*)newAV());
     SDOM_getNodeListLength(situa, list, &len);
     for (i = 0; i < len; i++) {
         SDOM_Node node;
         SDOM_getNodeListItem(situa, list, i, &node);
         av_push(RETVAL, __createNode(situa, node));
     }
     SDOM_disposeNodeList(situa, list);
     OUTPUT:
     RETVAL

char*
toString(object, ...)
     SV*      object
     CODE:
     SV* sit = SIT_PARAM(2);
     char* buff;
     SDOM_Document doc;
     SablotSituation situa;
     SDOM_Node node = NODE_HANDLE(object);
     CN( node );
     situa = SIT_SMART(sit);
     SDOM_getOwnerDocument(situa, node, &doc);
     CN( doc );
     SablotLockDocument(situa, doc);
     DE( situa, SDOM_nodeToString(situa, doc, node, (SDOM_char**)&buff) );
     RETVAL = buff;
     OUTPUT:
     RETVAL
     CLEANUP:
     if (buff) SablotFree(buff);
