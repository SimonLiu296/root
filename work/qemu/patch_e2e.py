import io
p = r'C:\Users\QingJ\Desktop\root\work\qemu\init_e2e_pd2238.c'
src = io.open(p, encoding='utf-8').read()
old = """  for(int fd=0;fd<320;fd++){
    int w=fd/64, b=fd%64;
    if(((inb[w]>>b)&1) || ((outb[w]>>b)&1) || ((exb[w]>>b)&1)){
      sys(SYS_dup3,hi,fd,0,0,0,0);
      n++;
    }
  }"""
new = """  for(int fd=0;fd<320;fd++){
    int w=fd/64, b=fd%64;
    if(((inb[w]>>b)&1) || ((outb[w]>>b)&1) || ((exb[w]>>b)&1)){
      long r=sys(SYS_dup3,hi,fd,0,0,0,0);
      if(r<0){ puts_("DUP3_FAIL fd="); putx_((unsigned long)fd); puts_(" r="); putx_((unsigned long)r); puts_("\\n"); }
      n++;
    }
  }"""
assert old in src, 'pattern not found'
src = src.replace(old, new)
io.open(p, 'w', encoding='utf-8').write(src)
print('patched OK')
