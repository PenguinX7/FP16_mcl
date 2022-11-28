#include <stdio.h>
#include <stdbool.h>

//Chinese encode with UTF-8;中文编码UTF-8

unsigned short FP16_mcl(unsigned short data1,unsigned short data2)
{
    unsigned short datanew;

    unsigned int sign1,exp1,rm1;
    unsigned int sign2,exp2,rm2;
    bool overflow;
    unsigned int rmcache;           //尾数计算
    unsigned short expcache;                 //阶数计算
    bool sign;                      //符号计算

    //step1:check
    sign1 = data1 >> 15;
    exp1 = (data1 >> 10) & 0x001f;
    sign2 = data2 >> 15;
    exp2 = (data2 >> 10) & 0x001f;
    if((((data1 >> 10) & 0x001f) == 0x1f) || (((data2 >> 10) & 0x001f) == 0x1f))    //溢出，data1[14:10]==11111 || data2[14:10]==11111
    {
        overflow = 1;
        rm1 = rm1;
        rm2 = rm2;
    }
    else if(((data1 & 0x7fff) == 0x0000) || ((data2 & 0x7fff) == 0x0000))                             //data1=0 || data2=0,~|data1[14:0] || ~|data2[14:0]
    {
        overflow = 0;
        rm1 = 0;
        rm2 = rm2;
    }
    else                             //正常
    {
        overflow = 0;
        rm2 = data2 & 0x03ff | 0x400;
        rm1 = data1 & 0x03ff | 0x400;
    }
    
    /*-------------------------step2:calculate------------------------------*/
    if(overflow)
    {}
    else
    {
        rmcache = rm1 * rm2;            //尾数相乘
        expcache = exp1 + exp2 - 15;        //阶数相加减15
        sign = sign1 ^ sign2;
    }                                       //符号异或

    /*-------------------------step3:carry------------------------------*/
    if(overflow)
    {}
    else
    {
        if((rmcache & 0x00200000) == 0x00200000 )           //如果第22位是1，即溢出
        {
            rmcache = rmcache >> 1;                         //尾数右移一位
            if(expcache == 30)
                overflow = 1;
            else
                expcache = expcache + 1;                        //阶数加一
        }
    }
        
    /*-----------------------step4:round to nearest even------------------------*/
    if(overflow)
    {}
    else
    {
        if( ((rmcache & 0x00000200) == 0x00000200) && (((rmcache & 0x00000400) == 0x00000400) || ((rmcache & 0x0000001ff) != 0x00000000)) )  
        {
            rmcache = rmcache + 0x00000400;                 //判断入条件:(第九位 && (第十位 || 低八位有没有1))，入则第十位加一
        }
    }

    /*-----------------------step5:carry again-------------------------------*/
    if(overflow)
    {}
    else
    {
        if((rmcache & 0x00200000) == 0x00200000)              //如果入了又溢出，即第22位是1
        {
            rmcache = rmcache >> 1;                         //尾数右移一位
            if(expcache == 30)
                overflow = 1;
            else
                expcache = expcache + 1;                        //阶数加一
        }
    }

    /*-----------------------step5:result----------------------------*/
    if(((expcache > 30) && (expcache < 63)) || overflow)                                   //阶数大于31或溢出，上溢出,expcache[6:5]==01
        datanew =  (sign << 15) | 0x7fff;
    else if (((expcache & 0x0040) == 0x0040) || (expcache ==0))                                             //expcache[6] == 1或expcache=0
        datanew = 0x0000;
    else                             //阶数正常，拼接符号位+阶数+尾数
        datanew = (sign << 15) | ((expcache & 0x001f) << 10) | ((rmcache & 0x000ffc00) >> 10);

    return datanew;


}

/*
int main()
{
    unsigned short data1 = 0x4ce3;
    unsigned short data2 = 0x6c00;
    unsigned short data_o = FP16_mcl(data1,data2);
    return 0 ;
}*/