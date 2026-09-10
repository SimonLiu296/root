# verify_qemu.py — 通过 QEMU monitor 验证 PD2238 内核偏移 (免 gdb)
# 原理: nokaslr 下 内核镜像 VA→PA 线性映射:
#   phys = VA - KIMAGE_TEXT_BASE + P0_KERNEL_PHYS_LOAD (0x40000000)
# 用 monitor 的 xp (物理内存查看) 读 .data 区验证符号偏移
import socket, sys, time, re

KIMAGE_TEXT_BASE = 0xffffffc008000000
PHYS_LOAD        = 0x40000000
MON_HOST, MON_PORT = '127.0.0.1', 5555

def va2pa(va):
    return PHYS_LOAD + (va - KIMAGE_TEXT_BASE)

def xp(addr, fmt='gx', count=1):
    s = socket.create_connection((MON_HOST, MON_PORT), timeout=5)
    s.recv(4096)  # banner
    s.sendall(b'xp /%d%s 0x%x\n' % (count, fmt.encode(), addr))
    time.sleep(0.3)
    data = b''
    try:
        while True:
            chunk = s.recv(4096)
            if not chunk: break
            data += chunk
            if b'(qemu)' in chunk: break
    except socket.timeout:
        pass
    s.close()
    return data.decode('utf-8', 'replace')

def check(label, va, fmt, count, expect_note):
    pa = va2pa(va)
    out = xp(pa, fmt, count).strip()
    print(f"[{'OK' if out else '--'}] {label} (VA {va:#x} -> PA {pa:#x}): {out.splitlines()[-1] if out else 'NO DATA'}")
    return out

def main():
    print(f"KIMAGE_TEXT_BASE={KIMAGE_TEXT_BASE:#x} PHYS_LOAD={PHYS_LOAD:#x}")
    offs = {
        'init_task':      0x2aec240,
        'init_uts_ns':    0x2aebfe8,
        'empty_zero_page':0x2d2d000,
        'root_task_group':0x2d33100,
        'sysctl_bootid':  0x2ee910d,
        'kmalloc_caches': 0x25d7b70,
        'anon_pipe_buf_ops': 0x2440ba8,
        'security_hook_heads': 0x25d8038,
        'ashmem_fops':    0x2595010,
        'loggers':        0x2ae1618,
    }
    for name, off in offs.items():
        check(name, KIMAGE_TEXT_BASE + off, 'gx', 2, name)

    # task_struct 字段验证 (init_task 基址)
    it = KIMAGE_TEXT_BASE + 0x2aec240
    check('task.comm @0x790', it + 0x790, 's', 1, 'comm string')
    check('task.real_cred/cred @0x778', it + 0x778, 'gx', 2, 'cred ptrs')
    check('task.pid/tgid @0x5c8', it + 0x5c8, 'wx', 2, 'pid')
    check('task.pi_blocked_on @0x898', it + 0x898, 'gx', 1, 'pi_blocked')
    check('task.tasks @0x4c8', it + 0x4c8, 'gx', 2, 'tasks list')

    print("DONE")

if __name__ == '__main__':
    main()
