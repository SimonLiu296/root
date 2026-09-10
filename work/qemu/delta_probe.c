/* 实测 DELTA: 同一线程先后做 futex-requeue(悬垂pib) 和 pselect,
 * gdb 冻结读 pib 值 + fdset 在栈上的位置. */
static long sys(long n,long a,long b,long c,long d,long e,long f){
  register long x8 __asm__("x8")=n; register long x0 __asm__("x0")=a;
  register long x1 __asm__("x1")=b; register long x2 __asm__("x2")=c;
  register long x3 __asm__("x3")=d; register long x4 __asm__("x4")=e;
  register long x5 __asm__("x5")=f;
  __asm__ volatile("svc #0":"+r"(x0):"r"(x8),"r"(x1),"r"(x2),"r"(x3),"r"(x4),"r"(x5):"memory");
  return x0;
}
#define SYS_write 64
#define SYS_nanosleep 101
#define SYS_pselect6 72
#define SYS_futex 98
#define SYS_clock_gettime 113
#define SYS_gettid 178
#define SYS_fcntl 25
#define SYS_dup3 24
#define SYS_timerfd_create 85
#define SYS_close 57
#define SYS_clone 220
#define FUTEX_LOCK_PI 6
#define FUTEX_WAIT_REQUEUE_PI 11
#define FUTEX_CMP_REQUEUE_PI 12
#define CLOCK_MONOTONIC 1
#define CLONE_FLAGS 0x50f00

static void puts_(const char*s){long n=0;while(s[n])n++;sys(SYS_write,1,(long)s,n,0,0,0);}
static void putx_(unsigned long v){
  char b[18]; b[0]='0'; b[1]='x';
  for(int i=0;i<16;i++){ int nib=(v>>((15-i)*4))&0xf; b[2+i]= nib<10?('0'+nib):('a'+nib-10); }
  sys(SYS_write,1,(long)b,18,0,0,0);
}
static void nsleep_us(long us){long ts[2]={us/1000000,(us%1000000)*1000};sys(SYS_nanosleep,(long)ts,0,0,0,0,0);}

__attribute__((naked)) static long thr_clone(long flags,void*stack,int(*fn)(void*),void*arg){
  __asm__ volatile(
    "mov x9, x2\n" "mov x10, x3\n"
    "mov x2, #0\n" "mov x3, #0\n" "mov x4, #0\n"
    "mov x8, #220\n" "svc #0\n"
    "cbnz x0, 1f\n"
    "mov x0, x10\n" "blr x9\n"
    "mov x8, #93\n" "svc #0\n"
    "1:\n" "ret\n");
}

volatile unsigned int f_wait, f_pi_target, f_pi_chain;
volatile int waiter_ready, owner_started, waiter_waiting;
static char wstack[65536] __attribute__((aligned(16)));
static char ostack[65536] __attribute__((aligned(16)));
static unsigned long inb[5], outb[5], exb[5];
static long g_waiter_tid;

static int waiter_fn(void*a){
  (void)a;
  g_waiter_tid = sys(SYS_gettid,0,0,0,0,0,0);
  puts_("WTID="); putx_((unsigned long)g_waiter_tid); puts_("\n");
  sys(SYS_futex,(long)&f_pi_chain,FUTEX_LOCK_PI,0,0,0,0);
  waiter_ready=1;
  while(!owner_started) nsleep_us(1000);
  long to[2]; sys(SYS_clock_gettime,CLOCK_MONOTONIC,(long)to,0,0,0,0);
  to[0]+=3;
  waiter_waiting=1;
  sys(SYS_futex,(long)&f_wait,FUTEX_WAIT_REQUEUE_PI,0,(long)to,(long)&f_pi_target,0);
  puts_("W_REQUEUE_RET\n");
  /* 悬垂 pib 已建立. 进入超长 pselect (用特征值填充 fdset) */
  long tfd = sys(SYS_timerfd_create,CLOCK_MONOTONIC,0,0,0,0,0);
  long hi  = sys(SYS_fcntl,tfd,0,352,0,0,0);
  sys(SYS_close,tfd,0,0,0,0,0);
  for(int k=0;k<5;k++){ inb[k]=0; outb[k]=0; exb[k]=0; }
  /* 特征值: 0x5555000000000000+i*8 标记 fdset 各 word */
  for(int k=0;k<5;k++){
    inb[k] = 0x5555000000000000UL + (unsigned long)(k*8);
    outb[k]= 0x5555000000000000UL + (unsigned long)((5+k)*8);
    exb[k] = 0x5555000000000000UL + (unsigned long)((10+k)*8);
  }
  for(int fd=0;fd<320;fd++){
    int w=fd/64, b=fd%64;
    if(((inb[w]>>b)&1) || ((outb[w]>>b)&1) || ((exb[w]>>b)&1)){
      sys(SYS_dup3,hi,fd,0,0,0,0);
    }
  }
  puts_("ENTERING_LONG_PSELECT\n");
  long pts[2]={300,0};  /* 5 分钟窗口 */
  sys(SYS_pselect6,320,(long)inb,(long)outb,(long)exb,(long)pts,0);
  puts_("PSELECT_RET\n");
  for(;;) nsleep_us(500000);
}
static int owner_fn(void*a){
  (void)a;
  sys(SYS_futex,(long)&f_pi_target,FUTEX_LOCK_PI,0,0,0,0);
  while(!waiter_ready) nsleep_us(1000);
  owner_started=1;
  sys(SYS_futex,(long)&f_pi_chain,FUTEX_LOCK_PI,0,0,0,0);
  for(;;) nsleep_us(500000);
}
void _start(void){
  puts_("\n=== DELTA-PROBE ===\n");
  thr_clone(CLONE_FLAGS,ostack+sizeof(ostack),owner_fn,0);
  thr_clone(CLONE_FLAGS,wstack+sizeof(wstack),waiter_fn,0);
  while(!waiter_waiting || !owner_started) nsleep_us(1000);
  nsleep_us(100000);
  /* BLOCKED mode: 不 requeue, waiter 永久阻塞在 WAIT_REQUEUE_PI */
  for(;;) nsleep_us(500000);
}
