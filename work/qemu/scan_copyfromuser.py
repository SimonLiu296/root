#!/usr/bin/env python3
"""scan_copyfromuser.py
系统性枚举 PD2238 (5.10.246, aarch64) 内核中所有 `bl _copy_from_user[.NNNN]`
调用点, 判断 x0 是否指向内核栈 (`add xN, sp, #imm`), 计算完整 syscall 调用链
深度 (从 __arm64_sys_* wrapper 入口 SP 算起), 筛选深度落在 [0x2e0,0x380] 的候选.

深度模型: depth = sum(各层函数帧大小) - 缓冲在目标函数帧内偏移
校准锚点(已验证): sched_setaffinity cpumask=0x40, select fdset=0x1f0,
pselect6 fdset=0x210, futex rt_waiter=0x330.

用法: python scan_copyfromuser.py [--json out.json] [--anchor] [--limit N]
"""
import struct
import sys
import json
import bisect
from elftools.elf.elffile import ELFFile

ELF = r'C:\Users\QingJ\Desktop\root\work\boot_out\output.elf'
KERNEL_VA = 0xffffffc008000000
KERNEL_SEC = '.kernel'

WINDOW_LO = 0x2e0
WINDOW_HI = 0x380
MIN_SIZE = 80

# ---------------- 指令解码 ----------------

def is_bl(ins):
    return (ins >> 26) == 0x25

def bl_target(va, ins):
    off = (ins & 0x3ffffff) << 2
    if ins & 0x2000000:
        off -= 0x10000000
    return (va + off) & 0xffffffffffffffff

def is_sub_sp(ins):
    return (ins >> 22) == 0x344 and (ins & 0x3ff) == 0x3ff

def sub_sp_imm(ins):
    return (ins >> 10) & 0xfff

def is_add_sp(ins):
    return (ins >> 24) == 0x91 and ((ins >> 5) & 0x1f) == 31

def add_sp_rd(ins):
    return ins & 0x1f

def add_sp_imm(ins):
    return (ins >> 10) & 0xfff

def is_movz(ins):
    return (ins >> 23) in (0x1a5, 0xa5)

def is_movk(ins):
    return (ins >> 23) in (0x1e5, 0xe5)

def movz_value(ins):
    imm16 = (ins >> 5) & 0xffff
    shift = (ins >> 21) & 0x3
    return imm16 << (shift * 16)

def is_orr_imm(ins):
    return (ins >> 23) in (0x164, 0x32)

