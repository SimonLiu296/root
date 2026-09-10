# PLAN-A: pselect fdset 栈喷射窗口分析（PD2238 / 5.10.246-android12-9）

> 只读分析产物。源码：`src/vivo-mtk510-src/fs/select.c`、`src/vivo-mtk510-src/include/linux/poll.h`；
> 配置：`kernel_config.txt`。目标：确定不转堆分配前提下 pselect 可控栈窗口的上限。

---

## 1. 结论速览

| 项目 | 值 |
|---|---|
| `SELECT_STACK_ALLOC` | **256 字节**（=`FRONTEND_STACK_ALLOC`，poll.h:24-25）|
| 栈内联缓冲 | `long stack_fds[32]` = 256 B（arm64 LP64，select.c:633）|
| 转堆阈值 | `size > sizeof(stack_fds)/6` 即 `size > 42`（整数除法，select.c:654）|
| **最大栈上 nfds** | **320**（每 set `ceil(320/64)=5` longs，`6×40=240 ≤ 256`）|
| nfds ≥ 321 | **静默转 `kvmalloc(6*size)` 堆分配，无任何错误码**（select.c:660-661）|
| 完全可控窗口（nfds=320） | in/out/ex 各 5 words → **15 words = 120 字节** |
| 半可控附加区（res_*） | 再 15 words = 120 B，**只能写 0/1 位图模式，不能写任意值** |

**核心结论：nfds=320 就是硬上限。"增大 nfds 扩大窗口"这条路线被源码直接证伪——超过 320 后 fdset 整体搬进堆，栈上一个字节都不再落地，而且系统调用照常成功返回。**

---

## 2. 关键代码摘录

### 2.1 常量定义 — `include/linux/poll.h:17-28`

```c
/* ~832 bytes of stack space used max in sys_select/sys_poll before allocating
   additional memory. */
#ifdef __clang__
#define MAX_STACK_ALLOC 768
#else
#define MAX_STACK_ALLOC 832
#endif
#define FRONTEND_STACK_ALLOC	256          // :24
#define SELECT_STACK_ALLOC	FRONTEND_STACK_ALLOC  // :25
#define POLL_STACK_ALLOC	FRONTEND_STACK_ALLOC
```

### 2.2 位图尺寸宏 — `fs/select.c:373-383`

```c
typedef struct {
	unsigned long *in, *out, *ex;
	unsigned long *res_in, *res_out, *res_ex;
} fd_set_bits;

#define FDS_BITPERLONG	(8*sizeof(long))                       // :381
#define FDS_LONGS(nr)	(((nr)+FDS_BITPERLONG-1)/FDS_BITPERLONG) // :382
#define FDS_BYTES(nr)	(FDS_LONGS(nr)*sizeof(long))           // :383
```

arm64 内核态 `sizeof(long)==8`：`FDS_LONGS(n)=ceil(n/64)`，`FDS_BYTES(n)=ceil(n/64)*8`。

### 2.3 分配逻辑 — `fs/select.c:624-670`

```c
int core_sys_select(int n, fd_set __user *inp, fd_set __user *outp,
			   fd_set __user *exp, struct timespec64 *end_time)
{
	fd_set_bits fds;
	void *bits;
	int ret, max_fds;
	size_t size, alloc_size;
	struct fdtable *fdt;
	/* Allocate small arguments on the stack to save memory and be faster */
	long stack_fds[SELECT_STACK_ALLOC/sizeof(long)];        // :633 → long[32]，256B

	ret = -EINVAL;
	if (n < 0)
		goto out_nofds;

	/* max_fds can increase, so grab it once to avoid race */
	rcu_read_lock();
	fdt = files_fdtable(current->files);
	max_fds = fdt->max_fds;
	rcu_read_unlock();
	if (n > max_fds)
		n = max_fds;                                     // :644-645 ← 静默截断！

	size = FDS_BYTES(n);                                 // :652 单个位图字节数
	bits = stack_fds;
	if (size > sizeof(stack_fds) / 6) {                  // :654 → size > 42 转堆
		ret = -ENOMEM;
		if (size > (SIZE_MAX / 6))
			goto out_nofds;
		alloc_size = 6 * size;
		bits = kvmalloc(alloc_size, GFP_KERNEL);         // :661 ← 堆，无提示
		if (!bits)
			goto out_nofds;
	}
	fds.in      = bits;                                  // :665 地址升序排布
	fds.out     = bits +   size;                         // :666
	fds.ex      = bits + 2*size;                         // :667
	fds.res_in  = bits + 3*size;                         // :668
	fds.res_out = bits + 4*size;                         // :669
	fds.res_ex  = bits + 5*size;                         // :670
```

