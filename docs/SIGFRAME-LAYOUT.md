# Linux 5.10 arm64 rt_sigreturn / sigframe 字节级逆向分析

> 分析对象：`src/vivo-mtk510-src`（vivo MTK 内核 5.10 源码树）
> 关键文件：
> - `arch/arm64/kernel/signal.c`（981 行）
> - `arch/arm64/include/uapi/asm/sigcontext.h`
> - `arch/arm64/include/uapi/asm/ucontext.h`
> - 辅助核实：`arch/arm64/kernel/ptrace.c`、`arch/arm64/include/{asm,uapi/asm}/ptrace.h`、`kernel/signal.c`、`include/uapi/linux/signal.h`
>
> 所有偏移按 LP64 小端（aarch64）计算。行号均指本地源码树。

---

## 1. 字节级布局

### 1.1 顶层结构

```c
// signal.c:40
struct rt_sigframe {
	struct siginfo info;      // 0x000, 128 字节
	struct ucontext uc;       // 0x080
};
```

- `sizeof(struct siginfo)` = **0x80 (128)** —— `siginfo_t` 是 union，含
  `_si_pad[SI_MAX_SIZE/sizeof(int)]` = `[32]int`（`include/uapi/asm-generic/siginfo.h:13,129-134`），arm64 无 `__ARCH_HAS_SWAPPED_SIGINFO`。
- `sizeof(struct rt_sigframe)` = **0x1248 (4680)**。
- `BASE_SIGFRAME_SIZE` = `round_up(0x1248,16)` = **0x1250 (4688)**（signal.c:64）。
- `offsetof(struct rt_sigframe, uc.uc_mcontext.__reserved)` = **0x248**（即 `init_user_layout()` 里 `user->size` 初值，signal.c:74）。

### 1.2 struct ucontext（uapi/asm/ucontext.h:22-31）

```c
struct ucontext {
	unsigned long   uc_flags;    // 0x00, 8B
	struct ucontext *uc_link;    // 0x08, 8B
	stack_t         uc_stack;    // 0x10, 24B
	sigset_t        uc_sigmask;  // 0x28, 8B
	__u8            __unused[1024/8 - sizeof(sigset_t)]; // 0x30, 120B
	struct sigcontext uc_mcontext; // 0xA8
};
```

- `stack_t`（= `sigaltstack`）= `{void *ss_sp; int ss_flags; size_t ss_size;}` → 8+4+(4 pad)+8 = **24B**；
- 内核侧 `sigset_t`：arm64 `_NSIG=64, _NSIG_BPW=64` → `_NSIG_WORDS=1` → **8B**；
- `__unused` = 128−8 = **120B**；
- `sizeof(struct ucontext)` = 0xA8 + 0x1120 = **0x11C8**。

### 1.3 struct sigcontext（uapi/asm/sigcontext.h:28-37）

```c
struct sigcontext {
	__u64 fault_address;              // 0x000
	__u64 regs[31];                   // 0x008 .. 0x0FF
	__u64 sp;                         // 0x100
	__u64 pc;                         // 0x108
	__u64 pstate;                     // 0x110
	__u8  __reserved[4096] __aligned(16); // 0x120（0x118 对齐填充到 0x120）
};
```

- `sizeof(struct sigcontext)` = 0x120 + 0x1000 = **0x1120 (4384)**。

### 1.4 rt_sigframe 绝对偏移总表（frame 基址 = 进入 syscall 时的 regs->sp）

