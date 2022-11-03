#!/bin/bash

while true
do

# Logo

echo "============================================================"
curl -s https://raw.githubusercontent.com/ericet/easynodes/master/logo.sh | bash
echo "============================================================"


source ~/.profile

PS3='选择一个操作 '
options=(
"安装必要的环境" 
"导入钱包"
"任务3"
"退出")
select opt in "${options[@]}"
               do
                   case $opt in
                   
"安装必要的环境")
echo "============================================================"
echo "准备开始。。。"
echo "============================================================"

#INSTALL DEPEND
echo "============================================================"
echo "Update and install APT"
echo "============================================================"
sleep 3
sudo apt update && sudo apt upgrade -y && \
sudo apt install curl tar wget clang pkg-config libssl-dev jq build-essential bsdmainutils git make ncdu gcc git jq chrony liblz4-tool -y

#INSTALL GO
echo "============================================================"
echo "Install GO 1.18.1"
echo "============================================================"
sleep 3
wget https://golang.org/dl/go1.18.1.linux-amd64.tar.gz; \
rm -rv /usr/local/go; \
tar -C /usr/local -xzf go1.18.1.linux-amd64.tar.gz && \
rm -v go1.18.1.linux-amd64.tar.gz && \
echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> ~/.profile && \
source ~/.profile && \
go version > /dev/null

git clone https://github.com/sei-protocol/sei-chain.git
cd sei-chain
git checkout 1.1.4beta
make install
seid config node https://sei-testnet-rpc.brocha.in:443
seid config chain-id atlantic-1

echo "============================================================"
echo "服务器环境准备好了!"
echo "============================================================"
break
;;
            


"导入钱包")
echo "============================================================"
echo "输入钱包名称:"
echo "============================================================"
               
read SEIWALLET
SEIWALLET=$SEIWALLET
echo 'export SEIWALLET='${SEIWALLET} >> $HOME/.profile

echo "============================================================"
echo "导入助记词!"
echo "============================================================"
               
seid keys add $SEIWALLET --recover
SEIADDRWALL=$(seid keys show $SEIWALLET -a)
echo 'export SEIADDRWALL='${SEIADDRWALL} >> $HOME/.profile
source $HOME/.profile

echo "============================================================"
echo "钱包地址: $SEIADDRWALL"
echo "============================================================"
               
break
;;

"任务3")
seid tx dex place-orders sei1466nf3zuxpya8q9emxukd7vftaf6h4psr0a07srl5zw74zh84yjqpeheyc Long?30?1?UST2?ATOM?Limit?"{\"position_effect\":\"Open\",\"leverage\":\"1\"}" Long?30?1?UST2?ATOM?Limit?"{\"position_effect\":\"Open\",\"leverage\":\"1\"}" --amount=60000000uust2 -y --from=$SEIWALLET --chain-id=atlantic-1 --fees=10000usei --gas=50000000 --broadcast-mode=block
break
;;

"退出")
exit
;;

*) echo "invalid option $REPLY";;
esac
done
done
