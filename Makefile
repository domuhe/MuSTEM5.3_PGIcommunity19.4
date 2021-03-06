# MAKEFILE for compiling MuSTEM 5.3 on the command line with PGI on Linux or Windows
#
# ---Dorothea Muecke-Herzberg/SuperSTEM/20190705
#
# TOK for Windows10 with Turing architecture NVidia GPU (RTX 2080Ti) with PGI Community compiler v19.4 and version 5.3 Source folder of MuSTEM on github
#     and Ubuntu 18.04 with Turing architecture NVidia GPU (RTX 2080Ti) with PGI Community compiler v19.4 and version 5.3 Source folder of MuSTEM on github
#
# Prerequisites:
# Windows: install MS Windows SDK, Visual Studio Community 2017, CUDA 10.1, PGI 19.4 Community, FFTW3 pre-compiled libraries (and create import libraries)
# Linux: install CUDA dependencies, CUDA 10.1, PGI 19.4 Community, "source pgi.env", compile FFTW3 libraries

# PGI Compiler:
# source pgi.env
# "pgi.env"
# ---------------------------------------
# export PGI=/opt/pgi;
# export LM_LICENSE_FILE="$LM_LICENSE_FILE":/opt/pgi/license.dat;
# export PATH=/opt/pgi/linux86-64/19.4/bin:$PATH;
# export PATH=/opt/openmpi_4.0.1_pgi/bin:$PATH
#
# Intel Fortran Compiler:
# source/opt/intel/parallel_studio_xe_2019.4.070/bin/psxevars.sh

# Note: Quick hack in line 145 in mustem.f90 from "OPEN (6, CARRIAGECONTROL = "FORTRAN")" to "Open(6)" was necessary to get it to compile
#
# Note: Don't forget to run "make clean" between builds
###############################################################################################
#CHANGE HERE AS NECCESSARY:
MKLROOT = /opt/intel/compilers_and_libraries_2019.4.243/linux/mkl

#(pgf90/ifort)
FC=pgf90
#(gpu/cpu)
PROC=cpu
#(double/single)
PREC=single
#(lin/win)
OS=lin
#FFTW3 location (Ubuntu supplied FFTW3 libraries for PGI, Intel's own FFTW3 for IFORT
FFTW3LIBDIR=/usr/lib/x86_64-linux-gnu
FFTW3INCDIR=/usr/include/
ifeq ($(FC),ifort)
        #default of the makefile is to use Intel's own FFT routines, see below
	FFTW3INCDIR=${MKLROOT}/include/fftw/
endif

ifeq ($(OS),win)
	FFTW3LIBDIR="C:\Program Files\PGI\win64\2019\fftw3.3.5\"
	FFTW3INCDIR="C:\Program Files\PGI\win64\2019\fftw3.3.5\"
	#cuFFT location (only for Windows)
	CUFFTDIR="C:\Program Files\PGI\win64\2019\cuda\10.1\lib\x64\"
endif
#DBG=-dryrun

################################################################################################
#THERE SHOULD BE NO NEED TO CHANGE ANYTHING BELOW:

#Correctly installed compiler environment should find this by itself:
#CUDA_PATH="C:\Program Files\PGI\win64\2019\cuda\10.1"
#LINKER_FLAGS= -pgf90libs -lpgf90rtl

##CPU: 
GPU_FLAGS=-Mcuda=cc75 -ta=tesla:cc75 
#FFTW3 libraries
ifeq ($(OS),lin)
	#Linux: 
	FFTW3_FLAGS=-L$(FFTW3LIBDIR) -I$(FFTW3INCDIR) -lfftw3_threads -lfftw3 -lfftw3f_threads -lfftw3f -Wl,-rpath=$(FFTW3LIBDIR)
	ifeq ($(FC),ifort)
                # using system FFTW3:
		#FFTW3_FLAGS=-I $(FFTW3INCDIR) -L$(FFTW3LIBDIR) -lfftw3_threads -lfftw3 -lfftw3f_threads -lfftw3f
                # using Intel MKL FFT:
		FFTW3_FLAGS=-I $(FFTW3INCDIR)
	endif
