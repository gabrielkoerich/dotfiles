#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# jmjeong, 2013/3/25

import os
import plistlib
import subprocess

import sys
reload(sys)
sys.setdefaultencoding('utf-8')

dirname = sys.argv[1]

plist = plistlib.readPlist(os.path.join(dirname, 'info.plist'))
keyword = [o['config']['keyword'] for o in plist['objects'] if 'alfred.workflow.input' in o['type']][0]

launchArgs = "tell application \"Alfred 2\" to search \"%s\"" % keyword 
subprocess.check_call(["osascript", "-e", launchArgs])
