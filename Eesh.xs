#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "E.h"

extern char waitonly ;
static Client *e, *me ;

MODULE = Eesh		PACKAGE = Eesh		

void
e_open()
   CODE:
      waitonly = 0;
      lists.next = NULL;
      display_name = NULL;

      // Inspired by eesh's main.c.  Yeah, that's it: 'inspired'.

      SetupX() ;
      CommsSetup();
      CommsFindCommsWindow();
      XSelectInput(disp, comms_win, StructureNotifyMask);
      XSelectInput(disp, root.win, PropertyChangeMask);
      e = MakeClient(comms_win);
      AddItem(e, "E", e->win, LIST_TYPE_CLIENT);
      me = MakeClient(my_win);
      AddItem(me, "ME", me->win, LIST_TYPE_CLIENT);
      CommsSend(e, "set clientname Eesh.pm");
      CommsSend(e, "set version 0.1");
      CommsSend(e, "set author The Rasterman interpreted by Barrie Slaymaker");
      CommsSend(e, "set email barries@slaysys.com");
      CommsSend(e, "set web http://www.slaysys.com/");
   /*  CommsSend(e, "set address NONE"); */
      CommsSend(e, "set info Eesh.pm: Enlightenment IPC - talk to E from Perl");
   /*  CommsSend(e, "set pixmap 0"); */

      XSync(disp, False) ;


void
e_send(command)
   char *command ;
   CODE:
      CommsSend(e,command);
      XSync(disp,False);


SV *
e_recv_nb()
   PREINIT:
      Client *c ;
      XEvent ev ;
      char   *s ;
      char   *r ;
   CODE:
      r = 0 ;
      while (XPending(disp)) {
	 XNextEvent(disp,&ev) ;
	 if (ev.type == ClientMessage) {
	    // Borrowed from comms.c: HandleComms(ev)
	    s = CommsGet(&c,&ev) ;
	    if (s) {
	       if ( ! r ) {
	          r = (char *)malloc( strlen( s ) + 1 ) ;
		  strcpy( r, s ) ;
	       }
	       else {
	          r = (char *)realloc( r, strlen( r ) + strlen( s ) + 1 ) ;
		  strcat( r, s ) ;
	       }
	       Efree(s) ;
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
