"""
    This file is part of Isar.

    Copyright (C) 2017 Mixed Mode GmbH

    Additional utils required for bitbake.conf file.
    At the time when bitbake.conf is parsed, some inline python
    lines are needed.
    This file was created in order to hold the bitbake source code tree as clean
    as possible, in case of running updates later.
    Only the codeparser.py module needs an import for bb.early_utils.
"""
import os
import re

class SkipException(Exception):
    def __init__(self, message=None):
        self.message = message

def prune_suffix(var, suffixes, d):
    # See if var ends with any of the suffixes listed and
    # remove it if found
    if not var or not suffixes:
        return var

    for suffix in suffixes:
        if var.endswith(suffix):
            var = var.replace(suffix, '')
    return var

def prune_suffixes(var, suffixes, skip, d):
    # Does the same as prune_suffix(), but for DEPENDS like strings.
    # Replaces suffixes for each item in the string.
    if not var or not suffixes:
        return var

    t = var.split()
    su = suffixes.split()

    for suffix in su:
        try:
            for i in range(len(t)):
                for s in skip:
                    if t[i].startswith(s):
                        raise SkipException()

                if t[i].endswith(suffix):
                    t[i] = t[i].replace(suffix,'')
        except SkipException():
            pass
    return ' '.join(t)


def append_suffix(var, suffix, d):
    # Add a suffix to a variable.
    if not var or not suffix:
        return var

    if var.endswith(suffix):
        return var
    return var + suffix


def append_suffixes(var, suffix, skip, d):
    # Does the same as append_suffix(), but for DEPENDS like strings.
    # Appends suffixes for each item in the string.
    if not var or not suffix:
        return var

    t = var.split()
    skip = skip.split()

    for i in range(len(t)):
        try:
            for s in skip:
                if t[i].startswith(s):
                    raise SkipException()

            t[i] = append_suffix(t[i], suffix, d)
        except SkipException:
            pass
    return ' '.join(t)


def convertSpaces(d, s, to=':'):
    """ Convert strings separated by spaces into other separators. """
    t = d.getVar(s, True)
    clean = t.strip()
    new = clean.split()
    for i in range(len(new)):
        new[i] = new[i].strip(to)
    new = to.join(new)
    return new


def deb_hostarch():
    posix_arch = os.uname()[4]

    if re.match(r"x86[_-]64|i\d86[_-]64$", posix_arch):
        return "amd64"
    elif re.match(r"i\d86$", posix_arch):
        return "i386"
    elif re.match(r"armv", posix_arch):
        return "armhf"

def topdir_name(d):
  topdir = d.getVar('TOPDIR', True)
  name = os.path.basename(topdir)
  return name
