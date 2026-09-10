set pagination off
set confirm off
set architecture aarch64
target remote :1234
printf "SCRATCH_PRE lock=%016lx %016lx %016lx %016lx parent=%016lx %016lx bootid=%016lx\n", *(unsigned long*)0xffffffc00ae90000, *(unsigned long*)0xffffffc00ae90008, *(unsigned long*)0xffffffc00ae90010, *(unsigned long*)0xffffffc00ae90018, *(unsigned long*)0xffffffc00ae90100, *(unsigned long*)0xffffffc00ae90108, *(unsigned long*)0xffffffc00aee910d
break *0xffffffc008227eac
commands
  silent
  printf "PIB pid=%d pib=0x%lx bootid=%016lx root=%016lx\n", *(int*)($x19+0x5c8), $x8, *(unsigned long*)0xffffffc00aee910d, *(unsigned long*)0xffffffc00ae90008
  continue
end
continue
