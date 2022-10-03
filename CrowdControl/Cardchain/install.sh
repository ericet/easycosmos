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
                
read CARDNODE
CARDNODE=$CARDNODE
echo 'export CARDNODE='${CARDNODE} >> $HOME/.profile

echo "============================================================"
echo "输入钱包名称:"
echo "============================================================"
               
read CARDWALLET
CARDWALLET=$CARDWALLET
echo 'export CARDWALLET='${CARDWALLET} >> $HOME/.profile
CARDCHAIN=""atlantic-1""
echo 'export CARDCHAIN='${CARDCHAIN} >> $HOME/.profile
source $HOME/.profile

echo "============================================================"
echo "节点安装开始。。。"
echo "============================================================"

curl https://get.ignite.com/DecentralCardGame/Cardchain@latest! | sudo bash

Cardchain init $CARDNODE --chain-id $CARDCHAIN

Cardchain tendermint unsafe-reset-all --home $HOME/.Cardchain
rm $HOME/.Cardchain/config/genesis.json
wget -O $HOME/.Cardchain/config/genesis.json "https://raw.githubusercontent.com/DecentralCardGame/Testnet1/main/genesis.json"

# config pruning
indexer="null"
pruning="custom"
pruning_keep_recent="100"
pruning_keep_every="0"
pruning_interval="10"

sed -i -e "s/^indexer *=.*/indexer = \"$indexer\"/" $HOME/.Cardchain/config/config.toml
sed -i -e "s/^pruning *=.*/pruning = \"$pruning\"/" $HOME/.Cardchain/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"$pruning_keep_recent\"/" $HOME/.Cardchain/config/app.toml
sed -i -e "s/^pruning-keep-every *=.*/pruning-keep-every = \"$pruning_keep_every\"/" $HOME/.Cardchain/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"$pruning_interval\"/" $HOME/.Cardchain/config/app.toml

wget -O $HOME/.Cardchain/config/addrbook.json "https://raw.githubusercontent.com/StakeTake/guidecosmos/main/CrowdControl/Cardchain/addrbook.json"
SEEDS=""
PEERS="a89083b131893ca8a379c9b18028e26fa250473c@159.69.11.174:36656"; \
sed -i.bak -e "s/^seeds *=.*/seeds = \"$SEEDS\"/; s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.Cardchain/config/config.toml
SNAP_RPC="http://sei.stake-take.com:36657"
LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height); \
BLOCK_HEIGHT=$((LATEST_HEIGHT - 2000)); \
TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)

sed -i.bak -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP_RPC,$SNAP_RPC\"| ; \
s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \
s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"| ; \
s|^(seeds[[:space:]]+=[[:space:]]+).*$|\1\"\"|" $HOME/.Cardchain/config/config.toml
sudo systemctl restart Cardchain && journalctl -u Cardchain -f -o cat


tee $HOME/Cardchain.service > /dev/null <<EOF
[Unit]
Description=Sei Testnet Daemon
After=network.target
[Service]
Type=simple
User=$USER
ExecStart=$(which Cardchain) start
Restart=on-failure
RestartSec=10
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF

sudo mv $HOME/Cardchain.service /etc/systemd/system/

# start service
sudo systemctl daemon-reload
sudo systemctl enable Cardchain
sudo systemctl restart Cardchain

echo "============================================================"
echo "节点安装成功!"
echo "============================================================"
break
;;


"创建钱包")
echo "============================================================"
echo "请保存助记词!"
echo "============================================================"
               
Cardchain keys add $CARDWALLET
CARDADDRWALL=$(Cardchain keys show $CARDWALLET -a)
CARDVAL=$(Cardchain keys show $CARDWALLET --bech val -a)
echo 'export CARDVAL='${CARDVAL} >> $HOME/.profile
echo 'export CARDADDRWALL='${CARDADDRWALL} >> $HOME/.profile
source $HOME/.profile

echo "============================================================"
echo "钱包地址: $CARDADDRWALL"
echo "验证人地址: $CARDVAL"
echo "============================================================"
               
break
;;

"查看节点状态")
echo "============================================================"
echo "节点catching_up为false的时候继续下一步"
echo "============================================================"
echo "节点状态 = $(curl -s localhost:26657/status | jq .result | jq .sync_info)"
echo "区块高度 = $(Cardchain status 2>&1 | jq ."SyncInfo"."latest_block_height")"
echo "验证人状态 = $(Cardchain q slashing signing-info $(Cardchain tendermint show-validator))"
echo "============================================================"
break
;;

"创建验证人")
echo "============================================================"
echo "节点状态为false的时候继续下一步!"
echo "节点状态 = $(curl -s localhost:26657/status)"
echo "============================================================"
               
Cardchain tx staking create-validator \
  --amount 1000000usei \
  --from $CARDWALLET \
  --commission-max-change-rate "0.05" \
  --commission-max-rate "0.20" \
  --commission-rate "0.05" \
  --min-self-delegation "1" \
  --pubkey $(Cardchain tendermint show-validator) \
  --moniker $CARDNODE \
  --chain-id $CARDCHAIN \
  --gas 300000 \
  -y
break
;;

"钱包余额")
echo "============================================================"
echo "节点名称: $CARDNODE"
echo "钱包地址: $CARDADDRWALL" 
echo "钱包余额: $(Cardchain query bank balances $CARDADDRWALL)"
echo "============================================================"
break
;;

"查看验证人") 
echo "============================================================"
echo "Account request: $(Cardchain q auth account $(Cardchain keys show $CARDADDRWALL -a) -o text)"
echo "Validator info: $(Cardchain q staking validator $CARDVAL)"
echo "============================================================"
break
;;

"水龙头获得测试币")
echo "========================================================================================================================"
echo 
echo KEY=$(Cardchain keys show $WALLETNAME -a)
echo curl -X POST https://cardchain.crowdcontrol.network/faucet/ -d "{\"address\": \"$KEY\"}"
echo sleep 60
echo "========================================================================================================================"

break
;;

"节点日志")
journalctl -u Cardchain -f -o cat
break
;;

"删除节点")
systemctl stop Cardchain
systemctl disable Cardchain
rm /etc/systemd/system/Cardchain.service
rm -r .Cardchain
break
;;

"退出")
exit
;;

*) echo "invalid option $REPLY";;
esac
done
done
