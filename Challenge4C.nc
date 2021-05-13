/**
 *  Source file for implementation of module sendAckC in which
 *  the node 1 send a request to node 2 until it receives a response.
 *  The reply message contains a reading from the Fake Sensor.
 *
 *  @author Luca Pietro Borsani
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
    interface PacketAcknowledgements as Ack;
    interface AMPacket;

    //interfaces for communication
	//interface for timer
    //other interfaces, if needed

	//interface used to perform sensor reading (to get the value from a sensor)
	interface Read<uint16_t>;
  }

} implementation {

  uint8_t counter=0;
  uint8_t rec_id;
  message_t packet;
  am_addr_t sender_addr;
  bool locked;

  void sendReq();
  void sendResp();


  //***************** Send request function ********************//
  void sendReq() {
	/* This function is called when we want to send a request
	 *
	 * STEPS:
	 * 1. Prepare the msg
	 * 2. Set the ACK flag for the message using the PacketAcknowledgements interface
	 *     (read the docs)
	 * 3. Send an UNICAST message to the correct node
	 * X. Use debug statements showing what's happening (i.e. message fields)
	 */
 }

  //****************** Task send response *****************//
  void sendResp() {
  	/* This function is called when we receive the REQ message.
  	 * Nothing to do here.
  	 * `call Read.read()` reads from the fake sensor.
  	 * When the reading is done it raise the event read one.
  	 */
	call Read.read();
  }

  //***************** Boot interface ********************//
  event void Boot.booted() {
	dbg("boot","Application booted.\n");
	call SplitControl.start();
	/* Fill it ... */
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
	 * Fill this part...
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
        counter++;

        if(call Ack.requestAck(&packet)==SUCCESS) {
            dbg("radio_ack", "Acks enabled\n");
        }

        if(call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(my_msg_t)) == SUCCESS) {
            locked = TRUE;
        }
    }
  }


  //********************* AMSend interface ****************//
  event void AMSend.sendDone(message_t* buf,error_t err) {
	/* This event is triggered when a message is sent
	 *
	 * STEPS:
	 * 1. Check if the packet is sent
	 * 2. Check if the ACK is received (read the docs)
	 * 2a. If yes, stop the timer. The program is done
	 * 2b. Otherwise, send again the request
	 * X. Use debug statements showing what's happening (i.e. message fields)
	 */
    if(&packet == buf) {
        my_msg_t* sent_msg = (my_msg_t*)buf;
        dbg("radio_send", "\nType: %hu, \nCounter: %hu, \nValue: %hu\n", sent_msg->msg_type, sent_msg->msg_counter, sent_msg->value);
        locked = FALSE;
        if(call Ack.wasAcked(buf) && TOS_NODE_ID==1) {
            call MilliTimer.stop();
            dbg("radio_ack", "Acked\n");
        }
        else if(call Ack.wasAcked(buf) && TOS_NODE_ID==2) {
            dbg("radio_ack", "OK\n");
            call SplitControl.stop();
        }
        else {
            dbg("radio_ack", "Not Acked\n");
        }
    }
  }

  //***************************** Receive interface *****************//
  event message_t* Receive.receive(message_t* buf,void* payload, uint8_t len) {
	/* This event is triggered when a message is received
	 *
	 * STEPS:
	 * 1. Read the content of the message
	 * 2. Check if the type is request (REQ)
	 * 3. If a request is received, send the response
	 * X. Use debug statements showing what's happening (i.e. message fields)
	 */
    my_msg_t* message_received = (my_msg_t*)payload;
    if(len != sizeof(message_received)) return buf;

    if(TOS_NODE_ID==2) {
        counter = message_received->msg_counter;
        sender_addr = call AMPacket.source(buf);
        call Read.read();
    }

}

  //************************* Read interface **********************//
  event void Read.readDone(error_t result, uint16_t data) {
	/* This event is triggered when the fake sensor finish to read (after a Read.read())
	 *
	 * STEPS:
	 * 1. Prepare the response (RESP)
	 * 2. Send back (with a unicast message) the response
	 * X. Use debug statement showing what's happening (i.e. message fields)
	 */
    if(!locked && result == SUCCESS) {
        //nx_uint16_t value = data;
        //dbg("internal", "\nFake sensor: %hu", data);

        my_msg_t* message = (my_msg_t*)call Packet.getPayload(&packet, sizeof(my_msg_t));

        if (message == NULL) {
            return;
        }

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
