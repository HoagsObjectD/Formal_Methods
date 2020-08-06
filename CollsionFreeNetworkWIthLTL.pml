#define p (len(link) < 2)

chan link= [2] of { byte }; /* Communications link between repeater and receiver*/
chan input = [2] of { byte }; /* Communications link between sender and receiver */

chan out_Controller = [0] of {byte}; /* Communication link between the repeator and controller*/
chan in_Controller = [0] of {byte};  /* Communication link between the controller and repeator*/
chan controller_rec = [0] of {byte}; /* Communication link between the reciever and the controller*/

mtype = { SEND, REQUEST, LINK_IS_EMPTY, WAIT, ARRIVAL}

/* Repeater process: receives messages from Sender and relays them to Receiver */
proctype Repeater(chan ingress, egress, inController, outController; byte msg_cnt)
{
	mtype signal;
	byte msg;
	bool controller_signal = false;
    
    do
    :: ingress?msg ->  msg_cnt++;
    :: (msg_cnt > 0) -> outController!signal ->

    if
    ::inController?signal
     -> egress!msg; msg_cnt--;  
    fi
 
    od;
    
  }
  


  /* Sender process: continuously generates random messages */
  proctype Sender(chan out)
  {
  	byte msg;
    do
    :: select(msg: 0..9) -> out!msg -> msg = 0;
    od
  }
  
  /* Receiver process: simply consumes the messages that it receives */
  proctype Receiver(chan in, controller; byte msg_cnt)
  {
  	byte msg;
  	mtype signal;
  	
  	
    do
  
    :: in?msg ->controller!ARRIVAL;skip; 
    :: (msg_cnt == 1) -> controller!ARRIVAL;msg_cnt--;
    
    od
  }
  
  
    /* Controller, checks if the link between the repeater and the reciever is free in order to send a message*/
    
    proctype Controller(chan repeatorIn,repeatorOut,rec)
    {
    	mtype signal, recSignal;
    	bool linkIsFree = false;
    do
    
    ::repeatorIn?signal;
    	if
    	::rec?recSignal ->	 
    	 	repeatorOut!signal;
    	fi
    
    od
    
    
    }
  	
  
  init
  {
  	atomic
    {
    run Sender(input);
    run Repeater(input, link, in_Controller, out_Controller, 0); 
    run Controller(out_Controller, in_Controller, controller_rec);
    run Receiver(link, controller_rec, 1);
    }
  }
  
  ltl p1 { always p }
