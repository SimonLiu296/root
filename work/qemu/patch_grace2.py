import io
p = r'C:\Users\QingJ\Desktop\root\work\qemu\init_sweep.c'
src = io.open(p, encoding='utf-8').read()

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
assert old in src, 'consumer_fn not found'
src = src.replace(old, new)
io.open(p, 'w', encoding='utf-8').write(src)

# 验证
src2 = io.open(p, encoding='utf-8').read()
assert 'CONSUMER_GRACE_10S' in src2
print('grace re-applied and verified')
