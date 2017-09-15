""" Implementation of a simple shell command runner wrapping
    the python subprocess module.
"""
import subprocess

class Command:
    """ Class representing a shell command, and possible actions on it."""

    def __init__(self, cmd):
        self.orig_cmd = cmd

        if isinstance(cmd, list):
            self.cmd = cmd
        else:
            self.cmd = cmd.split()


    def set(self, cmd):
        self.orig_cmd = cmd

        if isinstance(cmd, list):
            self.cmd = cmd
        else:
            self.cmd = cmd.split()

    def run(self, check=False, debug=False):
        process = subprocess.Popen(self.cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        self.stdout, self.stderr = process.communicate()
        self.stdout = self.stdout.decode().strip()
        self.stderr = self.stderr.decode().strip()
        self.errcode = process.returncode


        if debug == True:
            print('Running command: %s' % (self.orig_cmd))

        if self.errcode != 0:
            print(self.stderr)
            print(self.stdout)

            if check == True:
                raise Exception('Shell command failed with errorcode {0}! Command: {1}'.format(self.errcode, self.orig_cmd))
            self.output = self.stderr

        else:
            self.output = self.stdout

        if debug == True:
            print('Command returned %s' % (self.errcode))

        return self.errcode