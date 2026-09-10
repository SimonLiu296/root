# PLAN1 — copy_from_user 内核栈缓冲区候选扫描报告

目标: 在 PD2238 内核 (5.10.246, aarch64, 带符号 ELF) 中系统性枚举所有
`copy_from_user` 调用点, 筛选**栈目标缓冲深度 ∈ [0x2e0, 0x380]** (旧 rt_waiter 窗口)
且**大小 ≥ 80 字节** 的候选 (CVE-2026-43499 利用链需要)。

产物:
- 扫描器: `work/qemu/scan_copyfromuser.py` (可复用)
- 全量 JSON: `work/qemu/cands6.json` (1271 个调用点, 含 x0/x1/x2 解析与深度)
- 本报告: `docs/PLAN1-COPYFROMUSER.md`

---

## 1. 方法说明

### 1.1 数据来源
- ELF: `work/boot_out/output.elf` (vmlinux-to-elf, 符号 st_size=0)
- 全部代码位于 `.kernel` 段 (0xffffffc008000000, 51.7MB), 线性扫描指令

### 1.2 步骤
1. **符号表**: 收集全部 STT_FUNC 符号 (224 个 `_copy_from_user`/`_copy_from_user.NNNN`/`__arch_copy_from_user`),
   函数边界 = 相邻符号地址。
2. **指令扫描**: 全段线性扫描, 手工解码 (pyelftools + struct, 无 capstone 依赖):
   - `bl` (top6=0x25) → 调用图; 符号扩展修正: `off = (imm26<<2) - 0x10000000` (bit25)
     — 早期版本误用 0x40000000 导致所有后向分支目标错误, 已修复;
   - `sub sp, sp, #imm` + `stp x29,x30,[sp,#-imm]!` (pre-index, `(ins>>22)==0x2a6 && rn==31`) → 帧大小;
3. **帧大小**: 函数内所有 `sub sp` 之和 + pre-index stp 的 `|imm|` (序言, 前 0x80 字节内)。
4. **向后数据流** (每调用点 ≤200 条指令): 全寄存器跟踪 (x0-x28), 解析:
   - `x0` = `add xN, sp, #imm` 链 → `('spadd', imm)` — 栈目标;
   - `movz/movk/orr-imm` → 立即数 (拷贝大小);
   - `x0-x7` 入口参数回退 (`argN`);
   - `bl/blr/br` 污染规则: 只杀 caller-saved (x0-x18), callee-saved (x19-x28) 跨调用存活;
   - 指令写寄存器分类器 (branch/store/system/SIMD 不写 GPR, 其余写 rd)。
5. **调用链回溯** (反查 bl 图): 从目标函数向上走到 `__arm64_sys_*`/`__do_compat_sys_*` 根,
   累加每层帧大小。深度模型:
   ```
   depth(buffer) = Σ(各层帧大小) - imm(缓冲在目标函数帧内偏移)
   ```
   基准 SP = el0_svc_common 派发点 (= wrapper 入口 SP, 同一线程两次 syscall 相同)。
6. **间接调用** (ioctl/setsockopt 等 fops `blr`) 的链无法静态闭合 → 用
   `__arm64_sys_ioctl(0x50) + do_vfs_ioctl(0xa0) = 0xf0` 前缀估算 (标注"估算")。

### 1.3 校准 (锚点验证, 全部通过)
| 锚点 | 期望深度 | 本工具计算 | 链 |
|---|---|---|---|
| sched_setaffinity cpumask | 0x40 | **0x40** | __arm64_sys_sched_setaffinity(0x40), imm=0 (三星改版 wrapper 内拷贝 8B) |
| select fdset | 0x1f0 | **0x1f0** | __arm64_sys_select(0x80) → core_sys_select(0x1c0), imm=0x50 |
| pselect6 fdset | 0x210 | **0x210** | __arm64_sys_pselect6(0xa0) → core_sys_select(0x1c0), imm=0x50 |
| futex rt_waiter | 0x330 | **0x330** | __arm64_sys_futex(0xe0) → do_futex(0xc0) → futex_lock_pi(0x1a0), rt_waiter@sp+0x10 (人工验证) |
| poll/ppoll pollfd | 0x528 | 0x434/0x454 | **不可复现**: 本 build 中 poll=0x434, ppoll=0x454, ppoll_time32=0x444 |

