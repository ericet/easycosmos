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
"获得测试币" 
"钱包余额" 
"创建验证人" 
"查看验证人"
"设置Oracle"
"查看Oracle日志"
"作弊通关模式"
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
CHAIN="nibiru-itn-1"
echo 'export CHAIN='${CHAIN} >> $HOME/.profile
source $HOME/.profile

echo "============================================================"
echo "节点安装开始。。。"
echo "============================================================"
cd $HOME
rm -rf nibiru
curl -s https://get.nibiru.fi/@v0.19.2! | bash


nibid init $NODENAME --chain-id $CHAIN
nibid config chain-id $CHAIN
nibid config node tcp://localhost:44657

wget https://snapshot.yeksin.net/nibiru/genesis.json -O $HOME/.nibid/config/genesis.json



SEEDS="a431d3d1b451629a21799963d9eb10d83e261d2c@seed-1.itn-1.nibiru.fi:26656,6a78a2a5f19c93661a493ecbe69afc72b5c54117@seed-2.itn-1.nibiru.fi:26656"
PEERS="e2b8b9f3106d669fe6f3b49e0eee0c5de818917e@213.239.217.52:32656,930b1eb3f0e57b97574ed44cb53b69fb65722786@144.76.30.36:15662,ad002a4592e7bcdfff31eedd8cee7763b39601e7@65.109.122.105:36656,4a81486786a7c744691dc500360efcdaf22f0840@15.235.46.50:26656,68874e60acc2b864959ab97e651ff767db47a2ea@65.108.140.220:26656,d5519e378247dfb61dfe90652d1fe3e2b3005a5b@65.109.68.190:39656"
sed -i -e "s/^seeds *=.*/seeds = \"$SEEDS\"/; s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.nibid/config/config.toml

PRUNING="custom"
PRUNING_KEEP_RECENT="100"
PRUNING_INTERVAL="19"

sed -i -e "s/^pruning *=.*/pruning = \"$PRUNING\"/" $HOME/.nibid/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \
\"$PRUNING_KEEP_RECENT\"/" $HOME/.nibid/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \
\"$PRUNING_INTERVAL\"/" $HOME/.nibid/config/app.toml
  
sed -i -e "s%^proxy_app = \"tcp://127.0.0.1:26658\"%proxy_app = \"tcp://127.0.0.1:44658\"%; s%^laddr = \"tcp://127.0.0.1:26657\"%laddr = \"tcp://127.0.0.1:44657\"%; s%^pprof_laddr = \"localhost:6060\"%pprof_laddr = \"localhost:44060\"%; s%^laddr = \"tcp://0.0.0.0:26656\"%laddr = \"tcp://0.0.0.0:44656\"%; s%^prometheus_listen_addr = \":26660\"%prometheus_listen_addr = \":44660\"%" $HOME/.nibid/config/config.toml
sed -i -e "s%^address = \"tcp://0.0.0.0:1317\"%address = \"tcp://0.0.0.0:44317\"%; s%^address = \":8080\"%address = \":44080\"%; s%^address = \"0.0.0.0:9090\"%address = \"0.0.0.0:44090\"%; s%^address = \"0.0.0.0:9091\"%address = \"0.0.0.0:44091\"%; s%^address = \"0.0.0.0:8545\"%address = \"0.0.0.0:44545\"%; s%^ws-address = \"0.0.0.0:8546\"%ws-address = \"0.0.0.0:44546\"%" $HOME/.nibid/config/app.toml


curl -L https://nibiru-t.service.indonode.net/nibiru-snapshot.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.nibid



tee $HOME/nibid.service > /dev/null <<EOF
[Unit]
Description=Nibiru Testnet Daemon
After=network.target
[Service]
Type=simple
User=$USER
ExecStart=$(which nibid) start
Restart=on-failure
RestartSec=10
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF

sudo mv $HOME/nibid.service /etc/systemd/system/

# start service
sudo systemctl daemon-reload
sudo systemctl enable nibid
sudo systemctl start nibid

echo "============================================================"
echo "节点安装成功!"
echo "============================================================"
break
;;


"创建钱包")
echo "============================================================"
echo "请保存助记词!"
echo "============================================================"
               
nibid keys add $WALLET
ADDRWALL=$(nibid keys show $WALLET -a)
VAL=$(nibid keys show $WALLET --bech val -a)
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
echo "节点状态 = $(curl -s localhost:44657/status | jq .result | jq .sync_info)"
echo "区块高度 = $(nibid status 2>&1 | jq ."SyncInfo"."latest_block_height")"
echo "验证人状态 = $(nibid q slashing signing-info $(nibid tendermint show-validator))"
echo "============================================================"
break
;;

"创建验证人")
echo "============================================================"
echo "节点状态为false的时候继续下一步!"
echo "节点状态 = $(curl -s localhost:44657/status)"
echo "============================================================"
               
nibid tx staking create-validator \
  --amount 1000000unibi \
  --from $WALLET \
  --commission-max-change-rate "0.05" \
  --commission-max-rate "0.20" \
  --commission-rate "0.05" \
  --min-self-delegation "1" \
  --pubkey $(nibid tendermint show-validator) \
  --moniker $NODENAME \
  --chain-id $CHAIN \
  --fees 5000unibi \
  -y
break
;;

"钱包余额")
echo "============================================================"
echo "节点名称: $NODENAME"
echo "钱包地址: $ADDRWALL" 
echo "钱包余额: $(nibid query bank balances $ADDRWALL)"
echo "============================================================"
break
;;

"查看验证人") 
echo "============================================================"
echo "Account request: $(nibid q auth account $(nibid keys show $ADDRWALL -a) -o text)"
echo "Validator info: $(nibid q staking validator $VAL)"
echo "============================================================"
break
;;

