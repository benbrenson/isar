import hashlib

def calcHash(file, blocksize=4096, size=-1):
    hasher = hashlib.sha1()
    with open(file, 'rb') as calcfile:
        offset = 0
        rest = size
        nxt = blocksize

        while True:
            if size > 0:
                if rest >= blocksize:
                    rest -= blocksize
                    nxt = blocksize
                else:
                    nxt = rest
                    rest = 0

            buf = calcfile.read(nxt)
            offset += len(buf)

            if len(buf) == 0:
                break

            hasher.update(buf)

    return hasher.hexdigest()

def getHasher():
    return hashlib.sha1()