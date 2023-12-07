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
["jdk17"]="https://dragonwell.oss-cn-shanghai.aliyuncs.com/17.0.8.0.8%2B7/Alibaba_Dragonwell_Standard_17.0.8.0.8.7_x64_linux.tar.gz"
)

#显示下载列表
echo_normal "显示可用下载列表"
for key in ${!download_list[@]}
do
    echo_normal "版本：$key 下载地址：${download_list[$key]}"
done
read -p "请输入需要下载的版本（默认jdk8）：" version
#如果输入为空则默认下载jdk8
if [ -z $version ];then
    version="jdk8"
fi
if [ ! ${download_list[$version]} ];then
    fail_echo "输入的版本号有误"
    exit 1
fi


download_url=${download_list[$version]}

#开始下载jdk安装包
echo_normal "开始下载jdk压缩包"
#检测系统中是否已经安装了wget
echo_normal "开始检测系统中是否已经安装了wget"
wget --version > /dev/null 2>&1
if [ $? -eq 0 ];then
    pass_echo "系统中已经安装了wget"
    echo_normal "开始用wget下载jdk压缩包"
    #wget 只显示进度条
    wget --no-check-certificate  -O /opt/jdk.tar.gz $download_url > /dev/null 2>&1
    if [ $? -eq 0 ];then
        pass_echo "jdk压缩包下载成功,下载路径为：/opt/jdk.tar.gz"
    else
        fail_echo "jdk压缩包下载失败"
        exit 1
    fi
else
    fail_echo "系统中没有安装wget"
    #是否用curl下载
    echo_normal "是否用curl下载？回车默认为Y"
    #输入y或者Y则下载，其他则不下载
    read -p "(y/n):" is_curl
    if [ -z $is_curl ];then
        is_curl="y"
    fi
    if [ $is_curl == "y" ] || [ $is_curl == "Y" ];then
        echo_normal "开始用curl下载jdk"
        curl -L -o /opt/jdk.tar.gz $download_url > /dev/null 2>&1
        if [ $? -eq 0 ];then
            pass_echo "jdk压缩包下载成功,下载路径为：/opt/jdk.tar.gz"
        else
            fail_echo "jdk压缩包下载失败"
            exit 1
        fi
    else
        echo_normal "不需要用curl下载jdk压缩包"
        exit 1
    fi
fi

echo_normal "开始解压jdk压缩包"
#判断是否安装了tar
echo_normal "开始检测系统中是否已经安装了tar"
tar --version > /dev/null 2>&1
#如果tar命令执行成功，则说明已经安装了tar
if [ $? -eq 0 ];then
    pass_echo "系统中已经安装了tar"
    echo_normal "开始解压jdk"
    tar -zxvf /opt/jdk.tar.gz -C /opt > /dev/null 2>&1
    if [ $? -eq 0 ];then
        jdk_dir=`tar -tf /opt/jdk.tar.gz | head -1 | awk -F "/" '{print $1}'`
        pass_echo "jdk压缩包解压成功,解压路径为：/opt/$jdk_dir"
    else
        fail_echo "jdk压缩包解压失败"
        exit 1
    fi
else
    fail_echo "系统中没有安装tar"
    #是否用yum安装tar
    echo_normal "是否用yum安装tar？回车默认为Y"
    #输入y或者Y则安装，其他则不安装
    read -p "(y/n):" is_install_tar
    if [ -z $is_install_tar ];then
        is_install_tar="y"
    fi
    if [ $is_install_tar == "y" ] || [ $is_install_tar == "Y" ];then
        echo_normal "开始用yum安装tar"
        yum install -y tar
        if [ $? -eq 0 ];then
            pass_echo "tar安装成功"
            echo_normal "开始解压jdk压缩包"
            tar -zxvf /opt/jdk.tar.gz -C /opt > /dev/null 2>&1
            #获取解压后的文件夹名称
            if [ $? -eq 0 ];then
                jdk_dir=`tar -tf /opt/jdk.tar.gz | head -1 | awk -F "/" '{print $1}'`
                pass_echo "jdk压缩包解压成功,解压路径为：/opt/$jdk_dir"
            else
                fail_echo "jdk压缩包解压失败"
                exit 1
            fi
        else
            fail_echo "tar安装失败"
            exit 1
        fi
    else
        echo_normal "不需要用yum安装tar"
        exit 1
    fi
fi

#配置java环境变量
echo_normal "检测系统中是否已经配置了java环境变量"
grep "JAVA_HOME" /etc/profile > /dev/null 2>&1
if [ $? -eq 0 ];then
    fail_echo "系统中已经配置了java环境变量"
    exit 1
else
    pass_echo "系统中没有配置java环境变量"
fi

#配置java环境变量
echo_normal "开始配置java环境变量"
echo "export JAVA_HOME=/opt/$jdk_dir" >> /etc/profile
echo 'export PATH=$JAVA_HOME/bin:$PATH' >> /etc/profile
echo 'export CLASSPATH=.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar' >> /etc/profile
source /etc/profile

#检测java是否配置成功
echo_normal "开始检测java是否配置成功"
java -version > /dev/null 2>&1
if [ $? -eq 0 ];then
    pass_echo "java配置成功" `java -version 2>&1 | awk 'NR==1{ gsub(/"/,""); print $3 }'`
else
    fail_echo "java配置失败"
    exit 1
fi