import io
p = r'C:\Users\QingJ\Desktop\root\work\qemu\init_e2e_pd2238.c'
src = io.open(p, encoding='utf-8').read()

# 1) g_log 固定为 1 (简单可靠)
old1 = """static volatile long g_log = 1;   /* high-fd console dup: fds 0..2 get claimed below */"""
new1 = """static volatile long g_log = 1;   /* console on fd1: keep it simple */"""
assert old1 in src
src = src.replace(old1, new1)

old2 = """  /* grow the fdtable so core_sys_select does not clamp n to max_fds */
  sys(SYS_fcntl,1,0,352);

  { long l=sys(SYS_fcntl,1,0,400,0,0,0); if(l>0) g_log=l; }   /* console -> high fd */
  build_overlay();"""
new2 = """  /* grow the fdtable so core_sys_select does not clamp n to max_fds */
  sys(SYS_fcntl,1,0,352);
  g_log = 1;
  build_overlay();"""
assert old2 in src
src = src.replace(old2, new2)

io.open(p, 'w', encoding='utf-8').write(src)
print('patched: g_log fixed to fd1')
