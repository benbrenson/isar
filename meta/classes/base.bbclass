# Copyright (C) 2003  Chris Larson
# Copyright (C) 2017 Mixed Mode GmbH
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.

inherit logging

THISDIR = "${@os.path.dirname(d.getVar('FILE', True))}"


addtask showdata
do_showdata[nostamp] = "1"
python do_showdata() {
	import sys
	# emit variables and shell functions
	bb.data.emit_env(sys.__stdout__, d, True)
	# emit the metadata which isnt valid shell
	for e in bb.data.keys(d):
		if bb.data.getVarFlag(e, 'python', d):
			sys.__stdout__.write("\npython %s () {\n%s}\n" % (e, bb.data.getVar(e, d, 1)))
}

addtask listtasks
do_listtasks[nostamp] = "1"
python do_listtasks() {
	import sys
	for e in bb.data.keys(d):
		if bb.data.getVarFlag(e, 'task', d):
			sys.__stdout__.write("%s\n" % e)
}

addtask build
do_build[dirs] = "${TOPDIR}"
python base_do_build () {
	bb.note("The included, default BB base.bbclass does not define a useful default task.")
	bb.note("Try running the 'listtasks' task against a .bb to see what tasks are defined.")
}


addtask cleanall
python do_cleanall() {
    import subprocess as shell
    src_uri    = (d.getVar('SRC_URI', True) or "").split()
    pf         = d.getVar('PF', True)
    stampdir   = d.getVar('STAMPS_DIR', True)
    extractdir = d.getVar('EXTRACTDIR', True)
    # clean stamps
    stamps = os.listdir(stampdir)
    for stamp in stamps:
    	if pf in stamp:
    		os.remove(stampdir + '/' + stamp)
    
    # clean workdir
    if not os.path.isdir(extractdir):
        return
    
    for entry in os.listdir(extractdir):
    	if 'temp' not in entry:
    		abspath = extractdir + '/' + entry
    		shell.call(['sudo', 'rm', '-rf', abspath])
    # clean downloads
    if len(src_uri) == 0:
    	return
    try:
    	fetcher = bb.fetch2.Fetch(src_uri, d)
    	fetcher.clean()
    except bb.fetch2.BBFetchException as e:
    	raise bb.build.FuncFailed(e)
}
do_cleanall[nostamp] = "1"

addtask clean
python do_clean() {
    import subprocess as shell
    src_uri    = (d.getVar('SRC_URI', True) or "").split()
    pf         = d.getVar('PF', True)
    stampdir   = d.getVar('STAMPS_DIR', True)
    extractdir = d.getVar('EXTRACTDIR', True)
    # clean stamps
    stamps = os.listdir(stampdir)
    for stamp in stamps:
    	if pf in stamp:
    		os.remove(stampdir + '/' + stamp)
    
    # clean workdir
    if not os.path.isdir(extractdir):
        return
    
    for entry in os.listdir(extractdir):
    	if 'temp' not in entry:
    		abspath = extractdir + '/' + entry
    		shell.call(['sudo', 'rm', '-rf', abspath])
}
do_clean[nostamp] = "1"


EXPORT_FUNCTIONS do_clean do_mrproper do_build
