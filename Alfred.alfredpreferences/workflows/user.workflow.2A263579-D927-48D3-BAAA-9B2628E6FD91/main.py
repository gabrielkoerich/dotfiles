#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# jmjeong, 2013/3/25

import alfred
import subprocess
import re
import os
import plistlib

import sys
reload(sys)
sys.setdefaultencoding('utf-8')

# this information is borrowed from (com.help.shawn.rice) by Shawn Rice
hotmod = {
                131072 : "sht",
				262144 : "ctl",
				262401 : "ctl", # https://github.com/shawnrice/alfred2-workflow-help/pull/2/files
				393216 : "sht-ctl",
				524288 : "opt",
				655360 : "sht-opt",
				786432 : "ctl-opt",
				917504 : "sht-ctl-opt",
				1048576 : "cmd",
				1179648 : "sht-cmd",
				1310720 : "ctl-cmd",
				1310985 : "ctl-cmd", # https://github.com/shawnrice/alfred2-workflow-help/pull/2/files
				1441792 : "sht-ctl-cmd",
				1572864 : "opt-cmd",
				1703936 : "sht-opt-cmd",
				1835008 : "ctl-opt-cmd",
				1966080 : "sht-ctl-opt-cmd"
}

def process(query):
    dirname = os.path.dirname(os.path.abspath('.'))
    
    dirs = [f for f in os.listdir(dirname) if os.path.isdir(os.path.join(dirname, f))]

    results = []

    for (idx,d) in enumerate(dirs):
        try:
            plist = plistlib.readPlist(os.path.join(dirname, d, 'info.plist'))
        except:
            continue

        title = plist['name']
        createdby = plist['createdby']
        disabled = plist.get('disabled', None)
        try:
            keyword = ",".join([o['config']['keyword'].strip() for o in plist['objects'] if 'alfred.workflow.input' in o['type']])
        except KeyError:
            keyword = ""

        if not query in title.lower() + createdby.lower() + keyword.lower():
            continue

        try:
            hotkeys = ",".join([hotmod[o['config']['hotmod']]+"-"+o['config']['hotstring'].lower()
                                for o in plist['objects']
                                if 'alfred.workflow.trigger.hotkey' in o['type']
                                and o['config']['hotmod'] != 0 and o['config']['hotkey'] != 0])
        except KeyError:
            hotkeys = ""

        if keyword or hotkeys:
            if hotkeys: keyword += " : "
                
            keyword = " (" + keyword + hotkeys + ")"

        displayTitle = title + (' - disabled' if disabled else '')

        results.append({'title': displayTitle, 'createdby' : createdby, 'disabled' : disabled,
                        'keyword': keyword, 'directory' : d})

    results = sorted(results, key=lambda a: a['title'].lower())

    resultsData = [alfred.Item(title=f['title'], subtitle=' by ' + (f['createdby'] or "[noinfo]") + f['keyword'],
                           attributes = {'arg':os.path.join(dirname,f['directory'])},
                           icon=os.path.join(dirname, f['directory'], u"icon.png")) for f in results]    

    alfred.write(alfred.xml(resultsData,maxresults=None))


if __name__ == '__main__':
    try:
        query = "".join(sys.argv[1:])
    except:
        query = u""

    process(query)
