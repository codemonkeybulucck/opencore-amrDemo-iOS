//
//  8KWavToAmr.h
//  -01VoiceForAMR
//  提供了8KHZ 的编码和解码   和 16kHZ的编码和解码
//  Created by 势必可赢 on 16/6/16.
//  Copyright © 2016年 势必可赢. All rights reserved.
//

#ifndef WavToAmr_h
#define WavToAmr_h
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include "interf_dec.h"
#include "interf_enc.h"
#include "enc_if.h"
#include "dec_if.h"

#define AMRNB_MAGIC_NUMBER "#!AMR\n"
#define AMRWB_MAGIC_NUMBER "#!AMR-WB\n"

#define PCMNB_FRAME_SIZE 160 // 8khz 8000*0.02=160
#define PCMWB_FRAME_SIZE 320 //16khz
#define MAX_AMR_FRAME_SIZE 32
#define AMR_FRAME_COUNT_PER_SECOND 50

typedef struct
{
    char chChunkID[4];
    int nChunkSize;
}XCHUNKHEADER;

typedef struct
{
    short nFormatTag;
    short nChannels;
    int nSamplesPerSec;
    int nAvgBytesPerSec;
    short nBlockAlign;
    short nBitsPerSample;
}WAVEFORMAT;

typedef struct
{
    short nFormatTag;
    short nChannels;
    int nSamplesPerSec;
    int nAvgBytesPerSec;
    short nBlockAlign;
    short nBitsPerSample;
    short nExSize;
}WAVEFORMATX;

typedef struct
{
    char chRiffID[4];
    int nRiffSize;
    char chRiffFormat[4];
}RIFFHEADER;

typedef struct
{
    char chFmtID[4];
    int nFmtSize;
    WAVEFORMAT wf;
}FMTBLOCK;

typedef enum
{
    SAMPLERATETYPEEightKHZ,
    SAMPLERATETYPESiXTeenKHZ
}SAMPLERATETYPE;

/**
 *  WAV 转 amr
 *
 *  @param pchWAVEFilename wav文件路径
 *  @param pchAMRFileName  amr文件路径
 *  @param nChannels       信道数
 *  @param nBitsPerSample  采样位数
 *  @param sampleRateType  采样率类型
 *
 *  @return 是否编码成功
 */
int EncodeWAVEFileToAMRFile(const char* pchWAVEFilename, const char* pchAMRFileName, int nChannels, int nBitsPerSample,SAMPLERATETYPE sampleRateType);

/**
 *  AMR 转 WAV
 *
 *  @param pchAMRFileName  amr文件路径
 *  @param pchWAVEFilename wav文件路径
 *  @param sampleRateType  采样率类型
 *
 *  @return 是否解码成功
 */
int DecodeAMRFileToWAVEFile(const char* pchAMRFileName, const char* pchWAVEFilename,SAMPLERATETYPE sampleRateType);

#endif