#调用base.sh中的函数
source base.sh

check_locale
check_centos
check_network
check_python

#开始获取git的下载地址
echo_normal "开始获取git官网下载页面"
html_content=$(curl -s https://git-scm.com/download/linux)
if [ $? -eq 0 ];then
    pass_echo "git官网下载页面获取成功"
else
    fail_echo "git官网下载页面获取失败"
    exit 1
fi


#通过正则表达式获取git的下载地址
echo_normal "开始获取git的下载地址"
download_url=$(echo $html_content | grep -oP "(?<=href=\").*?(?=\")" | grep -E "git-.*?\.tar\.gz")
if [ $? -eq 0 ];then
    pass_echo "git的下载地址获取成功"
else
    fail_echo "git的下载地址获取失败"
    exit 1
fi

#通过正则表达式获取git的版本号
echo_normal "开始获取git的版本号"
git_version=$(echo $download_url | grep -oP "(?<=git-).*?(?=.tar.gz)")
if [ $? -eq 0 ];then
    pass_echo "git的版本号获取成功"
    pass_echo "git的版本号为：$git_version"
else
    fail_echo "git的版本号获取失败"
    exit 1
fi

#检测系统中是否已经安装了git
echo_normal "开始检测系统中是否已经安装了git"
git --version > /dev/null 2>&1
if [ $? -eq 0 ];then
    fail_echo "系统中已经安装了git,请先卸载git, $(git --version)"
    exit 1
else
    pass_echo "系统中没有安装git"
fi


#开始下载git源码包
echo_normal "开始下载git源码包"
#检测系统中是否已经安装了wget
echo_normal "开始检测系统中是否已经安装了wget"
wget --version > /dev/null 2>&1
if [ $? -eq 0 ];then
    pass_echo "系统中已经安装了wget"
    echo_normal "开始用wget下载git源码包"
    #wget 只显示进度条
    wget --no-check-certificate  -O /opt/git.tar.gz $download_url > /dev/null 2>&1
    if [ $? -eq 0 ];then
        pass_echo "git源码包下载成功,下载路径为：/opt/git.tar.gz"
    else
        fail_echo "git源码包下载失败"
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
        echo_normal "开始用curl下载git源码包"
        curl -L -o /opt/git.tar.gz $download_url > /dev/null 2>&1
        if [ $? -eq 0 ];then
            pass_echo "git源码包下载成功,下载路径为：/opt/git.tar.gz"
        else
            fail_echo "git源码包下载失败"
            exit 1
        fi
    else
        echo_normal "不需要用curl下载git源码包"
        exit 1
    fi
fi


#开始解压git源码包
echo_normal "开始解压git源码包"
#判断是否安装了tar
echo_normal "开始检测系统中是否已经安装了tar"
tar --version > /dev/null 2>&1
#如果tar命令执行成功，则说明已经安装了tar
if [ $? -eq 0 ];then
    pass_echo "系统中已经安装了tar"
    echo_normal "开始解压git源码包"
    tar -zxvf /opt/git.tar.gz -C /opt > /dev/null 2>&1
    if [ $? -eq 0 ];then
        pass_echo "git源码包解压成功,解压路径为：/opt/git-$git_version"
    else
        fail_echo "git源码包解压失败"
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
            echo_normal "开始解压git源码包"
            tar -zxvf /opt/git.tar.gz -C /opt > /dev/null 2>&1
            if [ $? -eq 0 ];then
                pass_echo "git源码包解压成功,解压路径为：/opt/git-$git_version"
            else
                fail_echo "git源码包解压失败"
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

#开始安装依赖
echo_normal "开始用yum安装依赖"
yum install -y curl-devel expat-devel gettext-devel openssl-devel zlib-devel gcc perl-ExtUtils-MakeMaker > /dev/null 2>&1
if [ $? -eq 0 ];then
    pass_echo "依赖安装成功"
else
    fail_echo "依赖安装失败"
    exit 1
fi

#开始安装git
echo_normal "开始安装git"
#切换到git源码包目录
cd /opt/git-$git_version
#安装git
make prefix=/usr/local/git all > /dev/null 2>&1 && make prefix=/usr/local/git install > /dev/null 2>&1

#配置环境变量
echo_normal "开始配置环境变量"
echo "export PATH=$PATH:/usr/local/git/bin" >> /etc/profile
source /etc/profile

#检测git是否安装成功
echo_normal "开始检测git是否安装成功"
git --version > /dev/null 2>&1
if [ $? -eq 0 ];then
    pass_echo "git安装成功"
else
    fail_echo "git安装失败"
    exit 1
fi