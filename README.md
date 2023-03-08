# Posit_in_Verilog
Posit numbers are a new way to represent real numbers for computers, an alternative to the standard IEEE floating point formats. 
The primary advantage of posits is the ability to get more precision or dynamic range out of a given number of bits. 
If an application can switch from using 64-bit IEEE floats to using 32-bit posits, for example, it can fit twice as many numbers in memory at a time. 
That can make a big difference in the performance of applications that process large amounts of data.
Reference - https://www.johndcook.com/blog/2018/04/11/anatomy-of-a-posit-number/