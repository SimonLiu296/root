# PLAN-B 帧布局分析 — PD2238 (5.10.246) futex rt_waiter ↔ pselect fdset 的 DELTA

目标：对 `C:\Users\QingJ\Desktop\root\work\boot_out\output.elf`（PD2238 内核，aarch64，带符号）做纯静态帧求和，
计算同线程 16KB VMAP_STACK 上两次系统调用的对象相对偏移 Δ = fdset_addr − rt_waiter_addr，
并推导 PSELECT_WAITER_WORD_SHIFT。方法与 aristotle 5.10.136 分析（`src/aristotle-root/RTMUTEX_WALK_DISASM_ANALYSIS.md`）相同，数字不通用。

公共分叉点：`el0_svc_common`（invoke_syscall 已内联）在 `blr x20`（0xffffffc0080bbe00，CFI 跳表项只含
`bti c; b target`，无栈帧）处间接调用两个 syscall wrapper。两条链在同一 sp（下称 SP_DIV）分叉。
所有函数均为单次 `sub sp, sp, #N` 序言（paciasp + SCS `str x30,[x18],#8`，LR 在 shadow call stack 上，
不占真栈），中间层全部为直接 `bl`，无额外帧。

---

## 1. FUTEX 链（waiter 线程 FUTEX_WAIT_REQUEUE_PI → 悬垂 rt_waiter）

### __arm64_sys_futex @ 0xffffffc0082dbbf0 — 帧 0xe0
```
ffffffc0082dbbf4: d10383ff   sub   sp, sp, #0xe0
ffffffc0082dbc9c: 97ffc28b   bl    0xffffffc0082cc6c8 <do_futex>
```

### do_futex @ 0xffffffc0082cc6c8 — 帧 0xc0
```
ffffffc0082cc6cc: d10303ff   sub   sp, sp, #0xc0
...
ffffffc0082cc8b4: d503249f   bti   j                      ; case FUTEX_WAIT_REQUEUE_PI
ffffffc0082cc8c0: aa1403e0   mov   x0, x20
ffffffc0082cc8c8: aa1703e3   mov   x3, x23                ; uaddr2
ffffffc0082cc8d4: 94001d24   bl    0xffffffc0082d3d64 <futex_wait_requeue_pi>   ; 直接调用
```

### futex_wait_requeue_pi @ 0xffffffc0082d3d64 — 帧 0x1b0，rt_waiter @ +0x20
```
ffffffc0082d3d68: d106c3ff   sub   sp, sp, #0x1b0
```
rt_waiter 地址由两个独立消费方双重证明：

(1) rt_mutex_wait_proxy_lock(lock, to, waiter) 的第 3 参：
```
ffffffc0082d4018: a97c27a8   ldp   x8, x9, [x29, #-0x40]
ffffffc0082d4024: 91004116   add   x22, x8, #0x10         ; lock = q.rt_mutex
ffffffc0082d4028: 910083e2   add   x2, sp, #0x20          ; ★ &rt_waiter = 本帧 sp+0x20
ffffffc0082d402c: aa1603e0   mov   x0, x22
ffffffc0082d4030: aa1303e1   mov   x1, x19                ; to
ffffffc0082d4034: 97fd5129   bl    rt_mutex_wait_proxy_lock
```
(2) rt_mutex_cleanup_proxy_lock(lock, waiter) 的第 2 参：
```
ffffffc0082d407c: 910083e1   add   x1, sp, #0x20          ; ★ &rt_waiter 再次确认
ffffffc0082d4084: 97fd5180   bl    rt_mutex_cleanup_proxy_lock
```
旁证（帧内布局自洽）：hrtimer_init_sleeper 参数 `add x0, sp, #0x70`（timeout @ +0x70..+0xaf）；
`futex_wait_setup(..., x3 = x29-0x90 = sp+0xc0 = &q, x4 = sp+0x18 = &hb)`；
`futex_wait_queue_me(hb, &q, to)` 第 2 参 `sub x1, x29, #0x90` → q @ +0xc0。rt_waiter(0x50 B) 位于
sp+0x20..sp+0x70，与入口清零循环 `stp xzr,[sp,#0x00..0xa0]` 吻合。