```
偏移     大小    字段                                   rt_sigreturn 是否读取
------  ------  ------------------------------------  --------------------
0x000   0x080   info (siginfo_t)                       ✗ 完全不读
0x080   0x008   uc.uc_flags                            ✗
0x088   0x008   uc.uc_link                             ✗
0x090   0x008   uc.uc_stack.ss_sp                      ✓ (restore_altstack, 错误被吞*)
0x098   0x004   uc.uc_stack.ss_flags (+4B pad)         ✓ (同上)
0x0A0   0x008   uc.uc_stack.ss_size                    ✓ (同上)
0x0A8   0x008   uc.uc_sigmask                          ✓ 必须可读
0x0B0   0x078   uc.__unused (120B)                     ✗
0x128   0x008   uc.uc_mcontext.fault_address           ✗（仅投递时写入）
0x130   0x0F8   uc.uc_mcontext.regs[0..30]             ✓ 必须可读 (regs[i]@0x130+8i;
                                                       x29@0x218, x30@0x220)
0x228   0x008   uc.uc_mcontext.sp                      ✓ 必须可读
0x230   0x008   uc.uc_mcontext.pc                      ✓ 必须可读
0x238   0x008   uc.uc_mcontext.pstate                  ✓ 必须可读
0x240   0x008   （sigcontext 内 0x118→0x120 对齐填充）  ✗
0x248   0x1000  uc.uc_mcontext.__reserved[4096]        ✓ 解析区（见 §1.5/§2）
------  ------
0x1248          sizeof(rt_sigframe) = 4680
```

\* `restore_altstack()` 除 EFAULT 外吞掉一切错误（`kernel/signal.c:4128-4137` 直接 `return 0`），所以 uc_stack 内容不影响成败，只要这 24 字节可读。

### 1.5 __reserved[] 解析区（绝对 0x248 起，相对解析基址 0x000）

解析参数（signal.c:329-333）：`base = &sc->__reserved`（绝对 0x248）、`limit = sizeof(sc->__reserved) = 0x1000`。
`access_ok(frame, sizeof(*frame))` 覆盖的是未取整的 **0x1248** 字节（signal.c:547）。

标准内核生成帧（native、FPSIMD、无 ESR/SVE）的 __reserved 内容：

```
相对 __reserved 偏移   绝对偏移   内容
-------------------   --------   ------------------------------------------
0x000                 0x248      fpsimd_context:
0x000                 0x248        head.magic = 0x46508001 (FPSIMD_MAGIC)
0x004                 0x24C        head.size  = 0x00000210
0x008                 0x250        fpsr (u32)
0x00C                 0x254        fpcr (u32)
0x010                 0x258        vregs[32] × 16B = 512B  → 结束于 0x457
                                 （sizeof(fpsimd_context) = 8+4+4+512 = 0x210）
0x210                 0x458      terminator: {magic=0, size=0}（8B 即够；
                                 内核预留 round_up(8,16)=16B）
```

有 ESR 时（投递时 `current->thread.fault_code != 0`）：esr_context 在 0x458（{ESR_MAGIC=0x45535201, size=0x10, esr:u64}，共 16B），terminator 移到 0x468。
其余空间（terminator 之后到 0xFFF）内核不写、sigreturn 不读——可为任意垃圾。

各 context 结构尺寸速查：

| 结构 | 组成 | sizeof | magic |
|---|---|---|---|
| `_aarch64_ctx` | magic:u32, size:u32 | **8** (0x8) | — |
| `fpsimd_context` | head + fpsr + fpcr + vregs[32]×16 | **0x210** (528) | FPSIMD_MAGIC = 0x46508001 |
| `esr_context` | head + esr:u64 | **0x10** (16) | ESR_MAGIC = 0x45535201 |
| `sve_context` | head + vl:u16 + __reserved[3]×u16 | **0x10** (16) | SVE_MAGIC = 0x53564501 |
| `extra_context` | head + datap:u64 + size:u32 + __reserved[3]×u32 | **0x20** (32) | EXTRA_MAGIC = 0x45585401 |
| terminator | `{0,0}` | 逻辑 8B / 预留 16B (`TERMINATOR_SIZE`) | 0 |
| `EXTRA_CONTEXT_SIZE` | round_up(32,16) | 0x20 | — |

---

## 2. 完整校验链（按执行顺序）

