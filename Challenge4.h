/**
 * 	Challenge 4 header file.
 *  @author Luca Pirovano, Luca Vecchio
 */

#ifndef CHALLENGE4_H
#define CHALLENGE4_H

//payload of the msg
typedef nx_struct my_msg {
    nx_uint8_t msg_type;
	nx_uint16_t msg_counter;
	// used only by mote 2
	nx_uint16_t value;
} my_msg_t;

#define REQ 1
#define RESP 2

enum{
    AM_RADIO_COUNT_MSG = 6, AM_MY_MSG = 6,
};

#endif
