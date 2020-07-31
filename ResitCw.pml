/* Donat Salihu */

chan link= [2] of { byte }; /* Communications link between repeater and receiver*/
chan input = [2] of { byte }; /* Communications link between sender and receiver */
chan out_Controller = [2] of {byte}; /* Communication link between the repeator and controller*/
chan in_Controller = [2] of {byte};  /* Communication link between the controller and repeator*/
chan controller_rec = [2] of {byte}; /* Communication link between the reciever and the controller*/


mtype = { canI, youCan, SEND };


/* Repeater process: receives messages from Sender and relays them to Receiver */
/* Before relaying the message to the reciever, the repeaotr firstly sends a signal to the controller in order to confirm that the message can be sent to the reciever*/

proctype Repeater(chan ingress, egress, inController, outController; byte msg_cnt)
{
		byte msg,signal;
		int s;
		msg_cnt = 0;
    do
    :: ingress?msg -> msg_cnt++;
    :: inController?signal(s)
    :: (msg_cnt > 0) -> outController!canI
    if
    ::(msg_cnt>0) && (signal == SEND)->
    :: egress!msg; msg_cnt--;
    fi;
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
  /* The moment the reciever recives a message, the reciever relays a signal to inform the controller that the link between the repeator and the reciever 
  is free and the next message can be relayed*/
  /*In order to not have a deadlock, the reciever is going to count every time a message is consumed by the repeator and decrement by one each time a signal is send to the 
  controller,therefore if there is a case when the link is free but the reciever never consumed a message, the reciever could still send the signal to the controller in order to inform that the link
  is free.  */
  proctype Receiver(chan in, controller; byte msg_cnt, signal_cnt)
  {
  	byte msg, signal;
  	int m,s;
    do
    :: in?msg -> msg_cnt++
    if
    :: (msg >= 0 && msg  <= 9)->
    :: controller!youCan; msg_cnt--;
    printf("Message recieved\n");
    printf("The next message can be sent, the link is free!\n");
    
    	fi;
    
    od
  }
  
  
    /* Controller, checks if the link between the repeater and the reciever is free in order to send a message*/
    /**/
    
    proctype Controller(chan in,out,rec; byte signal_cnt)
    {
    	byte signal1,signal2;
    	int s1,s2;
    do
    	::in?signal1(s1) ->
    	::rec?signal2(s2) ->
    	if
    	::(signal1 == canI) && (signal2 == youCan)->
    	printf("Signal from the repeater recieved!\n");
    	printf("The message can be sent to the reciever!\n");
    	::out!SEND
    	else ->
    	printf("The link between the repeater and the reciever is not empty!\n");
    	fi;
    od
    }
  	
  
  init
  {
  	atomic
    {
    run Sender(input);
    run Repeater(input, link, in_Controller, out_Controller, 0); 
    run Controller(out_Controller, in_Controller, controller_rec, 0);
    run Receiver(link, controller_rec, 0,0);
    }
  }
