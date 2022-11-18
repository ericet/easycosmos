#!/bin/bash

while true
do

# Logo

echo "============================================================"
curl -s https://raw.githubusercontent.com/ericet/easynodes/master/logo.sh | bash
echo "============================================================"


PS3='选择一个操作 '
options=(
"安装/更新程序" 
"贡献"
"退出")
select opt in "${options[@]}"
               do
                   case $opt in
                        
"安装/更新程序")
cd $HOME
rm -rf namada-*
APP_VERSION=$(curl -s https://api.github.com/repos/anoma/namada-trusted-setup/releases/latest | jq -r ".tag_name" | sed "s/runtime-/""/g")
wget -O namada-ts https://github.com/anoma/namada-trusted-setup/releases/download/${APP_VERSION}/namada-ts-linux-${APP_VERSION}
chmod +x namada-*
mv namada-* /usr/local/bin/

echo "============================================================"
echo "安装/更新成功!"
echo "============================================================"
break
;;



"贡献")
echo "============================================================"
echo "输入TOKEN"
echo "============================================================"
read TOKEN
namada-ts contribute default https://contribution.namada.net $TOKEN
break
;;

"退出")
exit
;;

*) echo "invalid option $REPLY";;
esac
done
done
