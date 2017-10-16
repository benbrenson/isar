import os
import re
import fileinput


def fixVarInFile(var, value, file):

    pre = re.compile('^%s=' % var)
    if 'pc.in' in file or '.pc'   in file:
        bb.note('Try to fix values in pkgconfig file: %s' % file)

        for line in fileinput.input(file, inplace=True):
            if pre.search(line):
                a = '%s=%s' % (var, value)
                print(a)
            else:
                print(line.strip())


def fixVar(var, value, location, d):

    cdir = os.getcwd()

    if os.path.isfile(location):
        fixVarInFile(var, value, location)
        return

    elif location.endswith('*'):
        dir = os.path.dirname(location)
        os.chdir(dir)
        for file in os.listdir():
            fixVarInFile(var, value, file)

        os.chdir(cdir)

    elif os.path.isdir(location):
        os.chdir(location)
        for file in os.listdir():
            fixVarInFile(var, value, file)

        os.chdir(cdir)