# verify_vaddr.py — 通过 QEMU monitor 虚拟地址读取验证 PD2238 内核偏移 (权威)
import socket, time

BASE = 0xffffffc008000000
MON_HOST, MON_PORT = '127.0.0.1', 5555

def mon(cmd):
    s = socket.create_connection((MON_HOST, MON_PORT), timeout=5)
    time.sleep(0.2)
    s.recv(8192)
    s.sendall((cmd+'\n').encode())
    time.sleep(0.5)
    data=b''
    try:
        while True:
            c=s.recv(8192)
            if not c: break
            data+=c
            if b'(qemu)' in c: break
    except: pass
    s.close()
    return data.decode('utf-8','replace')

def clean(out):
    for l in out.splitlines():
        l=l.strip()
        if l and 'qemu' not in l and '[K' not in l and not l.startswith('x'):
            return l
    return '?'

def main():
    print(f"KIMAGE_TEXT_BASE={BASE:#x}  (QEMU 虚拟地址验证)")
    tests = [
        ('init_task',         0x2aec240, 'gx', 2, 'usage+lock'),
        ('task.comm@0x790',   0x2aec240+0x790, 'bx', 12, 'swapper/0'),
        ('task.real_cred@0x778',0x2aec240+0x778, 'gx', 2, 'init_cred ptr'),
        ('task.pid/tgid@0x5c8',0x2aec240+0x5c8, 'wx', 2, '0/0'),
        ('init_uts_ns',       0x2aebfe8, 'bx', 12, 'Linux'),
        ('sysctl_bootid',     0x2ee910d, 'bx', 16, 'uuid'),
        ('root_task_group',   0x2d33100, 'gx', 2, 'ptr'),
        ('kmalloc_caches',    0x25d7b70, 'gx', 2, 'ptr'),
        ('security_hook_heads',0x25d8038, 'gx', 2, 'ptr'),
        ('anon_pipe_buf_ops', 0x2440ba8, 'gx', 2, 'ptr'),
        ('loggers',           0x2ae1618, 'gx', 2, 'ptr'),
        ('ashmem_fops',       0x2595010, 'gx', 2, 'fops'),
        ('empty_zero_page',   0x2d2d000, 'gx', 1, 'zeros'),
    ]
    for name, off, fmt, cnt, note in tests:
        out = clean(mon('x /%d%s 0x%x' % (cnt, fmt, BASE+off)))
        print(f"  {name:26s} {out}")
    print("DONE — 全部偏移应为有效数据 (非 0xcccccccc 毒化)")

if __name__ == '__main__':
    main()
