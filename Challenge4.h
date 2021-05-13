#ifndef CHALLENGE4_H
#define CHALLENGE4_H

//payload of the msg
typedef nx_struct my_msg {
    nx_uint16_t msg_type;
	nx_uint16_t msg_counter;
	nx_uint8_t value;
} my_msg_t;

#define REQ 1
#define RESP 2 

enum{
    AM_RADIO_COUNT_MSG = 6, AM_MY_MSG = 6,
};

#endif
