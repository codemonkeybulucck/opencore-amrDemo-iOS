//
//  8KWavToAmr.m
//  -01VoiceForAMR
//
//  Created by 势必可赢 on 16/6/16.
//  Copyright © 2016年 势必可赢. All rights reserved.
//

#include "WavToAmr.h"
int amrnbEncodeMode[] = {4750, 5150, 5900, 6700, 7400, 7950, 10200, 12200}; // amr 编码方式
int amrwbEncodeMode [] =  {6600,8850,12650,14250,15850,18250,19850,23050,23850};//九种编码方式
// 从WAVE文件中跳过WAVE文件头，直接到PCM音频数据
void SkipToPCMAudioData(FILE* fpwave)
{
    RIFFHEADER riff;
    FMTBLOCK fmt;
    XCHUNKHEADER chunk;
    WAVEFORMATX wfx;
    int bDataBlock = 0;
    
    // 1. 读RIFF头
    fread(&riff, 1, sizeof(RIFFHEADER), fpwave);
    
    // 2. 读FMT块 - 如果 fmt.nFmtSize>16 说明需要还有一个附属大小没有读
    fread(&chunk, 1, sizeof(XCHUNKHEADER), fpwave);
    if ( chunk.nChunkSize>16 )
    {
        fread(&wfx, 1, sizeof(WAVEFORMATX), fpwave);
    }
    else
    {
        memcpy(fmt.chFmtID, chunk.chChunkID, 4);
        fmt.nFmtSize = chunk.nChunkSize;
        fread(&fmt.wf, 1, sizeof(WAVEFORMAT), fpwave);
    }
    
    // 3.转到data块 - 有些还有fact块等。
    while(!bDataBlock)
    {
        fread(&chunk, 1, sizeof(XCHUNKHEADER), fpwave);
        if ( !memcmp(chunk.chChunkID, "data", 4) )
        {
            bDataBlock = 1;
            break;
        }
        // 因为这个不是data块,就跳过块数据
        fseek(fpwave, chunk.nChunkSize, SEEK_CUR);
    }
}

// 从WAVE文件读一个完整的PCM音频帧
// 返回值: 0-错误 >0: 完整帧大小
int ReadPCMFrame(short speech[], FILE* fpwave, int nChannels, int nBitsPerSample,SAMPLERATETYPE sampleRateType)
{
    int nRead = 0;
    int x = 0, y=0;
    //	unsigned short ush1=0, ush2=0, ush=0;
    int pcm_frame_size;
    if (sampleRateType == SAMPLERATETYPEEightKHZ)
    {
        pcm_frame_size = PCMNB_FRAME_SIZE;
    }
    if (sampleRateType ==SAMPLERATETYPESiXTeenKHZ)
    {
        pcm_frame_size = PCMWB_FRAME_SIZE;
    }
    // 原始PCM音频帧数据
    unsigned char  pcmFrame_8b1[pcm_frame_size];
    unsigned char  pcmFrame_8b2[pcm_frame_size<<1];
    unsigned short pcmFrame_16b1[pcm_frame_size];
    unsigned short pcmFrame_16b2[pcm_frame_size<<1];
    
    if (nBitsPerSample==8 && nChannels==1)
    {
        
        nRead = fread(pcmFrame_8b1, (nBitsPerSample/8), pcm_frame_size*nChannels, fpwave);
        
        for(x=0; x<pcm_frame_size; x++)
        {
            speech[x] =(short)((short)pcmFrame_8b1[x] << 7);
        }
    }
    else
    if (nBitsPerSample==8 && nChannels==2)
    {
        nRead = fread(pcmFrame_8b2, (nBitsPerSample/8), pcm_frame_size*nChannels, fpwave);
        for( x=0, y=0; y<pcm_frame_size; y++,x+=2 )
        {
            // 1 - 取两个声道之左声道
            speech[y] =(short)((short)pcmFrame_8b2[x+0] << 7);
            // 2 - 取两个声道之右声道
            //speech[y] =(short)((short)pcmFrame_8b2[x+1] << 7);
            // 3 - 取两个声道的平均值
            //ush1 = (short)pcmFrame_8b2[x+0];
            //ush2 = (short)pcmFrame_8b2[x+1];
            //ush = (ush1 + ush2) >> 1;
            //speech[y] = (short)((short)ush << 7);
        }
    }
    else
    if (nBitsPerSample==16 && nChannels==1)
    {
        nRead = fread(pcmFrame_16b1, (nBitsPerSample/8), pcm_frame_size*nChannels, fpwave);
        for(x=0; x<pcm_frame_size; x++)
        {
            speech[x] = (short)pcmFrame_16b1[x+0];
        }
    }
    else
				if (nBitsPerSample==16 && nChannels==2)
				{
                    nRead = fread(pcmFrame_16b2, (nBitsPerSample/8), pcm_frame_size*nChannels, fpwave);
                    for( x=0, y=0; y<pcm_frame_size; y++,x+=2 )
                    {
                        //speech[y] = (short)pcmFrame_16b2[x+0];
                        speech[y] = (short)((int)((int)pcmFrame_16b2[x+0] + (int)pcmFrame_16b2[x+1])) >> 1;
                    }
                }
    
    // 如果读到的数据不是一个完整的PCM帧, 就返回0
    if (nRead<pcm_frame_size*nChannels) return 0;
    
    return nRead;
}


