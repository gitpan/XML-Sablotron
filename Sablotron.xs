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
 * The Original Code is the XML::Sablotron module.
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
#include <sablot.h>
#include <shandler.h>
#include <sdom.h>

#if defined(WIN32)
#if defined(__cplusplus) && !defined(PERL_OBJECT)
#include <malloc.h>
#endif
#else
#include <stdlib.h>
#endif


/* struct MHCallbackVector{
   SV *makeCodeProc;
   SV *logProc;
   SV *errorProc;
 };


typedef struct MHCallbackVector MHCallbackVector;

struct SHCallbackVector {
  SV *openProc;
  SV *getProc;
  SV *putProc;
  SV *closeProc;
};

typedef struct SHCallbackVector SHCallbackVector;

struct XHCallbackVector {
  SV *openProc;
  SV *getProc;
  SV *putProc;
  SV *closeProc;
};

typedef struct XHCallbackVector XHCallbackVector;

MHCallbackVector mh_callback_vector;
SHCallbackVector sh_callback_vector;
XHCallbackVector xh_callback_vector;

*/

/**************************************************************
  message handler
**************************************************************/
MH_ERROR 
MessageHandlerMakeCodeStub(void *userData, void *processor, int severity, 
	unsigned short facility, 
	unsigned short code) {

  SV *wrapper;
  SV * processor_obj;
  HV *stash;
  GV *gv;
  unsigned long ret = 0;

  wrapper = (SV*)userData;

  processor_obj = (SV*) SablotGetInstanceData(processor);

  stash = SvSTASH(SvRV(wrapper));
  gv = gv_fetchmeth(stash, "MHMakeCode", 10, 0);

  if (gv) { 
    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);  
    XPUSHs(wrapper);
    if (processor_obj) 
      XPUSHs(processor_obj);
    else
      XPUSHs(&sv_undef);
    XPUSHs(sv_2mortal(newSViv(severity)));
    XPUSHs(sv_2mortal(newSViv(facility)));
    XPUSHs(sv_2mortal(newSViv(code)));
    PUTBACK;

    perl_call_sv((SV*)GvCV(gv), G_SCALAR);

    SPAGAIN;
	
    ret = POPi;

    PUTBACK;
    FREETMPS;
    LEAVE;
  } else {
    croak("MHMakeCode method missing");
  }
  return ret;
}


MH_ERROR 
MessageHandlerLogStub(void *userData, void *processor, MH_ERROR code, 
	MH_LEVEL level, char **fields) {

  SV *wrapper;
  SV * processor_obj;
  HV *stash;
  GV *gv;
  char **foo;

  wrapper = (SV*)userData;

  processor_obj = (SV*) SablotGetInstanceData(processor);;
  stash = SvSTASH(SvRV(wrapper));
  gv = gv_fetchmeth(stash, "MHLog", 5, 0);

  if (gv) {
    dSP;
    ENTER;
    SAVETMPS;

    PUSHMARK(SP);  
    XPUSHs(wrapper);
    if (processor_obj) 
      XPUSHs(processor_obj);
    else
      XPUSHs(&sv_undef);
    XPUSHs(sv_2mortal(newSViv(code)));
    XPUSHs(sv_2mortal(newSViv(level)));
    foo = fields;
    while (*foo) {
      XPUSHs(sv_2mortal(newSVpv(*foo, strlen(*foo))));
      foo++;
    }

    PUTBACK;

    perl_call_sv((SV*)GvCV(gv), G_VOID);

    FREETMPS;
    LEAVE;
  } else {
    croak("MHLog method missing");
  }
  return code;
}