### 2.4 用户数据落栈与 res 区清零 — `fs/select.c:672-678, 388-397`

```c
	if ((ret = get_fd_set(n, inp, fds.in)) ||            // :672 copy_from_user → 栈
	    (ret = get_fd_set(n, outp, fds.out)) ||
	    (ret = get_fd_set(n, exp, fds.ex)))
	...
	zero_fd_set(n, fds.res_in);                          // :676 res 区先清零
	zero_fd_set(n, fds.res_out);
	zero_fd_set(n, fds.res_ex);

	ret = do_select(n, &fds, end_time);                  // :680
```

```c
static inline int get_fd_set(unsigned long nr, void __user *ufdset,
			     unsigned long *fdset)
{
	nr = FDS_BYTES(nr);
	if (ufdset)
		return copy_from_user(fdset, ufdset, nr) ? -EFAULT : 0;  // :393
	memset(fdset, 0, nr);
	return 0;
}
```

### 2.5 res 区只有 ready 位才置位 — `do_select()`，`fs/select.c:569-574`

```c
			if (res_in)
				*rinp = res_in;              // 仅当该 fd 在 in 中置位
			if (res_out)                         // 且 vfs_poll 报告就绪
				*routp = res_out;
			if (res_ex)
				*rexp = res_ex;
```

### 2.6 BADF 校验（发生在 copy 之后）— `fs/select.c:446-447`

```c
		if (set & ~*open_fds)
			return -EBADF;                   // 置位 fd 必须真实打开
```

copy 已在 `core_sys_select:672` 完成，EBADF 时数据仍在栈上，但 `do_select` 立即返回，
不会再压入 poll_wqueues 等深帧。

### 2.7 compat 路径（32 位 app）— `fs/select.c:1193-1226`

`compat_core_sys_select` 使用同一个 256 B 栈缓冲和同一阈值（:1201、:1221），
内核侧仍以 64-bit long 为单位展开（`compat_get_bitmap`），**窗口大小与 64 位调用方完全一致**。

---

## 3. nfds 上限计算过程

阈值：`sizeof(stack_fds)/6 = 256/6 = 41.67 → 整数除法 = 42`。
转堆条件：`size > 42`。`size` 是 8 的倍数，故栈内联 ⇔ `size ≤ 40` ⇔ `ceil(n/64) ≤ 5` ⇔ `n ≤ 320`。

| nfds | FDS_LONGS | 单 set size | 6×size 总占用 | vs 42 阈值 | 分配方式 |
|---:|---:|---:|---:|---|---|
| 1–64 | 1 | 8 | 48 | 栈 | 栈（浪费严重）|
| 192–256 | 4 | 32 | 192 | 栈 | 栈 |
| **257–320** | **5** | **40** | **240** | **40 ≤ 42 ✓** | **栈（最优档）** |
| 321–384 | 6 | 48 | 288 | 48 > 42 ✗ | **kvmalloc 堆** |
| 385–448 | 7 | 56 | 336 | ✗ | 堆 |

- n=320 时占满 `stack_fds` 前 240 B，数组尾部剩余 16 B 保持旧残留（不可控，无意义）。
- **不存在任何中间档**：n 从 320 → 321，窗口从"栈上 240B"瞬间变为"堆上 288B"，栈上归零。

---

## 4. fdset 内存布局（文字版，nfds=320）

```
低地址 ▼（ARM64 全递减栈，越往下越是新压入的帧）

 ┌──────────────────────────────────┐ bits+0x000  ← stack_fds 基址
 │ fds.in    [w0 w1 w2 w3 w4] 40B   │  copy_from_user(inp)  ★任意值可控
 ├──────────────────────────────────┤ bits+0x028
 │ fds.out   [w0 w1 w2 w3 w4] 40B   │  copy_from_user(outp) ★任意值可控
 ├──────────────────────────────────┤ bits+0x050
 │ fds.ex    [w0 w1 w2 w3 w4] 40B   │  copy_from_user(exp)  ★任意值可控
 ├──────────────────────────────────┤ bits+0x078
 │ fds.res_in   [5 longs]           │  先 memset 0；仅"in 置位 ∧ 该 fd 就绪"
 ├──────────────────────────────────┤ bits+0x0A0        的位写 1 → 只有 0/1 位图模式
 │ fds.res_out  [5 longs]           │  同上（out 掩码）
 ├──────────────────────────────────┤ bits+0x0C8
 │ fds.res_ex   [5 longs]           │  同上（ex 掩码，需 EPOLLPRI）
 ├──────────────────────────────────┤ bits+0x0F0
 │ （stack_fds 尾部 16B 旧残留）      │  不可控
 └──────────────────────────────────┘ bits+0x100 = stack_fds 末尾

 高地址 ▲（syscall 入口链 el0_svc → __se_sys_pselect6 → do_pselect 的帧在此之上）
```