int EncodeWAVEFileToAMRFile(const char* pchWAVEFilename, const char* pchAMRFileName, int nChannels, int nBitsPerSample,SAMPLERATETYPE sampleRateType)
{
    FILE* fpwave;
    FILE* fpamr;
    
    /* input speech vector */
    short speechnb[160];
    short speechwb[320];
    
    /* counters */
    int byte_counter, frames = 0, bytes = 0;
    
    /* pointer to encoder state structure */
    void *enstate;
    
    /* requested mode */
    enum Mode nbreq_mode = MR122;
    enum WBMode wbreq_mode = WB1265;
    
    int dtx = 0;
    
    /* bitstream filetype */
    unsigned char amrFrame[MAX_AMR_FRAME_SIZE];
    
    fpwave = fopen(pchWAVEFilename, "rb");
    if (fpwave == NULL)
    {
        return 0;
    }
    
    // 创建并初始化amr文件
    fpamr = fopen(pchAMRFileName, "wb");
    if (fpamr == NULL)
    {
        fclose(fpwave);
        return 0;
    }
    /* write magic number to indicate single channel AMR file storage format */
    if (sampleRateType == SAMPLERATETYPEEightKHZ)
    {
        bytes = fwrite(AMRNB_MAGIC_NUMBER, sizeof(char), strlen(AMRNB_MAGIC_NUMBER), fpamr);

    }
    else
    {
         bytes = fwrite(AMRWB_MAGIC_NUMBER, sizeof(char), strlen(AMRWB_MAGIC_NUMBER), fpamr);
    }
    
    /* skip to pcm audio data*/
    SkipToPCMAudioData(fpwave);
    
    //8KHZ编码
    if (sampleRateType == SAMPLERATETYPEEightKHZ)
    {
        enstate = Encoder_Interface_init(dtx);
        
        while(1)
        {
            // read one pcm frame
            if (!ReadPCMFrame(speechnb, fpwave, nChannels, nBitsPerSample,sampleRateType)) break;
            
            frames++;
            
            /* call encoder */
            byte_counter = Encoder_Interface_Encode(enstate, nbreq_mode, speechnb, amrFrame, 0);
            
            bytes += byte_counter;
            fwrite(amrFrame, sizeof (unsigned char), byte_counter, fpamr );
        }
        
        Encoder_Interface_exit(enstate);
        
        fclose(fpamr);
        fclose(fpwave);
        
        return frames;
    }
    //16kHZ编码
    else
    {
        enstate = E_IF_init();
        
        while(1)
        {
            // read one pcm frame
            if (!ReadPCMFrame(speechwb, fpwave, nChannels, nBitsPerSample,sampleRateType)) break;
            
            frames++;
            
            /* call encoder */
            byte_counter = E_IF_encode(enstate, wbreq_mode, speechwb, amrFrame, dtx);
            
            bytes += byte_counter;
            fwrite(amrFrame, sizeof (unsigned char), byte_counter, fpamr );
        }
        
        E_IF_exit(enstate);
        
        fclose(fpamr);
        fclose(fpwave);
        
        return frames;
    }
}




#pragma mark - Decode
//decode
void WriteWAVEFileHeader(FILE* fpwave, int nFrame,SAMPLERATETYPE sampleRateType)
{
    char tag[10] = "";
    
    // 1. 写RIFF头
    RIFFHEADER riff;
    strcpy(tag, "RIFF");
    memcpy(riff.chRiffID, tag, 4);
    riff.nRiffSize = 4                                     // WAVE
    + sizeof(XCHUNKHEADER)               // fmt
    + sizeof(WAVEFORMATX)           // WAVEFORMATX
    + sizeof(XCHUNKHEADER)               // DATA
    + nFrame*160*sizeof(short);    //
    strcpy(tag, "WAVE");
    memcpy(riff.chRiffFormat, tag, 4);
    fwrite(&riff, 1, sizeof(RIFFHEADER), fpwave);
    
    // 2. 写FMT块
    XCHUNKHEADER chunk;
    WAVEFORMATX wfx;
    strcpy(tag, "fmt ");
    memcpy(chunk.chChunkID, tag, 4);
    chunk.nChunkSize = sizeof(WAVEFORMATX);
    fwrite(&chunk, 1, sizeof(XCHUNKHEADER), fpwave);
    memset(&wfx, 0, sizeof(WAVEFORMATX));
    wfx.nFormatTag = 1;
    wfx.nChannels = 1; // 单声道
    wfx.nSamplesPerSec = 8000; // 8khz
    //16kHZ
    if (sampleRateType == SAMPLERATETYPESiXTeenKHZ)
    {
        wfx.nSamplesPerSec = 16000;
    }
    wfx.nAvgBytesPerSec = 16000;
    wfx.nBlockAlign = 2;
    wfx.nBitsPerSample = 16; // 16位
    fwrite(&wfx, 1, sizeof(WAVEFORMATX), fpwave);
    
    // 3. 写data块头
    strcpy(tag, "data");
    memcpy(chunk.chChunkID, tag, 4);
    chunk.nChunkSize = nFrame*160*sizeof(short);
    fwrite(&chunk, 1, sizeof(XCHUNKHEADER), fpwave);
}

