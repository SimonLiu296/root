/* 最小 pselect 隔离实验: 不跑 futex 竞态, 只验证 fd_set 布局 + pselect */
static long sys(long n,long a,long b,long c,long d,long e,long f){
  register long x8 __asm__("x8")=n; register long x0 __asm__("x0")=a;
  register long x1 __asm__("x1")=b; register long x2 __asm__("x2")=c;
  register long x3 __asm__("x3")=d; register long x4 __asm__("x4")=e;
  register long x5 __asm__("x5")=f;
  __asm__ volatile("svc #0":"+r"(x0):"r"(x8),"r"(x1),"r"(x2),"r"(x3),"r"(x4),"r"(x5):"memory");
  return x0;
}
#define SYS_write 64
#define SYS_pselect6 72
#define SYS_fcntl 25
#define SYS_dup3 24
#define SYS_timerfd_create 85
#define SYS_close 57
#define SYS_nanosleep 101

static void puts_(const char*s){long n=0;while(s[n])n++;sys(SYS_write,1,(long)s,n,0,0,0);}
static void putx_(unsigned long v){
  char b[18]; b[0]='0'; b[1]='x';
  for(int i=0;i<16;i++){ int nib=(v>>((15-i)*4))&0xf; b[2+i]= nib<10?('0'+nib):('a'+nib-10); }
  sys(SYS_write,1,(long)b,18,0,0,0);
}

static unsigned long inb[16], outb[16], exb[16];

void _start(void){
  puts_("\n=== PSELECT-TEST: start ===\n");
  /* 只置位 fd 13 (in set), 其余全零 */
  for(int k=0;k<16;k++){ inb[k]=0; outb[k]=0; exb[k]=0; }
  inb[0] = 1UL << 13;   /* fd 13 */

  /* 开 fd 13 为 timerfd */
  long tfd = sys(SYS_timerfd_create,0,0,0,0,0,0);
  puts_("timerfd="); putx_((unsigned long)tfd); puts_("\n");
  long r = sys(SYS_dup3,tfd,13,0,0,0,0);
  puts_("dup3(13)="); putx_((unsigned long)r); puts_("\n");
  /* 验证 fd13 有效 */
  long chk = sys(SYS_fcntl,13,1,0,0,0,0);
  puts_("fcntl(13,F_GETFD)="); putx_((unsigned long)chk); puts_("\n");
  /* pselect 只等 in[fd13] */
  long pts[2]={3,0};
  long pr = sys(SYS_pselect6,64,(long)inb,(long)outb,(long)exb,(long)pts,0);
  puts_("pselect(64, in={13})="); putx_((unsigned long)pr); puts_("\n");
  puts_("=== PSELECT-TEST: done ===\n");
  for(;;){ long ts[2]={10,0}; sys(SYS_nanosleep,(long)ts,0,0,0,0,0); }
}
