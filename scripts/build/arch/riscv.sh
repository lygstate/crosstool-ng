# Compute RISC-V-specific values

CT_DoArchTupleValues() {
    CT_TARGET_ARCH="riscv${CT_ARCH_BITNESS}${target_endian_be}"
}
