#include <iostream>
#include <stdlib.h>
#include "CImg.h"
#include <time.h>
extern "C" int main2(unsigned char* imag);



void filtro(unsigned char* imag)
{
	int tr,tg,tb;
	unsigned char *R,*G,*B,*RR,*GG,*BB;
	RR=R=imag;
	GG=G=R+4096*4096;
	BB=B=G+4096*4096;
	R+=4096*2;
	G+=4096*2;
	B+=4096*2;
	for(int i=2;i<4094;i++)
	{
		R+=2;
		G+=2;
		B+=2;
		for(int j=2;j<4094;j++)
		{
			tr=tg=tb=0;
			for(int k=-2;k<3;k++)
			{
				for(int l=-2;l<3;l++)
				{
					tr+=*(R+k*4096+l);
					tg+=*(G+k*4096+l);
					tb+=*(B+k*4096+l);
				}
			}
			
			*R=tr/25;
			*G=tg/25;
			*B=tb/25;

			R++;
			G++;
			B++;
		}
		R=RR+4096*i;
		G=GG+4096*i;
		B=BB+4096*i;
	}
}
void borde(unsigned char* imag)
{
	unsigned char *R,*G,*B,*RR,*GG,*BB;
	RR=R=imag;
	GG=G=R+4096*4096;
	BB=B=G+4096*4096;
	unsigned char *T=new unsigned char[4096*4096];
	memset(T,0,4096*4096);
	unsigned char *TT=T;
	for(int i=0;i<4096;i++)
	{
		for(int j=0;j<4096;j++)
		{
			if(i!=4095 || j!=4095)
			{
				if(*R>*(R+1))
				{
					*T+=*R-*(R+1);
					*(T+1)+=*R-*(R+1);
				}
				else
				{
					*T+=*(R+1)-*R;
					*(T+1)+=*(R+1)-*R;
				}

				if(*R>*(R+4096))
				{
					*T+=*R-*(R+4096);
					*(T+4096)+=*R-*(R+4096);
				}
				else
				{
					*T+=*(R+4096)-*R;
					*(T+4096)+=*(R+4096)-*R;
				}

				if(*R>*(R+4097))
				{
					*T+=*R-*(R+4097);
					*(T+4097)+=*R-*(R+4097);
				}
				else
				{
					*T+=*(R+4097)-*R;
					*(T+4097)+=*(R+4097)-*R;
				}

				if(*G>*(G+1))
				{
					*T+=*G-*(G+1);
					*(T+1)+=*G-*(G+1);
				}
				else
				{
					*T+=*(G+1)-*G;
					*(T+1)+=*(G+1)-*G;
				}

				if(*G>*(G+4096))
				{
					*T+=*G-*(G+4096);
					*(T+4096)+=*G-*(G+4096);
				}
				else
				{
					*T+=*(G+4096)-*G;
					*(T+4096)+=*(G+4096)-*G;
				}

				if(*G>*(G+4097))
				{
					*T+=*G-*(G+4097);
					*(T+4097)+=*G-*(G+4097);
				}
				else
				{
					*T+=*(G+4097)-*G;
					*(T+4097)+=*(G+4097)-*G;
				}

				if(*B>*(B+1))
				{
					*T+=*B-*(B+1);
					*(T+1)+=*B-*(B+1);
				}
				else
				{
					*T+=*(B+1)-*B;
					*(T+1)+=*(B+1)-*B;
				}

				if(*B>*(B+4096))
				{
					*T+=*B-*(B+4096);
					*(T+4096)+=*B-*(B+4096);
				}
				else
				{
					*T+=*(B+4096)-*B;
					*(T+4096)+=*(B+4096)-*B;
				}

				if(*B>*(B+4097))
				{
					*T+=*B-*(B+4097);
					*(T+4097)+=*B-*(B+4097);
				}
				else
				{
					*T+=*(B+4097)-*B;
					*(T+4097)+=*(B+4097)-*B;
				}
			}
			
			
			T++;
			R++;
			G++;
			B++;
		}
		T=TT+4096*i;
		R=RR+4096*i;
		G=GG+4096*i;
		B=BB+4096*i;
	}

	R=imag;
	T=TT;
	for(int i=0;i<4096;i++)
	{
		for(int j=0;j<4096;j++)
		{
			/*
			*R=*T;
			*(R+4096*4096)=*T;
			*(R+4096*4096*2)=*T;
			*/
			//umbral 
			if(*(T)>85)
			{
				*R=255;
				*(R+4096*4096)=255;
				*(R+4096*4096*2)=255;
			}
			else
			{
				*R=0;
				*(R+4096*4096)=0;
				*(R+4096*4096*2)=0;
			}
			T++;
			R++;
		}
	}
}

int main(int argc, char** argv)
{
	cimg_library::CImg<unsigned char> alpha("planeta.bmp");
	unsigned char *a=&alpha(0,0,0);
	clock_t t_ini, t_fin;
	double secs;
	
	t_ini=clock();
	//filtro(a);
	//borde(a);
	

	main2(a);
	t_fin=clock();
	secs=(double)(t_fin-t_ini)/CLOCKS_PER_SEC;
	std::cout<<"tiempo que se demoro: "<<secs<<std::endl;
	alpha.display();
	
}