"""批量扫描: 找内核栈上"用户数据缓冲区"落在 rt_waiter 深度 [0x2e0,0x330] 的 syscall.
方法: 对每个 __arm64_sys_* wrapper, 递归跟踪直接调用的下一个函数 (bl), 累计帧深.
在每一层, 记录所有 `add xN, sp, #imm` 把栈地址传给 copy_from_user 类函数的候选.
"""
import struct
from elftools.elf.elffile import ELFFile

ELF = r'C:\Users\QingJ\Desktop\root\work\boot_out\output.elf'
BASE = 0xffffffc008000000

with open(ELF, 'rb') as f:
    elf = ELFFile(f)
    symtab = elf.get_section_by_name('.symtab')
    syms = {}
    for s in symtab.iter_symbols():
        if s.name and s['st_value']:
            syms[s.name] = s['st_value']

    def read_va(va, n):
        for seg in elf.iter_segments():
            if seg['p_type'] != 'PT_LOAD': continue
            vs = seg['p_vaddr']
            if vs <= va < vs + seg['p_filesz'] and va+n <= vs + seg['p_filesz']:
                return seg.data()[(va-vs):(va-vs)+n]
        return None

    def decode_insn(va):
        d = read_va(va, 4)
        if not d: return None, None
        ins = struct.unpack_from('<I', d, 0)[0]
        return ins, va

    def get_frame(addr):
        """读函数序言: 先找 sub sp,sp,#imm (可能在前 8 条指令内)"""
        for off in range(0, 32, 4):
            ins = None
            d = read_va(addr+off, 4)
            if not d: break
            ins = struct.unpack_from('<I', d, 0)[0]
            if (ins >> 22) == 0x344:
                imm12 = (ins >> 10) & 0xFFF
                rd = ins & 0x1F; rn = (ins >> 5) & 0x1F
                if rd == 31 and rn == 31:
                    return imm12
        return None

    def scan_function(addr, depth_so_far, path, results, max_depth=5, visited=None):
        """扫描函数: 找 bl 调用 + add sp 传参给 copy_from_user"""
        if visited is None: visited = set()
        if addr in visited or depth_so_far > max_depth: return
        visited.add(addr)
        # 粗扫前 0x200 字节找 bl 指令 (函数可能很长, 但关键调用在前部)
        for off in range(0, 0x200, 4):
            d = read_va(addr+off, 4)
            if not d: break
            ins = struct.unpack_from('<I', d, 0)[0]
            if (ins >> 26) == 0x25:  # bl
                target = addr + off + ((ins & 0x3ffffff) << 2)
                if ins & 0x2000000: target -= 0x4000000
                # 找 bl 前面的 add xN, sp, #imm (参数准备)
                add_sp = None
                for back in range(4, 40, 4):
                    d2 = read_va(addr+off-back, 4)
                    if not d2: break
                    ins2 = struct.unpack_from('<I', d2, 0)[0]
                    if (ins2 >> 24) == 0x91:  # ADD imm
                        imm12 = (ins2 >> 10) & 0xFFF
                        rd = ins2 & 0x1F; rn = (ins2 >> 5) & 0x1F
                        if rn == 31:  # sp
                            add_sp = (rd, imm12)
                            break
                # 只记录调用了"用户数据相关"函数的
                tname = next((n for n, a in syms.items() if a == target), hex(target))
                # 记录所有调用, 附带可能的栈参数
                results.append((path, off, tname, add_sp, depth_so_far))
                # 递归 (只追一次, 避免爆炸)
                if tname.startswith('__arm64_sys_') or tname.startswith('do_') or tname.startswith('ksys_'):
                    f2 = get_frame(target)
                    if f2 is not None:
                        scan_function(target, depth_so_far + f2, path + '->' + tname.split('.')[0], results, max_depth, visited)

    # 只扫重点候选 (有用户数据拷贝语义的)
    targets = [
        'ppoll','poll','pselect6','select','sched_setaffinity','sched_getaffinity',
        'setxattr','fsetxattr','setrlimit','prlimit64','sigprocmask','rt_sigprocmask',
        'rt_sigtimedwait','sigaltstack','io_pgetevents','recvmmsg','sendmmsg',
        'getxattr','lgetxattr','fgetxattr','getrlimit','getgroups','setgroups',
        'listxattr','flistxattr','mincore','msync','madvise','mlock','membarrier',
        'name_to_handle_at','fanotify_mark','inotify_add_watch','keyctl','add_key',
        'request_key','quotactl','lookup_dcookie','ustat','statfs','fstatfs',
    ]
    results = []
    for t in targets:
        for n, a in syms.items():
            if n == f'__arm64_sys_{t}':
                fr = get_frame(a)
                if fr is not None:
                    results.append((n, a, fr, 'ROOT'))
                    scan_function(a, fr, n, results, max_depth=4)

    print(f"{'path':<100s} depth")
    seen = set()
    for r in results:
        if len(r) == 4:
            continue
        path, off, tname, add_sp, depth = r
        key = (path, off)
        if key in seen: continue
        seen.add(key)
        # 只打印有栈参数传给目标的
        if add_sp and depth and 0x250 <= depth <= 0x380:
            print(f"{path+'->'+tname:<100s} 0x{depth:03x} add_sp={add_sp}")