失败统一走 `badframe:`（signal.c:558-560）：`arm64_notify_segfault(regs->sp)` → 强制注入 SIGSEGV（si_code = MAPERR/ACCERR，si_addr = 此刻的 regs->sp），syscall 返回 0。**注意：寄存器恢复发生在校验之前，parse 失败时 PC/SP 已是攻击者值**（经典 sigret 原语）。

### 2.1 SYSCALL_DEFINE0(rt_sigreturn)（signal.c:530-561）

| # | 检查 | 失败条件 | 动作 |
|---|---|---|---|
| R1 | `regs->sp & 15` | SP 非 16 对齐 | badframe |
| R2 | `access_ok(frame, 0x1248)` | frame 不在用户 VA 区间 | badframe |
| R3 | `restore_sigframe()` 返回非 0 | 见下 | badframe |
| R4 | `restore_altstack(&uc.uc_stack)` | 仅当 24B 读取出 EFAULT | badframe（其他 altstack 错误被吞，kernel/signal.c:4135） |
| 成功 | `return regs->regs[0]` | — | x0 恢复值兼作返回值 |

### 2.2 restore_sigframe()（signal.c:486-528）

顺序敏感，逐条列出：

| # | 操作 | 失败条件 | errno | 备注 |
|---|---|---|---|---|
| S1 | `__copy_from_user(&set, &sf->uc.uc_sigmask, 8)`（0xA8） | 不可读 | -EFAULT | 失败仍继续往下；err==0 才 `set_current_blocked()`。成功时即使后续失败，信号掩码已被改 |
| S2 | 逐个恢复 regs[0..30]、sp、pc、pstate（0x130–0x23F） | 任一不可读 | err 累计 | 恢复先于任何结构校验！ |
| S3 | `forget_syscall(regs)` | — | — | |
| S4 | `valid_user_regs(&regs->user_regs, current)` | 返回 0（pstate 非法） | err≠0 | **在 parse 之前**执行，见 §2.5。副作用：无论成败都先剥离 RES0 位 |
| S5 | `parse_user_sigframe(&user, sf)` | 见 §2.3 | -EINVAL/-EFAULT | 仅在 S1-S4 全过时执行 |
| S6 | `system_supports_fpsimd()` 且 S5 过后 | `user.fpsimd == NULL` | **-EINVAL** | __reserved 中没有 fpsimd 记录直接拒绝 |
| S7 | 有 sve 记录但 `!system_supports_sve()` | | **-EINVAL** | |
| S8 | `restore_fpsimd_context(user.fpsimd)` 或 `restore_sve_fpsimd_context()` | 见 §2.4 | -EFAULT/-EINVAL | |

### 2.3 parse_user_sigframe()（signal.c:326-484）— 核心校验清单

初始化：`user->fpsimd=NULL, user->sve=NULL`；`base=__reserved`(须 IS_ALIGNED(base,16)，否则 invalid)；`offset=0, limit=0x1000`。

循环体每轮依次：

| # | 检查 | 失败动作 |
|---|---|---|
| P1 | `limit - offset >= sizeof(*head)`（剩 ≥8B 放头部） | -EINVAL |
| P2 | `IS_ALIGNED(offset, 16)` —— **每个记录起点相对当前区域基址必须 16 对齐** | -EINVAL |
| P3 | `__get_user` 读 magic/size（各 u32） | 原样返回 -EFAULT |
| P4 | `limit - offset >= size`（记录整体不出界） | -EINVAL |
| P5 | switch(magic)：见下 | |
| P6 | `size >= sizeof(*head)`（≥8） | -EINVAL |
| P7 | `limit - offset >= size`（冗余复查） | -EINVAL |
| P8 | `offset += size`，进入下一轮 | — |

switch(magic) 分支细则：

