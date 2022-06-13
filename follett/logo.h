#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdlib.h>
#include <strings.h>
#include <stdio.h>
#include "app_json.h"
#include "app.h"

char * file_data_array;
uint32_t file_size;

char *dec_to_hex(int dec);
int copy_logo_from_usb_to_flash();
int read_logo_from_flash();
int read_image();
int check_image();
uint16_t get_height();
uint16_t get_width();
void logo_process();