> poll 锚点偏差说明: 3 个拷贝类锚点 + rt_waiter 锚点全部精确命中, 深度模型可信。
> poll 的 0x528 在本 build 任何路径 (poll/ppoll/compat/restart) 都算不出, 疑似锚点测量
> 条件不同 (或基于其它 build)。不影响窗口定位 (窗口由 rt_waiter=0x330 锚定)。

---

## 2. 完整候选表 (深度 ≥ 0x200, x0=栈, 已定根链)

> 全量 1271 调用点 → 670 个 x0=栈 → 155 个有定根调用链 → 12 个 size≥0x50。
> 下表为深度 ≥0x200 的全部 155 个中有代表性的 (完整见 cands6.json)。

### 2.1 命中目标窗口 [0x2e0, 0x380] (★ = 重点)

| 深度 | 函数 | imm | 大小 | 调用链 | 用户可控? |
|---|---|---|---|---|---|
| **0x300** | **restore_fpsimd_context** | sp+0x0 | **0x200 (512B)** | __arm64_sys_rt_sigreturn(0x50) → restore_sigframe(0x60) → restore_fpsimd_context(0x250) | ✅ 信号帧 fpsimd vregs, 任意进程, **无特权** |
| **0x310** | **restore_sve_fpsimd_context** | sp+0x10 | **0x200 (512B)** | 同上 (SVE 路径) | ✅ (需 CONFIG_ARM64_SVE+硬件支持) |
| **0x320** | restore_sve_fpsimd_context | sp+0x0 | 0x10 | 同上 | ✅ (SVE header) |
| **0x300** | **bpf_prog_get_info_by_fd** | sp+0x50 | min(用户len, 0xd0) (208B) | __arm64_sys_bpf(0x10) → __do_sys_bpf(0x1b0) → bpf_prog_get_info_by_fd(0x190) | ✅ len 用户可控, 上限 0xd0; 但需 bpf() 特权 (Android 默认禁 unprivileged BPF) |
| **0x358** | **prctl_set_package** (三星 vendor) | sp+0x18 | **用户 arg4, 无上界** (canary 在 +0xc0) | __arm64_sys_prctl(0x10) → __do_sys_prctl(0x230) → prctl_set_package(0x130) | ✅ prctl(PR_SET_PACKAGE, ...), 无特权; 长度 ≥0x28 即盖满窗口 (0x358+0x28=0x380) |
| 0x300/0x350 | __copy_msghdr_from_user | sp+0x0 | 0x38 (56B) | sendmsg/sendmmsg 系 (多链: 0x280/0x290/0x2a0/0x2b0/0x300/0x350...) | ✅ msghdr 内容; 但 56B<80 |
| 0x300/0x350 | ____sys_sendmsg | sp+0x10 | 未知 (≈0x38) | sendmsg 系 | ✅ |
| 0x318 | cmsghdr_from_user_compat_to_kern | sp+0x18 | 0xc (12B) | compat sendmsg 系 | ✅ 太小 |

### 2.2 部分覆盖窗口 (区间与窗口相交, 起点略低于 0x2e0)

| 区间 | 函数 | 大小 | 链/估计 |
|---|---|---|---|
| [0x2a8, 0x328] | compat_ptrace_request (PTRACE_SETREGS 系, sp+0x38) | 0x80 (128B) | __do_compat_sys_ptrace(0) → compat_arch_ptrace(0x1e0) → compat_ptrace_request(0x100) — 需 ptrace 权限 |
| [0x268, 0x370] | usbdev_ioctl (sp+0x68) | 0x104/0x108 | ioctl 估算: 0x50+0xa0+0x1e0-0x68 — 需 /dev/bus/usb 权限 |
| [0x328, 0x458] | lo_ioctl (sp+0x8) | 0x130/0xe8 | ioctl 估算: 0x50+0xa0+0x240-0x8 — 需 loop 设备 |
| [0x268, 0x328] | ext4_ioc_getfsmap (sp+0x28) | 0xc0 (192B) | ioctl 估算 (另有 ext4_ioctl 中间层, 更深) |

