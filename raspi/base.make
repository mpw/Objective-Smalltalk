#
#   base.make
#
#   Makefile flags and configs to build with the base library.
#
#   Copyright (C) 2001 Free Software Foundation, Inc.
#
#   Author:  Nicola Pero <n.pero@mi.flashnet.it>
#   Based on code originally in the gnustep make package
#
#   This file is part of the GNUstep Base Library.
#
#   This library is free software; you can redistribute it and/or
#   modify it under the terms of the GNU General Public License
#   as published by the Free Software Foundation; either version 2
#   of the License, or (at your option) any later version.
#   
#   You should have received a copy of the GNU General Public
#   License along with this library; see the file COPYING.LIB.
#   If not, write to the Free Software Foundation,
#   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

#
# FIXME - macro names
#
  CONFIG_SYSTEM_INCL += -fobjc-runtime=gnustep-2.1  -fconstant-string-class=NSConstantString
  CONFIG_SYSTEM_DEFS += 

  FND_LDFLAGS =
  FND_LIBS = -lgnustep-base
  FND_DEFINE = -DGNUSTEP_BASE_LIBRARY=1
  GNUSTEP_DEFINE = -DGNUSTEP
  # If gc=yes was passed, use the appropriate library and defines
  ifeq ($(gc), yes)
    AUXILIARY_CPPFLAGS += -DGS_WITH_GC=1
    AUXILIARY_INCLUDE_DIRS += -I/usr/include/gc
  endif