| magic | 分支行为 | 拒绝条件（全部 → -EINVAL） |
|---|---|---|
| **0** | terminator：`size==0` → `goto done`（成功）；`size!=0` → invalid | magic=0 但 size≠0 |
| **FPSIMD (0x46508001)** | `system_supports_fpsimd()` 必须；`user->fpsimd` 为空则记录之 | 不支持 FP；重复 fpsimd 记录；`size < 0x210`。**size 允许 > 0x210**（只查下界） |
| **ESR (0x45535201)** | 完全忽略（任何 size，只要过 P4/P6/P7） | —（无专门拒绝） |
| **SVE (0x53564501)** | `system_supports_sve()` 必须；记入 user->sve | 不支持 SVE；重复；`size < 0x10` |
| **EXTRA (0x45585401)** | 见下方专述 | |
| 其他任何值 | `default: goto invalid` | **未知 magic 一律 -EINVAL**（包括厂商私有 magic） |

EXTRA_MAGIC 附加规则（signal.c:404-464）：

1. 只能出现一次（`have_extra_context`）；
2. `size >= sizeof(extra_context)` = 0x20；
3. 当前区域内 extra 记录之后必须还装得下 16B：`limit-offset-size >= TERMINATOR_SIZE`；
4. 紧随其后的 8 字节必须是 dummy terminator `{0,0}`（只读 8B，但位置预留 16B）；
5. `datap` 必须精确等于 `base + offset + size + 16`（数据紧跟 terminator，连续布局）；
6. `datap` 16 对齐、`extra_size` 16 对齐；
7. `extra_size <= sfp + SIGFRAME_MAXSZ(0x10000) - userp`（防超 64K 大帧）；
8. `access_ok(datap, extra_size)`；
9. 之后 `offset=0; limit=extra_size; base=datap`，在新区域继续同一循环——新区域同样必须以 `{0,0}` 结束；
10. 新区域里同样接受 FPSIMD/SVE/ESR（本版本未限制 fpsimd 必须留在 __reserved 内，只有 extra 自身禁止重复）。

**对齐的隐藏推论**：P2 要求每个记录起点 16 对齐，而 `offset += size` 直接累加，因此**实际上每个记录的 size 也必须是 16 的倍数**（如 fpsimd 写 0x210 ✓、0x211 ✗——后者会让下一个记录起点不对齐，即使紧跟 terminator 也是 -EINVAL）。内核生成端用 `round_up(size,16)` 正是为此。

**多记录**：允许顺序放多个不同类型记录（fpsimd + esr + …），但每种至多一个；第一个 `{magic=0,size=0}` 终止解析，其后字节不再看。

### 2.4 restore_fpsimd_context()（signal.c:189-216）

| # | 检查 | errno |
|---|---|---|
| F1 | `ctx->head.magic == FPSIMD_MAGIC`（再读一次） | -EFAULT（读取失败）/ -EINVAL |
| F2 | `ctx->head.size == sizeof(fpsimd_context)` 即 **必须恰好等于 0x210**（注意：这里与 P5 的 `>=` 不同，是严格相等） | -EINVAL |
| F3 | `__copy_from_user(fpsimd.vregs, ctx->vregs, 512)`（0x258–0x457 → 内核栈局部 `user_fpsimd_state`） | -EFAULT |
| F4 | 读 fpsr/fpcr（0x250/0x254） | -EFAULT |
| F5 | `clear_thread_flag(TIF_SVE)`；`fpsimd_update_current_state(&fpsimd)` 加载硬件 | — |

**vregs/fpsr/fpcr 内容完全任意**，无任何位约束，全部原样进硬件 V0-V31/FPSR/FPCR。

### 2.5 valid_user_regs() → valid_native_regs()（kernel/ptrace.c:1888-1951）