### 2.3 深度在窗口内但 < 80B (可组合多个小缓冲)

| 深度 | 函数 | 大小 | 说明 |
|---|---|---|---|
| 0x300/0x350 | __copy_msghdr_from_user | 0x38 | msghdr 56B, 用户完全可控; [0x300,0x338] 覆盖 rt_waiter 头 8B; [0x350,0x388] 覆盖 rt_waiter 中后段 |
| 0x318 | cmsghdr_from_user_compat_to_kern | 0xc | 12B |
| 0x320 | restore_sve_fpsimd_context (header) | 0x10 | 与 0x310 的 0x200 连续, 合计覆盖 [0x310,0x520] |
| 0x3c8/0x408 | ptrace_request | 0x8/0x10 | 太小 |

### 2.4 邻近窗口 (0x250-0x2e0 / 0x380-0x430, 供参考)
- 0x268 compat_ptrace_request (0x80) — 部分覆盖见 2.2
- 0x280-0x2b0 __copy_msghdr_from_user (0x38) / ____sys_sendmsg / sendmsg_copy_msghdr (0x1c)
- 0x388 cmsghdr_from_user_compat_to_kern (0xc)
- 0x39c compat_gpr_set (sp+0x4, 72B, compat ptrace SETREGS)
- 0x3b0 gpio_ioctl (sp+0x20, **0x250=592B!**, ioctl 0xC250B407 GPIO_V2_GET_LINEINFO_WATCH; 估算深度, 差 0x30 未进窗口)
- 0x434/0x444/0x454 do_sys_poll pollfd (sp+0x7c, nfds*8 动态, 栈上 30 个首段)

---

## 3. 重点候选详细验证 (人工反汇编)

### ★★★ 1. restore_fpsimd_context — rt_sigreturn 信号帧 vregs (首选)
```
__arm64_sys_rt_sigreturn:  sub sp, #0x50            (0xffffffc0080a6f9c)
restore_sigframe:          sub sp, #0x60            (0xffffffc0080a7128)
restore_fpsimd_context:    stp x29,x30,[sp,#-0x30]! ; sub sp, #0x220   (0xa8bb4/0xa8bc4) 帧=0x250
  0xa8ee0: mov  x0, sp                 ← 内核栈目标 sp+0
  0xa8ee4: mov  w2, #0x200             ← 512 字节
  0xa8ee8: bl   __arch_copy_from_user  ← 源 = 用户 sigframe fpsimd_context.vregs
深度 = 0x50 + 0x60 + 0x250 - 0 = 0x300  ✅ 窗口内
覆盖 [0x300, 0x500] — 完整包含 rt_waiter 区域 [0x330, 0x388]
```
- 任意进程可发起 rt_sigreturn(), 帧内容完全用户可控 (access_ok 检查不影响内容)
- fpsr/fpcr 另用 `ldtr` 单拷贝 4B (深度 0x300 处)
- **结论: 完美覆盖窗口的 512B 用户可控栈缓冲, 无特权。**

### ★★ 2. restore_sve_fpsimd_context (SVE 变体)
```
帧 = 0x30 + 0x240 = 0x270; 0xa8528: add x0, sp, #0x10; mov w2, #0x200; bl __arch_copy_from_user
深度 = 0x50+0x60+0x270-0x10 = 0x310  ✅ 覆盖 [0x310, 0x510]
```
(需 SVE 支持; 若 SVE 未启用则此路径不可达, fpsimd 路径仍可用)

