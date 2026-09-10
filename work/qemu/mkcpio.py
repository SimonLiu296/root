import sys, os, struct
def align(n): return (n + 0xFF) & ~0xFF
out = bytearray()
def add(path, data, mode=0o100755):
    global out
    name = path.encode()
    hdr = b'070701'
    hdr += b'%08x' % 0
    hdr += b'%08x' % mode
    hdr += b'00000000' + b'00000000'
    hdr += b'%08x' % len(data)
    hdr += b'00000000' + b'00000000'
    hdr += b'00000000' + b'00000000'
    hdr += b'%08x' % len(name)
    hdr += b'00000000' + b'00000000'
    out += hdr + name + b'\x00'
    out += b'\x00' * (align(110 + len(name) + 1) - (110 + len(name) + 1))
    out += data
    out += b'\x00' * (align(len(data)) - len(data))
add('init', open(sys.argv[1],'rb').read())
out += b'TRAILER!!!' + b'\x00' * 87
sys.stdout.buffer.write(bytes(out))
