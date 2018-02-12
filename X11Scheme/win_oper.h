#pragma once
#include <unistd.h>

id root_width_read(int wid);
id root_height_read(int wid);

void border_color_write(int wid, const char *buf);

id border_width_read(int wid);
void border_width_write(int wid, id );


id geometry_width_read(int wid);
void geometry_width_write(int wid, const char *buf);

id geometry_height_read(int wid);
void geometry_height_write(int wid, const char *buf);

id geometry_x_read(int wid);
void geometry_x_write(int wid, const char *buf);

id geometry_y_read(int wid);
void geometry_y_write(int wid, const char *buf);


id mapped_read(int wid);
void mapped_write(int wid, const char *buf);


id ignored_read(int wid);
void ignored_write(int wid, const char *buf);


void stack_write(int wid, const char *buf);


id title_read(int wid);


id class_read(int wid);


id event_read(int wid);


id focused_read(int wid);
void focused_write(int wid, const char *buf);
