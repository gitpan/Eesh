#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "Xlib.h"

static Display            *disp;
static Window              comms_win;
static Window              my_win;
static Window              client_win;
static Window              root_win;

/*
 * A bunch of routines copied and hacked from the eesh source code
 */

void SetupX() {
   char *display_name = NULL;
   disp = XOpenDisplay(display_name);
   /* if cannot connect to display */
   if (!disp)
     {
	fprintf(stderr,"Eesh cannot connect to the display nominated by\n"
	      "your shell's DISPLAY environment variable. You may set this\n"
	      "variable to indicate which display name Enlightenment is to\n"
	      "connect to. It may be that you do not have an Xserver already\n"
	      "running to serve that Display connection, or that you do not\n"
	      "have permission to connect to that display. Please make sure\n"
	      "all is correct before trying again. Run an Xserver by running\n"
	      "xdm or startx first, or contact your local system\n"
	      "administrator, or Xserver vendor, or read the X, xdm and\n"
	      "startx manual pages before proceeding.\n");
	exit(1);
     }

   root_win = DefaultRootWindow(disp);

   /* warn, if necessary about X version problems */
   if (ProtocolVersion(disp) != 11)
     {
	fprintf(stderr,"WARNING:\n"
	      "This is not an X11 Xserver. It infact talks the X%i protocol.\n"
	      "This may mean Enlightenment will either not function, or\n"
	      "function incorrectly. If it is later than X11, then your\n"
	      "server is one the author(s) of Enlightenment neither have\n"
	      "access to, nor have heard of.\n", ProtocolVersion(disp));
     }
}


char *
duplicate(char *s)
{
   char               *ss;
   int                 sz;

   if (!s)
      return NULL;
   sz = strlen(s);
   ss = malloc(sz + 1);
   strncpy(ss, s, sz + 1);
   return ss ;
}


void
CommsSend( char *command )
{
   char                ss[21];
   int                 i, j, k, len;
   XEvent              ev;
   Atom                a;

   if ( !command ) return ;

   len = strlen(command);
   a = XInternAtom(disp, "ENL_MSG", True);
   ev.xclient.type = ClientMessage;
   ev.xclient.serial = 0;
   ev.xclient.send_event = True;
   ev.xclient.window = comms_win ;
   ev.xclient.message_type = a;
   ev.xclient.format = 8;

   for (i = 0; i < len + 1; i += 12)
     {
	sprintf(ss, "%8x", (int)my_win);
	for (j = 0; j < 12; j++)
	  {
	     ss[8 + j] = command[i + j];
	     if (!command[i + j])
		j = 12;
	  }
	ss[20] = 0;
	for (k = 0; k < 20; k++)
	   ev.xclient.data.b[k] = ss[k];
	XSendEvent(disp, comms_win, False, 0, (XEvent *) & ev);
     }
}

void
CommsFindCommsWindow()
{
   unsigned char      *s;
   Atom                a, ar;
   unsigned long       num, after;
   int                 format;
   Window              rt;
   int                 dint;
   unsigned int        duint;

   a = XInternAtom(disp, "ENLIGHTENMENT_COMMS", True);
   if (a != None)
     {
	s = NULL;
	XGetWindowProperty(disp, root_win, a, 0, 14, False, AnyPropertyType, &ar,
			   &format, &num, &after, &s);
	if (s)
	  {
	     sscanf((char *)s, "%*s %x", (unsigned int *)&comms_win);
	     XFree(s);
	  }
	else
	   (comms_win = 0);
	if (comms_win)
	  {
	     if (!XGetGeometry(disp, comms_win, &rt, &dint, &dint,
			       &duint, &duint, &duint, &duint))
		comms_win = 0;
	     s = NULL;
	     if (comms_win)
	       {
		  XGetWindowProperty(disp, comms_win, a, 0, 14, False,
				  AnyPropertyType, &ar, &format, &num, &after,
				     &s);
		  if (s)
		     XFree(s);
		  else
		     comms_win = 0;
	       }
	  }
     }
//   if (comms_win)
//      XSelectInput(disp, comms_win,
//		   StructureNotifyMask | SubstructureNotifyMask);
}


char *
CommsGet(char **msg, XEvent * ev)
{
   char                s[13], s2[9], st[32];
   int                 i;
   Window              win;

   if (!ev)
      return NULL;
   if (ev->type != ClientMessage)
      return NULL;
   s[12] = 0;
   s2[8] = 0;
   for (i = 0; i < 8; i++)
      s2[i] = ev->xclient.data.b[i];
   for (i = 0; i < 12; i++)
      s[i] = ev->xclient.data.b[i + 8];
   if (*msg)
     {
	/* append text to end of msg */
	*msg = realloc(*msg, strlen(*msg) + strlen(s) + 1);
	if (!*msg)
	   return NULL;
	strcat(*msg, s);
     }
   if (strlen(s) < 12)
     {
	return *msg;
     }
   return 0;
}

MODULE = Eesh		PACKAGE = Eesh		

void
e_open()
   CODE:
      // Inspired by eesh's main.c.  Yeah, that's it: 'inspired'.

      SetupX() ;
      my_win = XCreateSimpleWindow(disp, root_win, -100, -100, 5, 5, 0, 0, 0);
      // CommsSetup();
      CommsFindCommsWindow();
      XSelectInput(disp, comms_win, StructureNotifyMask);
      XSelectInput(disp, root_win, PropertyChangeMask);
      CommsSend( "set clientname Eesh.pm");
      CommsSend( "set version 0.1");
      CommsSend( "set author The Rasterman interpreted by Barrie Slaymaker");
      CommsSend( "set email barries@slaysys.com");
      CommsSend( "set web http://www.slaysys.com/");
   /*  CommsSend( "set address NONE"); */
      CommsSend( "set info Eesh.pm: Enlightenment IPC - talk to E from Perl");
   /*  CommsSend( "set pixmap 0"); */

      XSync(disp, False) ;


void
e_send(command)
   char *command ;
   CODE:
      CommsSend(command);
      XSync(disp,False);


SV *
e_recv_nb()
   PREINIT:
      XEvent ev ;
      char   *s ;
      char   *r ;
      char *msg ;
   CODE:
      r = 0 ;
      msg = malloc(1000);
      *msg = '\0';
      while (XPending(disp)) {
	 XNextEvent(disp,&ev) ;
	 if (ev.type == ClientMessage) {
	    // Borrowed from comms.c: HandleComms(ev)
	    s = CommsGet(&msg,&ev) ;
	    if (s) {
	       if ( ! r ) {
	          r = (char *)malloc( strlen( s ) + 1 ) ;
		  strcpy( r, s ) ;
	       }
	       else {
	          r = (char *)realloc( r, strlen( r ) + strlen( s ) + 1 ) ;
		  strcat( r, s ) ;
	       }
	       free(s) ;
	    }
	 }
      }
      ST(0) = sv_newmortal() ;
      if ( r ) {
         sv_setpv(ST(0),r) ;
      }
      else {
	 ST(0) = &PL_sv_undef ;
      }