def decode_bitmask(immN, imms, immr, M):
    def ones(n):
        return (1 << n) - 1
    if immN != 0:
        esize = M
        length = M.bit_length() - 1
    else:
        inv = (~imms) & 0x3f
        if inv == 0:
            length = M.bit_length() - 1
        else:
            length = inv.bit_length()
        if length > 6:
            length = 6
        esize = 1 << length
    levels = ones(length) if length else 0
    S = imms & levels
    R = immr & levels
    if S >= esize:
        S = esize - 1
    wmask = ones(S + 1) & ones(esize)
    wmask = ((wmask >> R) | (wmask << (esize - R))) & ones(esize)
    out = 0
    m = wmask
    for _ in range(M // esize):
        out |= m
        m <<= esize
    return out & ones(M)

def orr_imm_value(ins):
    N = (ins >> 22) & 1
    imms = (ins >> 10) & 0x3f
    immr = (ins >> 16) & 0x3f
    return decode_bitmask(N, imms, immr, 64 if (ins >> 31) else 32)

def mov_reg_info(ins):
    """mov xD, xM: ORR D, ZR, M (或 ORR D, M, ZR). 返回 (rd, src) 或 None."""
    if (ins >> 24) in (0xaa, 0x2a) and (ins >> 22) & 0x3 == 0 and ((ins >> 10) & 0x3f) == 0:
        rn = (ins >> 5) & 0x1f
        rm = (ins >> 16) & 0x1f
        if rn == 31 and rm == 31:
            return (ins & 0x1f, 'zr')
        if rn == 31:
            return (ins & 0x1f, rm)
        if rm == 31:
            return (ins & 0x1f, rn)
    return None

def insn_writes_rd(ins):
    """返回指令定义的 GPR rd (0-30), 无定义返回 None."""
    t6 = ins >> 26
    if t6 in (0x05, 0x25, 0x54, 0x34, 0x35, 0x36, 0x37):  # b/bl/b.cond/cbz/cbnz/tbz/tbnz
        return None
    if t6 == 0xd6 and (ins & 0x3ff) == 0:  # blr/br/ret
        return None
    if (ins >> 24) == 0xd5:                # system (mrs/msr/sys/svc/hint/pac)
        if (ins >> 20) == 0xd53:           # MRS
            return ins & 0x1f
        return None
    if (ins >> 24) in (0x90, 0x10):        # adrp/adr
        return ins & 0x1f
    if (ins >> 25) in (0x18, 0x38):        # SIMD ld/st (Q bit)
        return None
    b = ins >> 24
    if b in (0x39, 0x79, 0xb9, 0xf9):      # ldr/str uns-offset: opc bit20=1 load
        if (ins >> 20) & 1:
            return ins & 0x1f
        return None
    if b in (0x38, 0x78, 0xb8, 0xf8):      # ldur/stur: bit21=1 load
        if (ins >> 21) & 1:
            return ins & 0x1f
        return None
    if b in (0xa9, 0x29):                  # GPR ldp/stp: bit22=1 load
        if (ins >> 22) & 1:
            return ins & 0x1f
        return None
    if b in (0x2d, 0x6d, 0xad, 0xed, 0x3d, 0x7d, 0xbd, 0xfd):  # SIMD/FP ldp/stp, ldr/str
        return None
    return ins & 0x1f                      # 默认: 写 rd (保守)


class ElfReader:
    def __init__(self, path):
        self.f = open(path, 'rb')
        self.elf = ELFFile(self.f)
        sec = self.elf.get_section_by_name(KERNEL_SEC)
        self.code = sec.data()
        self.code_base = sec['sh_addr']

    def read_insn(self, va):
        off = va - self.code_base
        if off < 0 or off + 4 > len(self.code):
            return None
        return struct.unpack_from('<I', self.code, off)[0]


def load_funcs(elf):
    symtab = elf.get_section_by_name('.symtab')
    funcs = {}
    for s in symtab.iter_symbols():
        if s['st_info']['type'] != 'STT_FUNC':
            continue
        va = s['st_value']
        if not va or s['st_shndx'] == 'SHN_UNDEF':
            continue
        funcs.setdefault(va, []).append(s.name)
    return funcs


def best_name(names):
    for n in names:
        if not n.endswith('.cfi_jt'):
            return n
    return names[0]


def main():
    args = sys.argv[1:]
    dump_json = None
    if '--json' in args:
        dump_json = args[args.index('--json') + 1]
    only_anchor = '--anchor' in args
    limit = None
    if '--limit' in args:
        limit = int(args[args.index('--limit') + 1])

    r = ElfReader(ELF)
    func_va_names = load_funcs(r.elf)
    starts = sorted(func_va_names.keys())
    name_of = {va: best_name(func_va_names[va]) for va in starts}
    start_set = set(starts)

    def enclosing(va):
        i = bisect.bisect_right(starts, va) - 1
        return starts[i] if i >= 0 else None

    def next_start(f):
        i = bisect.bisect_right(starts, f)
        return starts[i] if i < len(starts) else f + 0x10000

    cfu_set = set()
    for va in starts:
        n = name_of[va]
        if n == '_copy_from_user' or (n.startswith('_copy_from_user.') and not n.endswith('.cfi_jt')) \
           or n == '__arch_copy_from_user':
            cfu_set.add(va)
    print('[+] copy_from_user symbols:', len(cfu_set))

    # ---- sweep: bl 调用图 + sub sp ----
    bl_sites = []
    subs = {}
    code = r.code
    base = r.code_base
    n_insns = len(code) // 4
    for i in range(n_insns):
        ins = struct.unpack_from('<I', code, i * 4)[0]
        va = base + i * 4
        if ins >> 26 == 0x25:
            tgt = bl_target(va, ins)
            if tgt in start_set:
                bl_sites.append((va, tgt))
        elif ins >> 22 == 0x344 and ins & 0x3ff == 0x3ff:
            f = enclosing(va)
            if f is not None:
                subs.setdefault(f, []).append((va, sub_sp_imm(ins)))
    print('[+] sweep done: %d bl sites, funcs with subs: %d' % (len(bl_sites), len(subs)))

    frame_of = {}
    late_sub = {}
    bl_sites_by_addr = sorted(bl_sites, key=lambda x: x[0])
    bl_addr = [s for s, t in bl_sites_by_addr]
    all_frames = set(subs.keys()) | set(starts)
    for f in all_frames:
        total = sum(im for va, im in subs.get(f, []))
        lo = bisect.bisect_left(bl_addr, f)
        hi = bisect.bisect_left(bl_addr, next_start(f))
        first_call = bl_addr[lo] if lo < hi else None
        late = [va for va, im in subs.get(f, []) if first_call and va > first_call]
        # pre-index stp [sp, #-imm]! 也分配帧
        for va in range(f, min(f + 0x80, next_start(f)), 4):
            ins = r.read_insn(va)
            if ins is None:
                break
            if (ins >> 22) == 0x2a6 and (ins & 0x3e0) == 0x3e0:
                imm7 = (ins >> 15) & 0x7f
                if imm7 & 0x40:
                    imm7 -= 0x80
                if imm7 < 0:
                    total += (-imm7) << 3
        frame_of[f] = total
        if late:
            late_sub[f] = late

    rev = {}
    for site, tgt in bl_sites:
        rev.setdefault(tgt, []).append(site)

    caller_of = {}
    for tgt, sites in rev.items():
        lst = []
        for s in sites:
            c = enclosing(s)
            if c is not None and c != tgt:
                lst.append((c, s))
        caller_of[tgt] = lst

    # ---- 向后数据流 (全寄存器跟踪) ----
    def analyze_site(site_va, func_start, func_end, want=(0, 1, 2)):
        descs = {}
        blocked = set()
        va = site_va - 4
        steps = 0
        while va >= func_start and steps < 200:
            ins = r.read_insn(va)
            if ins is None:
                break
            steps += 1
            if is_bl(ins):
                for x in range(19):
                    if x not in descs and x not in blocked:
                        blocked.add(x)
                va -= 4
                continue
            if t6blk(ins):
                va -= 4
                continue
            rd = insn_writes_rd(ins)
            if rd is None or rd > 28:
                va -= 4
                continue
            if rd in descs or rd in blocked:
                va -= 4
                continue
            # 未决: 记录定义
            if is_movz(ins) or is_movk(ins):
                descs[rd] = ('const', movz_value(ins))
            elif is_orr_imm(ins):
                descs[rd] = ('const', orr_imm_value(ins))
            elif is_add_sp(ins):
                descs[rd] = ('spadd', add_sp_imm(ins))
            elif (ins >> 24) == 0x91 or (ins >> 24) == 0xd1:
                rn = (ins >> 5) & 0x1f
                imm = (ins >> 10) & 0xfff
                isadd = (ins >> 24) == 0x91
                if rn == 31:
                    descs[rd] = ('spadd', imm if isadd else -imm)
                elif rn == 30:  # add/sub xD, x30, #imm: 视为未知
                    descs[rd] = ('unknown', 'add30')
                else:
                    descs[rd] = ('add', rn, imm, isadd)
            elif (ins >> 24) in (0x90, 0x10):
                descs[rd] = ('global',)
            else:
                mv = mov_reg_info(ins)
                if mv is not None:
                    d, src = mv
                    if d == rd:
                        if src == 'zr':
                            descs[rd] = ('const', 0)
                        else:
                            descs[rd] = ('alias', src)
                        va -= 4
                        continue
                descs[rd] = ('unknown', 'insn')
            va -= 4
        # 入口参数回退 (x0-x7 且未被调用污染)
        for n in range(8):
            if n not in descs and n not in blocked:
                descs[n] = ('arg', n)
        def resolve(d):
            if d is None:
                return ('unknown', 'undef')
            seen = 0
            while d[0] == 'alias' and seen < 8:
                d = descs.get(d[1])
                if d is None:
                    return ('unknown', 'alias-cycle')
                seen += 1
            if d[0] == 'add':
                b = descs.get(d[1])
                if b is not None and b[0] == 'spadd':
                    return ('spadd', b[1] + d[2] if d[3] else b[1] - d[2])
                return ('unknown', 'add-base')
            return d
        return {x: resolve(descs.get(x)) for x in want}

    def t6blk(ins):
        t6 = ins >> 26
        if t6 in (0x05, 0x54, 0x34, 0x35, 0x36, 0x37):
            return True
        if t6 == 0xd6 and (ins & 0x3ff) == 0:
            return True
        if (ins >> 24) == 0xd5 and (ins >> 20) != 0xd53:
            return True
        return False

    cfu_sites = [(s, t) for s, t in bl_sites if t in cfu_set]
    print('[+] copy_from_user call sites:', len(cfu_sites))

    cands = []
    for site, tgt in cfu_sites:
        f = enclosing(site)
        res = analyze_site(site, f, next_start(f))
        cands.append({
            'site': site, 'func': f, 'func_name': name_of[f],
            'target': tgt, 'target_name': name_of[tgt],
            'x0': res[0], 'x1': res[1], 'x2': res[2],
        })

    # ---- 调用链 (直接 bl) ----
    ROOT_PREFIXES = ('__arm64_sys_', '__do_compat_sys_', 'compat_sys_', '__se_sys_', '__arm64_compat_sys_')
    cache_chains = {}

    def build_chains(func_start, max_depth=7, max_chains=64):
        if func_start in cache_chains:
            return cache_chains[func_start]
        results = []
        visited = set()

        def walk(f, path):
            if len(path) >= max_depth:
                results.append((path, 'DEPTH_LIMIT'))
                return
            name = name_of.get(f, '')
            if name.startswith(ROOT_PREFIXES):
                results.append((path, 'ROOT'))
                return
            cs = caller_of.get(f, [])
            if not cs:
                results.append((path, 'NO_CALLER'))
                return
            if len(cs) > 200:
                results.append((path, 'MANY_CALLERS'))
                return
            roots = [c for c in cs if name_of.get(c[0], '').startswith(ROOT_PREFIXES)]
            cand_cs = roots if roots else cs
            for c, site_c in cand_cs[:32]:
                if c in visited:
                    continue
                visited.add(c)
                walk(c, path + [(c, site_c, frame_of.get(c, 0))])
                visited.discard(c)

        walk(func_start, [(func_start, None, frame_of.get(func_start, 0))])
        cache_chains[func_start] = results
        return results

    results = []
    for c in cands:
        x0 = c['x0']
        x2 = c['x2']
        chains = build_chains(c['func'])
        c['chains'] = chains
        depth_list = []
        if x0[0] == 'spadd':
            imm = x0[1]
            seen = set()
            for chain, kind in chains:
                if kind != 'ROOT':
                    continue
                total = sum(fr for f_, s_, fr in chain)
                depth = total - imm
                if depth not in seen:
                    seen.add(depth)
                    depth_list.append((depth, chain, imm))
        elif x0[0] == 'arg':
            n = x0[1]
            seen = set()
            for chain, kind in chains:
                if kind != 'ROOT' or len(chain) < 2:
                    continue
                f, site_c, fr = chain[1]
                res = analyze_site(site_c, f, next_start(f), (n,))
                d = res[n]
                if d[0] == 'spadd':
                    total = sum(fr2 for f2_, s2_, fr2 in chain[1:])
                    depth = total - d[1]
                    if depth not in seen:
                        seen.add(depth)
                        depth_list.append((depth, chain, d[1]))
        c['depths'] = depth_list
        results.append(c)

    # ---- 输出 ----
    def fmt_d(d):
        if d[0] == 'spadd':
            return 'sp+0x%x' % d[1]
        if d[0] == 'const':
            return '0x%x' % d[1]
        if d[0] == 'arg':
            return 'arg%d' % d[1]
        if d[0] == 'global':
            return 'GLOBAL'
        return 'UNKNOWN'

    def fmt_chain(chain):
        return ' -> '.join('%s(0x%x)' % (name_of[f], fr) for f, s, fr in chain)

    # 锚点验证
    print('\n===== 校准锚点 =====')
    anchor_map = {'__arm64_sys_sched_setaffinity': 0x40, '__arm64_sys_select': 0x1f0,
                  '__arm64_sys_pselect6': 0x210}
    for c in results:
        if c['func_name'] in anchor_map and c['x0'][0] == 'spadd':
            for d, chain, imm in c['depths']:
                print('%-30s depth=0x%03x (期望 0x%x) %s' % (
                    c['func_name'], d, anchor_map[c['func_name']], fmt_chain(chain)))
    if only_anchor:
        return

    stack_cands = [c for c in results if c['x0'][0] == 'spadd']
    arg_cands = [c for c in results if c['x0'][0] == 'arg' and c['depths']]
    print('\n===== 栈目标候选: %d 个 =====' % len(stack_cands))
    print('%-46s %-6s %-8s %-8s %s' % ('func', 'frame', 'imm', 'size', 'depth(s)'))
    for c in sorted(stack_cands, key=lambda x: (x['depths'][0][0] if x['depths'] else 9999)):
        depths = ', '.join('0x%03x' % d for d, ch, im in c['depths'])
        print('%-46s 0x%-4x sp+0x%-3x %-8s %s' % (
            c['func_name'][:46], frame_of.get(c['func'], 0), c['x0'][1], fmt_d(c['x2']), depths))

    print('\n===== 窗口 [0x2e0, 0x380] 命中 =====')
    hits = []
    for c in stack_cands + arg_cands:
        size = c['x2'][1] if c['x2'][0] == 'const' else 0
        for d, chain, imm in c['depths']:
            if WINDOW_LO <= d < WINDOW_HI:
                hits.append((c, d, size, chain, imm))
    hits.sort(key=lambda h: h[1])
    for c, d, size, chain, imm in hits:
        print('* 0x%03x size=0x%x  %-40s (%s)' % (d, size, c['func_name'], fmt_chain(chain)))
    if not hits:
        print('  (无命中)')

    print('\n===== 邻近窗口 (0x250-0x2e0 / 0x380-0x430) =====')
    near = []
    for c in stack_cands + arg_cands:
        size = c['x2'][1] if c['x2'][0] == 'const' else 0
        for d, chain, imm in c['depths']:
            if (0x250 <= d < WINDOW_LO) or (WINDOW_HI <= d < 0x430):
                near.append((c, d, size, chain, imm))
    for c, d, size, chain, imm in sorted(near, key=lambda h: h[1])[:limit if limit else 200]:
        print('~ 0x%03x size=0x%x  %-40s' % (d, size, c['func_name']))

    if dump_json:
        out = []
        for c in results:
            out.append({
                'site': '0x%x' % c['site'], 'func': c['func_name'], 'func_va': '0x%x' % c['func'],
                'target': c['target_name'],
                'x0': fmt_d(c['x0']), 'x1': fmt_d(c['x1']), 'x2': fmt_d(c['x2']),
                'frame': frame_of.get(c['func'], 0),
                'depths': ['0x%x' % d for d, ch, im in c['depths']],
            })
        with open(dump_json, 'w') as f:
            json.dump(out, f, indent=1)
        print('[+] json ->', dump_json)


if __name__ == '__main__':
    main()
