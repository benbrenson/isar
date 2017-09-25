""" Implementation of a simple shell command runner wrapping
    the python subprocess module.
"""
import subprocess

class Command:
    """ Class representing a shell command, and possible actions on it."""

    def __init__(self, cmd=''):
        self.orig_cmd = cmd

    def set(self, cmd):
        self.orig_cmd = cmd

    def run(self, check=False, debug=False, shell=False):

        if isinstance(self.orig_cmd, list):
            _shell = False
            self.cmd = self.orig_cmd

        elif isinstance(self.orig_cmd, str) and shell == True:
            _shell=True
            self.cmd = self.orig_cmd

        elif isinstance(self.orig_cmd, str) and shell == False:
            _shell=False
            self.cmd = self.orig_cmd.split()


        process = subprocess.Popen(self.cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=_shell)
        self.stdout, self.stderr = process.communicate()
        self.stdout = self.stdout.decode().strip()
        self.stderr = self.stderr.decode().strip()
        self.errcode = process.returncode


        if debug == True:
            print('Running command: %s' % (self.orig_cmd))

        if self.errcode != 0:
            print(self.stderr)
            if check == True:
                raise Exception('Shell command failed with errorcode {0}! Command: {1}'.format(self.errcode, self.orig_cmd))
            self.output = self.stderr

        else:
            self.output = self.stdout

        if debug == True:
            print(self.output)
            print('Command returned %s' % (self.errcode))

        return self.errcode