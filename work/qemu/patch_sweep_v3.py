import io
p = r'C:\Users\QingJ\Desktop\root\work\qemu\init_sweep.c'
src = io.open(p, encoding='utf-8').read()

old = r'''static unsigned long flat[30];   /* 连续 30-word 视图: in(5)+out(5)+ex(5) x2 页 */
static void build_overlay_shift(int s){
  unsigned long parent = SCRATCH + 0x108;
  unsigned long lock   = SCRATCH;
  for(int k=0;k<WPS;k++){ inb[k]=0; outb[k]=0; exb[k]=0; }
  for(int k=0;k<30;k++){ flat[k]=0; }
  /* 5.10 flat waiter 形状, 起始全局 word = j:
     w[j+0] tree.pc=parent  w[j+2] tree.left=&bootid(rb_erase 写这)
     w[j+5] pi.pc=parent    w[j+7] pi.left=&bootid
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
}'''

new = r'''static unsigned long flat[15];   /* 连续视图: in(5)+out(5)+ex(5) = 15 words */
static void build_overlay_shift(int s){
  unsigned long parent = SCRATCH + 0x108;
  unsigned long lock   = SCRATCH;
  for(int k=0;k<WPS;k++){ inb[k]=0; outb[k]=0; exb[k]=0; }
  for(int k=0;k<15;k++){ flat[k]=0; }
  /* 5.10 flat waiter 精确布局 (aristotle e2e 原版):
     w0 tree.pc=parent(写值)  w1 tree.right=0
     w2 tree.left=&bootid     <- rb_erase 把 w0 的值写到 w2 指向处
     w3 pi.pc=parent          w4 pi.right=0
     w5 pi.left=&bootid
     w6 task=INIT_TASK        w7 lock=SCRATCH
     w8 prio=3                其余 0 */
  flat[s+0]=parent;
  flat[s+1]=0;
  flat[s+2]=SYSCTL_BOOTID;
  flat[s+3]=parent;
  flat[s+4]=0;
  flat[s+5]=SYSCTL_BOOTID;
  flat[s+6]=INIT_TASK;
  flat[s+7]=lock;
  flat[s+8]=3;
  /* 拆到三组 (每组 5 words, nfds=320) */
  for(int k=0;k<5;k++){
    inb[k]=flat[k];
    outb[k]=flat[5+k];
    exb[k]=flat[10+k];
  }
}'''

assert old in src, 'build_overlay_shift not found'
src = src.replace(old, new)
io.open(p, 'w', encoding='utf-8').write(src)
print('overlay layout FIXED to exact aristotle shape')
