//
#include "cuda_runtime.h"
#include "device_launch_parameters.h"

#include <stdio.h>
#include <algorithm>
//Limite de hilos 1024

#define M 4096

__global__ void filtroKernel(unsigned char *a)
{
	int j=blockIdx.x;
	int i=threadIdx.x;
	int R,G,B;
	int tr,tg,tb;
	for(i=threadIdx.x;i<4096;i+=1024)
	{
		
		if(i>1||i<4094||j>1||j<4094)
		{
			tr=tg=tb=0;
			R=i+j*4096;
			G=i+j*4096+4096*4096;
			B=i+j*4096+4096*4096*2;
			for(int x=-2;x<3;x++)
			{
				for(int y=-2;y<3;y++)
				{
					tr+=a[R+x+y*M];
					tg+=a[G+x+y*M];
					tb+=a[B+x+y*M];
				}
			}
			__syncthreads:
			a[R]=tr/25;
			a[G]=tg/25;
			a[B]=tb/25;
		}
	}

}

__global__ void bordeKernel(unsigned char* a,int* temp)
{
	int j=blockIdx.x;
	int i=threadIdx.x;
	int R,G,B;

	if(j==0||j==4095)
		return;
	
	for(i=threadIdx.x;i<4095;i+=1024)
	{
		if(i==0)
			continue;
		R=i+j*4096;
		G=i+j*4096+4096*4096;
		B=i+j*4096+4096*4096*2;

		for(int x=-1;x<2;x++)
		{
			for(int y=-1;y<2;y++)
			{
				temp[R]+=std::abs(a[R]-a[R+x+M*y]);
				temp[R]+=std::abs(a[G]-a[G+x+M*y]);
				temp[R]+=std::abs(a[B]-a[B+x+M*y]);
			}
		}

		temp[R]/=9;
	}





	
}

__global__ void finKernel(unsigned char* a,int* temp)
{
	int j=blockIdx.x;
	int i=threadIdx.x;
	int R,G,B;
	for(i=threadIdx.x;i<4096;i+=1024)
	{
		R=i+j*4096;
		G=i+j*4096+4096*4096;
		B=i+j*4096+4096*4096*2;
		//a[R]=a[G]=a[B]=temp[R];
		
		
		if(temp[R]>20)
		{
			a[R]=a[G]=a[B]=255;
		}
		else
		{
			a[R]=a[G]=a[B]=0;
		}
		
	}
}

extern "C"
int main2(unsigned char* imag)
{
	cudaError_t cudaStatus=cudaSetDevice(0);
	unsigned char *Im=0;
	int *Temp=0;
	cudaStatus = cudaMalloc<unsigned char>(&Im,4096*4096*3*sizeof(unsigned char));
	
	cudaStatus = cudaMalloc<int>(&Temp,4096*4096*sizeof(int));
	
	cudaStatus = cudaMemcpy(Im,imag,4096*4096*3*sizeof(unsigned char),cudaMemcpyHostToDevice);

	cudaStatus= cudaMemset(Temp,0,4096*4096*sizeof(int));
	
	filtroKernel<<<4096,1024>>>(Im);

	cudaDeviceSynchronize();
	bordeKernel<<<4096,1024>>>(Im,Temp);
	cudaStatus=cudaGetLastError();
	if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "1! fallo lanzamiento!  Lo has hecho bien?\n");
    }
	cudaDeviceSynchronize();
	finKernel<<<4096,1024>>>(Im,Temp);



	cudaStatus=cudaMemcpy(imag,Im,4096*4096*3*sizeof(unsigned char),cudaMemcpyDeviceToHost);

	if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "2! fallo lanzamiento!  Lo has hecho bien?\n");
    }

    return 0;
}
/*
// Helper function for using CUDA to add vectors in parallel.
cudaError_t addWithCuda(int *c, const int *a, const int *b, unsigned int size)
{
    int *dev_a = 0;
    int *dev_b = 0;
    int *dev_c = 0;
    cudaError_t cudaStatus;

    // Choose which GPU to run on, change this on a multi-GPU system.
    cudaStatus = cudaSetDevice(0);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaSetDevice failed!  Do you have a CUDA-capable GPU installed?");
        goto Error;
    }

    // Allocate GPU buffers for three vectors (two input, one output)    .
    cudaStatus = cudaMalloc((void**)&dev_c, size * sizeof(int));
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMalloc failed!");
        goto Error;
    }

    cudaStatus = cudaMalloc((void**)&dev_a, size * sizeof(int));
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMalloc failed!");
        goto Error;
    }

    cudaStatus = cudaMalloc((void**)&dev_b, size * sizeof(int));
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMalloc failed!");
        goto Error;
    }

    // Copy input vectors from host memory to GPU buffers.
    cudaStatus = cudaMemcpy(dev_a, a, size * sizeof(int), cudaMemcpyHostToDevice);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMemcpy failed!");
        goto Error;
    }

    cudaStatus = cudaMemcpy(dev_b, b, size * sizeof(int), cudaMemcpyHostToDevice);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMemcpy failed!");
        goto Error;
    }

    // Launch a kernel on the GPU with one thread for each element.
    addKernel<<<1, size>>>(dev_c, dev_a, dev_b);

    // Check for any errors launching the kernel
    cudaStatus = cudaGetLastError();
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "addKernel launch failed: %s\n", cudaGetErrorString(cudaStatus));
        goto Error;
    }
    
    // cudaDeviceSynchronize waits for the kernel to finish, and returns
    // any errors encountered during the launch.
    cudaStatus = cudaDeviceSynchronize();
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaDeviceSynchronize returned error code %d after launching addKernel!\n", cudaStatus);
        goto Error;
    }

    // Copy output vector from GPU buffer to host memory.
    cudaStatus = cudaMemcpy(c, dev_c, size * sizeof(int), cudaMemcpyDeviceToHost);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMemcpy failed!");
        goto Error;
    }

Error:
    cudaFree(dev_c);
    cudaFree(dev_a);
    cudaFree(dev_b);
    
    return cudaStatus;
}
*/