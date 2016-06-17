//
//  SiXKhzWavToAmrViewController.m
//  -01VoiceForAMR
//
//  Created by 势必可赢 on 16/6/16.
//  Copyright © 2016年 势必可赢. All rights reserved.
//

#import "EightKhzWavToAmrViewController.h"
#import "VoiceConverter.h"

@interface EightKhzWavToAmrViewController ()
@property (weak, nonatomic) IBOutlet UILabel *originWavLabel;
@property (weak, nonatomic) IBOutlet UILabel *amrLabel;
@property (weak, nonatomic) IBOutlet UILabel *ToWavLabel;
@property (weak, nonatomic) IBOutlet UIButton *recordBtn;
@property (weak, nonatomic) IBOutlet UIButton *playBtn;
@property (weak, nonatomic) IBOutlet UIButton *playBtn2;
@property (strong, nonatomic)   AVAudioRecorder  *recorder;
@property (strong, nonatomic)   AVAudioPlayer    *player;
@property (strong, nonatomic)   NSString         *recordFileName;
@property (strong, nonatomic)   NSString         *recordFilePath;
- (IBAction)startRecording;
- (IBAction)stopRecording;
- (IBAction)playOriginWav;
- (IBAction)playToWav;
@end

@implementation EightKhzWavToAmrViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.recordBtn.layer.cornerRadius = 10;
    self.recordBtn.layer.masksToBounds = YES;
    self.playBtn.layer.cornerRadius = 5;
    self.playBtn.layer.masksToBounds = YES;
    self.playBtn2.layer.cornerRadius = 5;
    self.playBtn2.layer.masksToBounds = YES;
    self.player  = [[AVAudioPlayer alloc]init];
}


- (IBAction)startRecording {
    //根据当前时间生成文件名
    self.recordFileName = [self getCurrentTimeString];
    //获取路径
    self.recordFilePath = [self GetPathByFileName:self.recordFileName ofType:@"wav"];
    NSLog(@"录音文件的路径是：%@",self.recordFilePath);
    //初始化录音 8KHZ
    self.recorder = [[AVAudioRecorder alloc]initWithURL:[NSURL fileURLWithPath:self.recordFilePath]
                                               settings:[VoiceConverter GetAudioRecorderSettingDictWithSampleRateType:SAMPLERATETYPEEightKHZ]
                                                  error:nil];
    
    //准备录音
    if ([self.recorder prepareToRecord]){
        
        [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayAndRecord error:nil];
        [[AVAudioSession sharedInstance] setActive:YES error:nil];
        
        //开始录音
        if ([self.recorder record]){
            [self.recordBtn setTitle:@"停止" forState:UIControlStateNormal];
            self.playBtn.enabled = NO;
            self.playBtn2.enabled = NO;
            
        }
    }

}

- (NSString *)getCurrentTimeString
{
    NSDateFormatter *dateformat = [[NSDateFormatter  alloc]init];
    [dateformat setDateFormat:@"yyyyMMddHHmmss"];
    NSString* dateStr = [dateformat stringFromDate:[NSDate date]];
    return [NSString stringWithFormat:@"8KHZWAV%@",dateStr];
}

- (IBAction)stopRecording {
    
    //停止录音
    [self.recorder stop];
    [self.recordBtn setTitle:@"录音" forState:UIControlStateNormal];
    
    self.playBtn.enabled = YES;
    //设置label信息
    self.originWavLabel.text = [NSString stringWithFormat:@"原wav:\n%@",[self getVoiceFileInfoByPath:self.recordFilePath convertTime:0]];
    
    //开始转换格式
    
    NSDate *date = [NSDate date];
    NSString *amrPath = [self GetPathByFileName:self.recordFileName ofType:@"amr"];
    
#warning wav转amr
    if ([VoiceConverter ConvertWavToAmr:self.recordFilePath amrSavePath:amrPath sampleRateType:SAMPLERATETYPEEightKHZ])
    {
        
        //设置label信息
        self.amrLabel.text = [NSString stringWithFormat:@"原wav转amr:\n%@",[self getVoiceFileInfoByPath:amrPath convertTime:[[NSDate date] timeIntervalSinceDate:date]]];
        
        date = [NSDate date];
        NSString *convertedPath = [self GetPathByFileName:[self.recordFileName stringByAppendingString:@"_AmrToWav"] ofType:@"wav"];
        NSLog(@"----AMR文件:%@",convertedPath);
#warning amr转wav
        if ([VoiceConverter ConvertAmrToWav:amrPath wavSavePath:convertedPath sampleRateType:SAMPLERATETYPEEightKHZ])
        {
            //        设置label信息
            self.ToWavLabel.text = [NSString stringWithFormat:@"amr转wav:\n%@",[self getVoiceFileInfoByPath:convertedPath convertTime:[[NSDate date] timeIntervalSinceDate:date]]];
            self.playBtn2.enabled = YES;
        }else
        {
            NSLog(@"amr转wav失败");
        }
    
    }
    else
    {
        NSLog(@"wav转amr失败");
    }

}

- (IBAction)playOriginWav {
    [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayback error:nil];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    self.player = [self.player initWithContentsOfURL:[NSURL URLWithString:self.recordFilePath] error:nil];
    [self.player play];
}

- (IBAction)playToWav {
    [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayback error:nil];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    NSString *convertedPath = [self GetPathByFileName:[self.recordFileName stringByAppendingString:@"_AmrToWav"] ofType:@"wav"];
    self.player = [self.player initWithContentsOfURL:[NSURL URLWithString:convertedPath] error:nil];
    [self.player play];
}

#pragma mark - 生成文件路径
- (NSString*)GetPathByFileName:(NSString *)fileName ofType:(NSString *)_type{
    NSString *directory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)objectAtIndex:0];
    directory = [directory stringByAppendingPathComponent:@"8KHZFile"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:directory])
    {
        [[NSFileManager defaultManager] createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSString* fileDirectory = [[[directory stringByAppendingPathComponent:fileName]
                                stringByAppendingPathExtension:_type]
                               stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    return fileDirectory;
}

#pragma mark - 获取音频文件信息
- (NSString *)getVoiceFileInfoByPath:(NSString *)aFilePath convertTime:(NSTimeInterval)aConTime{
    
    NSInteger size = [self getFileSize:aFilePath]/1024;
    NSString *info = [NSString stringWithFormat:@"文件名:%@\n文件大小:%dkb\n",aFilePath.lastPathComponent,size];
    
    NSRange range = [aFilePath rangeOfString:@"wav"];
    if (range.length > 0) {
        AVAudioPlayer *play = [[AVAudioPlayer alloc]initWithContentsOfURL:[NSURL URLWithString:aFilePath] error:nil];
        info = [info stringByAppendingFormat:@"文件时长:%f\n",play.duration];
    }
    
    if (aConTime > 0)
    info = [info stringByAppendingFormat:@"转换时间:%f",aConTime];
    return info;
}

#pragma mark - 获取文件大小
- (NSInteger) getFileSize:(NSString*) path{
    NSFileManager * filemanager = [[NSFileManager alloc]init];
    if([filemanager fileExistsAtPath:path]){
        NSDictionary * attributes = [filemanager attributesOfItemAtPath:path error:nil];
        NSNumber *theFileSize;
        if ( (theFileSize = [attributes objectForKey:NSFileSize]) )
        return  [theFileSize intValue];
        else
        return -1;
    }
    else{
        return -1;
    }
}



@end
