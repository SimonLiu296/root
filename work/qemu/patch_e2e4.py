import io
p = r'C:\Users\QingJ\Desktop\root\work\qemu\init_e2e_pd2238.c'
src = io.open(p, encoding='utf-8').read()

# 修复: hi=F_DUPFD 后立即 close(tfd), 再 dup3 循环 (避免 close(tfd) 误关 dup 后的 fd3)
old = """  long tfd = sys(SYS_timerfd_create,CLOCK_MONOTONIC,0,0,0,0,0);
  long hi  = sys(SYS_fcntl,tfd,0,352,0,0,0);      /* F_DUPFD above nfds */
  int n=0;
  for(int fd=0;fd<320;fd++){
    int w=fd/64, b=fd%64;
    if(((inb[w]>>b)&1) || ((outb[w]>>b)&1) || ((exb[w]>>b)&1)){
      long r=sys(SYS_dup3,hi,fd,0,0,0,0);
      if(r<0){ puts_("DUP3_FAIL fd="); putx_((unsigned long)fd); puts_(" r="); putx_((unsigned long)r); puts_("\\n"); }
      n++;
    }
  }
  sys(SYS_close,tfd,0,0,0,0,0);"""
new = """  long tfd = sys(SYS_timerfd_create,CLOCK_MONOTONIC,0,0,0,0,0);
  long hi  = sys(SYS_fcntl,tfd,0,352,0,0,0);      /* F_DUPFD above nfds */
  sys(SYS_close,tfd,0,0,0,0,0);                    /* close FIRST: tfd may equal a set fd */
  int n=0;
  for(int fd=0;fd<320;fd++){
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
print('patched: close-tfd-first')