MH_ERROR 
MessageHandlerErrorStub(void *userData, void *processor, MH_ERROR code, 
	MH_LEVEL level, char **fields) {

  SV *wrapper;
  SV * processor_obj;
  HV *stash;
  GV *gv;
  char **foo;

  wrapper = (SV*)userData;

  processor_obj = (SV*) SablotGetInstanceData(processor);
  stash = SvSTASH(SvRV(wrapper));
  gv = gv_fetchmeth(stash, "MHError", 7, 0);

  if (gv) {
    dSP;
    ENTER;
    SAVETMPS;

    PUSHMARK(SP);  
    XPUSHs(wrapper);
    if (processor_obj) 
      XPUSHs(processor_obj);
    else
      XPUSHs(&sv_undef);
    XPUSHs(sv_2mortal(newSViv(code)));
    XPUSHs(sv_2mortal(newSViv(level)));
    foo = fields;
    while (*foo) {
      XPUSHs(sv_2mortal(newSVpv(*foo, strlen(*foo))));
      foo++;
    }

    PUTBACK;

    perl_call_sv((SV*)GvCV(gv), G_SCALAR);

    FREETMPS;
    LEAVE;
  } else {
    croak("MHError method missing");
  }
  return code;
}


MessageHandler mh_handler_vector = {
  MessageHandlerMakeCodeStub,
  MessageHandlerLogStub,
  MessageHandlerErrorStub
};

/*********************
 scheme handler
*********************/

int SchemeHandlerGetAllStub(void *userData, void *processor,
    const char *scheme, const char *rest, 
    char **buffer, int *byteCount) {

  SV *wrapper;
  SV *processor_obj;
  HV *stash;
  GV *gv;
  unsigned long ret = 0;
  SV *value;
  unsigned int len;

  wrapper = (SV*)userData;

  processor_obj = (SV*) SablotGetInstanceData(processor);

  stash = SvSTASH(SvRV(wrapper));
  gv = gv_fetchmeth(stash, "SHGetAll", 8, 0);

  if (gv) { 
    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);  
    XPUSHs(wrapper);
    if (processor_obj) 
      XPUSHs(processor_obj);
    else
      XPUSHs(&sv_undef);
    XPUSHs(sv_2mortal(newSVpv((char*) scheme, strlen(scheme))));
    XPUSHs(sv_2mortal(newSVpv((char*) rest, strlen(rest))));

    PUTBACK;

    perl_call_sv((SV*)GvCV(gv), G_SCALAR);

    SPAGAIN;
	
    ret = 0; /* oops */
    value = POPs;
    if ( SvOK(value) ) {
      SvPV(value, len);
      *buffer = (char*) malloc(len + 1);
      strcpy(*buffer, SvPV(value, PL_na));
      *byteCount = len + 1;
    } else {
      *byteCount = -1;
    }

    PUTBACK;
    FREETMPS;
    LEAVE;
  } else {
    *byteCount = -1;
  }
  return ret;
}

int SchemeHandlerFreeMemoryStub(void *userData, void *processor,
    char *buffer) {
  unsigned long ret = 0;
  if (buffer) {
    free(buffer);
  }
  return ret;
}

int SchemeHandlerOpenStub(void *userData, void *processor,
    const char *scheme, const char *rest, int *handle) {

  SV *wrapper;
  SV * processor_obj;
  HV *stash;
  GV *gv;
  unsigned long ret = 0;
  SV *value;

  wrapper = (SV*)userData;

  processor_obj = (SV*) SablotGetInstanceData(processor);

  stash = SvSTASH(SvRV(wrapper));
  gv = gv_fetchmeth(stash, "SHOpen", 6, 0);

  if (gv) { 
    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);  
    XPUSHs(wrapper);
    if (processor_obj) 
      XPUSHs(processor_obj);
    else
      XPUSHs(&sv_undef);
    XPUSHs(sv_2mortal(newSVpv((char*) scheme, strlen(scheme))));
    XPUSHs(sv_2mortal(newSVpv((char*) rest, strlen(rest))));

    PUTBACK;

    perl_call_sv((SV*)GvCV(gv), G_SCALAR);

    SPAGAIN;
	
    value = POPs;
    if ( SvOK(value) ) {
      ret = 0;
      SvREFCNT_inc(value);
      *handle = (int) value;
    } else {
      ret = 100;
      *handle = 0;
    }

    PUTBACK;
    FREETMPS;
    LEAVE;
  } else {
    croak("SHOpen method missing");
  }
  return ret;
}