else
	#Windows: this links to the import libraries of fftw DLLs
	#=> must add the library path to the environment variables to run executable sucessfully
        #   or put fftw3 DLLs into the PGI REDIST folder
	#FFTW3_FLAGS=-I$(FFTW3INCDIR) -L$(FFTW3LIBDIR) -lfftw3-3 -lfftw3f-3 
	FFTW3_FLAGS=-I$(FFTW3INCDIR) -Wl,/libpath:$(FFTW3LIBDIR) -defaultlib:libfftw3-3 -defaultlib:libfftw3f-3
endif
EXE1=cpu

##GPU: enable Cuda, use cuFFT that comes with Cuda/PGI
ifeq ($(PROC),gpu)
	GPU_FLAGS=-Mcuda=cc75 -ta=tesla:cc75 -DGPU
	ifeq ($(OS),lin)
	#Linux: #-lcufft must be called together with -Mcuda! -Mcudalib preferred, as then the compiler automatically chooses the correct library version
		#FFTW3_FLAGS=-lcufft $(GPU_FLAGS)
		#-Mcudalib MUST be called together with -Mcuda (so that the linker knows what version libraries to add!)
		#Cuda is only supplied as shared libraries *.so, so do not use -Bstatic!
		FFTW3_FLAGS=-Mcudalib=cufft
	else
	#Windows: 
		#MUST be called together with -Mcuda!
		#FFTW3_FLAGS="C:\Program Files\PGI\win64\2019\cuda\10.1\lib\x64\cufft.lib" 
		FFTW3_FLAGS=-Wl,/libpath:$(CUFFTDIR) cufft.lib
	endif
	EXE1=gpu
endif

PRECISION=double_precision
EXE2=dble
ifeq ($(PREC),single)
	PRECISION=single_precision
	EXE2=sngl
endif

OBJ=o
EXE3=out
OS_FLAG=-DLIN
ifeq ($(OS),win)
	OS_FLAG=-DWIN
	STATIC=-Bstatic
	OBJ=obj
	EXE3=exe
endif

BINARY=mustem_$(EXE1)_$(EXE2)_$(FC).$(EXE3)

###########################################################
#dynamic linking is default for PGI on linux, and static linking is default for PGI on windows!
#for windows -Bstatic has to be used for compiling and linking!
###
#-c:	Halts the compilation process after the assembling phase and writes the object code to a file
#-g:	Instructs the compiler to include symbolic debugging information in the object module; sets the optimization level to zero unless a -⁠O option is present on the command line
#-Bstatic:	link to static libraries (in Windows use for both, compiling and linking)
#-Mpreprocess:	Perform cpp-like preprocessing on assembly language and Fortran input source files
#-Mbackslash:	Determines how the backslash character is treated in quoted strings (Fortran only)
#-Mconcur:	Enable auto-concurrentization of loops. Multiple processors or cores will be used to execute parallelizable loops
#-Mextend:	Instructs the compiler to accept 132-column source code; otherwise it accepts 72-column code (Fortran only)
#-Mcuda:	Enables CUDA Fortran (and adds the cuda runtime libraries to the link), use option cc75 for turing support
#-Mcudalib=     .e.g. =cufft, the compiler will add the version of the library matching the cuda version given with -Mcuda
#-ta:		Enable OpenACC and specify the type of accelerator to which to target accelerator regions (tesla,host,multicore), suboption cc75 for turing support
#-O3:		Level three specifies aggressive global optimization. This level performs all level-one and level-two optimizations and enables more aggressive hoisting and scalar replacement optimizations that may or may not be profitable
#-Wl,rpath=	Stores the path of the libraries in the executable.
#-#:		show invocations of compiler, assembler and linker during Makefile run
###########################################################

#PGI compiler flags:
PGIFLAGS= $(STATIC) -c -fast -Mpreprocess -Mbackslash -Mconcur -Mextend -Mfree -Mrecursive -mp
PPFLAGS= -D$(PRECISION) $(OS_FLAG) $(DBG)
FCFLAGS= $(PGIFLAGS) $(GPU_FLAGS) $(PPFLAGS)
#PGF_FLAGS=$(STATIC) -c -g -O3 -Mpreprocess -Mbackslash -Mconcur -Mextend -Mfree -Mrecursive -mp  $(FFTW3_FLAGS) -D$(PRECISION) $(GPU_FLAGS) $(OS_FLAG) $(DBG)
LDFLAGS=$(STATIC) -mp $(GPU_FLAGS) $(FFTW3_FLAGS)

