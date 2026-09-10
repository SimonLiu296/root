#include <stddef.h>
#include <stdint.h>
#include <stdio.h>

/* Kernel (not bionic) rt_sigframe, matching arch/arm64/kernel/signal.c + uapi. */
typedef struct {
  void *ss_sp;
  int ss_flags;
  unsigned long ss_size;
} k_stack_t;

struct k_sigcontext {
  uint64_t fault_address;
  uint64_t regs[31];
  uint64_t sp;
  uint64_t pc;
  uint64_t pstate;
  uint8_t __reserved[4096] __attribute__((aligned(16)));
};

struct k_ucontext {
  unsigned long uc_flags;
  struct k_ucontext *uc_link;
  k_stack_t uc_stack;
  uint64_t uc_sigmask;
  uint8_t unused_pad[1024 / 8 - 8];
  struct k_sigcontext uc_mcontext;
};

struct k_rt_sigframe {
  uint8_t info[128];
  struct k_ucontext uc;
};

int main(void) {
  printf("sizeof sigcontext = 0x%zx\n", sizeof(struct k_sigcontext));
  printf("alignof sigcontext = %zu\n", _Alignof(struct k_sigcontext));
  printf("sizeof ucontext    = 0x%zx\n", sizeof(struct k_ucontext));
  printf("sizeof rt_sigframe = 0x%zx\n", sizeof(struct k_rt_sigframe));
  printf("uc_sigmask         = 0x%zx\n",
         offsetof(struct k_rt_sigframe, uc.uc_sigmask));
  printf("uc_mcontext        = 0x%zx\n",
         offsetof(struct k_rt_sigframe, uc.uc_mcontext));
  printf("regs[0]            = 0x%zx\n",
         offsetof(struct k_rt_sigframe, uc.uc_mcontext.regs[0]));
  printf("sp                 = 0x%zx\n",
         offsetof(struct k_rt_sigframe, uc.uc_mcontext.sp));
  printf("pc                 = 0x%zx\n",
         offsetof(struct k_rt_sigframe, uc.uc_mcontext.pc));
  printf("pstate             = 0x%zx\n",
         offsetof(struct k_rt_sigframe, uc.uc_mcontext.pstate));
  printf("__reserved         = 0x%zx  (mod16=%zu)\n",
         offsetof(struct k_rt_sigframe, uc.uc_mcontext.__reserved),
         offsetof(struct k_rt_sigframe, uc.uc_mcontext.__reserved) % 16);
  printf("vregs              = 0x%zx\n",
         offsetof(struct k_rt_sigframe, uc.uc_mcontext.__reserved) + 0x10);
  printf("fpsimd term        = 0x%zx\n",
         offsetof(struct k_rt_sigframe, uc.uc_mcontext.__reserved) + 0x210);
  return 0;
}
