# opencore-amrDemo-iOS
演示了8Khz wav文件和amr文件互转  和 16Khz wav文件和amr文件互转

## [使用opencore-amr实现wav转amr-8khz-16khz](http://lemon2well.top/2018/07/25/iOS%20开发/使用opencore-amr实现wav转amr-8khz-16khz/)

## 介绍
  8khz 和 16khz两个不同的采样率的wav文件如果要使用AMR压缩是使用两个不同的库，如果是8Khz的话是使用[opencore-amr](https://sourceforge.net/projects/opencore-amr/)
  里面提供的amrnb encode和decode的方法。
  
  如果是16khz则使用了两个库，如果是AMR解码则使用的是和8khz一样，使用的是[opencore-amr](https://sourceforge.net/projects/opencore-amr/files/opencore-amr/)
  里面提供的amrwb 的decode的方法。如果是AMR编码则使用的是另外一个库[vo-amrwbenc](https://sourceforge.net/projects/opencore-amr/files/vo-amrwbenc/)，该仓单独提供了一个独立的编码方法
  
## 编译
   
1. 首先新建一个文件夹，将下载到的vo-amrwbenc-0.1.3.tar.gz压缩包放到里面，然后进入这个文件夹，在里面创建build.sh文件,将以下脚本粘贴到文件里面。

如果是opencore-amr则使用下面的脚本：

```
#!/bin/sh
set -xe
 
VERSION="0.1.3"
SDKVERSION="8.4"
LIBSRCNAME="opencore-amr"
 
CURRENTPATH=`pwd`
 
mkdir -p "${CURRENTPATH}/src"
tar zxvf ${LIBSRCNAME}-${VERSION}.tar.gz -C "${CURRENTPATH}/src"
cd "${CURRENTPATH}/src/${LIBSRCNAME}-${VERSION}"
 
DEVELOPER=`xcode-select -print-path`
DEST="${CURRENTPATH}/lib-ios"
mkdir -p "${DEST}"
 
ARCHS="armv7 armv7s arm64 i386 x86_64"
# ARCHS="armv7"
LIBS="libopencore-amrnb.a libopencore-amrwb.a"
 
DEVELOPER=`xcode-select -print-path`
 
for arch in $ARCHS; do
case $arch in
arm*)
 
IOSV="-miphoneos-version-min=7.0"
if [ $arch == "arm64" ]
then
IOSV="-miphoneos-version-min=7.0"
fi
 
echo "Building for iOS $arch ****************"
SDKROOT="$(xcrun --sdk iphoneos --show-sdk-path)"
CC="$(xcrun --sdk iphoneos -f clang)"
CXX="$(xcrun --sdk iphoneos -f clang++)"
CPP="$(xcrun -sdk iphonesimulator -f clang++)"
CFLAGS="-isysroot $SDKROOT -arch $arch $IOSV -isystem $SDKROOT/usr/include -fembed-bitcode"
CXXFLAGS=$CFLAGS
CPPFLAGS=$CFLAGS
export CC CXX CFLAGS CXXFLAGS CPPFLAGS
 
./configure \
--host=arm-apple-darwin \
--prefix=$DEST \
--disable-shared --enable-static
;;
*)
IOSV="-mios-simulator-version-min=7.0"
echo "Building for iOS $arch*****************"
 
SDKROOT=`xcodebuild -version -sdk iphonesimulator Path`
CC="$(xcrun -sdk iphoneos -f clang)"
CXX="$(xcrun -sdk iphonesimulator -f clang++)"
CPP="$(xcrun -sdk iphonesimulator -f clang++)"
CFLAGS="-isysroot $SDKROOT -arch $arch $IOSV -isystem $SDKROOT/usr/include -fembed-bitcode"
CXXFLAGS=$CFLAGS
CPPFLAGS=$CFLAGS
export CC CXX CFLAGS CXXFLAGS CPPFLAGS
./configure \
--prefix=$DEST \
--disable-shared
;;
esac
make > /dev/null
make install
make clean
for i in $LIBS; do
mv $DEST/lib/$i $DEST/lib/$i.$arch
done
done
 
for i in $LIBS; do
input=""
for arch in $ARCHS; do
input="$input $DEST/lib/$i.$arch"
done
lipo -create -output $DEST/lib/$i $input
done

```

如果是vo-amrwbenc则使用下面的脚本：

```
#!/bin/sh

set -xe

VERSION="0.1.3"

LIBSRCNAME="vo-amrwbenc"

CURRENTPATH=`pwd`

mkdir -p "${CURRENTPATH}/src"

tar zxvf ${LIBSRCNAME}-${VERSION}.tar.gz -C "${CURRENTPATH}/src"

cd "${CURRENTPATH}/src/${LIBSRCNAME}-${VERSION}"

# 设置环境变量并创建lib-ios文件夹，后续生成的.a类库都会放在这个文件夹里边

DEST="${CURRENTPATH}/lib-ios"

mkdir -p "${DEST}"

ARCHS="armv7 armv7s arm64 i386 x86_64"

LIBS="libvo-amrwbenc.a"

for arch in $ARCHS; do

case $arch in arm*)

IOSV="-miphoneos-version-min=7.0"

if [ $arch == "arm64" ]

then

IOSV="-miphoneos-version-min=7.0"

fi

echo "Building for iOS $arch ****************"

# 编译 $arch 环境的类库（amr类型类型）

SDKROOT="$(xcrun --sdk iphoneos --show-sdk-path)"

CC="$(xcrun --sdk iphoneos -f clang)"

CXX="$(xcrun --sdk iphoneos -f clang++)"

CPP="$(xcrun -sdk iphonesimulator -f clang++)"

CFLAGS="-isysroot $SDKROOT -arch $arch $IOSV -isystem $SDKROOT/usr/include -fembed-bitcode"

CXXFLAGS=$CFLAGS

CPPFLAGS=$CFLAGS

export CC CXX CFLAGS CXXFLAGS CPPFLAGS

./configure \

--host=arm-apple-darwin \

--prefix=$DEST \

--disable-shared --enable-static

;;

*)

IOSV="-mios-simulator-version-min=7.0"

echo "Building for iOS $arch*****************"

SDKROOT=`xcodebuild -version -sdk iphonesimulator Path`

CC="$(xcrun -sdk iphoneos -f clang)"

CXX="$(xcrun -sdk iphonesimulator -f clang++)"

CPP="$(xcrun -sdk iphonesimulator -f clang++)"

CFLAGS="-isysroot $SDKROOT -arch $arch $IOSV -isystem $SDKROOT/usr/include -fembed-bitcode"

CXXFLAGS=$CFLAGS

CPPFLAGS=$CFLAGS

export CC CXX CFLAGS CXXFLAGS CPPFLAGS

./configure \

--prefix=$DEST \

--disable-shared

;;

esac

make > /dev/null

make install     

make clean   

for i in $LIBS; do

mv $DEST/lib/$i $DEST/lib/$i.$arch

done

done

for i in $LIBS; do

input=""

for arch in $ARCHS; do

input="$input $DEST/lib/$i.$arch"

done

lipo -create -output $DEST/lib/$i $input

done
```


2. 修改build.sh的权限，打开终端，cd到新建的文件夹，使用命令 chmod 777 build.sh 修改权限。

3. 修改完成之后在终端执行 ./build.sh 就会在对应的仓库里面里面生成一个lib-ios文件夹，里面就包含了对应的静态库和头文件。

## 使用

将Opencore-AMR拖到你的项目里面，然后 `#import "VoiceConverter.h"
`这个类里面提供了三个类方法。

1. 转换wav到amr(编码)
   
   ```
   /**
 *  转换wav到amr
 *
 *  @param aWavPath  wav文件路径
 *  @param aSavePath amr保存路径
 *
 *  @return 0失败 1成功
 */
+ (int)EncodeWavToAmr:(NSString *)aWavPath amrSavePath:(NSString *)aSavePath sampleRateType:(Sample_Rate)sampleRateType;

   ```

2. 转换amr到wav（解码）

```
/**
 *  转换amr到wav
 *
 *  @param aAmrPath  amr文件路径
 *  @param aSavePath wav保存路径
 *
 *  @return 0失败 1成功
 */
+ (int)DecodeAmrToWav:(NSString *)aAmrPath wavSavePath:(NSString *)aSavePath sampleRateType:(Sample_Rate)sampleRateType;
```

3. 获取采集声音默认设置，当初始化AVAudioRecorder的时候需要提供一个采集声音采样率，声道的设置，可以使用该类的下面这个方法来设置一个默认的设置。

```
/**
 获取采集声音默认设置

 @param sampleRateType 采样率
 @return
 */
+ (NSDictionary*)GetAudioRecorderSettingDictWithSampleRateType:(Sample_Rate)sampleRateType;
```
   
   ```
       self.recorder = [[AVAudioRecorder alloc]initWithURL:[NSURL fileURLWithPath:self.recordFilePath]
                                               settings:[VoiceConverter GetAudioRecorderSettingDictWithSampleRateType:Sample_Rate_8000]
                                                  error:nil];
   ```

---------------------------------------------------------

**2018.8.16更新**
由于有个哥们反映了旧的仓库转码效率比上另外的库时间慢上大概5倍左右，所以编译了最新的opencore-amr