注意：本构建入口有一段 vivo 补丁式的常量模板拷贝——从全局表 0xffffffc00a42c4b0 成对加载 8 组常量
写入 [x29-0x90 .. x29-0x18]（= sp+0xc0..sp+0x138，即整个扩展的 futex_q 区域）。这不影响 rt_waiter 定位。

**D_rtw（rt_waiter 深度）= 0xe0 + 0xc0 + 0x1b0 − 0x20 = 0x330**
→ **rt_waiter = SP_DIV − 0x330**，占据 [SP_DIV−0x330, SP_DIV−0x330+0x50) = […−0x2e0)。

---

## 2. PSELECT 链（同线程 pselect(320,…) → 栈上 fdset）

### __arm64_sys_pselect6 @ 0xffffffc008604e64 — 帧 0xa0（do_pselect 已内联，无独立符号）
```
ffffffc008604e68: d10283ff   sub   sp, sp, #0xa0
...                                        ; get_sigset_argpack / sigmask / timeout(sp+0x18)
ffffffc00860500c: 97fffa3b   bl    core_sys_select        ; 直接调用
```

### core_sys_select @ 0xffffffc0086038f8 — 帧 0x1c0，stack_fds(bits) @ +0x50
```
ffffffc0086038fc: d10703ff   sub   sp, sp, #0x1c0
...
ffffffc0086039d8: 9100ff28   add   x8, x25, #0x3f         ; size = FDS_BYTES(n) = 8*ceil(n/64)
ffffffc0086039dc: d343fd08   lsr   x8, x8, #3
ffffffc0086039e0: 927de51c   and   x28, x8, #~7
ffffffc0086039e4: f100af9f   cmp   x28, #0x2b             ; > 256/6 (=42.67) ?
ffffffc0086039e8: 54000183   b.lo  0xffffffc008603a18     ; 小路径 → 栈
ffffffc0086039fc: ...        kvmalloc_node(6*size)        ; 大路径 → 堆（不可能别名栈）
...
ffffffc008603a18: 910143f5   add   x21, sp, #0x50         ; ★ bits = &stack_fds = 本帧 sp+0x50
ffffffc008603a48: a90253f5   stp   x21, x20, [sp, #0x20]  ; fds.in/out/ex/res_* 六段连续排布
...
ffffffc008603b60: 910083e1   add   x1, sp, #0x20          ; &fds → do_select
ffffffc008603b68: 94000138   bl    do_select
```
阈值核对：SELECT_STACK_ALLOC=256，堆判定 size≥43；nfds=320 ⇒ FDS_BYTES=40（每 set 5 个 long），
40<43 → **栈路径成立**；六组共 240 B，位于 [bits, bits+240)。栈路径 nfds 上限恰为 320
（n≥321 ⇒ ceil(n/64)=6 ⇒ 48>42.67 → kvmalloc 堆）。

**D_fdset = 0xa0 + 0x1c0 − 0x50 = 0x210**
→ **fdset = SP_DIV − 0x210**，nfds=320 时覆盖窗口 [SP_DIV−0x210, SP_DIV−0x120)。

---

## 3. 公共祖先帧与 Δ

| 层 | futex 链帧 | pselect 链帧 |
|---|---|---|
| el0_svc_common（分叉，blr x20） | SP_DIV | SP_DIV |
| wrapper | __arm64_sys_futex 0xe0 | __arm64_sys_pselect6 0xa0 |
| 中间层 | do_futex 0xc0 | （无） |
| 目标函数 | futex_wait_requeue_pi 0x1b0 | core_sys_select 0x1c0 |
| 对象帧内偏移 | rt_waiter +0x20 | bits +0x50 |

- rt_waiter_addr = SP_DIV − 0x330
- fdset_addr     = SP_DIV − 0x210

## **Δ = fdset_addr − rt_waiter_addr = +0x120 = +288 字节**（fdset 在旧 rt_waiter 上方/高地址侧）
## PSELECT_WAITER_WORD_SHIFT = Δ/8 = **+36**

