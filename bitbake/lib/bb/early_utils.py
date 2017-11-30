"""
    This file is part of Isar.

    Copyright (C) 2017 Mixed Mode GmbH

    Additional utils required for bitbake.conf file.
    At the time when bitbake.conf is parsed, some inline python
    lines are needed.
    This file was created in order to hold the bitbake source code tree as clean
    as possible, in case of running updates later.
"""

def prune_suffix(var, suffixes, d):
    # See if var ends with any of the suffixes listed and
    # remove it if found
    for suffix in suffixes:
        if var.endswith(suffix):
            var = var.replace(suffix, '')
    return var


def convertSpaces(d, s, to=':'):
    """ Convert strings separated by spaces into other separators. """
    t = d.getVar(s, True)
    clean = t.strip()
    new = clean.split()
    for i in range(len(new)):
        new[i] = new[i].strip(to)
    new = to.join(new)
    return new