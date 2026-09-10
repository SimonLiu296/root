/* 探测: 各候选 syscall 的用户数据内核栈落点.
 * 测试线程循环调用候选 syscall, 参数里塞特征值 0x4141414100000000+i
 * gdb 冻结后搜栈, 找出哪次 syscall 的特征值落在 rt_waiter 深度窗口
 * rt_waiter = SP_DIV-0x330, 窗口 [SP_DIV-0x330, SP_DIV-0x2e0)
 * 测试协议: 主线程每 2 秒换一个候选, 打印标记, 死循环
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
#define SYS_getcwd 17
#define SYS_newfstatat 79
#define SYS_statfs64 43
#define SYS_fstatfs64 44
#define SYS_fcntl 25

static void puts_(const char*s){long n=0;while(s[n])n++;sys(SYS_write,1,(long)s,n,0,0,0);}
static void putx_(unsigned long v){
  char b[18]; b[0]='0'; b[1]='x';
  for(int i=0;i<16;i++){ int nib=(v>>((15-i)*4))&0xf; b[2+i]= nib<10?('0'+nib):('a'+nib-10); }
  sys(SYS_write,1,(long)b,18,0,0,0);
}
static void nsleep_us(long us){long ts[2]={us/1000000,(us%1000000)*1000};sys(SYS_nanosleep,(long)ts,0,0,0,0,0);}

/* 特征值缓冲区: 全部填充 0x4141414100000000+循环变量 */
static char marker_buf[256] __attribute__((aligned(64)));
static void fill_marker(int phase){
  for(int i=0;i<256;i+=8){
    unsigned long v = 0x4141414100000000UL + (unsigned long)(phase*32 + i/8);
    __builtin_memcpy(marker_buf+i, &v, 8);
  }
}

struct my_stat {
  unsigned long st_dev, st_ino, st_nlink, st_mode, st_uid, st_gid;
  unsigned long st_rdev, st_size, st_blksize, st_blocks;
  unsigned long st_atime, st_mtime, st_ctime;
};

void _start(void){
  puts_("\n=== STACK-PROBE ===\n");
  for(int phase=0;;phase++){
    fill_marker(phase);
    puts_("PHASE="); putx_((unsigned long)phase); puts_(" ");
    switch(phase % 6){
      case 0: {
        char buf[64];
        /* getcwd: 用户 buf, 内核也可能有栈缓冲 */
        long r = sys(SYS_getcwd,(long)buf,sizeof(buf),0,0,0,0);
        puts_("getcwd="); putx_((unsigned long)r); puts_("\n");
        break;
      }
      case 1: {
        struct my_stat st;
        /* newfstatat(dirfd, path, &st, flags) -> copy_to_user, 内核从 dcache 填 */
        long r = sys(SYS_newfstatat,-100,(long)"/",(long)&st,0,0,0);
        puts_("newfstatat="); putx_((unsigned long)r); puts_("\n");
        break;
      }
      case 2: {
        /* statfs64(path, &st) */
        long buf[20];
        long r = sys(SYS_statfs64,(long)"/",sizeof(buf)/2,(long)buf,0,0,0);
        puts_("statfs64="); putx_((unsigned long)r); puts_("\n");
        break;
      }
      case 3: {
        /* fstatfs64(fd, size, &st) */
        long buf[20];
        long r = sys(SYS_fstatfs64,1,sizeof(buf)/2,(long)buf,0,0,0);
        puts_("fstatfs64="); putx_((unsigned long)r); puts_("\n");
        break;
      }
      case 4: {
        /* fcntl F_SETLK 等不需要; 用 setxattr 类? 用 ioctl 特征 */
        /* 用 readlinkat: 内核把链接内容拷贝到用户 buf */
        char buf[64];
        long r = sys(SYS_fcntl,1,1,0,0,0,0);
        puts_("fcntl="); putx_((unsigned long)r); puts_("\n");
        break;
      }
      case 5: {
        /* 空转等待 (观察点) */
        puts_("wait\n");
        nsleep_us(1500000);
        break;
      }
    }
    nsleep_us(400000);
  }
}