int SchemeHandlerGetStub(void *userData, void *processor,
    int handle, char *buffer, int *byteCount) {

  SV *wrapper;
  SV * processor_obj;
  HV *stash;
  GV *gv;
  unsigned long ret = 0;
  SV *value;
  unsigned int len;

  wrapper = (SV*)userData;

  processor_obj = (SV*) SablotGetInstanceData(processor);

  stash = SvSTASH(SvRV(wrapper));
  gv = gv_fetchmeth(stash, "SHGet", 5, 0);

  if (gv) { 
    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);  
    XPUSHs(wrapper);
    if (processor_obj) 
      XPUSHs(processor_obj);
    else
      XPUSHs(&sv_undef);
    XPUSHs((SV*)handle);
    XPUSHs(sv_2mortal(newSViv(*byteCount - 1)));
    PUTBACK;

    perl_call_sv((SV*)GvCV(gv), G_SCALAR);

    SPAGAIN;
	
    value = POPs;
    if SvOK(value) {
      char *aux;
      aux = SvPV(value, len);
      *byteCount = len < *byteCount ? len : *byteCount;
      strncpy(buffer, aux, *byteCount + 1);
    } else {
      *byteCount = 0;
    }

    ret = 0; /* oops */

    PUTBACK;
    FREETMPS;
    LEAVE;
  } else {
    croak("SHGet method missing");
  }
  return ret;
}

int SchemeHandlerPutStub(void *userData, void *processor,
    int handle, const char *buffer, int *byteCount) {

  SV *wrapper;
  SV * processor_obj;
  HV *stash;
  GV *gv;
  unsigned long ret = 0;
  SV *value;

  wrapper = (SV*)userData;

  processor_obj = (SV*) SablotGetInstanceData(processor);

  stash = SvSTASH(SvRV(wrapper));
  gv = gv_fetchmeth(stash, "SHPut", 5, 0);

  if (gv) { 
    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);  
    XPUSHs(wrapper);
    if (processor_obj) 
      XPUSHs(processor_obj);
    else
      XPUSHs(&sv_undef);
    XPUSHs((SV*) handle);
    XPUSHs(sv_2mortal(newSVpv((char*) buffer, *byteCount)));
    PUTBACK;

    perl_call_sv((SV*)GvCV(gv), G_SCALAR);

    SPAGAIN;

    value = POPs;
    if (SvOK(value)) {
      ret = 0;
    } else {
      ret = 100;
    }

    PUTBACK;

    FREETMPS;
    LEAVE;
  } else {
    croak("SHPut method missing");
  }
  return ret;
}

int SchemeHandlerCloseStub(void *userData, void *processor,
    int handle) {

  SV *wrapper;
  SV * processor_obj;
  HV *stash;
  GV *gv;
  unsigned long ret = 0;

  wrapper = (SV*)userData;

  processor_obj = (SV*) SablotGetInstanceData(processor);

  stash = SvSTASH(SvRV(wrapper));
  gv = gv_fetchmeth(stash, "SHClose", 7, 0);

  if (gv) { 
    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);  
    XPUSHs(wrapper);
    if (processor_obj) 
      XPUSHs(processor_obj);
    else
      XPUSHs(&sv_undef);
    XPUSHs((SV*) handle);

    PUTBACK;

    perl_call_sv((SV*)GvCV(gv), 0);

    SvREFCNT_dec((SV*) handle);
    ret = 0;

    FREETMPS;
    LEAVE;
  } else {
    croak("SHClose method missing");
  }
  return ret;
}

SchemeHandler sh_handler_vector = {
  SchemeHandlerGetAllStub,
  SchemeHandlerFreeMemoryStub,
  SchemeHandlerOpenStub,
  SchemeHandlerGetStub,
  SchemeHandlerPutStub,
  SchemeHandlerCloseStub
};

/*********************
 miscellaneous handler
*********************/

