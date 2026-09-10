set pagination off
set architecture aarch64
target remote :1234
echo 
===== PD2238 OFFSET VERIFICATION (nokaslr, base 0xffffffc008000000) =====

echo init_task=0xffffffc00aaec240


echo 
--- [TASK] comm (expect swapper/0; TASK_COMM_OFF=0x790) ---

x/s 0xffffffc00aaec240+0x790

echo 
--- [TASK] real_cred(0x778)/cred(0x780) ---

x/2gx 0xffffffc00aaec240+0x778

echo 
--- [TASK] pid(0x5c8)/tgid(0x5cc) expect 0/0 ---

x/2wx 0xffffffc00aaec240+0x5c8

echo 
--- [TASK] pi_blocked_on(0x898) expect 0 ---

x/gx 0xffffffc00aaec240+0x898

echo 
--- [TASK] tasks(0x4c8) expect self-referencing ---

x/2gx 0xffffffc00aaec240+0x4c8

echo 
--- [TASK] seccomp(0x8e8) expect 0/0/0 ---

x/2wx 0xffffffc00aaec240+0x8e8
x/gx 0xffffffc00aaec240+0x8f0

echo 
===== CRED (init_cred via real_cred ptr above) =====

echo NOTE: read real_cred ptr from [TASK] output, then: x/24wx <real_cred>


echo 
===== SYMBOL SANITY =====

echo --- init_uts_ns @0xffffffc00aaebfe8 ---

x/4gx 0xffffffc00aaebfe8
echo --- sysctl_bootid @0xffffffc00aee910d (u8[16] uuid) ---

x/16bx 0xffffffc00aee910d
echo --- root_task_group @0xffffffc00ad33100 ---

x/gx 0xffffffc00ad33100
echo --- kmalloc_caches @0xffffffc00a5d7b70 ---

x/gx 0xffffffc00a5d7b70
echo 
===== DONE =====

detach
quit
