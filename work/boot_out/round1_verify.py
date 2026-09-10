# -*- coding: utf-8 -*-
"""Round-1 GhostLock offset verification.
Independent extraction from kallsyms.txt + output.elf vs CVE-2026-43499 target.h schema.
"""
from __future__ import print_function
import hashlib, json, os, re, sys, time
from collections import OrderedDict

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
BOOT = os.path.join(ROOT, "work", "boot_out")
OTA = os.path.join(ROOT, "work", "ota_out")
CVE = os.path.join(ROOT, "src", "CyberMeowfia-main", "IonStack", "CVE-2026-43499")
TOKAY = os.path.join(CVE, "exploit", "src", "targets", "tokay-CP2A.260605.012", "target.h")
DRAFT = os.path.join(BOOT, "target_pd2238_draft.h")
ARIST = os.path.join(ROOT, "src", "aristotle-root", "src", "targets",
                     "pd2238-16.3.15.0.W10", "target.h")
OUT_JSON = os.path.join(BOOT, "round1_verify.json")
OUT_TXT = os.path.join(BOOT, "round1_verify.txt")

sys.path.insert(0, os.path.join(ROOT, "tools", "python", "Lib", "site-packages"))
from elftools.elf.elffile import ELFFile  # noqa: E402


def sha256(path, limit=None):
    h = hashlib.sha256()
    n = 0
    with open(path, "rb") as f:
        while True:
            chunk = f.read(1024 * 1024)
            if not chunk:
                break
            h.update(chunk)
            n += len(chunk)
            if limit and n >= limit:
                break
    return h.hexdigest(), os.path.getsize(path)


def file_magic(path, n=16):
    with open(path, "rb") as f:
        b = f.read(n)
    return b.hex()


def linux_banner(path):
    with open(path, "rb") as f:
        data = f.read()
    m = re.search(br"Linux version [^\x00]{10,240}", data)
    if not m:
        return None
    return m.group(0).decode("latin1", "replace")


def parse_kallsyms(path):
    by_name = {}
    rows = []
    with open(path, "r", encoding="utf-8", errors="replace") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            parts = line.split()
            if len(parts) < 3:
                continue
            addr = int(parts[0], 16)
            typ = parts[1]
            name = parts[2]
            rows.append((addr, typ, name))
            by_name.setdefault(name, []).append((addr, typ))
    return rows, by_name


def parse_defines(path):
    out = OrderedDict()
    if not os.path.isfile(path):
        return out
    with open(path, "r", encoding="utf-8", errors="replace") as f:
        text = f.read()
    for m in re.finditer(r"#define\s+(\w+)\s+(.+)", text):
        name, val = m.group(1), m.group(2).strip()
        val = val.split("/*")[0].strip()
        out[name] = val
    return out


def parse_hex_ull(s):
    if s is None:
        return None
    s = s.strip().rstrip("ULL").rstrip("ull").rstrip("UL").rstrip("L")
    if s.startswith("(") or s.startswith("KIMAGE") or s.startswith("INIT_") or s.startswith("CONFIGFS_"):
        return None
    try:
        if s.startswith("0x") or s.startswith("0X"):
            return int(s, 16)
        if re.fullmatch(r"-?\d+", s):
            return int(s, 10)
    except ValueError:
        return None
    return None


def read_va(elf, va, n):
    for seg in elf.iter_segments():
        if seg["p_type"] != "PT_LOAD":
            continue
        va_s = seg["p_vaddr"]
        va_e = va_s + seg["p_filesz"]
        if va_s <= va and va + n <= va_e:
            data = seg.data()
            off = va - va_s
            return data[off:off + n]
    return None


def u64le(b, off=0):
    return int.from_bytes(b[off:off + 8], "little")


def lookup(ks, name):
    hits = ks.get(name, [])
    if not hits:
        return None
    return hits[0][0]


def lookup_any(ks, names):
    for n in names:
        a = lookup(ks, n)
        if a is not None:
            return n, a
    return None, None


