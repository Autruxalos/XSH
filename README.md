# XSH - The Native XOS Exokernel Shell [XSPEC-0006]

**XSH** is the native and official command interpreter for the **XOS** operating system. Unlike conventional environments such as Bash or Zsh, XSH is written entirely in **pure assembly** and operates under the philosophy of an **Exokernel**.

## 🎯 XSH Objectives

XSH’s architecture radically breaks with the legacy of UNIX, POSIX, and GNU to prioritize extreme performance and absolute control over the silicon:

* **Clean Exokernel Syntax:** Replaces the traditional UNIX path `/` with XOS’s **Smart Directories and SuperDir (`|`)** nomenclature, enabling faster and cleaner execution flows.
* **Zero Overhead (No Dependencies):** It does not depend on C libraries, complex memory allocators, or legacy Linux services. Each command communicates directly with CPU registers and memory.
* **Modularity and Portability:** Its central logic engine is isolated from the hardware, allowing the same shell to be compiled for x86 (16/32/64-bit) and, in the future, for RISC architectures (MIPS, PowerPC, RISC-V).
* **Dual Runtime Environment:** It features a system of conditional macros that allows it to be compiled natively for the actual hardware (`XKERNEL`) or as a compatible test binary on **Void Linux** (64-bit syscalls).

## 🛠️ Primary Internal Functions and Commands

As a minimalist shell specialized for optimizing resources on older or embedded hardware, XSH implements its most critical commands directly within its binary structure (Built-ins):

| Command | Exokernel Function | Technical Purpose |
| :--- | :--- | :--- |
| `ver` | System Identification | Displays the current shell version and confirms independence from GNU/UNIX environments. |
| `dir` | Object Exploration | Interacts with the **EXFS** driver to list global `XOBJ` structures in mapped linear directories (e.g., `\|system\|`, `\|apps\|`). |
| `clear` | Terminal Control | Performs an immediate screen wipe. In bare-metal mode, it uses the BIOS video interrupt; in Void Linux, it injects direct ANSI escape sequences. |
| *[XEXE]* | Binary Launcher | When it does not recognize an internal command, XSH parses the header of the requested `XEXE` file on disk and transfers execution control to it. |

## 🚀 External Compilation (64-bit Void Linux)

If you want to test the XSH command parser within your main development environment on Void Linux before integrating it into the boot sector, you can assemble it by running:

```bash
# Assemble by defining the Linux compatibility macro
nasm -f elf64 -dVOID_LINUX xsh.asm -o xsh.o

# Link the raw object to generate the native executable
ld xsh.o -o xsh

# Run the XOS shell
./xsh

Translated with DeepL.com (free version)
