import io
p = r'C:\Users\QingJ\Desktop\root\work\qemu\init_e2e_pd2238.c'
src = io.open(p, encoding='utf-8').read()

# 1) waiter 打印 tid
old1 = """static int waiter_fn(void*a){
  (void)a;
  waiter_tid = sys(SYS_gettid,0,0,0,0,0,0);
  sys(SYS_futex,(long)&f_pi_chain,FUTEX_LOCK_PI,0,0,0,0);"""
new1 = """static int waiter_fn(void*a){
  (void)a;
  waiter_tid = sys(SYS_gettid,0,0,0,0,0,0);
  puts_("WAITER_TID="); putx_((unsigned long)waiter_tid); puts_("\\n");
  sys(SYS_futex,(long)&f_pi_chain,FUTEX_LOCK_PI,0,0,0,0);"""
assert old1 in src, 'waiter pattern not found'
src = src.replace(old1, new1)

# 2) pselect 超时 5s -> 40s (给 gdb 观察时间)
old2 = """    long pts[2]={5,0};   /* ONE long pselect: the consumer fires many walks inside */"""
new2 = """    long pts[2]={40,0};  /* long pselect: gdb observation window */"""
assert old2 in src, 'pselect pattern not found'
src = src.replace(old2, new2)

io.open(p, 'w', encoding='utf-8').write(src)
print('patched: waiter_tid print + 40s pselect')
