#define FUSE_USE_VERSION 26


#import <Foundation/Foundation.h>
#include <stdio.h>
//#include <fuse.h>
#include <stdlib.h>
#include <stdbool.h>
#include <errno.h>
#include <string.h>
#include <fnmatch.h>
#include "x11fs.h"
#include "win_xcb.h"
#include "win_oper.h"
#include <sys/stat.h>
#import <MPWFoundation/MPWFoundation.h>
#import <ObjectiveSmalltalk/MPWStCompiler.h>



@implementation X11Scheme


//Represents a single file, contains pointers to the functions to call to read and write for that file
struct x11fs_file{
	const char *path;
	int mode;
	bool direct_io;
	bool dir;
	id (*read)(int wid);
	void (*write)(int wid, const char *buf);
};


//Our file layout
static const struct x11fs_file x11fs_files[] = {
	{"/",                     S_IFDIR | 0700, false, true,  NULL,                 NULL},
	{"/root",                 S_IFDIR | 0700, false, true,  NULL,                 NULL},
	{"/root/geometry",        S_IFDIR | 0700, false, true,  NULL,                 NULL},
	{"/root/geometry/width",  S_IFREG | 0400, false, false, root_width_read,      NULL},
	{"/root/geometry/height", S_IFREG | 0400, false, false, root_height_read,     NULL},
	{"/0x*",                  S_IFDIR | 0700, false, true,  NULL,                 NULL},
	{"/0x*/border",           S_IFDIR | 0700, false, true,  NULL,                 NULL},
	{"/0x*/border/color",     S_IFREG | 0200, false, false, NULL,                 border_color_write},
	{"/0x*/border/width",     S_IFREG | 0600, false, false, border_width_read,    border_width_write},
	{"/0x*/geometry",         S_IFDIR | 0700, false, true,  NULL,                 NULL},
	{"/0x*/geometry/width",   S_IFREG | 0600, false, false, geometry_width_read,  geometry_width_write},
	{"/0x*/geometry/height",  S_IFREG | 0600, false, false, geometry_height_read, geometry_height_write},
	{"/0x*/geometry/x",       S_IFREG | 0600, false, false, geometry_x_read,      geometry_x_write},
	{"/0x*/geometry/y",       S_IFREG | 0600, false, false, geometry_y_read,      geometry_y_write},
	{"/0x*/mapped",           S_IFREG | 0600, false, false, mapped_read,          mapped_write},
	{"/0x*/ignored",          S_IFREG | 0600, false, false, ignored_read,         ignored_write},
	{"/0x*/stack",            S_IFREG | 0200, false, false, NULL,                 stack_write},
	{"/0x*/title",            S_IFREG | 0400, false, false, title_read,           NULL},
	{"/0x*/class",            S_IFREG | 0400, false, false, class_read,           NULL},
	{"/focused",              S_IFREG | 0600, false, false, focused_read,         focused_write},
	{"/event",                S_IFREG | 0400, true,  false, event_read,           NULL},
};

//Pull out the id of a window from a path
static int get_winid(const char *path)
{
	int wid = -1;
	//Check if the path is to a window directory or it's contents
	if(!strncmp(path, "/0x", 3) && sscanf(path, "/0x%08x", &wid) != 1){
		wid = 0;
	}

	return wid;
}

NSArray*  x11fs_readdir( NSString *nspath )
{
  NSMutableArray *contentsArray=[NSMutableArray array];
  const char *path=[nspath UTF8String];

	//If the path is to a non existant window says so
	int wid;
	if((wid = get_winid(path)) != -1 && !exists(wid)){
		return nil;
	}

	bool exists = false;
	bool dir = false;


	//Iterate through our filesystem layout
	size_t files_length = sizeof(x11fs_files)/sizeof(struct x11fs_file);
	for(size_t i=0; i<files_length; i++){

		//If the path was to a window replace the wildcard in the layout with the actual window we're looking at
		char *matchpath;
		if((wid != -1) && (get_winid(x11fs_files[i].path) != -1)){
			matchpath=malloc(strlen(x11fs_files[i].path)+8);
			sprintf(matchpath, "/0x%08x", wid);
			sprintf(matchpath+11, "%s", x11fs_files[i].path+4);
		}
		else
			matchpath=strdup(x11fs_files[i].path);


		//As the path for the root directory is just a / with no text we need to treat it as being 0 length
		//This is for when we check if something in our layout is in the folder we're looking at, but not in a subfolder
		int len = !strcmp(path, "/") ? 0 : strlen(path);

		//If the file exists in our layout
		if(!strncmp(path, matchpath, strlen(path))){
			exists = true;

			//Check that to see if an element in our layout is directly below the folder we're looking at in the heirarchy
			//If so add it to the directory listing
			if((strlen(matchpath) > strlen(path))
					&& ((matchpath+len)[0] == '/')
					&& !strchr(matchpath+len+1, '/')){
				dir = true;

				//If it's a wildcarded window in our layout with the list of actual windows
				if(!strcmp(matchpath, "/0x*")){
					//Get the list of windows
					int *wins = list_windows();

					//Add each window to our directory listing
					for(int j=0; wins[j]; j++){
						int win = wins[j];
						char *win_string;

						win_string = malloc(sizeof(char)*(WID_STRING_LENGTH));
						sprintf(win_string, "0x%08x", win);

//						filler(buf, win_string, NULL, 0);
            [contentsArray addObject:[NSString stringWithUTF8String:win_string]];

						free(win_string);
					}

					free(wins);
				}
				//Otherwise just add the file to our directory listing
				else

         [contentsArray addObject:[NSString stringWithUTF8String:matchpath+len+1]];
			}
		}
		free(matchpath);
	}

	if(!exists)
		return nil;

	//Add any extra needed elements to the directory list
	if(dir){
	}else
		return nil;

	return contentsArray;
}

