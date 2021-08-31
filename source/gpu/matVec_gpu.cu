#include <assert.h>
#include <cuda.h>
#include <cuda_runtime.h>
#include <stdio.h>  //NULL, printf
#include <stdlib.h> //srand, rand
#include <string.h>
#include <time.h>

#include <iostream>
#include <sstream>

#include "../cpu/matVec_cpu.h"
#include "device_launch_parameters.h"
#include "matVec_gpu.cuh"
// OUR TILE SIZE SHOULD MATCH THAT OF OUR BLOCK
#define TILE_DIM_X 16
#define TILE_DIM_Y 16
// nvcc -arch=sm_37 --std=c++17
// gridDim.x - # of blocks in a grid, in x
// gridDim.y - # of blocks in a grid, in y
// blockDim.x - # of threads in a block, in x
// blockDim.y - # of threads in a block, in y

// CUDA kernels
void __global__ multiplyNaive(double *in1, unsigned int *rows1, unsigned int *cols1, double *in2, unsigned int *rows2, unsigned int *cols2,
                              double *output) {
  const unsigned int bid = blockIdx.x + blockIdx.y * gridDim.x; // 2D blockId
  const unsigned int threadsPerBlock = blockDim.x * blockDim.y;
  const unsigned int tid = threadIdx.x + threadIdx.y * blockDim.x; // 2D threadId
  const unsigned int gid = bid * threadsPerBlock + tid;            // 2D globalId
  const unsigned int x = blockIdx.y * blockDim.y + threadIdx.y;    // row
  const unsigned int y = blockIdx.x * blockDim.x + threadIdx.x;    // column
  // printf("thread(%d,%d,%d), block(%d,%d,%d), bid=%d, gid=%d, %f *
  // %f\n",threadIdx.x,threadIdx.y,threadIdx.z,
  //    blockIdx.x,blockIdx.y,blockIdx.z,bid,gid,in1[gid],in2[gid]);
  double sum = 0;
  // printf("gid:%i, %i %i %i %i\n",gid,*rows1, *cols1, *rows2, *cols2);
  if (*cols1 == *rows2) {
    // printf("row: %i \n",r);
    for (int i = 0; i < *cols1; i++) {
      sum += in1[x * *cols1 + i] * in2[i * *cols2 + y];
      // printf("sum = %f += in1[%d] * in2[%d] = %f * %f\n",sum,r * *cols1 + i,
      // i * *cols2 + c,in1[r * *cols1 + i],in2[i * *cols2 + c]);
    }
    output[x * *cols2 + y] = sum;
    // printf("output[%d] = %f\n",r * *cols2 + c, output[r * *cols2 + c]);
  } else {
    printf("MATRICIES CANNOT BE MULTIPLED, INVALID SIZES");
  }
}

void __global__ scale(double *input, double *scalar, double *output) {
  const unsigned int bid = blockIdx.x                               // 1D
                           + blockIdx.y * gridDim.x                 // 2D
                           + gridDim.x * gridDim.y * blockIdx.z;    // 3D
  const unsigned int threadsPerBlock = blockDim.x * blockDim.y      // 2D
                                       * blockDim.z;                // 3D
  const unsigned int tid = threadIdx.x                              // 1D
                           + threadIdx.y * blockDim.x               // 2D
                           + blockDim.x * blockDim.x * threadIdx.z; // 3D
  const unsigned int gid = bid * threadsPerBlock + tid;
  // printf("thread(%d,%d,%d), block(%d,%d,%d), bid=%d, gid=%d,
  // value=%f\n",threadIdx.x,threadIdx.y,threadIdx.z,
  //    blockIdx.x,blockIdx.y,blockIdx.z,bid,gid,input[gid]);
  output[gid] = input[gid] * *scalar;
  printf("%f = %f * %f\n", output[gid], input[gid], *scalar);
}

void __global__ print(double *input) {
  const unsigned int bid = blockIdx.x                               // 1D
                           + blockIdx.y * gridDim.x                 // 2D
                           + gridDim.x * gridDim.y * blockIdx.z;    // 3D
  const unsigned int threadsPerBlock = blockDim.x * blockDim.y      // 2D
                                       * blockDim.z;                // 3D
  const unsigned int tid = threadIdx.x                              // 1D
                           + threadIdx.y * blockDim.x               // 2D
                           + blockDim.x * blockDim.x * threadIdx.z; // 3D
  const unsigned int gid = bid * threadsPerBlock + tid;
  // printf("thread(%d,%d,%d), block(%d,%d,%d), bid=%d, gid=%d,
  // value=%f\n",threadIdx.x,threadIdx.y,threadIdx.z,
  //    blockIdx.x,blockIdx.y,blockIdx.z,bid,gid,input[gid]);
  __syncthreads();
  printf("%f\n", input[gid]);
}

