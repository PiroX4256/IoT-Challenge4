/**
 *  Configuration file for wiring of sendAckC module to other common 
 *  components needed for proper functioning
 *
 *  @author Luca Pietro Borsani
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
    //add the other components here

    /****** INTERFACES *****/
    //Boot interface
    App.Boot -> MainC.Boot;

    /****** Wire the other interfaces down here *****/
    //Send and Receive interfaces
    //Radio Control
    //Interfaces to access package fields
    //Timer interface
    //Fake Sensor read
    App.Read -> FakeSensorC;
    App.Receive -> AMReceiverC;
    App.AMSend -> AMSenderC;
    App.SplitControl -> ActiveMessageC;
    App.MilliTimer -> TimerMilliC;
    App.Packet -> AMSenderC;
}

