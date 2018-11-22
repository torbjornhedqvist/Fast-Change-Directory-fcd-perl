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
tar -cvf fcd-`perl ./fcd.pl -v`.tar fcd.pl fcd.csh fcd.sh changelog.txt README.md LICENSE
echo "Finished, destination tar file contains..."
tar -tvf fcd-`perl ./fcd.pl -v`.tar

