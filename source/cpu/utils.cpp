#include "utils.hpp"
#ifdef _WIN32
#include <Windows.h>
#else
#include <unistd.h>
#endif
#include <algorithm>
#include <cassert>
#include <chrono>
#include <cstdio>
#include <ctime>
#include <fstream>
#include <iomanip>
#include <iterator>
#include <limits>
#include <math.h>
#include <random>
#include <sstream>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

bool compareMat(double *MC, int rowC, int colC, double *MG, int rowG, int colG) {
  bool same = true;
  double epsilon = 1e-9;
  if (rowC != rowG || colC != colG || !same) {
    printf("MATRICIES SIZE  DO NOT MATCH matCPU(%d x %d) != matGPU(%d, %d)\n", rowC, colC, rowG, rowC);
    same = false;
  }
  if (same) {
    for (int i = 0; i < rowC * colC; i++) {
      // printf("MG[%d] = %f, MC[%d] = %f\n", i, MG[i], i, MC[i]);
      // printf("DIFF = %f, %f == %f\n", std::abs(MG[i] - MC[i]), MG[i], MC[i]);
      if (!(std::abs(MG[i] - MC[i]) < epsilon)) {
        printf("MATRICIES SIZE (%d x %d) DO NOT MATCH DISCREPANCY AT INDEX %d; DIFF = %f, %f "
               "== %f\n",
               rowC, colC, i, std::abs(MG[i] - MC[i]), MG[i], MC[i]);
        printf("MG[%d]=%f, MC[%d]=%f\nMG[%d]=%f, MC[%d]=%f\nMG[%d]=%f, "
               "MC[%d]=%f\nMG[%d]=%f, MC[%d]=%f\n",
               i - 1, MG[i - 1], i - 1, MC[i - 1], i, MG[i], i, MC[i], i + 1, MG[i + 1], i + 1, MC[i + 1], i + 2, MG[i + 2], i + 2, MC[i + 2]);
        printf("LAST ELEMENTS MG[%d]=%f, MC[%d]=%f\n", (rowC * colC) - 1, MG[(rowC * colC) - 1], (rowC * colC) - 1, MC[(rowC * colC) - 1]);
        same = false;
        break;
      }
    }
  };
  if (same) {
    printf("MATRICES MATCH FOR (%d x %d)\n", rowC, colC);
  };
  return same;
};

bool compareVal(double *VC, double *VG) {
  typedef std::numeric_limits<double> dbl;
  bool same = false;
  printf("GPU: %20f\n", *VG);
  printf("CPU: %20f\n", *VC);
  std::cout.precision(dbl::max_digits10);
  std::cout << *VC << std::endl;
  std::cout << *VG << std::endl;
  std::cout << std::abs(*VC - *VG) << std::endl;
  if (std::abs(*VC - *VG) < 1e-15) {
    printf("THEY ARE SAME\n");
    same = true;
  } else {
    printf("THEY ARE NOT SAME\n");
  }
  return same;
}

void writeArrayToFile(std::string dest, unsigned rows, unsigned cols, double *arr) {
  typedef std::numeric_limits<double> dbl;
  std::ofstream myfileA(dest);
  if (myfileA.is_open()) {
    for (int count = 0; count < rows * cols; count++) {
      if (count % cols == 0 && count != 0) {
        myfileA << "\n";
      }
      if ((count % cols) == (cols - 1)) {
        myfileA << std::setprecision(16) << arr[count];
      } else {
        myfileA << std::setprecision(16) << arr[count] << " ";
      }
    }
    myfileA.close();
    std::cout << "Data written to " << dest << std::endl;
  } else
    std::cout << "Unable to open file";
};

void readArrayFromFile(const char *path, unsigned r, unsigned c, std::vector<double> &mat) {
  // mat.resize(r*c); // not necessary
  std::ifstream file(path);
  assert(file.is_open());
  std::copy(std::istream_iterator<double>(file), std::istream_iterator<double>(), std::back_inserter(mat));
  file.close();
};