void
MiscHandlerDocumentInfoStub(void* userData, void *processor,
                        const char *contentType, 
                        const char *encoding) {

  SV *wrapper;
  SV * processor_obj;
  HV *stash;
  GV *gv;

  wrapper = (SV*)userData;

  processor_obj = (SV*) SablotGetInstanceData(processor);

  stash = SvSTASH(SvRV(wrapper));
  gv = gv_fetchmeth(stash, "XHDocumentInfo", 14, 0);

  if (gv) { 
    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);  
    XPUSHs(wrapper);
    if (processor_obj) 
      XPUSHs(processor_obj);
    else
      XPUSHs(&sv_undef);
    XPUSHs(sv_2mortal(newSVpv((char*) contentType, strlen(contentType))));
    XPUSHs(sv_2mortal(newSVpv((char*) encoding, strlen(encoding))));

    PUTBACK;

    perl_call_sv((SV*)GvCV(gv), 0);

    FREETMPS;
    LEAVE;
  } else {
    croak("XHDocumentInfo method missing");
  }
}

MiscHandler xh_handler_vector = {
  MiscHandlerDocumentInfoStub
};

/***********************************************************
* useful macros
***********************************************************/

#define SIT_HANDLE(sit) (SablotSituation)SvIV(*hv_fetch((HV*)SvRV(sit), "_handle", 7, 0))

#define VALIDATE_RV(sv)  (! SvOK(sv) || (SvROK(sv) && \
                          (SvTYPE(SvRV(sv)) == SVt_PVCV)))

#define VALIDATE_HASHREF(object) (SvOK(object) && (SvROK(object)) && \
                       (SvTYPE(SvRV(object)) == SVt_PVHV))

#define GET_PROCESSOR(object) (void*)(SvIV(*hv_fetch((HV*)SvRV(object), \
                              "_handle", 7, 0)))

#define DOC_HANDLE(doc) (SDOM_Document)SvIV(*hv_fetch((HV*)SvRV(doc), \
                         "_handle", 7, 0))


/* #define GET_PROCESSOR(object) ((void*)SvIV(SvRV(object))) */

/*
############################################################
############################################################
## real xs stuff
############################################################
############################################################
*/

MODULE = XML::Sablotron	PACKAGE = XML::Sablotron PREFIX = Sablot
PROTOTYPES: ENABLE

############################################################
#old non- object interface
############################################################

int
SablotProcessStrings(sheet,input,result)
	char * 		sheet
	char * 		input
	char * 		result
	PREINIT:
	char *foo;
	CODE:
        RETVAL = SablotProcessStrings(sheet, input, &foo);
	result = foo;  
	OUTPUT:
	result
	RETVAL
	CLEANUP:
	if (! RETVAL && foo) SablotFree(foo);

#/* renamed to avoid the conflict with the new object method process */

int
SablotProcess(sheetURI, inputURI, resultURI, params, arguments, result)
	char * 		sheetURI
	char *		inputURI
	char *		resultURI
	SV *		params
	SV *		arguments
	char * 		result
	PREINIT:
	char **params_ptr, **args_ptr;
	AV *params_av, *args_av;
	int i, size;
	SV *aux_sv;
	char *hoo;
	CODE:
	
	if (SvOK(params)) {
	  if (! SvROK(params) || !(SvFLAGS(params) & SVt_PVAV))
	    croak("4-th argument to SablotProcess has to be ARRAYREF");
          params_av = (AV*)SvRV(params);
          size = av_len(params_av) + 1;
          params_ptr = (char**)malloc((size + 1) * sizeof(char*));
          for (i = 0; i < size; i++) {
            aux_sv = *av_fetch(params_av, i, 0);
            params_ptr[i] = SvPV(aux_sv, PL_na);
          }
          params_ptr[size] = NULL;
	} else {
	  params_ptr = NULL;
	}

	if (SvOK(arguments)) {
	  if (! SvROK(arguments) || !(SvFLAGS(arguments) & SVt_PVAV))
	    croak("5-th argument to SablotProcess has to be ARRAYREF");
	  args_av = (AV*)SvRV(arguments);
	  size = av_len(args_av) + 1;
          args_ptr = (char**)malloc((size + 1) * sizeof(char*));
          for (i = 0; i < size; i++) {
            aux_sv = *av_fetch(args_av, i, 0);
            args_ptr[i] = SvPV(aux_sv, PL_na);
          }
          args_ptr[size] = NULL;
	} else {
	  args_ptr = NULL;
	}

       	RETVAL = SablotProcess(sheetURI, inputURI, resultURI, 
		               params_ptr, args_ptr, &hoo);
	if (params_ptr) free(params_ptr);
	if (args_ptr) free(args_ptr);
	result = hoo;
	OUTPUT:
	RETVAL
	result
	CLEANUP:
	if (! RETVAL && hoo) SablotFree(hoo);


