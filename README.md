# LSQR-CUDA
## Overview
LSQR-CUDA was written by Lawrence Ayers under the supervision of Stefan Guthe of the [GRIS](https://www.informatik.tu-darmstadt.de/gris/startseite_1/team/index.de.jsp) institute at the Technische Universität Darmstadt.

The goal of this work was to accelerate the computation time of the well-known [LSQR](https://web.stanford.edu/group/SOL/software/lsqr/) algorithm using a CUDA capable GPGPU.

The LSQR algorithm is an iterative method used to find the solution x for either of the following problems:
* Ax=b
* min(||Ax-b||)

where A is large, often sparse, square or rectangular matrix, and b is a normal vector of size Arows.

LSQR was first authored by Chris Paige and Michael Saunders in their publication [here](https://web.stanford.edu/group/SOL/software/lsqr/lsqr-toms82a.pdf), and has since been widely used.

## Requirements
LSQR-CUDA has the following requirements:
* *nix system or WSL for windows
* CUDA Capable GPGPU
* CUDA (nvcc) v11 or higher 
* g++ v11 or higher
* make

## Execution

To run the system, enter the [source](source/) directory and type the following command into your terminal
```
make run
```
### Inputs
You will then be asked if you would like automatic test inputs generated for you. If you have your own inputs available, you will need to save them as files with .mat (dense and sparse matricies) and .vec (vectors) extensions in the [input](input/) directory. These must use a white space delimiter: " ", and have a number of values such that Ax=b can be satisfied.
Inputs must have the following notation:
* ```#Arows_#Acols_A_#sparsity.mat```
* ```#Arows_1_b.vec```

As an example, a sparse matrix A with 1500 rows, 2000 columns, and a sparsity of 0.75% would have the following input files:

* ```1500_2000_A_75.mat```
* ```1500_1_b.vec```

### Outputs
The solution, x, will be correspondingly written to [output](output/) in a directory corresponding to the time of execution in the format:
* ```YYYY-MM-DDTHHMM/#Acols_1_x_implementation_#sparsity.vec```

for the above example, the x output file would look like this:
* ```YYYY-MM-DDTHHMM/2000_1_b.vec```

A csv with the timings of each implementation will be writt


<details open>
<summary><b>Table of Contents</b></summary>
<!-- MarkdownTOC -->

1.  [General](#General)
1.  [Background](#Background)
1.  [Methods](#Methods)
    1.  [CPU](#CPU)
    1.  [GPU](#CPU)
1.  [Results](#Results)
    1.   [Speedup](#Speedup)
    1.   [Accuracy](#Accuracy)
1.  [Conclusion](#Conclusion)
<!-- /MarkdownTOC -->
</details>

<a id="General"></a>
## 1. General
The purpose of this work was to implement the LSQR algorithm on a CUDA capabale GPU in order to analyze a potential runtime speedup in comparison to a standard, sequential CPU implementation. When run in CUDA, many matrix operations (e.g. multiplication, euclidean norm, addition, subtraction, etc.) can be run in parallel, and therefore decrease computation time.

This work has both sequential and parallel implementations of LSQR that are intended for both sparse and dense inputs.
___
<a id="Background"></a>
## 2. Background
___
<a id="Methods"></a>
## 3. Methods
The LSQR algorithm in this work is largely based off the scipy-lsqr algorithm. The results and speeds found here were compared to that of the scipy implementation. 

## CPU
All of the source files for implementations that run on the CPU can be found in the [cpu](source/cpu) directory. 

For this work, there was only one CPU implementation created, [VectorCPU](source/cpu/Vector.cpp), that executes on dense inputs.

## GPU
All source files pertaining to GPU implementations can be found in
___
<a id="Results"></a>
## 4. Results
___
<a id="Conclusion"></a>
## 5. Conclusion
___

# C++ and CUDA implementations of the lsqr algorithm
The following repository is split into two folders, one for the cpu implementation of lsqr, and one for the gpu implementation of lsqr.
___
# CPU Implementation
___
# GPU Implementation
The Kernels used in this implementation are all 2-Dimensional, and can all handle matricies of large various sizes depending on the capabilities of the GPU.

Here, the speed of both naive and optimizied algorithms are analyzed and compared. 

## Naive kernels


## Optimized kernels

### Transpose
The transpose kernel utilizes coalesced memory access via shared memory (block scope).

### Multiply