```c
int valid_user_regs(struct user_pt_regs *regs, struct task_struct *task)
{
	user_regs_reset_single_step(regs, task); // 强制清/置 SPSR.SS(bit21)
	if (is_compat_thread(...)) return valid_compat_regs(regs);
	return valid_native_regs(regs);
}
static int valid_native_regs(struct user_pt_regs *regs)
{
	regs->pstate &= ~SPSR_EL1_AARCH64_RES0_BITS;
	if (user_mode(regs) && !(pstate & PSR_MODE32_BIT) &&
	    !D && !A && !I && !F) return 1;
	regs->pstate &= NZCV;   // 失败时强制归零为纯 NZCV
	return 0;
}
```

- `SPSR_EL1_AARCH64_RES0_BITS = bits[63:32] | bits[27:26] | bits[23:22] | bits[20:13] | bit5` —— **先静默剥离再校验**（PAN/UAO/IL/TCO 等被无声清除而非拒绝）。
- 通过条件（剥离后）：`M[3:0]==EL0t(0)` && `bit4(MODE32)==0` && `bit9(D)==0` && `bit8(A)==0` && `bit7(I)==0` && `bit6(F)==0`。
- 失败：pstate 被改成只剩 NZCV，返回 0 → S4 err → badframe SIGSEGV。
- `user_regs_reset_single_step`（debug-monitors.c:408-415）：非单步任务强制清 bit21(SS)。

**pstate 位级判定表**（剥离掩码后的存活位）：

| 位 | 掩码值 | 含义 | 剥离？ | 允许保留？ |
|---|---|---|---|---|
| 3:0 | 0xf | M（模式） | 否 | 必须 =0 (EL0t) |
| 4 | 0x10 | MODE32 (AArch32) | 否 | 必须 =0 |
| 5 | 0x20 | res | 是 | — |
| 6 | 0x40 | F | 否 | 必须 =0 |
| 7 | 0x80 | I | 否 | 必须 =0 |
| 8 | 0x100 | A | 否 | 必须 =0 |
| 9 | 0x200 | D | 否 | 必须 =0 |
| 11:10 | 0xc00 | BTYPE | 否 | 任意（BTI 硬件语义照常生效） |
| 12 | 0x1000 | SSBS | 否 | 任意 |
| 20:13 | — | IL/GE 等 | 是 | — |
| 21 | 0x200000 | SS | 否（被 reset_single_step 重写） | — |
| 23:22 | — | UAO/PAN | 是 | — |
| 24 | 0x1000000 | DIT | 否 | 任意 |
| 25 | 0x2000000 | TCO | 否 | 任意 |
| 27:26 | — | res | 是 | — |
| 63:32 | — | res | 是 | — |
| 31:28 | NZCV | 条件标志 | 否 | 任意 |

**最简合法值：`pstate = 0x0000000000000000`。**

---

## 3. 最小合法 sigframe 构造要点

目标缓冲：**4680 字节（0x1248）**，置于 16 字节对齐的用户地址 SP0（R1/R2），整块须可访问。

### 3.1 必须写的字段（唯一集合）

| 绝对偏移 | 写入值 | 原因 |
|---|---|---|
| +0x238 | `u64 0x0000000000000000` | pstate：过 valid_native_regs（NZCV/BTYPE/DIT/SSBS 位可选加） |
| +0x230 | `u64 目标PC` | sigret 跳转地址，无任何校验 |
| +0x228 | `u64 新SP` | 恢复后生效，无校验 |
| +0x248 | `u32 0x46508001` | FPSIMD_MAGIC（LE 字节序 `01 80 50 46`） |
| +0x24C | `u32 0x00000210` | size 必须恰好 0x210 且为 16 倍数（F2 严格相等；P2 对齐） |
| +0x250 | `u32 fpsr`（可 0） | 任意 |
| +0x254 | `u32 fpcr`（可 0） | 任意 |
| +0x258…+0x457 | 512B vregs（可全 0） | 完全任意，直入硬件 |
| +0x458 | `u32 0` | terminator magic |
| +0x45C | `u32 0` | terminator size（两处合计 8 字节零即可满足解析器） |
| +0x0A8 | 8B 信号掩码（可全 0 = 清空掩码） | S1 无条件读取 |