//Read a file
id  x11fs_read(NSString *nspath)
{
  const char *path=[nspath UTF8String];
	//Iterate through our layout
	size_t files_length = sizeof(x11fs_files)/sizeof(struct x11fs_file);
	for(size_t i=0; i<files_length; i++){
		//If our file is in the layout
//    NSLog(@"match %s against %s",path,x11fs_files[i].path);
		if(!fnmatch(x11fs_files[i].path, path, FNM_PATHNAME)){
			//If the path is to a window check it exists
			int wid=get_winid(path);
			if(wid != -1 && !exists(wid)){
				return nil;
			}

			//Check we can actually read
			if(x11fs_files[i].dir)
				return x11fs_readdir(nspath);

			if(!x11fs_files[i].read)
				return nil;
			//Call the read function and stick the results in the buffer
			id result= x11fs_files[i].read(wid);
      return result;
		}
	}
	return nil;
}

//Write to a file
static int x11fs_write(const char *path, const char *buf, size_t size)
{
	//Iterate through our layout
	size_t files_length = sizeof(x11fs_files)/sizeof(struct x11fs_file);
	for(size_t i=0; i<files_length; i++){
		//If our file is in the layout
		if(!fnmatch(x11fs_files[i].path, path, FNM_PATHNAME)){
			//If the path is to a window check it exists
			int wid;
			if((wid=get_winid(path)) != -1 && !exists(wid)){
				return -ENOENT;
			}

			//Check we can actually read
			if(x11fs_files[i].dir)
				return -EISDIR;

			if(!x11fs_files[i].write)
				return -EACCES;

			//Call the write function
			char *trunc_buf = strndup(buf, size);
			x11fs_files[i].write(wid, trunc_buf);
			free(trunc_buf);
		}
	}
	return size;
}

//Delete a folder (closes a window)
static int x11fs_rmdir(const char *path)
{
	//Check the folder is one representing a window
	//Returning ENOSYS because sometimes this will be on a dir, just not one that represents a window
	//TODO: Probably return more meaningful errors
	int wid;
	if((wid=get_winid(path)) == -1 || strlen(path)>11)
		return -ENOSYS;

	//Close the window
	close_window(wid);
	return 0;
}

-valueForBinding:aBinding
{
  return x11fs_read([aBinding path]);
}

-(instancetype)init
{
    self=[super init];
    if(xcb_init()!=X11FS_SUCCESS){
        return nil;
    }
    return self;
}

@end

//
////Just setup our connection to X then let fuse handle the rest
//int main(int argc, char **argv)
//{
//  MPWByteStream* Stdout=[MPWPropertyListStream Stdout];
//  MPWStCompiler *compiler=[MPWStCompiler compiler];
//
//    if(xcb_init()!=X11FS_SUCCESS){
//        fputs("Failed to setup xcb. Quiting...\n", stderr);
//        return 1;
//    }
//  [compiler evaluateScriptString:@"scheme:x11 := X11Scheme scheme."];
//  NSLog(@"did setup environment");
//  NSString *path=@"/root/geometry";
//  if ( argc > 1 ) {
//    path=[NSString stringWithUTF8String:argv[1]];
//  } else {
//    NSLog(@"path defaulting to %@",path);
//  }
//  id result=[compiler evaluateScriptString:[NSString stringWithFormat:@"x11:%@",path]];
//  [Stdout writeObject:result];
//}

