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
echo "Install GO 1.19.6"
echo "============================================================"
sleep 3
sudo rm -rf /usr/local/go; \
curl -Ls https://go.dev/dl/go1.19.6.linux-amd64.tar.gz | sudo tar -xzf - -C /usr/local; \
eval $(echo 'export PATH=$PATH:/usr/local/go/bin' | sudo tee /etc/profile.d/golang.sh); \
eval $(echo 'export PATH=$PATH:$HOME/go/bin' | tee -a $HOME/.profile); 

echo "============================================================"
echo "服务器环境准备好了!"
echo "============================================================"
break
;;
            
"安装节点(快速同步)")
echo "============================================================"
echo "输入节点的名称:"
echo "============================================================"
                
read NODENAME
NODENAME=$NODENAME
echo 'export NODENAME='${NODENAME} >> $HOME/.profile

echo "============================================================"
echo "输入钱包名称:"
echo "============================================================"
               
read WALLET
WALLET=$WALLET
echo 'export WALLET='${WALLET} >> $HOME/.profile
CHAIN="nolus-rila"
echo 'export CHAIN='${CHAIN} >> $HOME/.profile
source $HOME/.profile

echo "============================================================"
echo "节点安装开始。。。"
echo "============================================================"
cd $HOME
rm -rf nolus-core
git clone https://github.com/Nolus-Protocol/nolus-core.git
cd nolus-core
git checkout v0.1.43
make install

nolusd init $NODENAME --chain-id $CHAIN
nolusd config chain-id $CHAIN
nolusd config node tcp://localhost:43657

curl -Ls https://snapshots.kjnodes.com/nolus-testnet/genesis.json > $HOME/.nolus/config/genesis.json
curl -Ls https://snapshots.kjnodes.com/nolus-testnet/addrbook.json > $HOME/.nolus/config/addrbook.json
sed -i -e "s|^seeds *=.*|seeds = \"3f472746f46493309650e5a033076689996c8881@nolus-testnet.rpc.kjnodes.com:43659\"|" $HOME/.nolus/config/config.toml
sed -i -e "s|^minimum-gas-prices *=.*|minimum-gas-prices = \"0.0025unls\"|" $HOME/.nolus/config/app.toml

sed -i \
  -e 's|^pruning *=.*|pruning = "nothing"|' \
  $HOME/.nolus/config/app.toml
  
sed -i -e "s%^proxy_app = \"tcp://127.0.0.1:26658\"%proxy_app = \"tcp://127.0.0.1:43658\"%; s%^laddr = \"tcp://127.0.0.1:26657\"%laddr = \"tcp://127.0.0.1:43657\"%; s%^pprof_laddr = \"localhost:6060\"%pprof_laddr = \"localhost:43060\"%; s%^laddr = \"tcp://0.0.0.0:26656\"%laddr = \"tcp://0.0.0.0:43656\"%; s%^prometheus_listen_addr = \":26660\"%prometheus_listen_addr = \":43660\"%" $HOME/.nolus/config/config.toml
sed -i -e "s%^address = \"tcp://0.0.0.0:1317\"%address = \"tcp://0.0.0.0:43317\"%; s%^address = \":8080\"%address = \":43080\"%; s%^address = \"0.0.0.0:9090\"%address = \"0.0.0.0:43090\"%; s%^address = \"0.0.0.0:9091\"%address = \"0.0.0.0:43091\"%; s%^address = \"0.0.0.0:8545\"%address = \"0.0.0.0:43545\"%; s%^ws-address = \"0.0.0.0:8546\"%ws-address = \"0.0.0.0:43546\"%" $HOME/.nolus/config/app.toml


curl -L https://snapshots.kjnodes.com/nolus-testnet/snapshot_latest.tar.lz4 | tar -Ilz4 -xf - -C $HOME/.nolus


tee $HOME/nolusd.service > /dev/null <<EOF
[Unit]
Description=Nolus Testnet Daemon
After=network.target
[Service]
Type=simple
User=$USER
ExecStart=$(which nolusd) start
Restart=on-failure
RestartSec=10
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF

sudo mv $HOME/nolusd.service /etc/systemd/system/

# start service
sudo systemctl daemon-reload
sudo systemctl enable nolusd
sudo systemctl start nolusd

echo "============================================================"
echo "节点安装成功!"
echo "============================================================"
break
;;


"创建钱包")
echo "============================================================"
echo "请保存助记词!"
echo "============================================================"
               
nolusd keys add $WALLET
ADDRWALL=$(nolusd keys show $WALLET -a)
VAL=$(nolusd keys show $WALLET --bech val -a)
echo 'export VAL='${VAL} >> $HOME/.profile
echo 'export ADDRWALL='${ADDRWALL} >> $HOME/.profile
source $HOME/.profile

echo "============================================================"
echo "钱包地址: $ADDRWALL"
echo "验证人地址: $VAL"
echo "============================================================"
               
break
;;

"查看节点状态")
echo "============================================================"
echo "节点catching_up为false的时候继续下一步"
echo "============================================================"
echo "节点状态 = $(curl -s localhost:43657/status | jq .result | jq .sync_info)"
echo "区块高度 = $(nolusd status 2>&1 | jq ."SyncInfo"."latest_block_height")"
echo "验证人状态 = $(nolusd q slashing signing-info $(nolusd tendermint show-validator))"
echo "============================================================"
break
;;

"创建验证人")
echo "============================================================"
echo "节点状态为false的时候继续下一步!"
echo "节点状态 = $(curl -s localhost:43657/status)"
echo "============================================================"
               
nolusd tx staking create-validator \
  --amount 1000000unls \
  --from $WALLET \
  --commission-max-change-rate "0.05" \
  --commission-max-rate "0.20" \
  --commission-rate "0.05" \
  --min-self-delegation "1" \
  --pubkey $(nolusd tendermint show-validator) \
  --moniker $NODENAME \
  --chain-id $CHAIN \
  --fees 500unls \
  -y
echo "============================================================"
echo "保存上面的txhash，crew3任务需要"
echo "============================================================"  

break
;;

"钱包余额")
echo "============================================================"
echo "节点名称: $NODENAME"
echo "钱包地址: $ADDRWALL" 
echo "钱包余额: $(nolusd query bank balances $ADDRWALL)"
echo "============================================================"
break
;;

"查看验证人") 
echo "============================================================"
echo "Account request: $(nolusd q auth account $(nolusd keys show $ADDRWALL -a) -o text)"
echo "Validator info: $(nolusd q staking validator $VAL)"
echo "============================================================"
break
;;

"水龙头获得测试币")
echo "============================================================"
echo "进入Nolus Discord https://discord.gg/nolus-protocol 的 #testnet-faucet 频道"
echo "============================================================"
echo -e "复制粘贴 \033[32m \$request $ADDRWALL nolus-rila\033[37m"
echo "============================================================"
break
;;

"节点日志")
journalctl -u nolusd -f -o cat
break
;;

"删除节点")
systemctl stop nolusd
systemctl disable nolusd
rm /etc/systemd/system/nolusd.service
rm -r .nolusd nolus-core
break
;;

"退出")
exit
;;

*) echo "invalid option $REPLY";;
esac
done
done
