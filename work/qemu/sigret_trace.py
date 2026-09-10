import socket, time, re, struct, json, os

MON_HOST='127.0.0.1'; MON_PORT=5555
LOG=r'C:\Users\QingJ\Desktop\root\work\qemu\sigret_trace.json'

def mon_connect():
    s=socket.create_connection((MON_HOST,MON_PORT),timeout=10)
    time.sleep(0.3); s.recv(65536)  # banner
    return s

def mon_cmd(s, cmd):
    s.sendall((cmd+'\n').encode())
    time.sleep(0.3)
    data=b''
    try:
        while True:
            c=s.recv(65536)
            if not c: break
            data+=c
            if b'(qemu)' in c: break
    except socket.timeout: pass
    return data.decode('utf-8','replace')

def parse_regs(output):
    regs={}
    for l in output.splitlines():
        l=l.strip()
        m=re.match(r'^(X\d{2})\s*=\s*([0-9a-fA-F]+)', l)
        if m: regs[m.group(1).lower()]=int(m.group(2),16)
        m=re.match(r'^(PC|SP)\s*=\s*([0-9a-fA-F]+)', l)
        if m: regs[m.group(1).lower()]=int(m.group(2),16)
    return regs

def main():
    s=mon_connect()
    # 停止 VM
    mon_cmd(s,'stop')
    time.sleep(0.5)
    
    # 读所有 vCPU 的寄存器
    result={'timestamp':time.time()}
    for cpu in range(2):
        s.sendall(f'cpu {cpu}\n'.encode())
        time.sleep(0.2); s.recv(65536)
        r=mon_cmd(s,'info registers')
        result[f'cpu{cpu}_regs']=r
        
    # 读内核栈区域（waiter 栈在之前崩溃中约 0xffffffc00b51xxxx）
    # 用 xp 命令读物理内存
    # 先读 el0_svc / rt_sigreturn 附近的代码确认基址
    for addr,label in [
        (0xffffffc0080a6f98,'sys_rt_sigreturn_entry'),
        (0xffffffc0080a7124,'restore_sigframe_entry'),
        (0xffffffc0080a793c,'parse_user_sigframe_entry'),
        (0xffffffc0080a8bac,'restore_fpsimd_entry'),
    ]:
        pa = addr - 0xffffffc008000000 + 0x40000000  # VA->PA (kernel image at phys base)
        out=mon_cmd(s,f'xp /4gx {pa:#x}')
        result[label]=out.strip()

    # 搜索整个可能的内核栈区域找 FPSIMD magic (0x46508001)
    # 栈区域大概在 0xffffffc00b400000-0xffffffc00b600000 (基于之前观测)
    # 对应物理地址 = VA - PAGE_OFFSET = VA - 0xffffff8000000000
    # 但更简单: 直接搜索物理内存 0x40000000 + 0xB400000..0xB600000 区域
    # 物理地址范围: 0x40000000 + 0xb40000 = 0x40b40000 到 0x40b60000... 不对
    # 线性映射: PA = VA - 0xffffff8000000000
    # 对于 VA=0xffffff8003e9xxxx, PA = 0x3e9xxxx... 这不对因为 RAM 从 0x40000000 开始
    # 实际上 arm64 线性映射: PA = VA & ~0xFFFFFF8000000000 (去掉高 bits)
    # 但要考虑 PHYS_OFFSET=0x40000000
    
    # 算了，直接搜物理内存找 FPSIMD magic
    print("Scanning physical RAM for FPSIMD_MAGIC (0x46508001)...")
    hits=[]
    chunk_size=0x100000  # 1MB chunks
    for base in range(0x40000000, 0x50000000, chunk_size):
        out=mon_cmd(s,f'xp /128wx {base:#x}')
        # 搜索 magic
        for m in re.finditer(r'0x46508001', out):
            offset_in_chunk = int(m.start() / 9) * 4  # rough estimate
            # 更精确: 解析每个 word 的位置
            words = re.findall(r'(?:^|\s)(?:0x)?([0-9a-fA-F]{8})', out[m.start()-200:m.start()+50])
            # 太复杂了, 改为直接记录 chunk
            hits.append({'chunk_base':hex(base),'context':out[max(0,m.start()-100):m.end()+100]})
            break
        # 检查是否被中断
        if len(hits)>5: break
    
    result['fpsimd_hits']=hits
    s.close()
    
    with open(LOG,'w') as f:
        json.dump(result,f,indent=2,default=str)
    
    # 打印摘要
    for cpu in range(2):
        r=result.get(f'cpu{cpu}_regs','')
        lines=[l.strip() for l in r.splitlines() if l.strip()]
        pc_match=[l for l in lines if l.startswith('PC')]
        sp_match=[l for l in lines if l.startswith('SP')]
        print(f"CPU{cpu}: PC={pc_match[0] if pc_match else '?'} SP={sp_match[0] if sp_match else '?'}")
    
    print(f"\nFPSIMD magic hits: {len(hits)}")
    for h in hits[:3]:
        print(f"  chunk={h['chunk_base']}")

if __name__=='__main__':
    main()
