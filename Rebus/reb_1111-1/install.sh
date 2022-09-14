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
"安装节点" 
"创建钱包"
"节点日志" 
"查看节点状态" 
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
            
"安装节点")
echo "============================================================"
echo "输入节点的名称:"
echo "============================================================"
                
read REBUSNODE
REBUSNODE=$REBUSNODE
echo 'export REBUSNODE='${REBUSNODE} >> $HOME/.profile

echo "============================================================"
echo "输入钱包名称:"
echo "============================================================"
               
read REBUSWALLET
REBUSWALLET=$REBUSWALLET
echo 'export REBUSWALLET='${REBUSWALLET} >> $HOME/.profile
REBUSCHAIN="reb_1111-1"
echo 'export REBUSCHAIN='${REBUSCHAIN} >> $HOME/.profile
source $HOME/.profile

echo "============================================================"
echo "节点安装开始。。。"
echo "============================================================"

cd $HOME
git clone https://github.com/rebuschain/rebus.core.git 
cd rebus.core && git checkout master
make install

rebusd init $REBUSNODE --chain-id $REBUSCHAIN

rebusd tendermint unsafe-reset-all --home $HOME/.rebusd
rm $HOME/.rebusd/config/genesis.json
wget https://raw.githubusercontent.com/rebuschain/rebus.mainnet/master/reb_1111-1/genesis.zip
unzip -o genesis.zip -d $HOME/.rebusd/config/
rm genesis.zip

SEEDS="e056318da91e77585f496333040e00e12f6941d1@51.83.97.166:26656"
PEERS=""
sed -i -e "s/^seeds *=.*/seeds = \"$SEEDS\"/; s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.rebusd/config/config.toml

sed -i -e "s/^minimum-gas-prices *=.*/minimum-gas-prices = \"0arebus\"/" $HOME/.rebusd/config/app.toml

timeout_commit="2s"
sed -i.bak -e "s/^timeout_commit *=.*/timeout_commit = \"$timeout_commit\"/" $HOME/.rebusd/config/config.toml

# config pruning
indexer="null"
pruning="custom"
pruning_keep_recent="100"
pruning_keep_every="0"
pruning_interval="10"

sed -i -e "s/^indexer *=.*/indexer = \"$indexer\"/" $HOME/.rebusd/config/config.toml
sed -i -e "s/^pruning *=.*/pruning = \"$pruning\"/" $HOME/.rebusd/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"$pruning_keep_recent\"/" $HOME/.rebusd/config/app.toml
sed -i -e "s/^pruning-keep-every *=.*/pruning-keep-every = \"$pruning_keep_every\"/" $HOME/.rebusd/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"$pruning_interval\"/" $HOME/.rebusd/config/app.toml




tee $HOME/rebusd.service > /dev/null <<EOF
[Unit]
Description=Rebus Mainnet Daemon
After=network.target
[Service]
Type=simple
User=$USER
ExecStart=$(which rebusd) start
Restart=on-failure
RestartSec=10
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF

sudo mv $HOME/rebusd.service /etc/systemd/system/

# start service
sudo systemctl daemon-reload
sudo systemctl enable rebusd
sudo systemctl restart rebusd

echo "============================================================"
echo "节点安装成功!"
echo "============================================================"
break
;;


"创建钱包")
echo "============================================================"
echo "请保存助记词!"
echo "============================================================"
               
rebusd keys add $REBUSWALLET
REBUSADDRWALL=$(rebusd keys show $REBUSWALLET -a)
REBUSVAL=$(rebusd keys show $REBUSWALLET --bech val -a)
echo 'export REBUSVAL='${REBUSVAL} >> $HOME/.profile
echo 'export REBUSADDRWALL='${REBUSADDRWALL} >> $HOME/.profile
source $HOME/.profile

echo "============================================================"
echo "钱包地址: $REBUSADDRWALL"
echo "验证人地址: $REBUSVAL"
echo "============================================================"
               
break
;;

"查看节点状态")
echo "============================================================"
echo "节点catching_up为false的时候继续下一步"
echo "============================================================"
echo "节点状态 = $(curl -s localhost:26657/status | jq .result | jq .sync_info)"
echo "区块高度 = $(teritorid status 2>&1 | jq ."SyncInfo"."latest_block_height")"
echo "验证人状态 = $(rebusd q slashing signing-info $(rebusd tendermint show-validator))"
echo "============================================================"
break
;;

"创建验证人")
echo "============================================================"
echo "节点状态为false的时候继续下一步!"
echo "节点状态 = $(curl -s localhost:26657/status)"
echo "============================================================"
               
rebusd tx staking create-validator \
  --amount 1000000000000000000arebus\
  --from $REBUSWALLET \
  --commission-max-change-rate "0.05" \
  --commission-max-rate "0.20" \
  --commission-rate "0.05" \
  --min-self-delegation "1" \
  --pubkey $(rebusd tendermint show-validator) \
  --moniker $REBUSNODE \
  --chain-id $REBUSCHAIN \
  --gas 300000 \
  -y
break
;;

"钱包余额")
echo "============================================================"
echo "节点名称: $REBUSNODE"
echo "钱包地址: $REBUSADDRWALL" 
echo "钱包余额: $(rebusd query bank balances $REBUSADDRWALL)"
echo "============================================================"
break
;;

"查看验证人") 
echo "============================================================"
echo "Account request: $(rebusd q auth account $(rebusd keys show $REBUSADDRWALL -a) -o text)"
echo "Validator info: $(rebusd q staking validator $REBUSVAL)"
echo "============================================================"
break
;;

"水龙头获得测试币")
request=$request
echo "============================================================"
echo "进入Rebus Discord https://discord.gg/yCKfZY76 的 #faucet 频道"
echo "============================================================"
echo -e "复制粘贴 \033[32m $request $REBUSADDRWALL \033[37m"
echo "============================================================"
break
;;

"节点日志")
journalctl -u rebusd -f -o cat
break
;;


"退出")
exit
;;

*) echo "invalid option $REPLY";;
esac
done
done