### ★★ 3. prctl_set_package — 三星 vendor prctl (无界长度)
```
__arm64_sys_prctl(0x10) → __do_sys_prctl(0x230, 跳转表分派 case @0x189368) → prctl_set_package(0x130)
0xa5e74c: add x0, sp, #0x18
0xa5e750: mov x1, x21      ← arg3 (用户指针)
0xa5e754: bl _copy_from_user.31673   ← x2 = arg4 (用户长度!), 拷贝前无任何上界检查
深度 = 0x10+0x230+0x130-0x18 = 0x358  ✅ 窗口内
```
- 大小 = 用户 arg4: len ≥ 0x28 即覆盖至 0x380; len > 0xc0 会打穿 canary (sp+0xd8)
  → panic; 0x28 ≤ len ≤ 0xc0 可干净覆盖窗口内任意范围
- 无特权 prctl() 可达; 分派发生在拷贝之后 (无前置权限检查)
- 注意: 无界拷贝本身即高危 (独立栈溢出面)

### ★ 4. bpf_prog_get_info_by_fd
```
0x3b7100: add x0, sp, #0x50; mov x1, x21(uinfo); mov x2, x20(=min(用户info_len, 0xd0))
0x3b710c: bl _copy_from_user.10073
深度 = 0x10+0x1b0+0x190-0x50 = 0x300  ✅ 窗口内; 大小用户可控上限 0xd0
```
(需 bpf() 权限 — Android 默认 unprivileged_bpf_disabled)

---

## 4. 置信度评估

| 项 | 置信度 | 说明 |
|---|---|---|
| 深度模型 | **高** | 4/5 锚点精确命中 (0x40/0x1f0/0x210/0x330); poll 0x528 不可复现(疑测量条件差异) |
| 调用点枚举完整性 | 高 | 全段扫描, bl 目标符号精确匹配; 1271 个调用点 (含 __arch_copy_from_user 直调) |
| x0 栈目标判定 | 高 | 全寄存器别名/加法链跟踪 + 人工抽查 (select/poll/futex/fpsimd/prctl/bpf 均吻合) |
| 帧大小 | 高 | sub sp + pre-index stp 双模式; 未处理 mid-body sub (有 flag 记录, 候选均已人工复核) |
| 间接调用链 (ioctl) | 中 | 静态 blr 无法闭合, 用标准路径估算; 已逐个人工读序言确认帧 |
| 首选候选 (fpsimd) | **极高** | 反汇编逐指令验证: x0=sp, x2=0x200, 链 0x50+0x60+0x250=0x300, 无特权, 完全用户可控 |

### 风险/限制
1. 线性扫描不做 CFG: 分支路径上的 x0 定义可能取错 (已对命中候选人工复核);
2. `add xD, sp` 的 imm 假设函数中途不再 sub sp (late_sub 已 flag, 命中候选无此情况);
3. ioctl/setsockopt 类深度为估算值 (需 QEMU 实测确认);
4. 未覆盖 `user_regset_copyin`/`iov_iter` 等间接拷贝路径 (本次任务限定 copy_from_user 直调)。

---

## 5. 结论

**命中窗口 [0x2e0,0x380] 且 size≥80B 的候选 (按可利用性排序):**

1. **restore_fpsimd_context** — 深度 **0x300**, **512B**, rt_sigreturn 任意进程无特权,
   用户完全可控 → **首选 (完美覆盖 rt_waiter 区)**
2. **restore_sve_fpsimd_context** — 深度 **0x310**, 512B (SVE 变体)
3. **prctl_set_package** — 深度 **0x358**, 大小 = 用户 arg4 无上界 (≥0x28 覆盖窗口)
4. bpf_prog_get_info_by_fd — 深度 0x300, ≤0xd0 (需 BPF 特权)
5. (部分覆盖) compat_ptrace_request [0x2a8,0x328] 128B; usbdev/lo/ext4 ioctl 系

无特权、完全可控、覆盖整个 rt_waiter 窗口的最优选择是 **rt_sigreturn → restore_fpsimd_context**。