void __global__ assignment(double *in1, double *in2) {
  const unsigned int bid = blockIdx.x                               // 1D
                           + blockIdx.y * gridDim.x                 // 2D
                           + gridDim.x * gridDim.y * blockIdx.z;    // 3D
  const unsigned int threadsPerBlock = blockDim.x * blockDim.y      // 2D
                                       * blockDim.z;                // 3D
  const unsigned int tid = threadIdx.x                              // 1D
                           + threadIdx.y * blockDim.x               // 2D
                           + blockDim.x * blockDim.x * threadIdx.z; // 3D
  const unsigned int gid = bid * threadsPerBlock + tid;
  // printf("thread(%d,%d,%d), block(%d,%d,%d), bid=%d, gid=%d, in1=%f, in2=%f\n", threadIdx.x,
  //        threadIdx.y, threadIdx.z, blockIdx.x, blockIdx.y, blockIdx.z, bid, gid, in1[gid],
  //        in2[gid]);
  in1[gid] = in2[gid];
}

void __global__ subtract(double *in1, double *in2, double *output) {
  const unsigned int bid = blockIdx.x                               // 1D
                           + blockIdx.y * gridDim.x                 // 2D
                           + gridDim.x * gridDim.y * blockIdx.z;    // 3D
  const unsigned int threadsPerBlock = blockDim.x * blockDim.y      // 2D
                                       * blockDim.z;                // 3D
  const unsigned int tid = threadIdx.x                              // 1D
                           + threadIdx.y * blockDim.x               // 2D
                           + blockDim.x * blockDim.x * threadIdx.z; // 3D
  const unsigned int gid = bid * threadsPerBlock + tid;
  const unsigned int r = blockIdx.y * blockDim.y + threadIdx.y; // the row of M1
  const unsigned int c = blockIdx.x * blockDim.x + threadIdx.x; // the col of M2
  // printf("thread(%d,%d,%d), block(%d,%d,%d), bid=%d, gid=%d, %f *
  // %f\n",threadIdx.x,threadIdx.y,threadIdx.z,
  //    blockIdx.x,blockIdx.y,blockIdx.z,bid,gid,in1[gid],in2[gid]);
  output[gid] = in1[gid] - in2[gid];
  printf("%f = %f - %f\n", output[gid], in1[gid], in2[gid]);
}

void __global__ add(double *in1, double *in2, double *out) {
  const unsigned int bid = blockIdx.x                               // 1D
                           + blockIdx.y * gridDim.x                 // 2D
                           + gridDim.x * gridDim.y * blockIdx.z;    // 3D
  const unsigned int threadsPerBlock = blockDim.x * blockDim.y      // 2D
                                       * blockDim.z;                // 3D
  const unsigned int tid = threadIdx.x                              // 1D
                           + threadIdx.y * blockDim.x               // 2D
                           + blockDim.x * blockDim.x * threadIdx.z; // 3D
  const unsigned int gid = bid * threadsPerBlock + tid;
  // printf("thread(%d,%d,%d), block(%d,%d,%d), bid=%d, gid=%d, in1=%f,
  // in2=%f\n",threadIdx.x,threadIdx.y,threadIdx.z,
  //    blockIdx.x,blockIdx.y,blockIdx.z,bid,gid,in1[gid],in2[gid]);
  out[gid] = in1[gid] + in2[gid];
  printf("%f = %f + %f\n", out[gid], in1[gid], in2[gid]);
}

