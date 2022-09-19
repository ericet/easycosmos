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

echo "============================================================"
echo "服务器环境准备好了!"
echo "============================================================"
break
;;
            
"安装节点(快速同步)")
echo "============================================================"
echo "输入节点的名称:"
echo "============================================================"
                
read SEINODE
SEINODE=$SEINODE
echo 'export SEINODE='${SEINODE} >> $HOME/.profile

echo "============================================================"
echo "输入钱包名称:"
echo "============================================================"
               
read SEIWALLET
SEIWALLET=$SEIWALLET
echo 'export SEIWALLET='${SEIWALLET} >> $HOME/.profile
SEICHAIN=""atlantic-1""
echo 'export SEICHAIN='${SEICHAIN} >> $HOME/.profile
source $HOME/.profile

echo "============================================================"
echo "节点安装开始。。。"
echo "============================================================"

git clone https://github.com/sei-protocol/sei-chain.git
cd sei-chain
git checkout 1.0.7beta-postfix
make install

seid init $SEINODE --chain-id $SEICHAIN

seid tendermint unsafe-reset-all --home $HOME/.sei
rm $HOME/.sei/config/genesis.json
curl -s https://raw.githubusercontent.com/sei-protocol/testnet/master/sei-incentivized-testnet/genesis.json > ~/.sei/config/genesis.json

# config pruning
indexer="null"
pruning="custom"
pruning_keep_recent="100"
pruning_keep_every="0"
pruning_interval="10"

sed -i -e "s/^indexer *=.*/indexer = \"$indexer\"/" $HOME/.sei/config/config.toml
sed -i -e "s/^pruning *=.*/pruning = \"$pruning\"/" $HOME/.sei/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"$pruning_keep_recent\"/" $HOME/.sei/config/app.toml
sed -i -e "s/^pruning-keep-every *=.*/pruning-keep-every = \"$pruning_keep_every\"/" $HOME/.sei/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"$pruning_interval\"/" $HOME/.sei/config/app.toml

wget -O $HOME/.sei/config/addrbook.json "https://raw.githubusercontent.com/StakeTake/guidecosmos/main/sei/atlantic-1/addrbook.json"
SEEDS=""
PEERS="e3b5da4caea7370cd85d7738eedaec8f56c5be28@144.76.224.246:36656,a37d65086e78865929ccb7388146fb93664223f7@18.144.13.149:26656,8ff4bd654d7b892f33af5a30ada7d8239d6f467b@91.223.3.190:51656,c4e8c9b1005fe6459a922f232dd9988f93c71222@65.108.227.133:26656"; \
sed -i.bak -e "s/^seeds *=.*/seeds = \"$SEEDS\"/; s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.sei/config/config.toml
SNAP_RPC="http://sei.stake-take.com:36657"
LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height); \
BLOCK_HEIGHT=$((LATEST_HEIGHT - 1000)); \
TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)

sed -i.bak -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP_RPC,$SNAP_RPC\"| ; \
s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \
s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"| ; \
s|^(seeds[[:space:]]+=[[:space:]]+).*$|\1\"\"|" $HOME/.sei/config/config.toml
sudo systemctl restart seid && journalctl -u seid -f -o cat


tee $HOME/seid.service > /dev/null <<EOF
[Unit]
Description=Sei Testnet Daemon
After=network.target
[Service]
Type=simple
User=$USER
ExecStart=$(which seid) start
Restart=on-failure
RestartSec=10
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF

sudo mv $HOME/seid.service /etc/systemd/system/

# start service
sudo systemctl daemon-reload
sudo systemctl enable seid
sudo systemctl restart seid

echo "============================================================"
echo "节点安装成功!"
echo "============================================================"
break
;;


"创建钱包")
echo "============================================================"
echo "请保存助记词!"
echo "============================================================"
               
seid keys add $SEIWALLET
SEIADDRWALL=$(seid keys show $SEIWALLET -a)
SEIVAL=$(seid keys show $SEIWALLET --bech val -a)
echo 'export SEIVAL='${SEIVAL} >> $HOME/.profile
echo 'export SEIADDRWALL='${SEIADDRWALL} >> $HOME/.profile
source $HOME/.profile

echo "============================================================"
echo "钱包地址: $SEIADDRWALL"
echo "验证人地址: $SEIVAL"
echo "============================================================"
               
break
;;

"查看节点状态")
echo "============================================================"
echo "节点catching_up为false的时候继续下一步"
echo "============================================================"
echo "节点状态 = $(curl -s localhost:26657/status | jq .result | jq .sync_info)"
echo "区块高度 = $(seid status 2>&1 | jq ."SyncInfo"."latest_block_height")"
echo "验证人状态 = $(seid q slashing signing-info $(seid tendermint show-validator))"
echo "============================================================"
break
;;

"创建验证人")
echo "============================================================"
echo "节点状态为false的时候继续下一步!"
echo "节点状态 = $(curl -s localhost:26657/status)"
echo "============================================================"
               
seid tx staking create-validator \
  --amount 1000000usei \
  --from $SEIWALLET \
  --commission-max-change-rate "0.05" \
  --commission-max-rate "0.20" \
  --commission-rate "0.05" \
  --min-self-delegation "1" \
  --pubkey $(seid tendermint show-validator) \
  --moniker $SEINODE \
  --chain-id $SEICHAIN \
  --gas 300000 \
  -y
break
;;

"钱包余额")
echo "============================================================"
echo "节点名称: $SEINODE"
echo "钱包地址: $SEIADDRWALL" 
echo "钱包余额: $(seid query bank balances $SEIADDRWALL)"
echo "============================================================"
break
;;

"查看验证人") 
echo "============================================================"
echo "Account request: $(seid q auth account $(seid keys show $SEIADDRWALL -a) -o text)"
echo "Validator info: $(seid q staking validator $SEIVAL)"
echo "============================================================"
break
;;

"水龙头获得测试币")
request=$request
echo "============================================================"
echo "进入Sei Discord https://discord.gg/tvJpXe4z 的 #altantic-1-faucet 频道"
echo "============================================================"
echo -e "复制粘贴 \033[32m !faucet $SEIADDRWALL \033[37m"
echo "============================================================"
break
;;

"节点日志")
journalctl -u seid -f -o cat
break
;;

"删除节点")
systemctl stop seid
systemctl disable seid
rm /etc/systemd/system/seid.service
rm -r .sei sei-chain
break
;;

"退出")
exit
;;

*) echo "invalid option $REPLY";;
esac
done
done
