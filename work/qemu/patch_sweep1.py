import io, re

p = r'C:\Users\QingJ\Desktop\root\work\qemu\init_e2e_pd2238.c'
src = io.open(p, encoding='utf-8').read()

# 1) 加全局 round 控制变量
old = 'volatile int waiter_ready, owner_started, waiter_waiting, armed, done_;'
new = ('volatile int waiter_ready, owner_started, waiter_waiting, armed, done_;\n'
       'volatile int round_go;\n'
       'static void build_overlay_shift(int j);\n')
assert old in src
src = src.replace(old, new)

# 2) waiter 的 pselect 改为多轮循环 (由主线程逐轮驱动)
old2 = """  {
    long pts[2]={3,0};   /* short window per sweep round */
    long pr=sys(SYS_pselect6,320,(long)inb,(long)outb,(long)exb,(long)pts,0);
    puts_("PSELECT ret="); putx_((unsigned long)pr); puts_("\\n");
  }"""
new2 = """  for(int round=0; round<40; round++){
    while(!round_go) nsleep_us(1000);
    long pts[2]={3,0};
    long pr=sys(SYS_pselect6,320,(long)inb,(long)outb,(long)exb,(long)pts,0);
    puts_("PS r="); putx_((unsigned long)pr); puts_(" j="); putx_((unsigned long)(round)); puts_("\\n");
    round_go=0;
  }"""
assert old2 in src, 'pselect block not found'
src = src.replace(old2, new2)

io.open(p, 'w', encoding='utf-8').write(src)
print('part1 OK: waiter multi-round loop')
