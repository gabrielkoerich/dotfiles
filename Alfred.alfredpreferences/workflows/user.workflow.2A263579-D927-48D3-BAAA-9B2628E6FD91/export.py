#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# Make distribution file for alfred extension
#
# Copyright 2013 Jaemok Jeong(jmjeong@gmail.com)
# [2013/03/29]

import alfred
import os
import plistlib
import zipfile
import re
import json
import shutil
import fnmatch

import sys
reload(sys)
sys.setdefaultencoding('utf-8')

ignore_patterns = (
    '*.pyc',
    '*.alfredworkflow',
    'screenshot.png',
    'README.md',
    '.DS_Store',
    'export.json',
    '*~',
    '#*',
    '_*'
    )

default_export_setting = """
{
    "workflow-export" :
	    {"directory" : "~/Downloads",
		 "enable": true},
    "source-export":
		{"directory" : "~/Downloads/src",
		 "enable": false}
}    
"""

def get_title(info_file):
    try:
        plist = plistlib.readPlist(info_file)
        title = plist['name'].replace(" ", "").replace("/","")
    except:
        title = "default-extension"
    return title

def should_ignore_pattern(name):
    for pattern in ignore_patterns:
        if fnmatch.fnmatch(name, pattern):
            return True
    return False

def get_files(dirname):
    files = []
    for f in os.listdir(dirname):
        if should_ignore_pattern(f):
            continue
        if os.path.isfile(os.path.join(dirname,f)):
            files.append(os.path.join(dirname,f))
        elif os.path.isdir(os.path.join(dirname,f)):
            files.extend(get_files(os.path.join(dirname,f)))
    return files

def do_archive(dirname, filename):
    files = get_files(dirname)

    with zipfile.ZipFile(filename, 'w') as z:
        for f in files:
            relfile = f.replace(dirname+"/", '')
            z.write(f, relfile)
    z.close()

def do_src_archive(dirname, targetdir):
    if dirname == targetdir:
        return
    
    files = get_files(dirname)
    for f in files:
        relfile = f.replace(dirname+"/", '')
        if os.path.dirname(relfile):
            alfred._create(os.path.join(targetdir, os.path.dirname(relfile)))
            
        shutil.copy(f, os.path.join(targetdir, os.path.dirname(relfile)))
    

def load_json(filename):
    try:
        with open(filename) as f:
            export_info = json.load(f, encoding="utf-8")
    except:
        export_info = json.loads(default_export_setting, encoding="utf-8")
    return export_info

def read_json_var(export_info):
    try:
        workflow_export_dir = os.path.abspath(os.path.expanduser(export_info['workflow-export']['directory']))
        alfred._create(workflow_export_dir)
        will_workflow_export = export_info['workflow-export']['enable']

        source_export_dir = os.path.abspath(os.path.expanduser(export_info['source-export']['directory']))
        alfred._create(source_export_dir)
        will_source_export = export_info['source-export']['enable']
    except KeyError:
        print "Invalid export.json file"
        sys.exit(1)
    except IOError:
        print "Io error"
        sys.exit(1)
        
    return (workflow_export_dir, will_workflow_export, source_export_dir, will_source_export)

def main(argv):
    if len(argv) >= 2:
        srcdir = os.path.abspath(sys.argv[1])
    else:
        srcdir = os.path.abspath(".")

    title = get_title(os.path.join(srcdir, 'info.plist'))
    
    export_info = load_json(os.path.join(srcdir, 'export.json'))
    (workflow_export_dir, will_workflow_export, source_export_dir, will_source_export) = read_json_var(export_info)

    try:
        if will_workflow_export:
            do_archive(srcdir, os.path.join(workflow_export_dir, title+".alfredworkflow"))
        if will_source_export:
            do_src_archive(srcdir, source_export_dir)
            
        print "Export : %s" % workflow_export_dir
    except ValueError:
        print "Export fail"
        
if __name__ == '__main__':
    main(sys.argv)