############################################################
# new object interface
############################################################
MODULE = XML::Sablotron PACKAGE = XML::Sablotron::Processor  PREFIX = Sablot
PROTOTYPES: ENABLE

void*
_createProcessor(object)
	SV 	*object
    	PREINIT: 
     	void *processor;
	SV *foo;
     	CODE:
     	SablotCreateProcessor(&processor);
	SablotSetInstanceData(processor, SvREFCNT_inc(object));
	RETVAL = processor;
     	OUTPUT:
     	RETVAL

void
_destroyProcessor(object)
	SV 	*object
	PREINIT:
	void *processor;
	SV *processor_obj;
	CODE:
	processor = GET_PROCESSOR(object);
	if ( SablotDestroyProcessor(processor) ) 
	  croak("SablotDestroyProcesso failed");

#break circular reference
void
_release(object)
	SV	*object
	PREINIT:
	void *processor;
	SV *processor_obj;
	CODE:
	processor = GET_PROCESSOR(object);
	processor_obj = (struct sv*) SablotGetInstanceData(processor);
	if (processor_obj) SvREFCNT_dec(processor_obj);
	SablotSetInstanceData(processor, NULL);

int
SablotRunProcessor(object, sheetURI, inputURI, resultURI, params, arguments)
	SV *		object
	char * 		sheetURI
	char *		inputURI
	char *		resultURI
	SV *		params
	SV *		arguments
	PREINIT:
	char **params_ptr, **args_ptr;
	AV *params_av, *args_av;
	int i, size;
	SV *aux_sv;
	char *hoo;
	void *processor;
	CODE:
	processor = GET_PROCESSOR(object);

	if (SvOK(params)) {
	  if (! SvROK(params) || !(SvFLAGS(params) & SVt_PVAV))
	    croak("4-th argument to SablotProcess has to be ARRAYREF");
          params_av = (AV*)SvRV(params);
          size = av_len(params_av) + 1;
          params_ptr = (char**)malloc((size + 1) * sizeof(char*));
          for (i = 0; i < size; i++) {
            aux_sv = *av_fetch(params_av, i, 0);
            params_ptr[i] = SvPV(aux_sv, PL_na);
          }
          params_ptr[size] = NULL;
	} else {
	  params_ptr = NULL;
	}

	if (SvOK(arguments)) {
	  if (! SvROK(arguments) || !(SvFLAGS(arguments) & SVt_PVAV))
	    croak("5-th argument to SablotProcess has to be ARRAYREF");
	  args_av = (AV*)SvRV(arguments);
	  size = av_len(args_av) + 1;
          args_ptr = (char**)malloc((size + 1) * sizeof(char*));
          for (i = 0; i < size; i++) {
            aux_sv = *av_fetch(args_av, i, 0);
            args_ptr[i] = SvPV(aux_sv, PL_na);
          }
          args_ptr[size] = NULL;
	} else {
	  args_ptr = NULL;
	}

       	RETVAL = SablotRunProcessor(processor, sheetURI, inputURI, resultURI, 
		               params_ptr, args_ptr);
	if (params_ptr) free(params_ptr);
	if (args_ptr) free(args_ptr);
	OUTPUT:
	RETVAL

