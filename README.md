# MuSTEM5.3_PGIcommunity19.4
Source folder of MuSTEMv5.3 with working Makefile for build with PGI Community 19.4 on Linux and Windows

This folder consists of the MuSTEMv5.3 "Source" folder plus my own Makefile and pgi.env to build MuSTEM v5.3
on Windows10 and Ubuntu18.04 with PGI Community 19.4 for an RTX 2080Ti graphics card that requires Cuda 10.0 as a minimum.

TOK with
<ul>
<li>Windows10 with Turing architecture NVidia GPU (RTX 2080Ti) with PGI Community compiler v19.4 and version 5.3 Source folder of MuSTEM from github</li>
<li>    and Ubuntu 18.04 with Turing architecture NVidia GPU (RTX 2080Ti) with PGI Community compiler v19.4 and version 5.3 Source folder of MuSTEM from github</li>
</ul>

## Prerequisites

### Windows
Install
<ul>
<li>MS Windows SDK</li>
<li>Visual Studio Community 2017</li>
<li>CUDA 10.1, PGI 19.4 Community</li>
</ul>

Download FFTW3 pre-compiled libraries and then create import libraries with

    lib /machine:x64 /def:libfftwfl-3.def
    lib /machine:x64 /def:libfftw3l-3.def
    lib /machine:x64 /def:libfftw3-3.def


### Linux
Install
<ul>
<li>CUDA dependencies</li>
<li>CUDA 10.1; "source cuda10.env"</li>
<li>PGI 19.4 Community; "source pgi.env"</li>
<li>compile FFTW3 libraries</li>
</ul>

    pgi.env:
    export PGI=/opt/pgi;
    export LM_LICENSE_FILE="$LM_LICENSE_FILE":/opt/pgi/license.dat;
    export PATH=/opt/pgi/linux86-64/19.4/bin:$PATH;
    export PATH=/opt/openmpi_4.0.1_pgi/bin:$PATH

    cuda.env:
    export PATH=$PATH:/usr/local/cuda-10.1/bin
    export CUDADIR=/usr/local/cuda-10.1
    export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/cuda-10.1/lib64


**Note: Quick hack in line 145 in mustem.f90: change "OPEN (6, CARRIAGECONTROL = "FORTRAN")" to "Open(6)" was necessary to get it to compile**

Note: Don't forget to run "make clean" between builds

## Build

### Windows
<ul>
<li> open PGI cygwin terminal (this has all necessary environment variables set)</li>
<li>edit top of Makefile to configure type of build (GPU/CPU,single,dble,Win/Lin,paths)</li>
<li>"make"</li>
<li>before a new build run "make clean" but don't forget to move the new executable out of the current folder</li>
<li>add the fftw3 DLLs to your library search path!
</ul>

### Linux

<ul>
<li> open bash terminal </li>
<li>"source pgi.env"</li>
<li>edit top of Makefile to configure type of build (GPU/CPU,single,dble,Win/Lin,paths)</li>
<li>"make"</li>
<li>before a new build run "make clean" but don't forget to move the new executable out of the current folder</li>
</ul>
