chan link= [2] of { byte }; /* Communications link between repeater and receiver*/
chan input = [2] of { byte }; /* Communications link between sender and receiver */
chan out_Controller = [2] of {byte}; /* Communication link between the repeator and controller*/
chan in_Controller = [2] of {byte};  /* Communication link between the controller and repeator*/
chan controller_rec = [2] of {byte}; /* Communication link between the reciever and the controller*/


mtype = { canI, youCan, WAIT };


/* Repeater process: receives messages from Sender and relays them to Receiver */
proctype Repeater(chan ingress, egress, inController, outController; byte msg_cnt)
{
		byte msg,signal;
    do
    :: ingress?msg -> msg_cnt++
   	if
    	::msg_cnt > 0;
    	:: outController!canI
    	fi
    :: (msg_cnt > 0) -> egress!msg; msg_cnt--
    
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
  proctype Receiver(chan in, controller; byte msg_cnt, signal_cnt)
  {
  	byte msg, signal;
  	int m,s;
    do
    :: in?msg -> msg_cnt++
    if
    :: (msg >= 0 && msg  <= 9) || (msg_cnt == 0) ->
    :: controller!youCan; msg_cnt--;
    printf("Message recieved\n");
    printf("The next message can be sent, the link is free!\n");
    
    	fi;
    
    od
  }
  
  
    /* Controller, checks if the link between the repeater and the reciever is free in order to send a message*/
    
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
