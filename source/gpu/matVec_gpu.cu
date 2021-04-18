#include <stdio.h> //NULL, printf
#include <stdlib.h> //srand, rand
#include <assert.h>
#include <cuda.h>
#include <cuda_runtime.h>
#include "device_launch_parameters.h"
#include <sstream>
#include <iostream>
#include <string.h>
#include <time.h>
#include "matVec_gpu.cuh"

//CUDA kernels
void __global__ scale(double * input, double scalar,double * output){
    const unsigned int bid = blockIdx.x //1D
        + blockIdx.y * gridDim.x //2D
        + gridDim.x * gridDim.y * blockIdx.z; //3D
    const unsigned int threadsPerBlock = blockDim.x
        *blockDim.y //2D
        *blockDim.z; //3D
    const unsigned int tid = threadIdx.x //1D
        +threadIdx.y*blockDim.x //2D
        +blockDim.x*blockDim.x*threadIdx.z; //3D
    const unsigned int gid = bid * threadsPerBlock + tid;
    //printf("thread(%d,%d,%d), block(%d,%d,%d), bid=%d, gid=%d, value=%f\n",threadIdx.x,threadIdx.y,threadIdx.z,
    //    blockIdx.x,blockIdx.y,blockIdx.z,bid,gid,input[gid]);
    output[gid] = input[gid] * scalar;
}

void __global__ multiply(double * in1, double * in2, double * output){
    const unsigned int bid = blockIdx.x //1D
        + blockIdx.y * gridDim.x //2D
        + gridDim.x * gridDim.y * blockIdx.z; //3D
    const unsigned int threadsPerBlock = blockDim.x
        *blockDim.y //2D
        *blockDim.z; //3D
    const unsigned int tid = threadIdx.x //1D
        +threadIdx.y*blockDim.x //2D
        +blockDim.x*blockDim.x*threadIdx.z; //3D
    const unsigned int gid = bid * threadsPerBlock + tid;
    //printf("thread(%d,%d,%d), block(%d,%d,%d), bid=%d, gid=%d, %f * %f\n",threadIdx.x,threadIdx.y,threadIdx.z,
    //    blockIdx.x,blockIdx.y,blockIdx.z,bid,gid,in1[gid],in2[gid]);
    output[gid] = in1[gid] * in2[gid];
}

void __global__ assignment(double * in1, double * in2){
    const unsigned int bid = blockIdx.x //1D
        + blockIdx.y * gridDim.x //2D
        + gridDim.x * gridDim.y * blockIdx.z; //3D
    const unsigned int threadsPerBlock = blockDim.x
        *blockDim.y //2D
        *blockDim.z; //3D
    const unsigned int tid = threadIdx.x //1D
        +threadIdx.y*blockDim.x //2D
        +blockDim.x*blockDim.x*threadIdx.z; //3D
    const unsigned int gid = bid * threadsPerBlock + tid;
    printf("thread(%d,%d,%d), block(%d,%d,%d), bid=%d, gid=%d, in1=%f, in2=%f\n",threadIdx.x,threadIdx.y,threadIdx.z,
        blockIdx.x,blockIdx.y,blockIdx.z,bid,gid,in1[gid],in2[gid]);
        in1[gid] = in2[gid];
    
    
}

void __global__ subtract(double * in1, double * in2, double * out){
    const unsigned int bid = blockIdx.x //1D
        + blockIdx.y * gridDim.x //2D
        + gridDim.x * gridDim.y * blockIdx.z; //3D
    const unsigned int threadsPerBlock = blockDim.x
        *blockDim.y //2D
        *blockDim.z; //3D
    const unsigned int tid = threadIdx.x //1D
        +threadIdx.y*blockDim.x //2D
        +blockDim.x*blockDim.x*threadIdx.z; //3D
    const unsigned int gid = bid * threadsPerBlock + tid;
    printf("thread(%d,%d,%d), block(%d,%d,%d), bid=%d, gid=%d, in1=%f, in2=%f\n",threadIdx.x,threadIdx.y,threadIdx.z,
        blockIdx.x,blockIdx.y,blockIdx.z,bid,gid,in1[gid],in2[gid]);
    out[gid] = in1[gid] - in2[gid];
}

void __global__ add(double * in1, double * in2, double * out){
    const unsigned int bid = blockIdx.x //1D
        + blockIdx.y * gridDim.x //2D
        + gridDim.x * gridDim.y * blockIdx.z; //3D
    const unsigned int threadsPerBlock = blockDim.x
        *blockDim.y //2D
        *blockDim.z; //3D
    const unsigned int tid = threadIdx.x //1D
        +threadIdx.y*blockDim.x //2D
        +blockDim.x*blockDim.x*threadIdx.z; //3D
    const unsigned int gid = bid * threadsPerBlock + tid;
    printf("thread(%d,%d,%d), block(%d,%d,%d), bid=%d, gid=%d, in1=%f, in2=%f\n",threadIdx.x,threadIdx.y,threadIdx.z,
        blockIdx.x,blockIdx.y,blockIdx.z,bid,gid,in1[gid],in2[gid]);
    out[gid] = in1[gid] + in2[gid];
}

//Operator overloads
Vector_GPU Vector_GPU::operator*(Vector_GPU &v){
    printf("WE GOT HERE %i %i\n",this->rows,v.columns);
    Vector_GPU out(this->rows,v.columns);
    dim3 grid(1,1,1);
    dim3 block(this->rows * v.columns,1,1);
    multiply <<<grid,block>>> (this->d_mat,v.d_mat,out.d_mat);
    return out;
}

Vector_GPU Vector_GPU::operator*(double i){
    Vector_GPU out(this->rows,this->columns);
    dim3 grid(1,1,1);
    dim3 block(this->rows * this->columns,1,1);
    scale <<<grid,block>>> (this->d_mat,i,out.d_mat);
    return out;
}

Vector_GPU& Vector_GPU::operator=(const Vector_GPU &v){
    printf("Assignment operator called\n");
    this->rows = v.rows;
    this->columns = v.columns;
    dim3 grid(1,1,1);
    dim3 block(v.rows * v.columns,1,1);
    //if (columns == v.rows){
        assignment <<<grid,block>>> (this->d_mat,v.d_mat);
        
    /*}
    else{
        printf("ARRAYS ARE NOT THE SAME SIZE, canot perform assignment operation\n");
    }*/
    return *this;
}

Vector_GPU Vector_GPU::operator-(const Vector_GPU &v){
    Vector_GPU out(this->rows,this->columns);
    dim3 grid(1,1,1);
    dim3 block(v.rows * v.columns,1,1);
    //if (columns == v.rows){
        subtract <<<grid,block>>> (this->d_mat,v.d_mat,out.d_mat);
        
    /*}
    else{
        printf("ARRAYS ARE NOT THE SAME SIZE, canot perform operation\n");
    }*/
    return out;   
}

Vector_GPU Vector_GPU::operator+(const Vector_GPU &v){
    Vector_GPU out(this->rows,this->columns);
    dim3 grid(1,1,1);
    dim3 block(v.rows * v.columns,1,1);
    //if (columns == v.rows){
        add <<<grid,block>>> (this->d_mat,v.d_mat,out.d_mat);
        
    /*}
    else{
        printf("ARRAYS ARE NOT THE SAME SIZE, canot perform operation\n");
    }*/
    return out;   
}