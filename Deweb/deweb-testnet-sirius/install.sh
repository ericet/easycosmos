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
"安装节点(快速同步)" 
"创建钱包"
"节点日志" 
"查看节点状态" 
"水龙头获得测试币" 
"钱包余额" 
"创建验证人" 
"查看验证人"
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
echo "Install GO 1.19"
echo "============================================================"
sleep 3
wget https://dl.google.com/go/go1.19.linux-amd64.tar.gz; \
rm -rv /usr/local/go; \
tar -C /usr/local -xzf go1.19.linux-amd64.tar.gz && \
rm -v go1.19.linux-amd64.tar.gz && \
echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> ~/.profile && \
source ~/.profile && \
go version > /dev/null

echo "============================================================"
echo "服务器环境准备好了!"
echo "============================================================"
break
;;
            
"安装节点(快速同步)")
echo "============================================================"
echo "输入节点的名称:"
echo "============================================================"
                
read DEWEBNODE
DEWEBNODE=$DEWEBNODE
echo 'export DEWEBNODE='${DEWEBNODE} >> $HOME/.profile

echo "============================================================"
echo "输入钱包名称:"
echo "============================================================"
               
read DEWEBWALLET
DEWEBWALLET=$DEWEBWALLET
echo 'export DEWEBWALLET='${DEWEBWALLET} >> $HOME/.profile
DEWEBCHAIN=""deweb-testnet-sirius""
echo 'export DEWEBCHAIN='${DEWEBCHAIN} >> $HOME/.profile
source $HOME/.profile

echo "============================================================"
echo "节点安装开始。。。"
echo "============================================================"

git clone https://github.com/deweb-services/deweb.git
cd deweb
git checkout v0.3.1
make install

dewebd init $DEWEBNODE --chain-id $DEWEBCHAIN

dewebd tendermint unsafe-reset-all --home $HOME/.deweb
rm $HOME/.deweb/config/genesis.json
curl -s https://raw.githubusercontent.com/deweb-services/deweb/main/genesis.json > ~/.deweb/config/genesis.json

# config pruning
indexer="null"
pruning="custom"
pruning_keep_recent="100"
pruning_keep_every="0"
pruning_interval="10"

SNAP_RPC="https://dws-testnet.nodejumper.io:443"

LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height); \
BLOCK_HEIGHT=$((LATEST_HEIGHT - 2000)); \
TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)

echo $LATEST_HEIGHT $BLOCK_HEIGHT $TRUST_HASH

peers="c5b45045b0555c439d94f4d81a5ec4d1a578f98c@dws-testnet.nodejumper.io:27656"
sed -i 's|^persistent_peers *=.*|persistent_peers = "'$peers'"|' $HOME/.deweb/config/config.toml

sed -i -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP_RPC,$SNAP_RPC\"| ; \
s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \
s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"|" $HOME/.deweb/config/config.toml


tee $HOME/dewebd.service > /dev/null <<EOF
[Unit]
Description=Deweb Testnet Daemon
After=network.target
[Service]
Type=simple
User=$USER
ExecStart=$(which dewebd) start
Restart=on-failure
RestartSec=10
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF

sudo mv $HOME/dewebd.service /etc/systemd/system/

# start service
sudo systemctl daemon-reload
sudo systemctl enable dewebd
sudo systemctl restart dewebd

echo "============================================================"
echo "节点安装成功!"
echo "============================================================"
break
;;


"创建钱包")
echo "============================================================"
echo "请保存助记词!"
echo "============================================================"
               
dewebd keys add $DEWEBWALLET
DEWEBADDRWALL=$(dewebd keys show $DEWEBWALLET -a)
DEWEBVAL=$(dewebd keys show $DEWEBWALLET --bech val -a)
echo 'export DEWEBVAL='${DEWEBVAL} >> $HOME/.profile
echo 'export DEWEBADDRWALL='${DEWEBADDRWALL} >> $HOME/.profile
source $HOME/.profile

echo "============================================================"
echo "钱包地址: $DEWEBADDRWALL"
echo "验证人地址: $DEWEBVAL"
echo "============================================================"
               
break
;;

"查看节点状态")
echo "============================================================"
echo "节点catching_up为false的时候继续下一步"
echo "============================================================"
echo "节点状态 = $(curl -s localhost:26657/status | jq .result | jq .sync_info)"
echo "区块高度 = $(dewebd status 2>&1 | jq ."SyncInfo"."latest_block_height")"
echo "验证人状态 = $(dewebd q slashing signing-info $(dewebd tendermint show-validator))"
echo "============================================================"
break
;;

"创建验证人")
echo "============================================================"
echo "节点状态为false的时候继续下一步!"
echo "节点状态 = $(curl -s localhost:26657/status)"
echo "============================================================"
               
dewebd tx staking create-validator \
  --amount 1000000udws \
  --from $DEWEBWALLET \
  --commission-max-change-rate "0.05" \
  --commission-max-rate "0.20" \
  --commission-rate "0.05" \
  --min-self-delegation "1" \
  --pubkey $(dewebd tendermint show-validator) \
  --moniker $DEWEBNODE \
  --chain-id $DEWEBCHAIN \
  --gas 300000 \
  -y
break
;;

"钱包余额")
echo "============================================================"
echo "节点名称: $DEWEBNODE"
echo "钱包地址: $DEWEBADDRWALL" 
echo "钱包余额: $(dewebd query bank balances $DEWEBADDRWALL)"
echo "============================================================"
break
;;

"查看验证人") 
echo "============================================================"
echo "Account request: $(dewebd q auth account $(dewebd keys show $DEWEBADDRWALL -a) -o text)"
echo "Validator info: $(dewebd q staking validator $DEWEBVAL)"
echo "============================================================"
break
;;

"水龙头获得测试币")
request=$request
echo "============================================================"
echo "进入Deweb Discord https://discord.gg/q8FvXpXR 的 #faucet 频道"
echo "============================================================"
echo -e "复制粘贴 \033[32m $request $DEWEBADDRWALL sirius\033[37m"
echo "============================================================"
break
;;

"节点日志")
journalctl -u dewebd -f -o cat
break
;;

"删除节点")
systemctl stop dewebd
systemctl disable dewebd
rm /etc/systemd/system/dewebd.service
cd $HOME
rm -r .dewebd deweb
break
;;

"退出")
exit
;;

*) echo "invalid option $REPLY";;
esac
done
done
