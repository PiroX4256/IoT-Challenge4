/**
 *	Challenge 4 Components, interfaces and wiring file.
 *  @author Luca Pirovano, Luca Vecchio
 */

#include "Challenge4.h"

configuration Challenge4AppC {}

implementation {


/****** COMPONENTS *****/
  components MainC, Challenge4C as App;
    components new AMSenderC(AM_RADIO_COUNT_MSG);
    components new AMReceiverC(AM_RADIO_COUNT_MSG);
    components new TimerMilliC();
    components ActiveMessageC;
    components SerialStartC;
    components new FakeSensorC();

    /****** INTERFACES *****/
    //Boot interface
    App.Boot -> MainC.Boot;

    /****** Wire the other interfaces down here *****/
    App.Read -> FakeSensorC;
    App.Receive -> AMReceiverC;
    App.AMSend -> AMSenderC;
    App.SplitControl -> ActiveMessageC;
    App.MilliTimer -> TimerMilliC;
    App.Packet -> AMSenderC;
    App.AMPacket -> AMSenderC;
    App.Ack -> ActiveMessageC;
}

