#定义一些base函数供其他shell调用
function pass_echo(){
    echo -e "\033[33m$*\033[0m \033[32m PASS \033[0m"
}

function fail_echo(){
    echo -e "\033[33m$*\033[0m \033[31m FAIL \033[0m"
}

function echo_normal(){
    echo -e "\033[36m$*\033[0m"
}

#定义一个检测当前系统的字符集是否能输出中文的函数
function check_locale(){
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
}

#定义一个检测当前系统是否为CentOS的函数
function check_centos(){
    echo_normal "开始检测当前系统是否为CentOS"
    if [ -f /etc/redhat-release ];then
        pass_echo "当前系统为CentOS"
        #打印当前系统的版本
        pass_echo "当前系统版本为：" `cat /etc/redhat-release`
        #打印当前系统的内核版本
        pass_echo "当前系统内核版本为：" `uname -r`
    else
        echo "当前系统不是CentOS"
        exit 1
    fi
}

#定义一个检测当前系统是否联网的函数
function check_network(){
    echo_normal "开始检测系统是否联网"
    ping -c 3 www.baidu.com > /dev/null 2>&1
    if [ $? -eq 0 ];then
        pass_echo "系统联网成功"
    else
        fail_echo "系统联网失败"
        exit 1
    fi
}

#定义一个检测当前系统是否有python的函数
function check_python(){
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
}