// BLOCK SWEEPS ACROSS TILE (TILE SIZE > BLOCK SIZE)
// source: https://developer.nvidia.com/blog/efficient-matrix-transpose-cuda-cc/
void __global__ transposeTiled(double *in1, double *output, unsigned int *rows, unsigned int *cols) {
  __shared__ double A[(TILE_DIM_X)][TILE_DIM_Y + 1]; // Add +1 to prevent race-conditions

  int x = blockIdx.x * TILE_DIM_X + threadIdx.x; // col
  int y = blockIdx.y * TILE_DIM_Y + threadIdx.y; // row

  // Load the matrix into shared memory
  for (int i = 0; i < TILE_DIM_Y; i += blockDim.y) {
    if ((x < *cols) && (y < *rows)) {
      // A[(row + i) * height + col] = in1[(row + i) * width + col];
      A[threadIdx.y + i][threadIdx.x] = in1[(y + i) * *cols + x];
      // printf(
      //     "block(%d, %d), thread(%d,% d), row = %d, col = %d, ,i=%d, A[%d][%d] "
      //     "= in1[%d] = %f\n",
      //     blockIdx.y, blockIdx.x, threadIdx.y, threadIdx.x, y, x, i, threadIdx.y + i,
      //     threadIdx.x, (y + i) * *cols + x, in1[(y + i) * *cols + x]);
    }
  };

  __syncthreads();
  x = blockIdx.y * TILE_DIM_X + threadIdx.x; // x-dimension col
  y = blockIdx.x * TILE_DIM_Y + threadIdx.y; // y-dimension row

  for (int i = 0; i < TILE_DIM_Y; i += blockDim.y) {
    // printf("block(%d, %d), thread(%d, %d), i=%d, A[%d][%d] = %f\n",
    //       blockIdx.y, blockIdx.x, threadIdx.y, threadIdx.x, i,
    //       threadIdx.y+i,threadIdx.x, A[threadIdx.y+i][threadIdx.x]);
    if ((y + i < *cols) && (x < *rows)) {
      // output[col * width + (row+i)] = A[(row + i) * width + col];
      output[(y + i) * *rows + x] = A[threadIdx.x][threadIdx.y + i];
      // printf(
      //     "block(%d, %d), thread(%d, %d), row = %d, col = %d, i=%d, output[%d] "
      //     "= A[%d][%d] = %f\n",
      //     blockIdx.y, blockIdx.x, threadIdx.y, threadIdx.x, y, x, i, (y + i) * *rows + x,
      //     threadIdx.x, threadIdx.y + i, A[threadIdx.x][threadIdx.y + i]);
    }
  }
}

// BLOCK AND TILE SWEEP TOGETHER (BLOCK_SIZE = TILE_SIZE)
void __global__ multiplyTiled(double *in1, unsigned int *rows1, unsigned int *cols1, double *in2, unsigned int *rows2, unsigned int *cols2,
                              double *output) {

  __shared__ double A[TILE_DIM_X][TILE_DIM_Y + 1], B[TILE_DIM_X][TILE_DIM_Y + 1];

  int y = blockIdx.y * blockDim.y + threadIdx.y; // row
  int x = blockIdx.x * blockDim.x + threadIdx.x; // col
  double sum = 0.0;                              // sum in block

  for (int i = 0; i < *cols1; i += blockDim.x) {
    int id1, id2;
    if (i + threadIdx.x < *cols1 && y < *rows1) {
      id1 = y * *cols1 + i + threadIdx.x;
      A[threadIdx.x][threadIdx.y] = in1[id1];
    } else {
      A[threadIdx.x][threadIdx.y] = 0.0;
    }
    if (i + threadIdx.y < *rows2 && x < *cols2) {
      id2 = (i * *cols2 + threadIdx.y * *cols2) + x;
      B[threadIdx.x][threadIdx.y] = in2[id2];
    } else {
      B[threadIdx.x][threadIdx.y] = 0.0;
    }

    __syncthreads();
    if (blockIdx.x == 0 && blockIdx.y == 0) {
      // printf("block(%d, %d), thread(%d,% d), y = %d, x = %d, i=%d, A[%d][%d]=%f=in1[%d]=%f "
      //        "B[%d][%d]=%f=in2[%d]=%f\n",
      //        blockIdx.x, blockIdx.y, threadIdx.x, threadIdx.y, y, x, i, threadIdx.x, threadIdx.y, A[threadIdx.x][threadIdx.y], id1, in1[id1],
      //        threadIdx.x, threadIdx.y, B[threadIdx.x][threadIdx.y], id2, in2[id2]);
    }
    for (int j = 0; j < blockDim.x; j++) {
      // if (x + j < *cols2 && y + j < *rows1) {
      int Ax, Ay, Bx, By;
      Ax = j;
      Ay = threadIdx.y;
      Bx = threadIdx.x;
      By = j;
      // if (blockIdx.x == 1 && blockIdx.y == 2 && threadIdx.x == 0 && threadIdx.y == 0) {
      //   printf("OUT block(%d, %d), thread(%d,% d), y = %d, x = %d, i=%d, j=%d, A[%d][%d]=%f * "
      //          "B[%d][%d]=%f\n",
      //          blockIdx.x, blockIdx.y, threadIdx.x, threadIdx.y, x, y, i, j, Ax, Ay, A[Ax][Ay], Bx, By, B[Bx][By]);
      // }
      sum += A[Ax][Ay] * B[Bx][By];
      //}
    };
    __syncthreads();
  };
  if (x < *cols2 && y < *rows1) {
    output[y * *cols2 + x] = sum;
  }
}

