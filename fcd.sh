#!/bin/bash
#
# Copyright (C) Torbjorn Hedqvist - All Rights Reserved
# You may use, distribute and modify this code under the
# terms of the MIT license. See LICENSE file in the project 
# root for full license information.
#
# This script works in conjunction with fcd.pl
# If fcd.pl creates the files below we will 
# a) change directory to the content of ~/.fcd_dir and
# b) execute the commands in ~/.fcd_cmd
#
fcd.pl $@

# Created on succesful cd in previous call to fcd.pl
if [ -e ~/.fcd_dir ]; then
    cd `cat ~/.fcd_dir`
fi

# Created if previous call to fcd.pl had an attached extra command line
if [ -e ~/.fcd_cmd ]; then
    source ~/.fcd_cmd 
fi

