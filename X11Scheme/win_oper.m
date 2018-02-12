#include "win_oper.h"
#include "win_xcb.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include "x11fs.h"

//Specific read and write functions for each file

void border_color_write(int wid, const char *buf)
{
	set_border_color(wid, strtol(buf, NULL, 16));
}

id border_width_read(int wid)
{
	int border_width=get_border_width(wid);
    return border_width < 0 ? nil : @(border_width);
}

void border_width_write(int wid, id width)
{
	set_border_width(wid, [width intValue]);
}

id root_width_read(int wid)
{
	(void) wid;
	return geometry_width_read(-1);
}

id root_height_read(int wid)
{
	(void) wid;
	return geometry_height_read(-1);
}

id geometry_width_read(int wid)
{
    int width=get_width(wid);
    return width < 0 ? nil : @(width);
}

void geometry_width_write(int wid, const char *buf)
{
	set_width(wid, atoi(buf));
}

id geometry_height_read(int wid)
{
	int height=get_height(wid);
    return height < 0 ? nil : @(height);
}

void geometry_height_write(int wid, const char *buf)
{
	set_height(wid, atoi(buf));
}

id geometry_x_read(int wid)
{
    int x=get_x(wid);
    return x < 0 ? nil : @(x);
}

void geometry_x_write(int wid, const char *buf)
{
	set_x(wid, atoi(buf));
}

id geometry_y_read(int wid)
{
    int x=get_x(wid);
    return x < 0 ? nil : @(x);
}

void geometry_y_write(int wid, const char *buf)
{
	set_y(wid, atoi(buf));
}

id mapped_read(int wid)
{
    return get_mapped(wid) ? @"true" : @"false";
}

void mapped_write(int wid, const char *buf)
{
	if(!strcmp(buf, "true\n"))
		set_mapped(wid, true);
	if(!strcmp(buf, "false\n"))
		set_mapped(wid, false);
}

id ignored_read(int wid)
{
    return get_ignored(wid) ? @"true" : @"false";
}

void ignored_write(int wid, const char *buf)
{
	if(!strcmp(buf, "true\n"))
		set_ignored(wid, true);
	if(!strcmp(buf, "false\n"))
		set_ignored(wid, false);
}

void stack_write(int wid, const char *buf)
{
	if(!strcmp(buf, "raise\n"))
		raise(wid);
	if(!strcmp(buf, "lower\n"))
		lower(wid);
}

id title_read(int wid)
{
	char *title=get_title(wid);
    return @(title);
}

id class_read(int wid)
{
    return @[];
//    char **classes=get_class(wid);
//    size_t class0_len = strlen(classes[0]), class1_len = strlen(classes[1]);
//    char *class_string=malloc(class0_len + class1_len + 3);
//    if ( class0_len ) {
//        sprintf(class_string, "%s\n", classes[0]);
//    }
//    if ( class1_len ) {
//        sprintf(class_string + class0_len + 1, "%s\n", classes[1]);
//    }
//    free(classes[0]);
//    free(classes[1]);
//    free(classes);
//    return class_string;
}

id event_read(int wid)
{
    return @(get_events());
}

id focused_read(int wid)
{
//    (void) wid;
//    char *focusedwin;
//    int focusedid=focused();
//    if(focusedid){
//        focusedwin = malloc(WID_STRING_LENGTH+1);
//        sprintf(focusedwin, "0x%08x\n", focusedid);
//    }else{
//        focusedwin = malloc(6);
//        sprintf(focusedwin, "root\n");
//    }
//    return focusedwin;
    return nil;
}


void focused_write(int wid, const char *buf)
{
	(void) wid;
	focus(strtol(buf, NULL, 16));
}
