#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# jmjeong, 2013/3/25

import os
import plistlib
import alfred

import sys
reload(sys)
sys.setdefaultencoding('utf-8')

dirname = sys.argv[1]

infofilename = os.path.join(dirname, 'info.plist')

plist = plistlib.readPlist(infofilename)
disabled = not plist['disabled']
plist['disabled'] = disabled
plistlib.writePlist(plist, infofilename)

alfred.write(disabled and "Disabled" or "Enabled")
