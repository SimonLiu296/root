import io
p = r'C:\Users\QingJ\Desktop\root\work\qemu\init_e2e_pd2238.c'
src = io.open(p, encoding='utf-8').read()

# consumer 加调用计数
old = """static int consumer_fn(void*a){
  (void)a;
  while(!armed) nsleep_us(1000);
  int i=0;
  while(armed){
    struct sched_attr at; char*p=(char*)&at; for(unsigned k=0;k<sizeof(at);k++)p[k]=0;
    at.size=sizeof(at);
    at.policy=(i&1)?SCHED_BATCH:SCHED_OTHER;   /* always reaches `change:` */
    at.nice=1;
    sys(SYS_sched_setattr,waiter_tid,(long)&at,0,0,0,0);
    i++;
    nsleep_us(20000);
  }
  puts_("CONSUMER CALLS="); putx_((unsigned long)i); puts_("\\n");
  for(;;) nsleep_us(200000);
}"""
new = """static int consumer_fn(void*a){
  (void)a;
  while(!armed) nsleep_us(1000);
  int i=0, ok=0;
  while(armed){
    struct sched_attr at; char*p=(char*)&at; for(unsigned k=0;k<sizeof(at);k++)p[k]=0;
    at.size=sizeof(at);
    at.policy=(i&1)?SCHED_BATCH:SCHED_OTHER;   /* always reaches `change:` */
    at.nice=1;
    long r=sys(SYS_sched_setattr,waiter_tid,(long)&at,0,0,0,0);
    if(r==0) ok++;
    i++;
    nsleep_us(20000);
    if(i>=100) break;
  }
  puts_("CONSUMER CALLS="); putx_((unsigned long)i); puts_(" ok="); putx_((unsigned long)ok); puts_("\\n");
  for(;;) nsleep_us(200000);
}"""
assert old in src, 'consumer pattern not found'
src = src.replace(old, new)
io.open(p, 'w', encoding='utf-8').write(src)
print('patched: consumer counter')