const int myround(const double x)
{
    return((int)(x+0.5));
}

// 根据帧头计算当前帧大小
int caclAMRFrameSize(unsigned char frameHeader,SAMPLERATETYPE sampleRateType)
{
    int mode;
    int temp1 = 0;
    int temp2 = 0;
    int frameSize;
    
    temp1 = frameHeader;
    
    // 编码方式编号 = 帧头的3-6位
    temp1 &= 0x78; // 0111-1000
    temp1 >>= 3;
    
    if (sampleRateType == SAMPLERATETYPEEightKHZ)
    {
        mode = amrnbEncodeMode[temp1];
    }
    if (sampleRateType == SAMPLERATETYPESiXTeenKHZ)
    {
        mode = amrwbEncodeMode[temp1];
    }
    
    // 计算amr音频数据帧大小
    // 原理: amr 一帧对应20ms，那么一秒有50帧的音频数据
    temp2 = myround((double)(((double)mode / (double)AMR_FRAME_COUNT_PER_SECOND) / (double)8));
    
    frameSize = myround((double)temp2 + 0.5);
    return frameSize;
}

// 读第一个帧 - (参考帧)
// 返回值: 0-出错; 1-正确
int ReadAMRFrameFirst(FILE* fpamr, unsigned char frameBuffer[], int* stdFrameSize, unsigned char* stdFrameHeader,SAMPLERATETYPE sampleRateType)
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wsizeof-array-argument"
#pragma clang diagnostic ignored "-Wsizeof-pointer-memaccess"
    memset(frameBuffer, 0, sizeof(frameBuffer));
#pragma clang diagnostic pop
    
    // 先读帧头
    fread(stdFrameHeader, 1, sizeof(unsigned char), fpamr);
    if (feof(fpamr)) return 0;
    
    // 根据帧头计算帧大小
    *stdFrameSize = caclAMRFrameSize(*stdFrameHeader,sampleRateType);
    
    // 读首帧
    frameBuffer[0] = *stdFrameHeader;
    fread(&(frameBuffer[1]), 1, (*stdFrameSize-1)*sizeof(unsigned char), fpamr);
    if (feof(fpamr)) return 0;
    
    return 1;
}

// 返回值: 0-出错; 1-正确
int ReadAMRFrame(FILE* fpamr, unsigned char frameBuffer[], int stdFrameSize, unsigned char stdFrameHeader)
{
    int bytes = 0;
    unsigned char frameHeader; // 帧头
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wsizeof-array-argument"
#pragma clang diagnostic ignored "-Wsizeof-pointer-memaccess"
    memset(frameBuffer, 0, sizeof(frameBuffer));
#pragma clang diagnostic pop
    
    // 读帧头
    // 如果是坏帧(不是标准帧头)，则继续读下一个字节，直到读到标准帧头
    while(1)
    {
        bytes = fread(&frameHeader, 1, sizeof(unsigned char), fpamr);
        if (feof(fpamr)) return 0;
        if (frameHeader == stdFrameHeader) break;
    }
    
    // 读该帧的语音数据(帧头已经读过)
    frameBuffer[0] = frameHeader;
    bytes = fread(&(frameBuffer[1]), 1, (stdFrameSize-1)*sizeof(unsigned char), fpamr);
    if (feof(fpamr)) return 0;
    
    return 1;
}

