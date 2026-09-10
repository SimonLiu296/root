import io
p = r'C:\Users\QingJ\Desktop\root\work\qemu\init_sweep.c'
src = io.open(p, encoding='utf-8').read()

old = """    unsigned long v = 0;
    if(f==0 || f==3 || f==5) v = parent;
    else if(f==2 || f==7)    v = SYSCTL_BOOTID;
    else if(f==10)           v = INIT_TASK;
    else if(f==11)           v = lock;
    else if(f==12)           v = 3;
    else v = 0;"""
new = """    unsigned long v = 0;
    if(f==0)      v = parent;        /* tree.__rb_parent_color (写值) */
    else if(f==2) v = SYSCTL_BOOTID; /* tree.rb_left (rb_erase 写入目标) */
    else if(f==3) v = parent;        /* pi_tree.pc */
    else if(f==5) v = SYSCTL_BOOTID; /* pi_tree.left */
    else if(f==6) v = INIT_TASK;     /* waiter.task */
    else if(f==7) v = lock;          /* waiter.lock */
    else if(f==8) v = 3;             /* prio */
    else v = 0;"""

assert old in src, 'value-select block not found'
src = src.replace(old, new)
io.open(p, 'w', encoding='utf-8').write(src)
print('field mapping FIXED: w2/w5=bootid-target, w6=task, w7=lock, w8=prio')