#Intel:
ifeq ($(FC),ifort)
IFORTFLAGS = -mkl  -fpp -c -qopenmp  -assume nobscc -I /usr/include/ -I ${MKLROOT}/include/
	FCFLAGS= $(IFORTFLAGS) $(PPFLAGS)
	LDFLAGS = -mkl $(FFTW3_FLAGS) -L${MKLROOT}/lib/intel64 -lmkl_intel_ilp64 -lmkl_intel_thread -lmkl_core -liomp5 -lpthread -ldl -lm -qopenmp -I ${MKLROOT}/include/ 
endif

executable: intermediate
	$(FC) -o $(BINARY) *.$(OBJ) $(LDFLAGS)
#	$(FC) -o $(BINARY) *.$(OBJ) $(STATIC) $(GPU_FLAGS) $(OS_FLAG)  $(DBG)


modules:
ifeq ($(PROC),gpu)
#GPU
	$(FC) $(FCFLAGS) quadpack.f90
	$(FC) $(FCFLAGS) m_precision.f90
	$(FC) $(FCFLAGS) m_string.f90
	$(FC) $(FCFLAGS) m_numerical_tools.f90
	$(FC) $(FCFLAGS) mod_global_variables.f90
	$(FC) $(FCFLAGS) m_crystallography.f90
	$(FC) $(FCFLAGS) m_electron.f90
	$(FC) $(FCFLAGS) m_user_input.f90
	$(FC) $(FCFLAGS) GPU_routines/mod_cufft.f90
	$(FC) $(FCFLAGS) mod_CUFFT_wrapper.f90
	$(FC) $(FCFLAGS) mod_output.f90
	$(FC) $(FCFLAGS) m_multislice.f90
	$(FC) $(FCFLAGS) m_lens.f90
	$(FC) $(FCFLAGS) m_tilt.f90
	$(FC) $(FCFLAGS) m_absorption.f90
	$(FC) $(FCFLAGS) GPU_routines/mod_cuda_array_library.f90
	$(FC) $(FCFLAGS) GPU_routines/mod_cuda_potential.f90
	$(FC) $(FCFLAGS) m_potential.f90
	$(FC) $(FCFLAGS) MS_utilities.f90
	$(FC) $(FCFLAGS) GPU_routines/mod_cuda_setup.f90
	$(FC) $(FCFLAGS) GPU_routines/mod_cuda_ms.f90
	$(FC) $(FCFLAGS) s_absorptive_stem.f90
	$(FC) $(FCFLAGS) s_qep_tem.f90
	$(FC) $(FCFLAGS) s_qep_stem.f90
	$(FC) $(FCFLAGS) s_absorptive_tem.f90
	$(FC) $(FCFLAGS) muSTEM.f90
else
#CPU
	$(FC) $(FCFLAGS) quadpack.f90
	$(FC) $(FCFLAGS) mod_CUFFT_wrapper.f90
	$(FC) $(FCFLAGS) m_precision.f90
	$(FC) $(FCFLAGS) m_string.f90
	$(FC) $(FCFLAGS) m_numerical_tools.f90
	$(FC) $(FCFLAGS) mod_global_variables.f90
	$(FC) $(FCFLAGS) m_crystallography.f90
	$(FC) $(FCFLAGS) m_electron.f90
	$(FC) $(FCFLAGS) m_user_input.f90
	$(FC) $(FCFLAGS) mod_output.f90
	$(FC) $(FCFLAGS) m_multislice.f90
	$(FC) $(FCFLAGS) m_lens.f90
	$(FC) $(FCFLAGS) m_tilt.f90
	$(FC) $(FCFLAGS) m_absorption.f90
	$(FC) $(FCFLAGS) m_potential.f90
	$(FC) $(FCFLAGS) MS_utilities.f90
	$(FC) $(FCFLAGS) s_absorptive_stem.f90
	$(FC) $(FCFLAGS) s_qep_tem.f90
	$(FC) $(FCFLAGS) s_qep_stem.f90
	$(FC) $(FCFLAGS) s_absorptive_tem.f90
	$(FC) $(FCFLAGS) muSTEM.f90
endif

intermediate: *.f90 modules
	$(FC) $(FCFLAGS) *.f90

clean:
	rm -f *.$(OBJ) *.mod *.tmp *.TMP *.out *.$(EXE3) *.dwf