### 可行性判定 —— 不满足约束，无法覆盖
覆盖条件要求全局 word 索引 i = waiter_word j + 36 落在窗口 [0, 30) 内（240B=30 words）；j=0 即需 i=36 ≥ 30，
越界。且：
- 窗口起点 bits=SP_DIV−0x210 与 nfds 无关（三个偏移都是编译期常量），增大 nfds 只能向高地址延伸；
- nfds>320 会切到 kvmalloc 堆缓冲，彻底失去栈别名能力；
- 结论：在本构建的原生 pselect6/select 路径上，**任何 WORD_SHIFT 都不能让 fdset 触到 rt_waiter**
  （差 288+ 字节）。备选包装 `__arm64_sys_select`（帧 0x80）给出 D=0x1f0、Δ=+0x140，更差。
- 对照：aristotle 5.10.136 上两链恰好重合（Δ=0、shift=−2）；PD2238 的差异来自
  __arm64_sys_futex 0x90→0xe0、do_futex 0x70→0xc0、fwrp 0x1a0→0x1b0 且 rt_waiter 从 +0x90 移到 +0x20、
  pselect wrapper 0xa0 不变但 core_sys_select 0x1c0 相同——净效果从 0 变成 +288。

崩溃佐证一致性：x28=0xffffffc00b513b10（悬垂 pib=旧 rt_waiter 首址）⇒ 推得该次 SP_DIV=0xffffffc00b513e40；
16K 栈块顶 0xffffffc00b514000，SP_DIV 之上有 0x1c0 余量 ≈ pt_regs(0x110) + 入口小帧，量级自洽
（consumer sp 0xb523c50 属另一 16K 栈块，是不同时刻/线程，不影响计算）。

### 对 exploit 的含义（PLAN-B 需要 B 计划）
fdset overlay 在此内核上不可用，悬垂 rt_waiter（[SP_DIV−0x330, SP_DIV−0x2e0)）需要换一个"落点深度
D∈[0x330−0x50+1, 0x330] 且缓冲可由用户数据填充"的栈消费者来回收，例如：
- 其它栈缓冲型 syscall（ppoll/pollfd、execve(filename)、getcwd(buf)、readlinkat、name_to_handle_at、
  sigaltstack、sched_setaffinity(mask)、socket 系 getsockopt(optval) 等）逐一做同样的帧求和找 D≈0x300±0x30；
- 或保留 pselect 但利用其深层辅助帧：core_sys_select 自身被调用前后的 set_user_sigmask /
  poll_select_finish 内的局部缓冲不在窗口内，不可行；do_select 的局部 fds 也不行。
建议写个小脚本批量扫符号表 + 单序言求和筛 D∈[0x2e0,0x330] 的候选再人工确认。

---

## 4. 置信度与验证建议

置信度：**Δ=+288 为高置信**（每个数字都来自单一 `sub sp,#N` 序言 + 明确的 `add/sub xN,sp/x29,#imm`
参数准备；rt_waiter 有两个独立调用点交叉印证；fdset 小路径有 cmp #0x2b 阈值与 stp 排布双重锁定）。
残余风险：若某层存在未识别的尾调用/内联变化（本二进制未见），或 exploit 实际走 compat/time32 包装
（__arm64_sys_pselect6_time32 仅 0x10 大小的跳板，需另行求和）。

QEMU gdb 复核步骤（不动真机）：
1. QEMU 启动同一 Image（`-M virt -cpu cortex-a76 -kernel Image …`），`-s -S` 挂 gdb。
2. 断点 `*el0_svc_common+0xd0`（blr x20 处 0xffffffc0080bbe00）：记录 $sp = SP_DIV 基准。
3. waiter 线程发 futex(FUTEX_WAIT_REQUEUE_PI)，断点 `*0xffffffc0082d4034`（rt_mutex_wait_proxy_lock 调用）：
   `p/x $x2` 应 == SP_DIV−0x330；同时 `x/6gx $x2` 看 waiter 清零态。
4. 同线程恢复后发 pselect(320,…)，断点 `*0xffffffc008603a18`（小路径取 bits）：`p/x $x21` 应 ==
   SP_DIV−0x210；断 `*0xffffffc008603a7c`（copy_from_user in）后检查 240B 落窗内容。
5. 直接验证 Δ：`(long)&fdset_word0 - (long)&rt_waiter == 0x120`；再扫 shift∈{33..40} 确认全部越窗，
   与静态结论（不可达）一致。
6. 若想进一步复核栈顶余量 0x1c0：断 entry 后第一 C 帧，对比 pt_regs 边界（stack_top−0x110）。
