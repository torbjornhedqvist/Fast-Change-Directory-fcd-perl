#!/bin/bash
#
# Copyright (C) Torbjorn Hedqvist - All Rights Reserved
# You may use, distribute and modify this code under the
# terms of the MIT license. See LICENSE file in the project 
# root for full license information.
#
# Package all required files into a tarball and include the current
# version number in the name.
echo "Making a tarball out of the following files"
tar -zcvf fcd-`perl ./fcd.pl -v`.tar.gz fcd.pl fcd.csh fcd.sh install.sh package.sh README.md LICENSE
echo "Finished, destination tar file contains..."
tar -tvf fcd-`perl ./fcd.pl -v`.tar.gz

