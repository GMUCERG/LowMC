# Lightweight Side-channel Resistant Implementations of the LowMC Block Cipher
## Details:

There are 3 implementations corresponds to 3 architectures of LowMC in the paper: lightweight, unrolled and memory-optimized. 

Each of them includes an unprotected and a SCA-protected versions. 

In each version: 
* Folder `src_rtl` contains all source files written in VHDL.
* Folder `tb` contains all test vectors and testbenches.

For the unprotected/protected memory-optimized and unrolled implementations, in the corresponding `lowmc_pkg.vhd`,  unroll factor `U` can be set to 1, 2 , 4, 8 or 16. 