// 将AMR文件解码成WAVE文件
int DecodeAMRFileToWAVEFile(const char* pchAMRFileName, const char* pchWAVEFilename,SAMPLERATETYPE sampleRateType)
{
    
    
    FILE* fpamr = NULL;
    FILE* fpwave = NULL;
    char nbMagic[8];
    char wbMagic[9];
    void * destate;
    int nFrameCount = 0;
    int stdFrameSize;
    unsigned char stdFrameHeader;
    
    unsigned char amrFrame[MAX_AMR_FRAME_SIZE];
    int pcm_frame_size;
    if (sampleRateType == SAMPLERATETYPEEightKHZ)
    {
        pcm_frame_size = PCMNB_FRAME_SIZE;
    }
    if (sampleRateType == SAMPLERATETYPESiXTeenKHZ)
    {
        pcm_frame_size = PCMWB_FRAME_SIZE;
    }
    short pcmFrame[pcm_frame_size];
    
    //	NSString * path = [[NSBundle mainBundle] pathForResource:  @"test" ofType: @"amr"];
    //	fpamr = fopen([path cStringUsingEncoding:NSASCIIStringEncoding], "rb");
    fpamr = fopen(pchAMRFileName, "rb");
    
    if ( fpamr==NULL ) return 0;
    // 检查amr文件头
    if (sampleRateType == SAMPLERATETYPEEightKHZ)
    {
        fread(nbMagic, sizeof(char), strlen(AMRNB_MAGIC_NUMBER), fpamr);
        if (strncmp(nbMagic, AMRNB_MAGIC_NUMBER, strlen(AMRNB_MAGIC_NUMBER)))
        {
            fclose(fpamr);
            return 0;
        }
    }
    else
    {
        fread(wbMagic, sizeof(char), strlen(AMRWB_MAGIC_NUMBER), fpamr);
        if (strncmp(wbMagic, AMRWB_MAGIC_NUMBER, strlen(AMRWB_MAGIC_NUMBER)))
        {
            fclose(fpamr);
            return 0;
        }
    }
    
    fpwave = fopen(pchWAVEFilename,"wb");
    
    WriteWAVEFileHeader(fpwave, nFrameCount,sampleRateType);
    
    if (sampleRateType == SAMPLERATETYPEEightKHZ)
    {
        /* init decoder */
        destate = Decoder_Interface_init();
        
        // 读第一帧 - 作为参考帧
        memset(amrFrame, 0, sizeof(amrFrame));
        memset(pcmFrame, 0, sizeof(pcmFrame));
        ReadAMRFrameFirst(fpamr, amrFrame, &stdFrameSize, &stdFrameHeader,sampleRateType);
        
        // 解码一个AMR音频帧成PCM数据
        Decoder_Interface_Decode(destate, amrFrame, pcmFrame, 0);
        nFrameCount++;
        fwrite(pcmFrame, sizeof(short), pcm_frame_size, fpwave);
        
        // 逐帧解码AMR并写到WAVE文件里
        while(1)
        {
            memset(amrFrame, 0, sizeof(amrFrame));
            memset(pcmFrame, 0, sizeof(pcmFrame));
            if (!ReadAMRFrame(fpamr, amrFrame, stdFrameSize, stdFrameHeader)) break;
            
            //解码一个AMR音频帧成PCM数据 (8k-16b-单声道)
            Decoder_Interface_Decode(destate, amrFrame, pcmFrame, 0);
            nFrameCount++;
            fwrite(pcmFrame, sizeof(short), pcm_frame_size, fpwave);
        }
        printf("frame = %d\n", nFrameCount);
        Decoder_Interface_exit(destate);
        
        fclose(fpwave);
    }
    else
    {
        /* init decoder */
        destate = D_IF_init();
        
        // 读第一帧 - 作为参考帧
        memset(amrFrame, 0, sizeof(amrFrame));
        memset(pcmFrame, 0, sizeof(pcmFrame));
        ReadAMRFrameFirst(fpamr, amrFrame, &stdFrameSize, &stdFrameHeader,sampleRateType);
        
        // 解码一个AMR音频帧成PCM数据
        D_IF_decode(destate, amrFrame, pcmFrame, 0);
        nFrameCount++;
        fwrite(pcmFrame, sizeof(short), pcm_frame_size, fpwave);
        
        // 逐帧解码AMR并写到WAVE文件里
        while(1)
        {
            memset(amrFrame, 0, sizeof(amrFrame));
            memset(pcmFrame, 0, sizeof(pcmFrame));
            if (!ReadAMRFrame(fpamr, amrFrame, stdFrameSize, stdFrameHeader)) break;
            
            //解码一个AMR音频帧成PCM数据 (8k-16b-单声道)
            D_IF_decode(destate, amrFrame, pcmFrame, 0);
            nFrameCount++;
            fwrite(pcmFrame, sizeof(short), pcm_frame_size, fpwave);
        }
        printf("frame = %d\n", nFrameCount);
        D_IF_exit(destate);
        
        fclose(fpwave);

    }
    // 重写WAVE文件头
    fpwave = fopen(pchWAVEFilename, "r+");
    WriteWAVEFileHeader(fpwave, nFrameCount,sampleRateType);
    fclose(fpwave);
    
    return nFrameCount;
}