// Operator overloads
Vector_GPU Vector_GPU::operator*(Vector_GPU &v) {
  printf("MATMULT\n");
  Vector_GPU out(this->h_rows, v.h_columns);
  dim3 numOfThreadsInBlock(TILE_DIM_X, TILE_DIM_Y, 1);
  unsigned int blocksY = (out.h_rows / TILE_DIM_X) + 1;
  unsigned int blocksX = (out.h_columns / TILE_DIM_Y) + 1;

  // if (out.h_columns % TILE_DIM_X > 0 || blocksX == 0) {
  //   blocksX += 2;
  // };
  // if (out.h_rows % TILE_DIM_Y > 0 || blocksY == 0) {
  //   blocksY += 2;
  // };

  dim3 numOfBlocksInGrid(blocksX, blocksY, 1);
  printf("threadsinblock(%d x %d)=%d, blocksingrid(%d, %d)=%d\n", numOfThreadsInBlock.x, numOfThreadsInBlock.y,
         numOfThreadsInBlock.x * numOfThreadsInBlock.y, numOfBlocksInGrid.x, numOfBlocksInGrid.y, numOfBlocksInGrid.x * numOfBlocksInGrid.y);
  multiplyTiled<<<numOfBlocksInGrid, numOfThreadsInBlock>>>(this->d_mat, this->d_rows, this->d_columns, v.d_mat, v.d_rows, v.d_columns, out.d_mat);
  // dim3 grid(1, 1, 1);
  // dim3 block(out.h_rows, out.h_columns, 1);
  // multiplyNaive<<<grid, block>>>(this->d_mat, this->d_rows, this->d_columns, v.d_mat, v.d_rows,
  //                                v.d_columns, out.d_mat);
  return out;
}

Vector_GPU Vector_GPU::operator*(double h_i) {
  printf("scale\n");
  Vector_GPU out(this->h_rows, this->h_columns);
  dim3 grid(1, 1, 1);
  dim3 block(this->h_rows, this->h_columns, 1);
  double *d_i;
  cudaMalloc((void **)&d_i, sizeof(double));
  cudaMemcpy(d_i, &h_i, sizeof(double), cudaMemcpyHostToDevice);

  scale<<<grid, block>>>(this->d_mat, d_i, out.d_mat);

  return out;
}

Vector_GPU Vector_GPU::operator-(const Vector_GPU &v) {
  printf("SUBTRACT CALLED\n");
  Vector_GPU out(this->h_rows, this->h_columns);
  dim3 grid(1, 1, 1);
  std::cout << v.h_rows << "=" << this->h_rows << std::endl;
  dim3 block(v.h_rows * v.h_columns, 1, 1);
  if (this->h_rows == v.h_rows && this->h_columns == v.h_columns) {
    subtract<<<grid, block>>>(this->d_mat, v.d_mat, out.d_mat);
  } else {
    printf("ARRAYS ARE NOT THE SAME SIZE, canot perform operation\n");
  }
  return out;
}

void Vector_GPU::operator=(Vector_CPU &v) { // Copy assignment Vector_CPU -> this Vector_GPU
  printf("ASSIGNMENT #2 called\n");
  cudaFree(d_mat);
  h_rows = v.getRows();
  h_columns = v.getColumns();
  cudaMalloc((void **)&d_mat, sizeof(double) * v.rows * v.columns);
  cudaMemcpy(d_rows, &h_rows, sizeof(unsigned int), cudaMemcpyHostToDevice);
  cudaMemcpy(d_columns, &h_columns, sizeof(unsigned int), cudaMemcpyHostToDevice);
  cudaMemcpy(d_mat, &v.mat[0], sizeof(double) * h_rows * h_columns, cudaMemcpyHostToDevice);
}

Vector_GPU Vector_GPU::operator+(const Vector_GPU &v) {
  Vector_GPU out(this->h_rows, this->h_columns);
  dim3 grid(1, 1, 1);
  dim3 block(v.h_rows * v.h_columns, 1, 1);
  if (this->h_rows == v.h_rows && this->h_columns == v.h_columns) {
    add<<<grid, block>>>(this->d_mat, v.d_mat, out.d_mat);
  } else {
    printf("ARRAYS ARE NOT THE SAME SIZE, canot perform operation\n");
  }
  return out;
}