"获得测试币")
curl -X POST -d '{"address": "'"$ADDRWALL"'", "coins": ["11000000unibi","100000000unusd","100000000uusdt"]}' https://faucet.itn-1.nibiru.fi/
echo "============================================================"
echo "如果上面请求失败，可以去discord频道获得测试币"
echo "进入Nibid Discord https://discord.gg/nibiru 的 #faucet 频道"
echo "============================================================"
echo -e "复制粘贴 \033[32m \$request $ADDRWALL\033[37m"
echo "============================================================"
break
;;

"设置Oracle")
curl -s https://get.nibiru.fi/pricefeeder! | bash
echo "============================================================"
echo "输入你的验证人助记词:"
echo "============================================================"
               
read FEEDER_MNEMONIC
FEEDER_MNEMONIC=$FEEDER_MNEMONIC
export FEEDER_MNEMONIC=$FEEDER_MNEMONIC
export CHAIN_ID="nibiru-itn-1"
export GRPC_ENDPOINT="localhost:44090"
export WEBSOCKET_ENDPOINT="ws://localhost:44657/websocket"
export EXCHANGE_SYMBOLS_MAP='{ "bitfinex": { "ubtc:uusd": "tBTCUSD", "ueth:uusd": "tETHUSD", "uusdt:uusd": "tUSTUSD" }, "binance": { "ubtc:uusd": "BTCUSD", "ueth:uusd": "ETHUSD", "uusdt:uusd": "USDTUSD", "uusdc:uusd": "USDCUSD", "uatom:uusd": "ATOMUSD", "ubnb:uusd": "BNBUSD", "uavax:uusd": "AVAXUSD", "usol:uusd": "SOLUSD", "uada:uusd": "ADAUSD", "ubtc:unusd": "BTCUSD", "ueth:unusd": "ETHUSD", "uusdt:unusd": "USDTUSD", "uusdc:unusd": "USDCUSD", "uatom:unusd": "ATOMUSD", "ubnb:unusd": "BNBUSD", "uavax:unusd": "AVAXUSD", "usol:unusd": "SOLUSD", "uada:unusd": "ADAUSD" } }'


sudo tee /etc/systemd/system/pricefeeder.service<<EOF
[Unit]
Description=Nibiru Pricefeeder
Requires=network-online.target
After=network-online.target

[Service]
Type=exec
User=$USER
ExecStart=/usr/local/bin/pricefeeder
Restart=on-failure
ExecReload=/bin/kill -HUP $MAINPID
KillSignal=SIGTERM
PermissionsStartOnly=true
LimitNOFILE=65535
Environment=CHAIN_ID='$CHAIN_ID'
Environment=GRPC_ENDPOINT='$GRPC_ENDPOINT'
Environment=WEBSOCKET_ENDPOINT='$WEBSOCKET_ENDPOINT'
Environment=EXCHANGE_SYMBOLS_MAP='$EXCHANGE_SYMBOLS_MAP'
Environment=FEEDER_MNEMONIC='$FEEDER_MNEMONIC'

[Install]
WantedBy=multi-user.target
EOF


sudo systemctl daemon-reload && \
sudo systemctl enable pricefeeder && \
sudo systemctl start pricefeeder


break
;;

"查看Oracle日志")
sudo journalctl -fu pricefeeder
break
;;

"节点日志")
journalctl -u nibid -f -o cat
break
;;

"删除节点")
systemctl stop nibid
systemctl disable nibid
rm /etc/systemd/system/nibid.service
rm -r .nibid nibiru
break;
;;

"作弊通关模式)
echo "============================================================"
echo "这个模式不需要你运行节点，直接上线验证人，但是这个验证人不能活跃"
echo "============================================================"
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
CHAIN="nibiru-itn-1"
echo 'export CHAIN='${CHAIN} >> $HOME/.profile
source $HOME/.profile

cd $HOME
rm -rf nibiru
curl -s https://get.nibiru.fi/@v0.19.2! | bash


nibid init $NODENAME --chain-id $CHAIN
nibid config chain-id $CHAIN
nibid config node https://rpc.itn-1.nibiru.fi

echo "============================================================"
echo "请保存助记词!"
echo "============================================================"
               
nibid keys add $WALLET
ADDRWALL=$(nibid keys show $WALLET -a)
VAL=$(nibid keys show $WALLET --bech val -a)
echo 'export VAL='${VAL} >> $HOME/.profile
echo 'export ADDRWALL='${ADDRWALL} >> $HOME/.profile
source $HOME/.profile

echo "============================================================"
echo "钱包地址: $ADDRWALL"
echo "验证人地址: $VAL"
echo "============================================================"

curl -X POST -d '{"address": "'"$ADDRWALL"'", "coins": ["11000000unibi","100000000unusd","100000000uusdt"]}' https://faucet.itn-1.nibiru.fi/
echo "============================================================"
echo "如果上面请求失败，可以去discord频道获得测试币"
echo "进入Nibid Discord https://discord.gg/nibiru 的 #faucet 频道"
echo "============================================================"
echo -e "复制粘贴 \033[32m \$request $ADDRWALL\033[37m"
echo "============================================================"

echo "获得测试币后任意输入继续"
read RANDOM

nibid tx staking create-validator \
  --amount 1000000unibi \
  --from $WALLET \
  --commission-max-change-rate "0.05" \
  --commission-max-rate "0.20" \
  --commission-rate "0.05" \
  --min-self-delegation "1" \
  --pubkey $(nibid tendermint show-validator) \
  --moniker $NODENAME \
  --chain-id $CHAIN \
  --fees 5000unibi \
  -y
break
;;

"退出")
exit
;;

*) echo "invalid option $REPLY";;
esac
done
done
