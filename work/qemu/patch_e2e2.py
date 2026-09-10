import io
p = r'C:\Users\QingJ\Desktop\root\work\qemu\init_e2e_pd2238.c'
src = io.open(p, encoding='utf-8').read()

# 在 open_selected 后加 F_GETFD 验证 (fd 有效性复检)
old = """  sys(SYS_close,tfd,0,0,0,0,0);
  puts_("OPEN_SELECTED n="); putx_((unsigned long)n); puts_(" hi="); putx_((unsigned long)hi); puts_("\\n");
}"""
new = """  sys(SYS_close,tfd,0,0,0,0,0);
  puts_("OPEN_SELECTED n="); putx_((unsigned long)n); puts_(" hi="); putx_((unsigned long)hi); puts_("\\n");
  for(int fd=0;fd<320;fd++){
    int w=fd/64, b=fd%64;
    if(((inb[w]>>b)&1) || ((outb[w]>>b)&1) || ((exb[w]>>b)&1)){
      long r=sys(SYS_fcntl,fd,1,0,0,0,0); /* F_GETFD */
      if(r<0){ puts_("FD_INVALID fd="); putx_((unsigned long)fd); puts_(" r="); putx_((unsigned long)r); puts_("\\n"); }
    }
  }
  puts_("FD_VERIFY_DONE\\n");
}"""
assert old in src, 'pattern not found'
src = src.replace(old, new)
io.open(p, 'w', encoding='utf-8').write(src)
print('patched OK')