void Vector_GPU::printmat() {
  dim3 grid(1, 1, 1);
  printf("PRINTING\n");
  dim3 block(this->h_rows, this->h_columns, 1);

  print<<<grid, block>>>(this->d_mat);
}

Vector_CPU Vector_GPU::matDeviceToHost() {
  double *out = new double[this->h_columns * this->h_rows]; // heap to prevent a stack overflow
  unsigned int rows;
  unsigned int cols;
  cudaMemcpy(out, this->d_mat, sizeof(double) * this->h_columns * this->h_rows, cudaMemcpyDeviceToHost);
  // cudaMemcpy(out, this, size, cudaMemcpyDeviceToHost);
  cudaMemcpy(&rows, this->d_rows, sizeof(unsigned int), cudaMemcpyDeviceToHost);
  cudaMemcpy(&cols, this->d_columns, sizeof(unsigned int), cudaMemcpyDeviceToHost);
  // std::cout << "d_rows=" << rows << "=h_rows=" << this->h_rows << std::endl;
  // std::cout << "d_columns=" << cols << "=h_columns=" << this->h_columns << std::endl;
  if (rows != this->h_rows || cols != this->h_columns) {
    printf("INCONSISTENT ROWS AND COLS BETWEEN HOST AND DEVICE\n");
  }
  Vector_CPU v_cpu(this->h_rows, this->h_columns, out);
  return v_cpu;
}

Vector_GPU Vector_GPU::transpose() {
  Vector_GPU out(this->h_columns, this->h_rows);

  dim3 numOfThreadsInBlock(TILE_DIM_X, TILE_DIM_Y / 4, 1);
  unsigned int blocksX = (this->h_columns / TILE_DIM_X);
  unsigned int blocksY = (this->h_rows / TILE_DIM_Y);

  if (this->h_columns % TILE_DIM_X > 0) {
    blocksX += 1;
  };
  if (this->h_rows % TILE_DIM_Y > 0) {
    blocksY += 1;
  };
  dim3 numOfBlocksInGrid(blocksX, blocksY, 1);
  printf("threadsinblock(%d x %d)=%d, blocksingrid(%d, %d)=%d\n", numOfThreadsInBlock.x, numOfThreadsInBlock.y,
         numOfThreadsInBlock.x * numOfThreadsInBlock.y, numOfBlocksInGrid.x, numOfBlocksInGrid.y, numOfBlocksInGrid.x * numOfBlocksInGrid.y);
  transposeTiled<<<numOfBlocksInGrid, numOfThreadsInBlock>>>(this->d_mat, out.d_mat, this->d_rows, this->d_columns);
  return out;
};

Vector_GPU Vector_GPU::multNai(Vector_GPU &v) {
  printf("MATMULT\n");
  Vector_GPU out(this->h_rows, v.h_columns);
  dim3 numOfThreadsInBlock(TILE_DIM_X, TILE_DIM_Y, 1);
  unsigned int blocksY = (out.h_rows / TILE_DIM_X) + 1;
  unsigned int blocksX = (out.h_columns / TILE_DIM_Y) + 1;

  // if (out.h_columns % TILE_DIM_X > 0 || blocksX == 0) {
  //   blocksX += 2;
  // };
  // if (out.h_rows % TILE_DIM_Y > 0 || blocksY == 0) {
  //   blocksY += 2;
  // };

  dim3 numOfBlocksInGrid(blocksX, blocksY, 1);
  printf("threadsinblock(%d x %d)=%d, blocksingrid(%d, %d)=%d\n", numOfThreadsInBlock.x, numOfThreadsInBlock.y,
         numOfThreadsInBlock.x * numOfThreadsInBlock.y, numOfBlocksInGrid.x, numOfBlocksInGrid.y, numOfBlocksInGrid.x * numOfBlocksInGrid.y);
  multiplyNaive<<<numOfBlocksInGrid, numOfThreadsInBlock>>>(this->d_mat, this->d_rows, this->d_columns, v.d_mat, v.d_rows, v.d_columns, out.d_mat);
  // dim3 grid(1, 1, 1);
  // dim3 block(out.h_rows, out.h_columns, 1);
  // multiplyNaive<<<grid, block>>>(this->d_mat, this->d_rows, this->d_columns, v.d_mat, v.d_rows,
  //                                v.d_columns, out.d_mat);
  return out;
};