from elftools.elf.elffile import ELFFile

ELF = r'C:\Users\QingJ\Desktop\root\work\boot_out\output.elf'
with open(ELF, 'rb') as f:
    elf = ELFFile(f)
    for s in elf.iter_sections():
        if s['sh_type'] in ('SHT_PROGBITS', 'SHT_NOBITS') and s['sh_size'] > 0x100000:
            print('%-24s size=0x%-9x addr=0x%-16x flags=%s' % (
                s.name, s['sh_size'], s['sh_addr'], s['sh_flags']))
    print('--- segments ---')
    for seg in elf.iter_segments():
        print('p_type=%s vaddr=0x%x filesz=0x%x memsz=0x%x off=0x%x' % (
            seg['p_type'], seg['p_vaddr'], seg['p_filesz'], seg['p_memsz'], seg['p_offset']))
