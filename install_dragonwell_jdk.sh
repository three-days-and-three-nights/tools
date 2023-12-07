#调用base.sh中的函数
source base.sh

check_locale
check_centos
check_network
check_python

#判断系统中是否有java
echo_normal "开始检测系统中是否有java"
if [ -f /usr/bin/java ];then
    fail_echo "系统中已经安装了java java版本为：" `java -version 2>&1 | awk 'NR==1{ gsub(/"/,""); print $3 }'`
    exit 1
else
    pass_echo "系统中没有安装java"
fi


#定义一个下载的键值对数组
declare -A download_list=(
["jdk8"]="https://dragonwell.oss-cn-shanghai.aliyuncs.com/8.16.17/Alibaba_Dragonwell_Standard_8.16.17_x64_linux.tar.gz"
["jdk11"]="https://dragonwell.oss-cn-shanghai.aliyuncs.com/11.0.20.16.8/Alibaba_Dragonwell_Standard_11.0.20.16.8_x64_linux.tar.gz"
["jdk17"]="https://dragonwell.oss-cn-shanghai.aliyuncs.com/17.0.9.0.10+9/Alibaba_Dragonwell_Standard_17.0.9.0.10+9_x64_linux.tar.gz"
)

#显示下载列表
echo_normal "显示可用下载列表"
for key in ${!download_list[@]}
do
    echo_normal "版本：$key 下载地址：${download_list[$key]}"
done
read -p "请输入需要下载的版本：" version
if [ ! ${download_list[$version]} ];then
    fail_echo "输入的版本号有误"
    exit 1
fi
#如果输入为空则默认下载jdk8
if [ -z $version ];then
    version="jdk8"
fi