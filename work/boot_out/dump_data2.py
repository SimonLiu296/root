import sys
from elftools.elf.elffile import ELFFile

def read_va(elf, va, n):
    for seg in elf.iter_segments():
        if seg['p_type'] != 'PT_LOAD': continue
        va_s = seg['p_vaddr']
        if va_s <= va < va_s+seg['p_filesz'] and va+n <= va_s+seg['p_filesz']:
            return seg.data()[(va-va_s):(va-va_s)+n]
    return None

with open(sys.argv[1],'rb') as f:
    elf = ELFFile(f)
    def dump(va, n, label):
        d = read_va(elf, va, n)
        if d is None:
            print(f"{label} @ {va:#x}: <unreadable>"); return
        qwords = [int.from_bytes(d[i:i+8],'little') for i in range(0, len(d)-7, 8)]
        print(f"{label} @ {va:#x}:")
        print('  ' + ', '.join(f'{q:#016x}' for q in qwords))
    dump(0xffffffc00aae1618, 80, 'loggers[] (nf_log loggers array)')
