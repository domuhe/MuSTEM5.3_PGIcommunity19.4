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
# "pgi.env"
# ---------------------------------------
# export PGI=/opt/pgi;
# export LM_LICENSE_FILE="$LM_LICENSE_FILE":/opt/pgi/license.dat;
# export PATH=/opt/pgi/linux86-64/19.4/bin:$PATH;
# export PATH=/opt/openmpi_4.0.1_pgi/bin:$PATH
#
# Note: Quick hack in line 145 in mustem.f90 from "OPEN (6, CARRIAGECONTROL = "FORTRAN")" to "Open(6)" was necessary to get it to compile
#
# Note: Don't forget to run "make clean" between builds
###############################################################################################
#CHANGE HERE AS NECESARY:
#(gpu/cpu)
PROC=cpu
#(double/single)
PREC=single
#(lin/win)
OS=lin
#FFTW3 location 
FFTW3DIR=/opt/fftw3.3.8_pgi
ifeq ($(OS),win)
	FFTW3DIR="C:\Program Files\PGI\win64\2019\fftw3.3.5"
	#cuFFT location (only for Windows)
	CUFFTDIR="C:\Program Files\PGI\win64\2019\cuda\10.1\lib\x64"
endif
#DBG=-dryrun 
################################################################################################
#THERE SHOULD BE NO NEED TO CHANGE ANYTHING BELOW:

#Correctly installed compiler environment should find this by itself:
#CUDA_PATH="C:\Program Files\PGI\win64\2019\cuda\10.1"
#LINKER_FLAGS= -pgf90libs -lpgf90rtl

#CPU: FFTW3 libraries
GPU_FLAGS=
ifeq ($(OS),lin)
	#Linux: 
	FFTW3_FLAGS=-L$(FFTW3DIR)/lib -I$(FFTW3DIR)/include -lfftw3 -lfftw3f -lfftw3_threads -lfftw3f_threads -Wl,-rpath=$(FFTW3DIR)/lib
else
	#Windows: this links to the import libraries of fftw DLLs
	#=> must add the library path to the environment variables to run executable sucessfully
        #   or put fftw3 DLLs into the PGI REDIST folder
	#FFTW3_FLAGS=-I$(FFTW3DIR) -L$(FFTW3DIR) -lfftw3-3 -lfftw3f-3 
	FFTW3_FLAGS=-I$(FFTW3DIR) -Wl,/libpath:$(FFTW3DIR) -defaultlib:libfftw3-3 -defaultlib:libfftw3f-3
endif
EXE1=cpu
#GPU: enable Cuda, use cuFFT that comes with Cuda/PGI
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
ifeq ($(OS),win)
    STATIC=-Bstatic
	OBJ=obj
	EXE3=exe
endif

BINARY=mustem_$(EXE1)_$(EXE2).$(EXE3)

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

PGF_FLAGS=$(STATIC) -c -g -O3 -Mpreprocess -Mbackslash -Mconcur -Mextend -Mfree -Mrecursive -mp  $(FFTW3_FLAGS) -D$(PRECISION) $(GPU_FLAGS) $(DBG)

executable: intermediate
	pgf90 -o $(BINARY) *.$(OBJ) $(STATIC) -mp $(FFTW3_FLAGS) $(GPU_FLAGS)  $(DBG) 

modules:
ifeq ($(PROC),gpu)
#GPU
	pgf90 $(PGF_FLAGS) quadpack.f90
	pgf90 $(PGF_FLAGS) m_precision.f90
	pgf90 $(PGF_FLAGS) m_string.f90
	pgf90 $(PGF_FLAGS) m_numerical_tools.f90
	pgf90 $(PGF_FLAGS) mod_global_variables.f90
	pgf90 $(PGF_FLAGS) m_crystallography.f90
	pgf90 $(PGF_FLAGS) m_electron.f90
	pgf90 $(PGF_FLAGS) m_user_input.f90
	pgf90 $(PGF_FLAGS) GPU_routines/mod_cufft.f90
	pgf90 $(PGF_FLAGS) mod_CUFFT_wrapper.f90
	pgf90 $(PGF_FLAGS) mod_output.f90
	pgf90 $(PGF_FLAGS) m_multislice.f90
	pgf90 $(PGF_FLAGS) m_lens.f90
	pgf90 $(PGF_FLAGS) m_tilt.f90
	pgf90 $(PGF_FLAGS) m_absorption.f90
	pgf90 $(PGF_FLAGS) GPU_routines/mod_cuda_array_library.f90
	pgf90 $(PGF_FLAGS) GPU_routines/mod_cuda_potential.f90
	pgf90 $(PGF_FLAGS) m_potential.f90
	pgf90 $(PGF_FLAGS) MS_utilities.f90
	pgf90 $(PGF_FLAGS) GPU_routines/mod_cuda_setup.f90
	pgf90 $(PGF_FLAGS) GPU_routines/mod_cuda_ms.f90
	pgf90 $(PGF_FLAGS) s_absorptive_stem.f90
	pgf90 $(PGF_FLAGS) s_qep_tem.f90
	pgf90 $(PGF_FLAGS) s_qep_stem.f90
	pgf90 $(PGF_FLAGS) s_absorptive_tem.f90
	pgf90 $(PGF_FLAGS) muSTEM.f90
else
#CPU
	pgf90 $(PGF_FLAGS) quadpack.f90
	pgf90 $(PGF_FLAGS) mod_CUFFT_wrapper.f90
	pgf90 $(PGF_FLAGS) m_precision.f90
	pgf90 $(PGF_FLAGS) m_string.f90
	pgf90 $(PGF_FLAGS) m_numerical_tools.f90
	pgf90 $(PGF_FLAGS) mod_global_variables.f90
	pgf90 $(PGF_FLAGS) m_crystallography.f90
	pgf90 $(PGF_FLAGS) m_electron.f90
	pgf90 $(PGF_FLAGS) m_user_input.f90
	pgf90 $(PGF_FLAGS) mod_output.f90
	pgf90 $(PGF_FLAGS) m_multislice.f90
	pgf90 $(PGF_FLAGS) m_lens.f90
	pgf90 $(PGF_FLAGS) m_tilt.f90
	pgf90 $(PGF_FLAGS) m_absorption.f90
	pgf90 $(PGF_FLAGS) m_potential.f90
	pgf90 $(PGF_FLAGS) MS_utilities.f90
	pgf90 $(PGF_FLAGS) s_absorptive_stem.f90
	pgf90 $(PGF_FLAGS) s_qep_tem.f90
	pgf90 $(PGF_FLAGS) s_qep_stem.f90
	pgf90 $(PGF_FLAGS) s_absorptive_tem.f90
	pgf90 $(PGF_FLAGS) muSTEM.f90
endif

intermediate: *.f90 modules
	pgf90 $(PGF_FLAGS) *.f90

clean:
	rm -f *.$(OBJ) *.mod *.tmp *.TMP *.out *.$(EXE3) *.dwf
