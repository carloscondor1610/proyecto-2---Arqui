    .text
    .option norvc
    .globl _start
_start:
    addi x5, x0, 7
    add  x6, x5, x5
    addi x7, x0, 1
    addi x8, x0, 21
    sw   x6, 0(x0)
    lw   x9, 0(x0)
    add  x10, x9, x9
    addi x11, x0, 11
    sw   x10, 4(x0)
    lw   x12, 4(x0)
    addi x13, x0, 13
    addi x14, x0, 14
    add  x15, x12, x0
    addi x16, x0, 16
    beq  x0, x0, target0
    sw   x5, 8(x0)
    sw   x5, 12(x0)
target0:
    addi x17, x0, 17
    beq  x0, x0, target1
    sw   x5, 16(x0)
    sw   x5, 20(x0)
target1:
    beq  x5, x0, not_taken0
    addi x18, x0, 18
    addi x19, x0, 19
not_taken0:
    beq  x5, x0, not_taken1
    beq  x5, x0, not_taken2
    beq  x5, x0, not_taken3
not_taken1:
    addi x20, x0, 20
not_taken2:
    addi x21, x0, 1
not_taken3:
    addi x21, x0, 2
    add  x22, x21, x0
    addi x31, x0, 31
    addi x25, x0, 25
    jal  x23, jump_target
    sw   x5, 24(x0)
    sw   x5, 28(x0)
jump_target:
    add  x24, x23, x0
    addi x26, x0, 26
    .rept 26
    nop
    .endr
