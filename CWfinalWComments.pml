// Donat Salihu

//Definition p, checks if there is a collision in the link, i.e more than 1 message simultaneously in the link channel 
#define p (len(link) < 2);

//Communication link between repeater,receiver and the sender
chan link= [2] of { byte }; /* Communications link between repeater and receiver*/
chan input = [2] of { byte }; /* Communications link between sender and receiver */

//Communication links between the controller and the repeater, receiver
chan out_Controller = [0] of {byte}; /* Communication link between the repeator and controller*/
chan in_Controller = [0] of {byte};  /* Communication link between the controller and repeator*/
chan controller_rec = [0] of {byte}; /* Communication link between the reciever and the controller*/

//Messages used in order to notify(or ask) the controller for the next processes to be executed and vice versa
mtype = { SEND, REQUEST, LINK_IS_EMPTY, WAIT, ARRIVAL}

/* Repeater process: receives messages from Sender and relays them to Receiver */


/* inController channel connects the controller to the repeater, the repeator after recieveing a message from the sender,
 notifies the controller via outController channel that a message is ready to be emmited to the receiver.
 After the message has been sent to the controller, the repeator waits for a confirmation from the controller that the link,
  i.e the channel that connects the repeater and the reciever is free, therefore avoiding a collision in the channel.  */

proctype Repeater(chan ingress, egress, inController, outController; byte msg_cnt)
{
	//Define the variables data types
	mtype signal;
	byte msg;
    
    
/*the do loop constantly recieves messages from the receiver and checks if the any signal is recieved 
 by the controller notifying that the link is free and the message can be sent to the reciever
 ingress is channel that the repeator gets the message from the sender, inController is the channel 
 the repeator uses to send signal to the controller(ask for permission), the outController channel
 is the channel the repeator recieves the signal message from the controller and the egress channel is
 the channel used to send the message to the reciever  */
    
    
    do
    
    //the repeator receives a message from the sender and the message count is incremented
    :: ingress?msg ->  msg_cnt++;
    /*if the message count is greater than 0, means that a message is already in the repeator,
    therefore sends a message to the controller notifying that the message is ready to be sent 
    to the reciever*/
    :: (msg_cnt > 0) -> outController!REQUEST -> 
 
 	   if
	 
	    /*after the signal has been sent to the controller, check whether a signal was recieved from
    	    the controller notifying the availability of the link in order to send a message to the reciever*/
    	    
    	    //recieve the signal from the controller, notifying the controller that the link is free
    	   ::inController?SEND
         
           //if so, send the message to the reciever and decrement the count of messages
          -> egress!msg;   msg_cnt--;
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
  
 /*The reciever is connected to the repeator by the "in" channel and to the controller by the "controller" channel.
 The reciever recieves a message and upon arrival of the message from the repeator, notifies the controller
 that the message has been arrived indicating a free channel(link), thus preventing a collision from happening.
  */
   
/* the reciever has three parameters, twho channels that connect the reciever to the repeator and the controller
and a varibale "msg_cnt" of type byte which is used to prevent from a deadlock*/

  proctype Receiver(chan in, controller; byte msg_cnt)
  {
  	//Declaration of variables data types
  	byte msg;
  	mtype signal;
  	
  /*the do loop constantly recieves a message from the repeator and send a signal to the controller
  to notify upon an arrival of the message */
  	
    do
  	/*after recieving a message from the repeator, send a signal to the controller in order to notify 
  	 that the link is free*/

    	:: in?msg ->controller!ARRIVAL;skip; 

    	/*Since, the reciever only informs the controller upon a free link after a message has been recieved from 
    	the repeator, a deadlock could occur before sending the first message.
    	Before the repeator sends the first message to the reciever, no message prior to that has been recieved,
    	therefore no confirmoation signal could be sent to the controller that the link is free, leading to a deadlock 
    	situation, when the reciever would be waiting to consume a message in order to notify the controller that the link is free
    	and the repeator would be waiting for a signal from the controller(which would never happen) that the message could be sent 
    	over the link.
    	In order to prevent the deadlock, a variable called msg_cnt was initialised to the reciever which initially has the value
    	1, so when the system starts, the do loop checks if any message has been recieved, since the statment is false, it checks 
    	for the second statment which states thai if the msg_cnt is equal to 1, send a signal to the the controller notifying the 
    	the link is free and imidiately decrement the count to 0, so that statment could never be true again, since there would 
    	not by any time where the msg_cnt would be 1 again.
    	After the signal has been sent to the controller notifying the the link is free, the repeator could send a message to the 
    	reciever and the do loop would only check the first statmen since the second statment would never be true again. */
    
    	:: (msg_cnt == 1) -> controller!ARRIVAL;msg_cnt--; 
    
    od
  }
  
  
/* Controller, checks if the link between the repeater and the reciever is free in order to send a message.
The controller recieves a signal from the repeator that a message is ready to be sent to the reciever over the link.
The controller send a signal to the controller notifying that the link(the channel connecting the repeator and the reciever is free).
If the controller recives a signal from the repeator and the controller, indicating the the message could be sent,
the controller sends a signal to the repeator to send the message to the reciever via the link channel
*/

//repeatorIn is the channel in which the controller recieves the signal from the repeator
//repeatorOut is the channel in which the controller sends the signal to the repeator
// rec is the channel that connects the reciever and the controller


    
    proctype Controller(chan repeatorIn,repeatorOut,rec)
    {
    	//Declaration of variables data types
    	mtype signal, recSignal;
    	
    /*the do loop recieves a signal from the repeator and the controller
    it then sends a signal to the repeator that the message could be send to the reciever*/
    	
    do
    //recive a signal from the repeator
    ::repeatorIn?REQUEST ->
    	if
    	/*if after repeating the signal from the repeator, the signal from the controller was recieved as well
    	send the signal to the repeator indicating that the link is free and the message can be sent to the reciever
    	*/
    	::rec?ARRIVAL ->	 
    		//send the signal to the repeator
    	 	repeatorOut!SEND; 
    	fi
    
    od

    }
  	
  init
  {
  	atomic
    {
    //proccess creation and mapping the channels that connect the processes with each other
    run Sender(input);
    run Repeater(input, link, in_Controller, out_Controller, 0); 
    run Controller(out_Controller, in_Controller, controller_rec);
    run Receiver(link, controller_rec, 1);
    }
  }

  
/*safety property- the ltl formlua p1 that makes sure that there are never more than 1 message passing thorught the 
link channel(channel that link the reciever to the repeator)  avoiding collision */
  ltl p1 { always p }
  