int
addArg(object, sit, name, buff)
        SV*     object
        SV*     sit
        char*   name
        char*   buff
	PREINIT:
	void *processor;
        CODE:
        SablotSituation situa = SIT_HANDLE(sit);
	processor = GET_PROCESSOR(object);
        RETVAL = SablotAddArgBuffer(situa, processor, name, buff);
        OUTPUT:
        RETVAL

int
addArgTree(object, sit, name, tree)
        SV*     object
        SV*     sit
        char*   name
        SV*     tree
	PREINIT:
	void *processor;
        SDOM_Document doc;
        CODE:
        SablotSituation situa = SIT_HANDLE(sit);
	processor = GET_PROCESSOR(object);
        doc = DOC_HANDLE(tree);
        SablotLockDocument(situa, doc);
        RETVAL = SablotAddArgTree(situa, processor, name, doc);
        OUTPUT:
        RETVAL

int
addParam(object, sit, name, value)
        SV*     object
        SV*     sit
        char*   name
        char*   value
	PREINIT:
	void *processor;
        CODE:
        SablotSituation situa = SIT_HANDLE(sit);
	processor = GET_PROCESSOR(object);
        RETVAL = SablotAddParam(situa, processor, name, value);
        OUTPUT:
        RETVAL

int 
process(object, sit, sheet, data, output)
        SV*     object
        SV*     sit
        char*   sheet
        char*   data
        char*   output
	PREINIT:
	void *processor;
        CODE:
        SablotSituation situa = SIT_HANDLE(sit);
	processor = GET_PROCESSOR(object);
        RETVAL = SablotRunProcessorGen(situa, processor, sheet, data, output);
        OUTPUT:
        RETVAL


char*
SablotGetResultArg(object, uri)
	SV *	object
	char * 	uri
	PREINIT:
	void *processor;
	char *hoo;
	int status;
	CODE:
	processor = GET_PROCESSOR(object);
	status = SablotGetResultArg(processor, uri, &hoo);
 	if ( status ) croak("Cann't get requested output buffer\n");
	RETVAL = hoo;
	OUTPUT:
	RETVAL
	CLEANUP:
	if (!status && hoo) SablotFree(hoo);
	
int 
SablotFreeResultArgs(object)
	SV *	object
	PREINIT:
	void *processor;
	CODE:
	processor = GET_PROCESSOR(object);
	RETVAL = SablotFreeResultArgs(processor);
	OUTPUT:
	RETVAL

int 
SablotSetBase(object, base)
	SV * 	object
	char *	base
	PREINIT:
	void *processor;
	CODE:
	processor = GET_PROCESSOR(object);
	RETVAL = SablotSetBase(processor, base);
	OUTPUT:
	RETVAL

int 
SablotSetBaseForScheme(object, scheme, base)
	SV * 	object
	char * 	scheme
	char *	base
	PREINIT:
	void *processor;
	CODE:
	processor = GET_PROCESSOR(object);
	RETVAL = SablotSetBaseForScheme(processor, scheme, base);
	OUTPUT:
	RETVAL

int 
SablotSetLog(object, filename, level)
	SV * 	object
	char *	filename
	int 	level
	PREINIT:
	void *processor;
	CODE:
	processor = GET_PROCESSOR(object);
	RETVAL = SablotSetLog(processor, filename, level);
	OUTPUT:
	RETVAL


int 
SablotClearError(object)
	SV * 	object
	PREINIT:
	void *processor;
	CODE:
	processor = GET_PROCESSOR(object);
	RETVAL = SablotClearError(processor);
	OUTPUT:
	RETVAL

void
SablotSetOutputEncoding(object, encoding)
	SV *	object
	char *	encoding
	PREINIT:
	void *processor;
	CODE:
	processor = GET_PROCESSOR(object);
	SablotSetEncoding(processor, encoding);

############################################################
# intrface for handlers
############################################################