要点：

1. **子位图地址序**：`in < out < ex < res_in < res_out < res_ex`，严格升序、无间隙
   （各 sub-bitmap 大小均为 `size`，天然 8 字节对齐；数组基址至少 8B 对齐，编译器常给 16B）。
2. **相对帧的方向**：ARM64 栈向低地址生长。`core_sys_select` 的帧位于 pselect 入口链之下；
   其被调函数（`do_select` 及其局部 `poll_wqueues` ≈ 数百字节）位于 fdset 之下的更低地址。
   因此：
   - 可控内容（in/out/ex，120B 任意值）只能覆盖 `[bits, bits+0x78)`；
   - 把 res 区"点亮"（预置就绪 fd）最多把**覆盖范围**向上扩到 `bits+0xF0`，
     但那 120B **只能呈现稀疏 0/1 位图**，塞不下 fake waiter 里的指针类字段；
   - **比 `bits` 更低的地址，pselect 原语永远够不到。**

---

## 5. 操作约束清单（实测前核对）

1. **nfds 静默钳制**（select.c:644-45）：`n` 先被截到 `fdt->max_fds`。若当前 fd 表小于
   320，实际窗口会更小且无报错。先打开 ≥320 个 fd（fd 表只增不减），推荐直接保持
   320 个 eventfd 打开。
2. **EBADF 规则**（select.c:446）：所有置位的 fd 号必须真实打开，否则整个调用
   `-EBADF` 返回（数据虽已落栈，但不进 do_select 深帧，栈深度剖面改变）。
   建议 0..319 全部真实打开并置位。
3. **nfds>320 行为警告**：`kvmalloc(6*size)` 走 slab/vmalloc 堆，**无错误返回**。
   如果实验里"调大 nfds 后栈上反而什么都没有了"，就是这个原因，不是参数没生效。
4. **res 区点亮方法**（如确需位图填充）：res_in/res_out 用 eventfd 即可
   （预先 write → 可读；空 eventfd → 恒可写）；res_ex 需要 `EPOLLPRI`
   （TCP loopback + `MSG_OOB`）。注意 res 区只能产生 0/1 模式，见第 6 节。
5. **配置核对**（kernel_config.txt）：
   - `CONFIG_VMAP_STACK=y`：线程栈 vmalloc 化，悬垂指针是同线程栈内偏移，不受影响；
   - `CONFIG_STACKPROTECTOR_STRONG=y`：帧顶 canary，不影响 fdset 数据区；
   - `CONFIG_SHADOW_CALL_STACK=y` / `CONFIG_CFI_CLANG=y`：与本数据型原语无关；
   - `CONFIG_HARDENED_USERCOPY=y`：40B/次的栈内 copy_from_user 合法，无拦截；
   - `CONFIG_FRAME_WARN=2048`：仅编译期告警；
   - `CONFIG_KASAN_HW_TAGS=y`：依 docs/PD2238-TARGET-CHECKLIST.md 判定为 defconfig
     残留（D8200 无 MTE，运行时不生效），且 HW-TAGS 不给栈上数组加红区。
   - `CONFIG_COMPAT=y`：32 位 app 走 compat_core_sys_select，窗口结论不变（§2.7）。

---

## 6. 对 PLAN-A 的影响

1. **"增大 nfds"路线证伪。** 120B 任意值窗口是本内核的硬上限，实测 +0x38 读到
   `0xdc0` 残留并非 nfds 不够大，而是目标槽位根本不在（也无法进入）fdset 覆盖段。
2. **下一步先测相对位置再选路线：**
   - 若目标槽位落在 `[bits+0x78, bits+0xF0)`（res 区段）：可用"点亮 res 位"扩大
     覆盖，但 fake waiter 的指针字段无法用 0/1 位图表达——仅当 walk 容忍这些字段
     为稀疏位模式时才可行；
   - 若目标槽位在 `bits` 之下（futex 链比 pselect 链走得更深，最常见情形）或
     `bits+0xF0` 之上：**pselect fdset 原语彻底出局**，需要换同一线程上更深的
     栈驻留原语，或调整 futex 阶段的调用链深度让旧 waiter 落点上移/下移到
     `[bits, bits+0xF0)` 窗口内。
3. 推荐立即动作：nfds 固定 **320**，用可观测手段（crash dump 中 sp 与悬垂指针差值）
   标定 `(old_waiter_slot − bits)` 相对偏移的符号与量级，据此在第 6.2 的分支里二选一。