def main():
    report = OrderedDict()
    report["generated_at"] = time.strftime("%Y-%m-%d %H:%M:%S")
    report["root"] = ROOT

    # --- inventory ---
    inv = OrderedDict()
    for label, path in [
        ("ota_boot.img", os.path.join(OTA, "boot.img")),
        ("boot_boot.img", os.path.join(BOOT, "boot.img")),
        ("kernel", os.path.join(BOOT, "kernel")),
        ("Image", os.path.join(BOOT, "Image")),
        ("output.elf", os.path.join(BOOT, "output.elf")),
        ("kallsyms.txt", os.path.join(BOOT, "kallsyms.txt")),
        ("ramdisk.cpio", os.path.join(BOOT, "ramdisk.cpio")),
    ]:
        if os.path.isfile(path):
            digest, size = sha256(path)
            inv[label] = {
                "path": path,
                "size": size,
                "sha256": digest,
                "magic": file_magic(path),
            }
        else:
            inv[label] = {"path": path, "missing": True}
    report["inventory"] = inv

    boot_same = (
        "ota_boot.img" in inv and "boot_boot.img" in inv
        and not inv["ota_boot.img"].get("missing")
        and inv["ota_boot.img"]["sha256"] == inv["boot_boot.img"]["sha256"]
    )
    report["boot_img_ota_equals_boot_out"] = boot_same
    kernel_eq_image = (
        not inv["kernel"].get("missing") and not inv["Image"].get("missing")
        and inv["kernel"]["sha256"] == inv["Image"]["sha256"]
    )
    report["kernel_equals_Image"] = kernel_eq_image
    report["linux_banner"] = linux_banner(os.path.join(BOOT, "Image")) if os.path.isfile(os.path.join(BOOT, "Image")) else None

    ota_files = []
    if os.path.isdir(OTA):
        for n in sorted(os.listdir(OTA)):
            p = os.path.join(OTA, n)
            if os.path.isfile(p):
                ota_files.append({"name": n, "size": os.path.getsize(p)})
    report["ota_out_files"] = ota_files

    cve_ok = os.path.isdir(CVE)
    report["cve_tree"] = {
        "present": cve_ok,
        "path": CVE,
        "has_exploit_src": os.path.isfile(os.path.join(CVE, "exploit", "src", "main.c")),
        "has_offset_h": os.path.isfile(os.path.join(CVE, "exploit", "src", "offset.h")),
        "has_poc": os.path.isfile(os.path.join(CVE, "poc", "poc.c")),
        "has_tokay_target": os.path.isfile(TOKAY),
        "git_dir": os.path.isdir(os.path.join(ROOT, "src", "CyberMeowfia-main", ".git")),
        "zip": os.path.isfile(os.path.join(ROOT, "src", "CyberMeowfia.zip")),
    }

    # --- kallsyms ---
    ks_path = os.path.join(BOOT, "kallsyms.txt")
    rows, by_name = parse_kallsyms(ks_path)
    text = lookup(by_name, "_text")
    stext = lookup(by_name, "_stext")
    etext = lookup(by_name, "_etext")
    end = lookup(by_name, "_end")
    report["kallsyms"] = {
        "count": len(rows),
        "unique_names": len(by_name),
        "_text": None if text is None else hex(text),
        "_stext": None if stext is None else hex(stext),
        "_etext": None if etext is None else hex(etext),
        "_end": None if end is None else hex(end),
        "first": ["%x %s %s" % (a, t, n) for a, t, n in rows[:3]],
        "last": ["%x %s %s" % (a, t, n) for a, t, n in rows[-3:]],
    }
    if text is None:
        raise SystemExit("_text missing from kallsyms")
    KBASE = text

    # GhostLock schema symbols (CVE target.h + 5.10 aliases)
    schema = OrderedDict([
        ("ASHMEM_MISC", ["ashmem_misc"]),
        ("ASHMEM_FOPS", ["ashmem_fops"]),
        ("ASHMEM_IOCTL", ["ashmem_ioctl"]),
        ("ASHMEM_COMPAT_IOCTL", ["compat_ashmem_ioctl", "ashmem_compat_ioctl"]),
        ("ASHMEM_MMAP", ["ashmem_mmap"]),
        ("ASHMEM_OPEN", ["ashmem_open"]),
        ("ASHMEM_RELEASE", ["ashmem_release"]),
        ("ASHMEM_SHOW_FDINFO", ["ashmem_show_fdinfo"]),
        ("ASHMEM_READ_ITER", ["ashmem_read_iter"]),
        ("CONFIGFS_READ_ITER", ["configfs_read_iter"]),
        ("CONFIGFS_BIN_WRITE_ITER", ["configfs_bin_write_iter"]),
        ("CONFIGFS_READ_BIN_FILE", ["configfs_read_bin_file"]),
        ("CONFIGFS_WRITE_BIN_FILE", ["configfs_write_bin_file"]),
        ("CONFIGFS_BIN_FOPS", ["configfs_bin_file_operations"]),
        ("CONFIGFS_FILE_FOPS", ["configfs_file_operations"]),
        ("COPY_SPLICE_READ", ["copy_splice_read", "generic_file_splice_read"]),
        ("NOOP_LLSEEK", ["noop_llseek"]),
        ("INIT_TASK", ["init_task"]),
        ("INIT_UTS_NS", ["init_uts_ns"]),
        ("EMPTY_ZERO_PAGE", ["empty_zero_page"]),
        ("ROOT_TASK_GROUP", ["root_task_group"]),
        ("SELINUX_BLOB_SIZES", ["selinux_blob_sizes"]),
        ("SELINUX_ENFORCING", ["selinux_enforcing"]),
        ("SELINUX_STATE", ["selinux_state"]),
        ("SECURITY_HOOK_HEADS", ["security_hook_heads"]),
        ("KMALLOC_CACHES", ["kmalloc_caches"]),
        ("ANON_PIPE_BUF_OPS", ["anon_pipe_buf_ops"]),
        ("INIT_NET", ["init_net"]),
        ("INIT_NSPROXY", ["init_nsproxy"]),
        ("SYSCTL_BOOTID", ["sysctl_bootid"]),
        ("RANDOM_TABLE", ["random_table"]),
        ("NFULNL_LOGGER", ["nfulnl_logger"]),
        ("LOGGERS", ["loggers"]),
        ("NFULNL_LOG_PACKET", ["nfulnl_log_packet"]),
        ("RT_MUTEX_START_PROXY_LOCK", ["rt_mutex_start_proxy_lock", "__rt_mutex_start_proxy_lock"]),
        ("REMOVE_WAITER", ["remove_waiter"]),
        ("FUTEX_REQUEUE_PI", ["futex_requeue_pi", "futex_proxy_trylock_atomic"]),
        ("SYS_PSELECT6", ["__arm64_sys_pselect6", "sys_pselect6"]),
        ("SYS_FUTEX", ["__arm64_sys_futex", "sys_futex"]),
        ("WORKER_THREAD", ["worker_thread"]),
    ])

    extracted = OrderedDict()
    missing = []
    aliases_used = OrderedDict()
    for key, names in schema.items():
        hit_name, addr = lookup_any(by_name, names)
        if addr is None:
            missing.append(key)
            extracted[key] = None
        else:
            aliases_used[key] = hit_name
            extracted[key] = {
                "symbol": hit_name,
                "va": hex(addr),
                "off": hex(addr - KBASE),
                "off_int": addr - KBASE,
                "type": by_name[hit_name][0][1],
            }
    report["extracted_symbols"] = extracted
    report["missing_symbols"] = missing
    report["alias_map"] = aliases_used
    report["kimage_text_base"] = hex(KBASE)

    # extra name dumps for ambiguous symbols
    extra = {}
    for pat in ["loggers", "nfulnl", "bootid", "boot_id", "configfs", "ashmem"]:
        extra[pat] = []
        for name, hits in by_name.items():
            if pat in name.lower() and len(extra[pat]) < 40:
                extra[pat].append({"name": name, "va": hex(hits[0][0]), "off": hex(hits[0][0] - KBASE), "type": hits[0][1]})
    report["symbol_name_search"] = extra

    # --- ELF ---
    elf_info = OrderedDict()
    elf_path = os.path.join(BOOT, "output.elf")
    with open(elf_path, "rb") as f:
        elf = ELFFile(f)
        elf_info["class"] = elf.elfclass
        elf_info["machine"] = elf["e_machine"]
        elf_info["type"] = elf["e_type"]
        elf_info["entry"] = hex(elf["e_entry"])
        segs = []
        for i, seg in enumerate(elf.iter_segments()):
            segs.append({
                "i": i,
                "type": seg["p_type"],
                "vaddr": hex(seg["p_vaddr"]),
                "paddr": hex(seg["p_paddr"]),
                "filesz": hex(seg["p_filesz"]),
                "memsz": hex(seg["p_memsz"]),
                "flags": int(seg["p_flags"]),
            })
        elf_info["segments"] = segs
        # ELF symbol table (vmlinux-to-elf usually embeds kallsyms)
        elf_syms = {}
        for sec in elf.iter_sections():
            if sec.name in (".symtab", ".dynsym"):
                n = 0
                for s in sec.iter_symbols():
                    n += 1
                    if s.name in ("_text", "init_task", "ashmem_fops", "ashmem_misc",
                                  "sysctl_bootid", "loggers", "nfulnl_logger",
                                  "configfs_bin_file_operations"):
                        elf_syms[s.name] = hex(s["st_value"])
                elf_info["symtab_%s_count" % sec.name.strip(".")] = n
        elf_info["selected_elf_syms"] = elf_syms

        dumps = OrderedDict()

        def dump_label(label, va, n):
            raw = read_va(elf, va, n)
            if raw is None:
                dumps[label] = {"va": hex(va), "unreadable": True}
                return
            q = [hex(u64le(raw, i)) for i in range(0, len(raw) - 7, 8)]
            dumps[label] = {"va": hex(va), "qwords": q, "hex": raw.hex()}

        if extracted.get("ASHMEM_MISC"):
            misc_va = int(extracted["ASHMEM_MISC"]["va"], 16)
            dump_label("ashmem_misc", misc_va, 32)
        if extracted.get("ASHMEM_FOPS"):
            dump_label("ashmem_fops", int(extracted["ASHMEM_FOPS"]["va"], 16), 64)
        if extracted.get("CONFIGFS_BIN_FOPS"):
            dump_label("configfs_bin_file_operations", int(extracted["CONFIGFS_BIN_FOPS"]["va"], 16), 64)
        elif extracted.get("CONFIGFS_READ_BIN_FILE"):
            # table hunt is later
            pass
        if extracted.get("LOGGERS"):
            dump_label("loggers", int(extracted["LOGGERS"]["va"], 16), 64)
        if extracted.get("NFULNL_LOGGER"):
            dump_label("nfulnl_logger", int(extracted["NFULNL_LOGGER"]["va"], 16), 32)
        if extracted.get("SYSCTL_BOOTID"):
            dump_label("sysctl_bootid", int(extracted["SYSCTL_BOOTID"]["va"], 16), 16)
        if extracted.get("INIT_TASK"):
            dump_label("init_task_head", int(extracted["INIT_TASK"]["va"], 16), 16)
        if extracted.get("INIT_UTS_NS"):
            dump_label("init_uts_ns", int(extracted["INIT_UTS_NS"]["va"], 16), 32)

        report["elf"] = elf_info
        report["elf_dumps"] = dumps

        # Cross-check: ashmem_misc.fops should point at ashmem_fops
        ashmem_fops_ptr_ok = None
        ashmem_misc_fops_off = None
        if extracted.get("ASHMEM_MISC") and extracted.get("ASHMEM_FOPS"):
            misc_va = int(extracted["ASHMEM_MISC"]["va"], 16)
            raw = read_va(elf, misc_va, 32)
            if raw is not None:
                fops_ptr = u64le(raw, 16)  # miscdevice.fops at +0x10
                ashmem_misc_fops_off = (misc_va + 0x10) - KBASE
                expected = int(extracted["ASHMEM_FOPS"]["va"], 16)
                ashmem_fops_ptr_ok = (fops_ptr == expected)
                report["ashmem_misc_fops_ptr"] = {
                    "ptr": hex(fops_ptr),
                    "expected_ashmem_fops": hex(expected),
                    "match": ashmem_fops_ptr_ok,
                    "ASHMEM_MISC_FOPS_OFF": hex(ashmem_misc_fops_off),
                }

        # Cross-check configfs bin fops read/write slots
        cfg_bin = OrderedDict()
        if extracted.get("CONFIGFS_BIN_FOPS"):
            tva = int(extracted["CONFIGFS_BIN_FOPS"]["va"], 16)
            raw = read_va(elf, tva, 0x30)
            if raw is not None:
                # 5.10 file_operations: read=+0x10 write=+0x18 read_iter=+0x20 write_iter=+0x28
                cfg_bin["table"] = hex(tva)
                cfg_bin["read"] = hex(u64le(raw, 0x10))
                cfg_bin["write"] = hex(u64le(raw, 0x18))
                cfg_bin["read_iter"] = hex(u64le(raw, 0x20))
                cfg_bin["write_iter"] = hex(u64le(raw, 0x28))
                if extracted.get("CONFIGFS_READ_BIN_FILE"):
                    cfg_bin["read_matches_configfs_read_bin_file"] = (
                        u64le(raw, 0x10) == int(extracted["CONFIGFS_READ_BIN_FILE"]["va"], 16)
                    )
                if extracted.get("CONFIGFS_WRITE_BIN_FILE"):
                    cfg_bin["write_matches_configfs_write_bin_file"] = (
                        u64le(raw, 0x18) == int(extracted["CONFIGFS_WRITE_BIN_FILE"]["va"], 16)
                    )
                # CFI jump tables: pointer may land on .cfi_jt not the function body
                if extracted.get("CONFIGFS_READ_BIN_FILE"):
                    rva = int(extracted["CONFIGFS_READ_BIN_FILE"]["va"], 16)
                    cfg_bin["read_minus_func"] = hex(u64le(raw, 0x10) - rva)
                if extracted.get("CONFIGFS_WRITE_BIN_FILE"):
                    wva = int(extracted["CONFIGFS_WRITE_BIN_FILE"]["va"], 16)
                    cfg_bin["write_minus_func"] = hex(u64le(raw, 0x18) - wva)
        report["configfs_bin_fops_check"] = cfg_bin

        # init_uts_ns name "Linux" typically at +0x00 or through name field
        if extracted.get("INIT_UTS_NS"):
            raw = read_va(elf, int(extracted["INIT_UTS_NS"]["va"], 16), 128)
            if raw:
                report["init_uts_ns_ascii"] = "".join(chr(b) if 32 <= b < 127 else "." for b in raw[:80])

        # init_task comm at typical 5.10 offset 0x790
        if extracted.get("INIT_TASK"):
            iva = int(extracted["INIT_TASK"]["va"], 16)
            comm_candidates = {}
            for off in (0x790, 0x848, 0x570, 0x738, 0x740, 0x750):
                raw = read_va(elf, iva + off, 16)
                if raw:
                    s = raw.split(b"\x00", 1)[0]
                    comm_candidates[hex(off)] = s.decode("latin1", "replace")
            report["init_task_comm_scan"] = comm_candidates

    # --- draft / tokay / aristotle ---
    def load_off_map(path):
        defs = parse_defines(path)
        m = OrderedDict()
        for k, v in defs.items():
            hv = parse_hex_ull(v)
            if hv is not None:
                m[k] = hv
            else:
                m[k] = v
        return m, defs

    tokay_map, _ = load_off_map(TOKAY)
    draft_map, _ = load_off_map(DRAFT)
    arist_map, _ = load_off_map(ARIST)

    # Build PD2238 recommended symbol offsets
    rec = OrderedDict()
    rec["KIMAGE_TEXT_BASE"] = KBASE
    if ashmem_misc_fops_off is not None:
        rec["ASHMEM_MISC_FOPS_OFF"] = ashmem_misc_fops_off
    for k, field in [
        ("ASHMEM_FOPS", "ASHMEM_FOPS_OFF"),
        ("ASHMEM_IOCTL", "ASHMEM_IOCTL_OFF"),
        ("ASHMEM_COMPAT_IOCTL", "ASHMEM_COMPAT_IOCTL_OFF"),
        ("ASHMEM_MMAP", "ASHMEM_MMAP_OFF"),
        ("ASHMEM_OPEN", "ASHMEM_OPEN_OFF"),
        ("ASHMEM_RELEASE", "ASHMEM_RELEASE_OFF"),
        ("ASHMEM_SHOW_FDINFO", "ASHMEM_SHOW_FDINFO_OFF"),
        ("COPY_SPLICE_READ", "COPY_SPLICE_READ_OFF"),
        ("NOOP_LLSEEK", "NOOP_LLSEEK_OFF"),
        ("INIT_TASK", "INIT_TASK_OFF"),
        ("INIT_UTS_NS", "INIT_UTS_NS_OFF"),
        ("EMPTY_ZERO_PAGE", "EMPTY_ZERO_PAGE_OFF"),
        ("ROOT_TASK_GROUP", "ROOT_TASK_GROUP_OFF"),
        ("SELINUX_BLOB_SIZES", "SELINUX_BLOB_SIZES_OFF"),
        ("SELINUX_ENFORCING", "SELINUX_ENFORCING_OFF"),
        ("SECURITY_HOOK_HEADS", "SECURITY_HOOK_HEADS_OFF"),
        ("KMALLOC_CACHES", "KMALLOC_CACHES_OFF"),
        ("ANON_PIPE_BUF_OPS", "ANON_PIPE_BUF_OPS_OFF"),
        ("INIT_NET", "INIT_NET_OFF"),
        ("INIT_NSPROXY", "INIT_NSPROXY_OFF"),
        ("SYSCTL_BOOTID", "SYSCTL_BOOTID_OFF"),
        ("NFULNL_LOGGER", "SLIDE_NFULNL_LOGGER_OFF"),
        ("LOGGERS", "SLIDE_LOGGERS_BASE_OFF"),
    ]:
        if extracted.get(k):
            rec[field] = extracted[k]["off_int"]

    # 5.10 configfs uses .read/.write not *_iter — recommended exploit slots
    if extracted.get("CONFIGFS_READ_BIN_FILE"):
        rec["CONFIGFS_READ_BIN_OFF"] = extracted["CONFIGFS_READ_BIN_FILE"]["off_int"]
        rec["CONFIGFS_READ_ITER_OFF"] = extracted["CONFIGFS_READ_BIN_FILE"]["off_int"]
    if extracted.get("CONFIGFS_WRITE_BIN_FILE"):
        rec["CONFIGFS_WRITE_BIN_OFF"] = extracted["CONFIGFS_WRITE_BIN_FILE"]["off_int"]
        rec["CONFIGFS_BIN_WRITE_ITER_OFF"] = extracted["CONFIGFS_WRITE_BIN_FILE"]["off_int"]
    # If CFI JT is what the fops table actually points to, prefer table pointers
    if cfg_bin.get("read") and cfg_bin["read"].startswith("0x"):
        rec["CONFIGFS_READ_BIN_TABLE_PTR_OFF"] = int(cfg_bin["read"], 16) - KBASE
    if cfg_bin.get("write") and cfg_bin["write"].startswith("0x"):
        rec["CONFIGFS_WRITE_BIN_TABLE_PTR_OFF"] = int(cfg_bin["write"], 16) - KBASE
    if extracted.get("LOGGERS"):
        rec["SLIDE_LOGGERS_0_1_OFF"] = extracted["LOGGERS"]["off_int"] + 8  # loggers[0][1]
    rec["SLIDE_SYSCTL_BOOTID_OFF"] = rec.get("SYSCTL_BOOTID_OFF")
    rec["SLIDE_RANDOM_BOOT_ID_DATA_OFF"] = rec.get("SYSCTL_BOOTID_OFF")
    rec["SLIDE_INIT_TASK_OFF"] = rec.get("INIT_TASK_OFF")
    rec["SLIDE_ROOT_TASK_GROUP_OFF"] = rec.get("ROOT_TASK_GROUP_OFF")
    rec["P0_PAGE_OFFSET"] = 0xFFFFFF8000000000
    rec["P0_PHYS_OFFSET"] = 0x40000000
    rec["FOPS_READ_OFF"] = 0x10
    rec["FOPS_WRITE_OFF"] = 0x18
    rec["FOPS_READ_ITER_OFF"] = 0x20
    rec["FOPS_WRITE_ITER_OFF"] = 0x28
    rec["FOPS_IOCTL_OFF"] = 0x50
    rec["FOPS_COMPAT_IOCTL_OFF"] = 0x58
    rec["FOPS_MMAP_OFF"] = 0x60
    rec["FOPS_OPEN_OFF"] = 0x70
    rec["FOPS_RELEASE_OFF"] = 0x80
    rec["FOPS_SPLICE_WRITE_OFF"] = 0xC0
    rec["FOPS_SPLICE_READ_OFF"] = 0xC8
    rec["FOPS_SHOW_FDINFO_OFF"] = 0xE0
    rec["WAITER_TREE_ENTRY_OFF"] = 0x00
    rec["WAITER_PI_TREE_ENTRY_OFF"] = 0x18
    rec["WAITER_TASK_OFF"] = 0x30
    rec["WAITER_LOCK_OFF"] = 0x38
    rec["WAITER_PRIO_OFF"] = 0x40
    rec["WAITER_DEADLINE_OFF"] = 0x48
    rec["CFG_PAGE_OFF"] = 0x10

    report["recommended_offsets"] = {k: (hex(v) if isinstance(v, int) else v) for k, v in rec.items()}

    # comparison tables
    def cmp_row(macro, extracted_key=None, rec_key=None):
        tokay_v = tokay_map.get(macro)
        draft_v = draft_map.get(macro)
        rec_v = rec.get(rec_key or macro)
        ext = extracted.get(extracted_key) if extracted_key else None
        ext_off = ext["off_int"] if ext else None
        row = {
            "macro": macro,
            "tokay_pixel_gki612": hex(tokay_v) if isinstance(tokay_v, int) else tokay_v,
            "draft_pd2238": hex(draft_v) if isinstance(draft_v, int) else draft_v,
            "kallsyms_off": hex(ext_off) if ext_off is not None else None,
            "recommended": hex(rec_v) if isinstance(rec_v, int) else rec_v,
        }
        # verdict vs kallsyms / recommended
        gold = rec_v if rec_v is not None else ext_off
        if isinstance(draft_v, int) and isinstance(gold, int):
            row["draft_matches_extracted"] = (draft_v == gold)
        elif draft_v is not None and gold is None:
            row["draft_matches_extracted"] = None
        return row

    compare = []
    pairs = [
        ("KIMAGE_TEXT_BASE", None, "KIMAGE_TEXT_BASE"),
        ("PSELECT_WAITER_WORD_SHIFT", None, None),
        ("ASHMEM_MISC_FOPS_OFF", "ASHMEM_MISC", "ASHMEM_MISC_FOPS_OFF"),
        ("ASHMEM_FOPS_OFF", "ASHMEM_FOPS", "ASHMEM_FOPS_OFF"),
        ("ASHMEM_IOCTL_OFF", "ASHMEM_IOCTL", "ASHMEM_IOCTL_OFF"),
        ("ASHMEM_COMPAT_IOCTL_OFF", "ASHMEM_COMPAT_IOCTL", "ASHMEM_COMPAT_IOCTL_OFF"),
        ("ASHMEM_MMAP_OFF", "ASHMEM_MMAP", "ASHMEM_MMAP_OFF"),
        ("ASHMEM_OPEN_OFF", "ASHMEM_OPEN", "ASHMEM_OPEN_OFF"),
        ("ASHMEM_RELEASE_OFF", "ASHMEM_RELEASE", "ASHMEM_RELEASE_OFF"),
        ("ASHMEM_SHOW_FDINFO_OFF", "ASHMEM_SHOW_FDINFO", "ASHMEM_SHOW_FDINFO_OFF"),
        ("CONFIGFS_READ_ITER_OFF", "CONFIGFS_READ_ITER", "CONFIGFS_READ_ITER_OFF"),
        ("CONFIGFS_BIN_WRITE_ITER_OFF", "CONFIGFS_BIN_WRITE_ITER", "CONFIGFS_BIN_WRITE_ITER_OFF"),
        ("CONFIGFS_READ_BIN_OFF", "CONFIGFS_READ_BIN_FILE", "CONFIGFS_READ_BIN_OFF"),
        ("CONFIGFS_WRITE_BIN_OFF", "CONFIGFS_WRITE_BIN_FILE", "CONFIGFS_WRITE_BIN_OFF"),
        ("COPY_SPLICE_READ_OFF", "COPY_SPLICE_READ", "COPY_SPLICE_READ_OFF"),
        ("NOOP_LLSEEK_OFF", "NOOP_LLSEEK", "NOOP_LLSEEK_OFF"),
        ("INIT_TASK_OFF", "INIT_TASK", "INIT_TASK_OFF"),
        ("INIT_UTS_NS_OFF", "INIT_UTS_NS", "INIT_UTS_NS_OFF"),
        ("EMPTY_ZERO_PAGE_OFF", "EMPTY_ZERO_PAGE", "EMPTY_ZERO_PAGE_OFF"),
        ("ROOT_TASK_GROUP_OFF", "ROOT_TASK_GROUP", "ROOT_TASK_GROUP_OFF"),
        ("SELINUX_BLOB_SIZES_OFF", "SELINUX_BLOB_SIZES", "SELINUX_BLOB_SIZES_OFF"),
        ("SELINUX_ENFORCING_OFF", "SELINUX_ENFORCING", "SELINUX_ENFORCING_OFF"),
        ("SECURITY_HOOK_HEADS_OFF", "SECURITY_HOOK_HEADS", "SECURITY_HOOK_HEADS_OFF"),
        ("KMALLOC_CACHES_OFF", "KMALLOC_CACHES", "KMALLOC_CACHES_OFF"),
        ("ANON_PIPE_BUF_OPS_OFF", "ANON_PIPE_BUF_OPS", "ANON_PIPE_BUF_OPS_OFF"),
        ("SLIDE_NFULNL_LOGGER_OFF", "NFULNL_LOGGER", "SLIDE_NFULNL_LOGGER_OFF"),
        ("SLIDE_LOGGERS_0_1_OFF", "LOGGERS", "SLIDE_LOGGERS_0_1_OFF"),
        ("SLIDE_SYSCTL_BOOTID_OFF", "SYSCTL_BOOTID", "SLIDE_SYSCTL_BOOTID_OFF"),
        ("SYSCTL_BOOTID_OFF", "SYSCTL_BOOTID", "SYSCTL_BOOTID_OFF"),
        ("FOPS_SPLICE_READ_OFF", None, "FOPS_SPLICE_READ_OFF"),
        ("FOPS_SHOW_FDINFO_OFF", None, "FOPS_SHOW_FDINFO_OFF"),
        ("WAITER_WAKE_STATE_OFF", None, None),
        ("WAITER_PRIO_OFF", None, "WAITER_PRIO_OFF"),
        ("WAITER_WW_CTX_OFF", None, None),
        ("TASK_COMM_OFF", None, None),
        ("TASK_CRED_OFF", None, None),
        ("CFG_PAGE_OFF", None, "CFG_PAGE_OFF"),
        ("CFG_BIN_BUFFER_OFF", None, None),
        ("PSELECT_WAITER_WORD_SHIFT", None, None),
    ]
    seen = set()
    for macro, ek, rk in pairs:
        if macro in seen:
            continue
        seen.add(macro)
        compare.append(cmp_row(macro, ek, rk))
    report["offset_compare"] = compare

    # verdicts
    symbol_pass = []
    symbol_fail = []
    for row in compare:
        if row["macro"].endswith("_OFF") and row.get("kallsyms_off"):
            if row.get("draft_matches_extracted") is True:
                symbol_pass.append(row["macro"])
            elif row.get("draft_matches_extracted") is False:
                symbol_fail.append(row["macro"])
    report["draft_symbol_pass"] = symbol_pass
    report["draft_symbol_fail"] = symbol_fail

    # ABI notes
    report["abi_notes"] = {
        "rt_mutex_waiter_5_10": (
            "tree_entry@0, pi_tree_entry@0x18, task@0x30, lock@0x38, "
            "prio@0x40, deadline@0x48; NO wake_state, NO ww_ctx "
            "(those fields exist on GKI 6.12 tokay target.h)"
        ),
        "configfs_5_10": (
            "file.c uses configfs_read_bin_file / configfs_write_bin_file "
            "(.read/.write), not configfs_read_iter / configfs_bin_write_iter"
        ),
        "ashmem_5_10": (
            "staging/android/ashmem.c: fops has read_iter=ashmem_read_iter, "
            "no .read/.write; hijack must use matching signature"
        ),
        "sysctl_bootid": "static u8 sysctl_bootid[16] in drivers/char/random.c — 1-byte alignment possible",
        "loggers_0_1": "loggers[NFPROTO][NF_LOG_TYPE]; slot [0][1] = base+8",
        "fops_splice_read_5_10": "splice_write@0xc0 splice_read@0xc8 show_fdinfo@0xe0",
        "va_bits": "kallsyms _text=0xffffffc008000000 implies 39-bit kimage base used by vmlinux-to-elf",
        "pselect_shift": "frame delta, cannot be derived from kallsyms; needs stack-frame measurement",
    }

    # overall
    critical_missing = [k for k in (
        "ASHMEM_FOPS", "ASHMEM_MISC", "INIT_TASK", "SYSCTL_BOOTID",
        "CONFIGFS_READ_BIN_FILE", "CONFIGFS_WRITE_BIN_FILE", "ANON_PIPE_BUF_OPS"
    ) if k in missing]
    report["overall"] = {
        "boot_unpack_ok": (not inv["Image"].get("missing") and not inv["kallsyms.txt"].get("missing")
                           and not inv["output.elf"].get("missing") and boot_same),
        "cve_source_ok": report["cve_tree"]["has_exploit_src"] and report["cve_tree"]["has_tokay_target"],
        "symbol_extract_ok": len(critical_missing) == 0,
        "critical_missing": critical_missing,
        "ashmem_fops_ptr_ok": report.get("ashmem_misc_fops_ptr", {}).get("match"),
        "pixel_numeric_offsets_must_not_be_copied": True,
        "struct_offsets_from_pixel_unverified": True,
    }

    with open(OUT_JSON, "w", encoding="utf-8") as f:
        json.dump(report, f, indent=2, ensure_ascii=False)

    lines = []
    def L(s=""):
        lines.append(s)
    L("PD2238 GhostLock round-1 verification")
    L("generated: %s" % report["generated_at"])
    L("kallsyms: %d rows, _text=%s" % (len(rows), hex(KBASE)))
    L("banner: %s" % report["linux_banner"])
    L("boot.img ota==boot_out: %s" % boot_same)
    L("kernel==Image: %s" % kernel_eq_image)
    L("CVE tree: %s" % report["cve_tree"])
    L("missing schema symbols: %s" % missing)
    L("ashmem_misc.fops match: %s" % report.get("ashmem_misc_fops_ptr"))
    L("configfs bin fops: %s" % cfg_bin)
    L("init_task comm scan: %s" % report.get("init_task_comm_scan"))
    L("init_uts_ns ascii: %s" % report.get("init_uts_ns_ascii"))
    L("")
    L("%-32s %-18s %-18s %-18s %-18s %s" % (
        "MACRO", "TOKAY(GKI6.12)", "DRAFT", "KALLSYMS", "RECOMMENDED", "DRAFT_OK"))
    for row in compare:
        L("%-32s %-18s %-18s %-18s %-18s %s" % (
            row["macro"],
            str(row["tokay_pixel_gki612"])[:18],
            str(row["draft_pd2238"])[:18],
            str(row["kallsyms_off"])[:18],
            str(row["recommended"])[:18],
            row.get("draft_matches_extracted"),
        ))
    L("")
    L("draft pass: %s" % symbol_pass)
    L("draft fail: %s" % symbol_fail)
    L("overall: %s" % report["overall"])
    text_out = "\n".join(lines)
    with open(OUT_TXT, "w", encoding="utf-8") as f:
        f.write(text_out)
    print(text_out)
    print("\nJSON:", OUT_JSON)


if __name__ == "__main__":
    main()
