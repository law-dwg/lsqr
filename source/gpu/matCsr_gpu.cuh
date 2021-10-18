#pragma once
#include "../cpu/matVec_cpu.hpp"
#include "matVec_gpu.cuh"
#include <algorithm>
#include <stdio.h>  //NULL, printf
#include <stdlib.h> /* srand, rand */
#include <time.h>   /* time */
#include <vector>

class MatrixCsrGPU {
public:
  unsigned h_rows, h_columns, *d_rows, *d_columns;
  int *d_csrRowPtr, *d_csrColInd, *d_nnz, h_nnz;
  double *d_csrVal;
  MatrixCsrGPU() : MatrixCsrGPU(0, 0, 0) { // Default Constructor
    printf("MatrixCsrGPU Default constructor called\n");
    cudaErrCheck(cudaMemset(d_csrVal, ZERO, h_nnz * sizeof(double)));
    cudaErrCheck(cudaMemset(d_csrColInd, ZERO, h_nnz * sizeof(int)));
    cudaErrCheck(cudaMemset(d_csrRowPtr, ZERO, (h_rows + 1) * sizeof(int)));
  };
  MatrixCsrGPU(unsigned r, unsigned c, int n) : h_rows(r), h_columns(c), h_nnz(n) { // Constructor helper #1
    printf("MatrixCsrGPU Constructor #1 was called\n");
    // allocate
    cudaErrCheck(cudaMalloc((void **)&d_rows, sizeof(unsigned)));
    cudaErrCheck(cudaMalloc((void **)&d_columns, sizeof(unsigned)));
    cudaErrCheck(cudaMalloc((void **)&d_nnz, sizeof(int)));
    cudaErrCheck(cudaMalloc((void **)&d_csrVal, h_nnz * sizeof(double)));
    cudaErrCheck(cudaMalloc((void **)&d_csrColInd, h_nnz * sizeof(int)));
    cudaErrCheck(cudaMalloc((void **)&d_csrRowPtr, (h_rows + 1) * sizeof(int)));

    // copy to device
    cudaErrCheck(cudaMemcpy(d_rows, &h_rows, sizeof(unsigned), cudaMemcpyHostToDevice));
    cudaErrCheck(cudaMemcpy(d_columns, &h_columns, sizeof(unsigned), cudaMemcpyHostToDevice));
  };
  MatrixCsrGPU(unsigned r, unsigned c, long long int n, double *values, int *colInd, int *rowPtr) : MatrixCsrGPU(r, c, n) { // Helper constructor #2
    printf("MatrixCsrGPU Helper Constructor #2 called\n");
    // copy to device
    cudaErrCheck(cudaMemcpy(d_csrVal, values, h_nnz * sizeof(double), cudaMemcpyDeviceToDevice));
    cudaErrCheck(cudaMemcpy(d_csrColInd, colInd, h_nnz * sizeof(int), cudaMemcpyDeviceToDevice));
    cudaErrCheck(cudaMemcpy(d_csrRowPtr, rowPtr, (h_rows + 1) * sizeof(int), cudaMemcpyDeviceToDevice));
  }
  MatrixCsrGPU(unsigned r, unsigned c, double *m) : h_rows(r), h_columns(c), h_nnz(0) { // Constructor (entry point)
    printf("MatrixCsrGPU Constructor #2 was called\n");
    int row, col;
    col = row = 0;
    std::vector<int> temp_rowPtr, temp_colIdx;
    temp_rowPtr.push_back(0);
    std::vector<double> temp_vals;
    for (int i = 0; i < r * c; ++i) {
      if (((int)(i / c)) > row) {
        // printf("i=%d, h_nnz=%d, row=%d\n", i, h_nnz, row);
        temp_rowPtr.push_back(h_nnz);
        row = i / c;
      }
      col = i - (row * c);
      if (m[i] > 1e-15) {
        h_nnz += 1;
        temp_colIdx.push_back(col);
        temp_vals.push_back(m[i]);
      }
    }
    temp_rowPtr.push_back(h_nnz);
    // for (int i = 0; i < temp_rowPtr.size(); ++i) {
    //  printf("rowPtr[%d]=%d\n", i, temp_rowPtr[i]);
    //}
    // for (int i = 0; i < temp_colIdx.size(); ++i) {
    //  printf("temp_colIdx[%d]=%d\n", i, temp_colIdx[i]);
    //}
    // for (int i = 0; i < temp_vals.size(); ++i) {
    //  printf("temp_vals[%d]=%f\n", i, temp_vals[i]);
    //}
    // allocate
    cudaMalloc((void **)&d_rows, sizeof(unsigned));
    cudaMalloc((void **)&d_columns, sizeof(unsigned));
    cudaMalloc((void **)&d_nnz, sizeof(int));
    cudaMalloc((void **)&d_csrRowPtr, sizeof(unsigned) * (r + 1));
    cudaMalloc((void **)&d_csrColInd, sizeof(unsigned) * h_nnz);
    cudaMalloc((void **)&d_csrVal, sizeof(double) * h_nnz);
    // copy to device
    cudaMemcpy(d_rows, &h_rows, sizeof(unsigned), cudaMemcpyHostToDevice);
    cudaMemcpy(d_columns, &h_columns, sizeof(unsigned), cudaMemcpyHostToDevice);
    cudaMemcpy(d_nnz, &h_nnz, sizeof(int), cudaMemcpyHostToDevice);
    cudaMemcpy(d_csrRowPtr, temp_rowPtr.data(), sizeof(unsigned) * (r + 1), cudaMemcpyHostToDevice);
    cudaMemcpy(d_csrColInd, temp_colIdx.data(), sizeof(unsigned) * h_nnz, cudaMemcpyHostToDevice);
    cudaMemcpy(d_csrVal, temp_vals.data(), sizeof(double) * h_nnz, cudaMemcpyHostToDevice);
    printf("nnz = %d, rowIdx.size = %d, colIdx.size = %d\n", h_nnz, temp_rowPtr.size(), temp_colIdx.size());
  };
  MatrixCsrGPU(const MatrixCsrGPU &m) : MatrixCsrGPU(m.h_rows, m.h_columns, m.h_nnz, m.d_csrVal, m.d_csrColInd, m.d_csrRowPtr){}; // Copy constructor
  MatrixCsrGPU &operator=(const MatrixCsrGPU &m) { // Copy assignment operator
    printf("MatrixCsrGPU Copy Assignment Operator called\n");
    h_rows = m.h_rows;
    h_columns = m.h_columns;
    h_nnz = m.h_nnz;
    // destroy old allocation
    cudaErrCheck(cudaFree(d_csrVal));
    cudaErrCheck(cudaFree(d_csrColInd));
    cudaErrCheck(cudaFree(d_csrRowPtr));
    // memory allocation
    cudaErrCheck(cudaMalloc((void **)&d_csrVal, sizeof(double) * h_nnz));
    cudaErrCheck(cudaMalloc((void **)&d_csrColInd, sizeof(int) * h_nnz));
    cudaErrCheck(cudaMalloc((void **)&d_csrRowPtr, sizeof(int) * (h_rows + 1)));
    // copy to device
    cudaErrCheck(cudaMemcpy(d_rows, m.d_rows, sizeof(unsigned), cudaMemcpyDeviceToDevice));
    cudaErrCheck(cudaMemcpy(d_columns, m.d_columns, sizeof(unsigned), cudaMemcpyDeviceToDevice));
    cudaErrCheck(cudaMemcpy(d_nnz, m.d_nnz, sizeof(int), cudaMemcpyDeviceToDevice));
    cudaErrCheck(cudaMemcpy(d_csrVal, m.d_csrVal, h_nnz * sizeof(double), cudaMemcpyDeviceToDevice));
    cudaErrCheck(cudaMemcpy(d_csrColInd, m.d_csrColInd, h_nnz * sizeof(int), cudaMemcpyDeviceToDevice));
    cudaErrCheck(cudaMemcpy(d_csrRowPtr, m.d_csrRowPtr, (m.h_rows + 1) * sizeof(int), cudaMemcpyDeviceToDevice));
    return *this;
  };
  MatrixCsrGPU(MatrixCsrGPU &&m) noexcept
      : MatrixCsrGPU(m.h_rows, m.h_columns, m.h_nnz, m.d_csrVal, m.d_csrColInd, m.d_csrRowPtr) { // MatrixCsrGPU Move Constructor
    printf("MatrixCsrGPU Move Constructor called\n");
    // free old resources
    cudaErrCheck(cudaFree(m.d_csrVal));
    cudaErrCheck(cudaFree(m.d_csrRowPtr));
    cudaErrCheck(cudaFree(m.d_csrColInd));
    m.h_rows = ZERO;
    m.h_nnz = ZERO;
    m.h_columns = ZERO;
    cudaErrCheck(cudaMalloc((void **)&m.d_csrVal, h_nnz * sizeof(double)));
    cudaErrCheck(cudaMalloc((void **)&m.d_csrColInd, h_nnz * sizeof(int)));
    cudaErrCheck(cudaMalloc((void **)&m.d_csrRowPtr, (h_rows + 1) * sizeof(int)));
    cudaErrCheck(cudaMemcpy(m.d_rows, &m.h_rows, sizeof(unsigned), cudaMemcpyHostToDevice));
    cudaErrCheck(cudaMemcpy(m.d_columns, &m.h_columns, sizeof(unsigned), cudaMemcpyHostToDevice));
    cudaErrCheck(cudaMemcpy(m.d_nnz, &m.h_nnz, sizeof(int), cudaMemcpyHostToDevice));
    cudaErrCheck(cudaMemset(m.d_csrVal, ZERO, m.h_nnz * sizeof(double)));
    cudaErrCheck(cudaMemset(m.d_csrColInd, ZERO, m.h_nnz * sizeof(int)));
    cudaErrCheck(cudaMemset(m.d_csrRowPtr, ZERO, (m.h_rows + 1) * sizeof(int)));
  };
  MatrixCsrGPU &operator=(MatrixCsrGPU &&m) noexcept { // Move assignment operator
    printf("MatrixCsrGPU Copy Assignment called\n");
    // call copy assignment
    *this = m;
    // free old resources
    cudaErrCheck(cudaFree(m.d_csrVal));
    cudaErrCheck(cudaFree(m.d_csrRowPtr));
    cudaErrCheck(cudaFree(m.d_csrColInd));
    m.h_rows = ZERO;
    m.h_nnz = ZERO;
    m.h_columns = ZERO;
    cudaErrCheck(cudaMalloc((void **)&m.d_csrVal, h_nnz * sizeof(double)));
    cudaErrCheck(cudaMalloc((void **)&m.d_csrColInd, h_nnz * sizeof(int)));
    cudaErrCheck(cudaMalloc((void **)&m.d_csrRowPtr, (h_rows + 1) * sizeof(int)));
    cudaErrCheck(cudaMemcpy(m.d_rows, &m.h_rows, sizeof(unsigned), cudaMemcpyHostToDevice));
    cudaErrCheck(cudaMemcpy(m.d_columns, &m.h_columns, sizeof(unsigned), cudaMemcpyHostToDevice));
    cudaErrCheck(cudaMemcpy(m.d_nnz, &m.h_nnz, sizeof(int), cudaMemcpyHostToDevice));
    cudaErrCheck(cudaMemset(m.d_csrVal, ZERO, m.h_nnz * sizeof(double)));
    cudaErrCheck(cudaMemset(m.d_csrColInd, ZERO, m.h_nnz * sizeof(int)));
    cudaErrCheck(cudaMemset(m.d_csrRowPtr, ZERO, (m.h_rows + 1) * sizeof(int)));
    return *this;
  };
  ~MatrixCsrGPU() { // Destructor
    printf("DESTRUCTOR CALLED\n");
    cudaErrCheck(cudaFree(d_rows));
    cudaErrCheck(cudaFree(d_columns));
    cudaErrCheck(cudaFree(d_nnz));
    cudaErrCheck(cudaFree(d_csrColInd));
    cudaErrCheck(cudaFree(d_csrRowPtr));
    cudaErrCheck(cudaFree(d_csrVal));
  };
  Vector_GPU operator*(Vector_GPU &v); // Multiplication
};