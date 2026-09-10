import io
p = r'C:\Users\QingJ\Desktop\root\work\qemu\init_sweep.c'
src = io.open(p, encoding='utf-8').read()

# consumer 在 armed 后延迟 10 秒再开始打点 (给 gdb 观察窗口)
old = """static int consumer_fn(void*a){
  (void)a;
  while(!armed) nsleep_us(1000);
  long i=0;
  for(;;){"""
new = """static int consumer_fn(void*a){
  (void)a;
  while(!armed) nsleep_us(1000);
  puts_("CONSUMER_GRACE_10S\\n");
  long ts[2]={10,0}; sys(SYS_nanosleep,(long)ts,0,0,0,0,0);
  long i=0;
  for(;;){"""
assert old in src
src = src.replace(old, new)

# waiter 打印自己的 pib 无法做到(用户态), 但可以打印一个特征值供 gdb 匹配:
# 在 sweep 第一轮前把 flat 特征值写进去 (已有 marker 模式天然自带)
io.open(p, 'w', encoding='utf-8').write(src)
print('consumer grace period added')
