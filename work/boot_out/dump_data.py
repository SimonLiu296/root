import sys
from elftools.elf.elffile import ELFFile

def read_va(elf, va, n):
    for seg in elf.iter_segments():
        if seg['p_type'] != 'PT_LOAD': continue
        va_s, va_e = seg['p_vaddr'], seg['p_vaddr']+seg['p_filesz']
        if va_s <= va < va_e and va+n <= va_e:
            off = seg['p_offset'] + (va - va_s)
            return seg.data()[ (va-va_s) : (va-va_s)+n ]
    return None

with open(sys.argv[1],'rb') as f:
    elf = ELFFile(f)
    base = 0xffffffc008000000
    def dump(va, n, label):
        d = read_va(elf, va, n)
        if d is None:
            print(f"{label}: <unreadable>"); return
        qwords = [int.from_bytes(d[i:i+8],'little') for i in range(0, len(d)-7, 8)]
        print(f"{label} @ {va:#x}:")
        print('  qwords: ' + ', '.join(f'{q:#016x}' for q in qwords))
    dump(0xffffffc00ac851d8, 32, 'ashmem_misc (miscdevice)')
    dump(0xffffffc00ae1618, 64, 'loggers[]')
    dump(0xffffffc00a44c0e0, 64, 'configfs_bin_file_operations table')