int
_regHandler(object, type, wrapper)
	SV * 	object
	int 	type
	SV * 	wrapper
	PREINIT:
	void *processor;
	void *vector;
	CODE:
	processor = GET_PROCESSOR(object);

	switch (type) {
	  case 0:
	    vector = &mh_handler_vector;
	    break;
          case 1:
	    vector = &sh_handler_vector;
            break;
          case 2:
            croak("SAX handler not yet supported");
            break;
          case 3:
            vector = &xh_handler_vector;
            break;
	  otherwise:
            croak("Unsupported handler type");
	}
	SvREFCNT_inc(wrapper);
	RETVAL = SablotRegHandler(processor, (HandlerType) type, vector, wrapper);
	OUTPUT:
	RETVAL

int
_unregHandler(object, type, wrapper)
	SV	*object
	int 	type
	SV 	*wrapper
	PREINIT:
	void *processor;
	void *vector;
	CODE:
	processor = GET_PROCESSOR(object);
	switch (type) {
	  case 0:
	    vector = &mh_handler_vector;
	    break;
          case 1:
	    vector = &sh_handler_vector;
            break;
          case 2:
            croak("SAX handler not yet supported");
            break;
          case 3:
            vector = &xh_handler_vector;
	    break;
	  otherwise:
            croak("Unsupported handler type");
	}
	RETVAL = SablotUnregHandler(processor, (HandlerType) type, vector, wrapper);
	SvREFCNT_dec(wrapper);
	OUTPUT:
	RETVAL

MODULE = XML::Sablotron    PACKAGE = XML::Sablotron::Situation

int
_getNewSituationHandle(object)
        SV*      object
        CODE:
        SablotSituation sit;
        SablotCreateSituation(&sit);
        RETVAL = (int)sit;
        OUTPUT:
        RETVAL

void
_releaseHandle(object)
        SV*      object
        CODE:
        SablotDestroySituation(SIT_HANDLE(object));

void
setOptions(object, flags)
        SV*      object
        int      flags
        CODE:
        SablotSetOptions(SIT_HANDLE(object), flags);

void
clear(object)
        SV*      object
        CODE:
        SablotClearSituation(SIT_HANDLE(object));

char*
getErrorURI(object)
        SV* object
        CODE:
        char *uri;
        /*uri =  (char*)SablotGetErrorURI(SIT_HANDLE(object)); */
        RETVAL = uri;
        OUTPUT:
        RETVAL

int
getErrorLine(object)
        SV* object
        CODE:
        /* RETVAL = SablotGetErrorLine(SIT_HANDLE(object)); */
        OUTPUT:
        RETVAL

char*
getErrorMsg(object)
        SV* object
        CODE:
        char *msg;
        /* msg = (char*)SablotGetErrorMessage(SIT_HANDLE(object)); */
        RETVAL = msg;
        OUTPUT:
        RETVAL
        CLEANUP:
        if (msg) SablotFree(msg);

int
getDOMExceptionCode(object)
        SV*      object
        CODE:
        RETVAL = SDOM_getExceptionCode(SIT_HANDLE(object));
        OUTPUT:
        RETVAL

char*
getDOMExceptionMessage(object)
        SV*      object
        CODE:
        char *message = SDOM_getExceptionMessage(SIT_HANDLE(object));
        RETVAL = message;
        OUTPUT:
        RETVAL
        CLEANUP:
        if (message) SablotFree(message);

AV*
getDOMExceptionDetails(object)
        SV*      object
        CODE:
        int code;
        char *message;
        char *documentURI;
        int fileLine;
        SDOM_getExceptionDetails(SIT_HANDLE(object), &code,
                                 &message, &documentURI, &fileLine);
        RETVAL = (AV*)sv_2mortal((SV*)newAV());
        av_push(RETVAL, newSViv(code));
        av_push(RETVAL, newSVpv(message, 0));
        av_push(RETVAL, newSVpv(documentURI, 0));
        av_push(RETVAL, newSViv(fileLine));
        OUTPUT:
        RETVAL
        CLEANUP:
        if (message) SablotFree(message);
        if (documentURI) SablotFree(documentURI);
