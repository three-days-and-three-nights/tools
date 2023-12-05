function pass_echo(){
    echo -e "\033[33m$*\033[0m \033[32m PASS \033[0m"
}

function fail_echo(){
    echo -e "\033[33m$*\033[0m \033[31m FAIL \033[0m"
}

function echo_normal(){
    echo -e "\033[36m$*\033[0m"
}

#检测当前系统的字符集是否能输出中文
echo_normal "Start to detect whether the character set of the current system can output Chinese"
if [ `echo "测试" | grep -c "测试"` -eq 1 ];then
    pass_echo "当前系统的字符集能输出中文"
else
    fail_echo "The current system character set cannot output Chinese."
    echo_normal "Start modifying character set"
    echo "LANG=\"zh_CN.UTF-8\"" > /etc/locale.conf
    source /etc/locale.conf
    if [ `echo "测试" | grep -c "测试"` -eq 1 ];then
        pass_echo "字符集修改成功"
    else
        fail_echo "Character set modification failed"
        exit 1
    fi
fi

echo_normal "开始检测当前系统是否为CentOS"
if [ -f /etc/redhat-release ];then
    pass_echo "当前系统为CentOS"
else
    echo "当前系统不是CentOS"
    exit 1
fi

#打印当前系统的版本
pass_echo "当前系统版本为：" `cat /etc/redhat-release`
#打印当前系统的内核版本
pass_echo "当前系统内核版本为：" `uname -r`


#检测系统是否联网
echo_normal "开始检测系统是否联网"
ping -c 3 www.baidu.com > /dev/null 2>&1
if [ $? -eq 0 ];then
    pass_echo "系统联网成功"
else
    fail_echo "系统联网失败"
    exit 1
fi

#检测当前系统中是否有python
echo_normal "开始检测当前系统中是否有python"
if [ -f /usr/bin/python ];then
    pass_echo "当前系统中有python，python的路径为/usr/bin/python。"
    pass_echo "当前系统中python的版本为：" `python --version 2>&1`
else
    fail_echo "当前系统中没有python"
    echo_normal "开始安装python"
    yum install -y python
    if [ $? -eq 0 ];then
        pass_echo "python安装成功"
    else
        fail_echo "python安装失败"
        exit 1
    fi
fi

#检测是否有CentOS-Base.repo文件
echo_normal "开始检测是否有CentOS-Base.repo文件"
if [ -f /etc/yum.repos.d/CentOS-Base.repo ];then
    pass_echo "当前系统中有CentOS-Base.repo文件"
else
    fail_echo "当前系统中没有CentOS-Base.repo文件"
    #是否需要下载CentOS-Base.repo文件
    echo_normal "是否需要下载CentOS-Base.repo文件？"
    #输入y或者Y则下载，其他则不下载
    read -p "(y/n):" is_download

    #如果is_download为空，则赋值为y
    if [ -z $is_download ];then
        is_download="y"
    fi

    if [ $is_download == "y" ] || [ $is_download == "Y" ];then
        echo_normal "开始下载CentOS-Base.repo文件"
        wget -O /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo
        if [ $? -eq 0 ];then
            pass_echo "CentOS-Base.repo文件下载成功"
        else
            fail_echo "CentOS-Base.repo文件下载失败"
            exit 1
        fi
    else
        echo_normal "不需要下载CentOS-Base.repo文件"
        exit 1
    fi
fi

#询问是否需要备份CentOS-Base.repo文件
echo_normal "是否需要备份CentOS-Base.repo文件？回车默认为Y"
#输入y或者Y则备份，其他则不备份
read -p "(y/n):" is_backup

#如果is_backup为空，则赋值为y
if [ -z $is_backup ];then
    is_backup="y"
fi

if [ $is_backup == "y" ] || [ $is_backup == "Y" ];then
    echo_normal "开始备份CentOS-Base.repo文件"
    cp /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup
    if [ $? -eq 0 ];then
        pass_echo "CentOS-Base.repo文件备份成功，备份文件为/etc/yum.repos.d/CentOS-Base.repo.backup"
    else
        fail_echo "CentOS-Base.repo文件备份失败"
        exit 1
    fi
else
    echo_normal "不需要备份CentOS-Base.repo文件"
fi


#定义一个源的键值对数组
declare -A mirrors=(
["ustc"]="https://mirrors.ustc.edu.cn"
["tencent"]="http://mirrors.cloud.tencent.com"
["netease"]="http://mirrors.163.com"
["tsinghua"]="https://mirrors.tuna.tsinghua.edu.cn"
["huawei"]="https://mirrors.huaweicloud.com"
)

#定义一个mirrors_test数组，用来存放镜像源的下载速度
declare -A mirrors_speed
#开始选路测试
for key in ${!mirrors[@]}
do
    echo_normal "开始测试${mirrors[$key]}的速度"
    #测试下载速度
    speed=`curl -o /dev/null -s -w %{speed_download} ${mirrors[$key]}/CentOS/7/isos/x86_64/CentOS-7-x86_64-DVD-2009.iso`
    #把speed转换成整数
    speed=${speed%.*}
    #把下载速度赋值给mirrors_test数组
    mirrors_speed[$key]=$speed
done

#选取最快的源，遍历数组，找出最大值
max=0
for key in ${!mirrors_speed[@]}
do
    if [ ${mirrors_speed[$key]} -gt $max ];then
        max=${mirrors_speed[$key]}
        max_key=$key
    fi
done

#输出最快的源
echo_normal "最快的源是：$max_key : 他的下载速度是 $max KB/s 地址是：${mirrors[$max_key]}"

#询问是否需要配置源
echo_normal "是否需要配置源？回车默认为Y"
#输入y或者Y则配置，其他则不配置
read -p "(y/n):" is_config

#如果is_config为空，则赋值为y
if [ -z $is_config ];then
    is_config="y"
fi

if [ $is_config == "y" ] || [ $is_config == "Y" ];then
    #询问需要配置哪个源
    echo_normal "请输入需要配置的源的键值,回车默认为最快的源："
    read -p "(ustc/tencent/netease/tsinghua/huawei):" mirror_key
    #判断输入的键值是否为空
    if [ -z $mirror_key ];then
        #就赋值为ustc
        mirror_key=$max_key
    fi
    #判断输入的键值是否在数组中
    if [ ${mirrors[$mirror_key]} ];then
        #开始配置源
        echo_normal "开始配置源"

        #把当前目录下的CentOS-Base.repo文件覆盖到/etc/yum.repos.d/目录下
        cp CentOS-Base.repo /etc/yum.repos.d/
        #修改CentOS-Base.repo文件
        sed -i "s|^mirrorlist=|#mirrorlist=|g" /etc/yum.repos.d/CentOS-Base.repo
        sed -i "s|^#baseurl=http://mirror.centos.org|baseurl=${mirrors[$mirror_key]}|g" /etc/yum.repos.d/CentOS-Base.repo
        #清除yum缓存
        yum clean all > /dev/null 2>&1
        #生成缓存
        yum makecache > /dev/null 2>&1
        if [ $? -eq 0 ];then
            pass_echo "源配置成功"
            #输入配置后的源
            echo_normal "当前系统中的源为：${mirrors[$mirror_key]}" 
            #过滤出当前系统中的源
            yum repolist | grep repolist | awk '{print $3}'
        else
            fail_echo "源配置失败"
            exit 1
        fi
    else
        fail_echo "输入的键值不在可配置的源中"
        exit 1
    fi
else
    echo_normal "不需要配置源"
fi