/**
 *	Challenge 4 implementation file.
 *  @author Luca Pirovano, Luca Vecchio
 */

#include "Challenge4.h"
#include "Timer.h"

module Challenge4C {

  uses {
  /****** INTERFACES *****/
	interface Boot;
    interface Receive;
    interface AMSend;
    interface Timer<TMilli> as MilliTimer;
    interface Packet;
    interface SplitControl;
    // ack
    interface PacketAcknowledgements as Ack;
    // used to get source addr - allows for less hardcode
    interface AMPacket;
	interface Read<uint16_t>;
  }

} implementation {

  // note: counter shows how many requests have been sent without receiving an ACK back
  uint8_t counter=0;
  uint8_t rec_id;
  message_t packet;
  am_addr_t sender_addr;
  bool locked;

  //***************** Boot interface ********************//
  event void Boot.booted() {
	dbg("boot","Application booted.\n");
	call SplitControl.start();
  }

  //***************** SplitControl interface ********************//
  event void SplitControl.startDone(error_t err){
    if(err == SUCCESS) {
        if(TOS_NODE_ID==1) {
            call MilliTimer.startPeriodic(1000);
        }
    }
    else {
        call SplitControl.start();
    }
  }

  event void SplitControl.stopDone(error_t err){
    /* Fill it ... */
    dbg("split-control", "Application stopped\n");
  }

  //***************** MilliTimer interface ********************//
  event void MilliTimer.fired() {
	/* This event is triggered every time the timer fires.
	 * When the timer fires, we send a request
	 */
    if(locked) {
        return;
    }
    else {
        my_msg_t* message = (my_msg_t*)call Packet.getPayload(&packet, sizeof(my_msg_t));
        if (message == NULL) {
            return;
        }
        message->msg_type = REQ;
        message->msg_counter = counter;
        message->value = 0;

        if(call Ack.requestAck(&packet)==SUCCESS) {
            dbg("radio_ack", "Ack message is enabled. Sending message...\n");
        } else {
        	dbgerror("radio_ack", "Acks DISABLED\n");
        }

        if(call AMSend.send(2, &packet, sizeof(my_msg_t)) == SUCCESS) {
            locked = TRUE;
        }

    }
  }


  //********************* AMSend interface ****************//
  event void AMSend.sendDone(message_t* buf,error_t err) {
	/* This event is triggered when a message is sent */
    if(&packet == buf) {
        my_msg_t* sent_msg = (my_msg_t*)buf;
        dbg("radio_send", "Sent message with counter: %hu\n", counter);
        locked = FALSE;
        // check for acks
        if(call Ack.wasAcked(buf) && TOS_NODE_ID==1) {
            call MilliTimer.stop();
            dbg("radio_ack", "Ack received.\n");
        }
        else if(call Ack.wasAcked(buf) && TOS_NODE_ID==2) {
            dbg("radio_ack", "Ack received. Exercise done :-)\n");
            call SplitControl.stop();
        }
        else {
            dbg("radio_ack", "Ack not received\n");
        }
        counter++;
    }
  }

  //***************************** Receive interface *****************//
  event message_t* Receive.receive(message_t* buf,void* payload, uint8_t len) {
	/* This event is triggered when a message is received */

    my_msg_t* message_received = (my_msg_t*)payload;
    dbg("radio_rec", "Received message\n");
    if(len != sizeof(my_msg_t)) return buf;

    dbg("radio_rec", "Received message and got through:\n\tType: %hu, \n\tCounter: %hu, \n\tValue: %hu\n", message_received->msg_type, message_received->msg_counter, message_received->value);


    if(TOS_NODE_ID==2) {
    	// prepare packet to send back
        counter = message_received->msg_counter;
        sender_addr = call AMPacket.source(buf);
        call Read.read();
    }

}

  //************************* Read interface **********************//
  event void Read.readDone(error_t result, uint16_t data) {
	/* This event is triggered when the fake sensor finishes to read (after a Read.read()) */
    if(!locked && result == SUCCESS) {

        my_msg_t* message = (my_msg_t*)call Packet.getPayload(&packet, sizeof(my_msg_t));

        if (message == NULL) {
            return;
        }

		// prepare packet to send
        message->msg_type = RESP;
        message->msg_counter = counter;
        message->value = data;
        if(call Ack.requestAck(&packet)==SUCCESS) {
            dbg("radio_ack", "Acks enabled\n");
        }
        if(call AMSend.send(sender_addr, &packet, sizeof(my_msg_t)) == SUCCESS) {
            locked = TRUE;
        }

    }

}

}
