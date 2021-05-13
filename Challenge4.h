#ifndef CHALLENGE4_H
#define CHALLENGE4_H

//payload of the msg
typedef nx_struct my_msg {
    bool req;
	uint16_t value;
} my_msg_t;

#define REQ 1
#define RESP 2 

enum{
AM_MY_MSG = 6,
};

#endif