### 3.2 可保持为零 / 完全忽略的字段

- `info` (+0x000, 128B)：rt_sigreturn 路径**从不读取**。
- `uc_flags` (+0x80)、`uc_link` (+0x88)：从不读取。
- `uc_stack` (+0x90, 24B)：会读取但错误被吞；建议 `ss_flags(+0x98) = 2 (SS_DISABLE)` 更干净（全零会触发内部 -ENOMEM，但结果一样被丢弃）。唯一致命情形是这 24 字节不可读（EFAULT）。
- `__unused` (+0x0B0, 120B)、`fault_address` (+0x128)：从不读取。
- `regs[0..30]` (+0x130, 248B)：除语义外任意；x0 会成为 syscall 返回值，x29/x30 仅作数据。
- `__reserved[+0x460 … +0xFFE]`（terminator 之后）：解析器遇到第一个 `{0,0}` 即停，其后不看。
- sigcontext 内对齐填充 (+0x240, 8B)：不看。

### 3.3 常见卡壳点（对应“exploit 卡在校验环节”排查）

1. **__reserved 偏移写成 0x240** —— 正确值 **0x248**（pstate 结束于 0x240，中间还有 8 字节 sigcontext 对齐填充）。可用 `init_user_layout()` 的 `offsetof` 断言自证（signal.c:74）。
2. fpsimd `size` 写成 `>=0x210` 的随意值——restore 时 F2 要求**严格 ==0x210**；且必须是 16 倍数否则链条错位。
3. 漏 terminator 或把 terminator 写成 16B 期望——只需 8B 零，但位置必须在 `0x248 + 0x210 = 0x458`（若 fpsimd size 写大则顺延）。
4. pstate 带了 DAIF（0x3C0）/MODE32(0x10)/非零 mode 位——直接 -EINVAL 路径。
5. 未知 magic（厂商扩展等）出现在 __reserved——default 分支一律 -EINVAL。
6. ESR 记录缺失不是问题（restore 侧可选），但若手工添加需 16B 尺寸对齐。
7. `access_ok` 按 0x1248（非 0x1250）检查；帧尾 8 字节可以贴着映射边界。

---

## 4. vivo / MTK 修改检测（vs 上游 v5.10）

对 `git.kernel.org` 不可达，改用 torvalds/linux v5.10 tag 逐文件 diff（`git diff --no-index`）：

| 文件 | 结论 |
|---|---|
| `include/uapi/asm/sigcontext.h` | **逐字节一致** |
| `include/uapi/asm/ucontext.h` | **逐字节一致** |
| `arch/arm64/kernel/ptrace.c`（valid_*_regs / SPSR RES0 区域） | **一致** |
| `arch/arm64/include/asm/ptrace.h`（valid_user_regs 声明、user_mode 宏） | 一致（仅 INIT_PSTATE_EL1/EL2 宏差异，与 sigreturn 无关） |
| `arch/arm64/kernel/signal.c` | 仅 4 处差异，**全部是主线上游 commit 回移，非厂商加固**：<br>① `#include <asm/syscall.h>` + `do_signal()` 用 `syscall_set_return_value()` 替代直写 regs[0]<br>② `setup_sigframe_layout()` 给 fpsimd 分配包上 `system_supports_fpsimd()`（上游修复：无 FP 硬件平台）<br>③ `_TIF_SIGPENDING \| _TIF_NOTIFY_SIGNAL`（TIF_NOTIFY_SIGNAL 特性回移）<br>④ 删除 `trace_hardirqs_off()`（配套改动） |

**核心结论：`rt_sigreturn` / `restore_sigframe` / `parse_user_sigframe` / `restore_fpsimd_context` / `valid_native_regs` 五个关键函数与上游 v5.10 行为完全相同，不存在 vivo/MTK 的额外校验。exploit 卡住的原因只能出在 sigframe 构造本身（对照 §3.3 排查），而不是厂商魔改。**