double rands() {
  static std::random_device rd;
  static std::mt19937 rng(rd());
  static std::uniform_int_distribution<std::mt19937::result_type> dist25(1, 25); // distribution in range [1, 6]
  // std::cout << dist25(rng) << std::endl;
  return dist25(rng);
}

void matrixBuilder(unsigned r, unsigned c, double sparsity, const char *dir, const char *matLetter) {
  // typedef std::mt19937 MyRNG; // the Mersenne Twister with a popular choice of parameters
  // uint32_t seed_val;          // populate somehow
  //
  // MyRNG rng; // e.g. keep one global instance (per thread)
  //
  // void initialize() { rng.seed(seed_val); }
  rands();
  std::vector<double> mat(r * c, 0.0);
  int zeros = round(sparsity * r * c);
  int nonZeros = r * c - zeros;
  // std::cout<<zeros<<std::endl;

  // printf("%f sparsity for %i elements leads to %f zero values which rounds to
  // %d. That means there are %d nonzero
  // values\n",this->sparsity,r*c,this->sparsity * r*c,zeros,nonZeros);
  // printf("mat size: %i\n",mat.size());
  for (int i = 0; i < nonZeros; i++) {
    mat[i] = rands();
  }
  std::random_shuffle(mat.begin(), mat.end());
  std::string fileExt = (*matLetter == 'A') ? "mat" : "vec";
  std::stringstream fileName;
  fileName << dir << r << "_" << c << "_" << (int)(sparsity * 100) << "_" << matLetter << "." << fileExt;
  writeArrayToFile(fileName.str(), r, c, mat.data());
};

void loading() {
  std::cout << "Loading";
  std::cout.flush();
  for (;;) {
    for (int i = 0; i < 3; i++) {
      std::cout << ".";
      std::cout.flush();
      sleep(1);
    }
    std::cout << "\b\b\b   \b\b\b";
  }
}

bool yesNo() {
  while (true) {
    std::string s;
    std::cin >> std::ws;
    getline(std::cin, s);
    if (s.empty())
      continue;
    switch (toupper(s[0])) {
    case 'Y':
      return true;
    case 'N':
      return false;
    }
    std::cout << "Invalid input, please enter Y for yes and N for no: ";
  }
}

void fileParserLoader(std::string file, unsigned &A_r, unsigned &A_c, std::vector<double> &A, unsigned &b_r, unsigned &b_c, std::vector<double> &b) {
  std::string path = file.c_str(); // keep path for reading data

  // parse filename
  std::vector<std::string> delim{"/\\", ".", "_"};
  size_t dot = file.find_last_of(delim[1]);           // file extension location
  size_t slash = file.find_last_of(delim[0]);         // file prefix location
  file.erase(file.begin() + dot, file.end());         // remove file extension
  file.erase(file.begin(), file.begin() + slash + 1); // remove file prefix
  size_t unders2 = file.find_last_of(delim[2]);       // underscore at end of filename
  size_t unders1 = file.find(delim[2]);               // underscore at beginning of filename

  // read and allocate data
  if (file.substr(unders2 + 1) == "A") { // A Matrix
    std::string temp = file.substr(unders1 + 1, (unders2 - unders1));
    size_t unders3 = temp.find(delim[2]);
    A_r = std::stoi(file.substr(0, unders1)); // read rows from filename
    A_c = std::stoi(temp.substr(0, unders3)); // read cols from filename
    printf("Loading matrix A(%d,%d)...", A_r, A_c);
    readArrayFromFile(path.c_str(), A_r, A_c, A);
    printf(" done\n");
  } else if (file.substr(unders2 + 1) == "b") {                     // b Vector
    b_r = std::stoi(file.substr(0, unders1));                       // read rows from filename
    b_c = std::stoi(file.substr(unders1 + 1, (unders2 - unders1))); // read cols from filename
    printf("Loading matrix b(%d,%d)...", b_r, b_c);
    readArrayFromFile(path.c_str(), b_r, b_c, b);
    printf(" done\n");
  } else { // err
    printf("Error while trying to read %s, please rename to either \"NumOfRows_1_b.vec\" or \"NumOfRows_NumOfCols_A.mat\" \n", path);
  }
}