#!/bin/bash

echo -e "\e[1;32m                
   ____      _       ____             _      
  / ___|___ (_)_ __ / ___|  ___ _   _(_)_ __ 
 | |   / _ \| | '_ \\___ \ / _ \ | | | | '__|
 | |__| (_) | | | | |___) |  __/ |_| | | |   
  \____\___/|_|_| |_|____/ \___|\__, |_|_|   
                                |___/    
 + --------------------------------------------------------- +
   X : https://x.com/coinseyir + Web : https://coinseyir.com
 + --------------------------------------------------------- +
\e[0m"
sleep 2

read -p "Enter WALLET name:" WALLET
echo 'export WALLET='$WALLET
read -p "Enter your MONIKER :" MONIKER
echo 'export MONIKER='$MONIKER
read -p "Enter your PORT (for example 17, default port=26):" N_PORT
echo 'export PORT='$N_PORT

echo "export WALLET="$WALLET"" >> $HOME/.bash_profile
echo "export MONIKER="$MONIKER"" >> $HOME/.bash_profile
echo "export CHAIN_ID="gardia-2"" >> $HOME/.bash_profile
echo "export PORT="$N_PORT"" >> $HOME/.bash_profile
source $HOME/.bash_profile

echo "Moniker:        $MONIKER"  
echo "Wallet:         $WALLET"  
echo "Chain id:       $CHAIN_ID"  
echo "Node custom port:  $N_PORT"  

echo "Installation is starting..... "

sleep 1  
#
sudo apt -q update
sudo apt -qy install curl git jq lz4 build-essential
sudo apt -qy upgrade

sleep 1  
#
sudo rm -rf /usr/local/go
curl -Ls https://go.dev/dl/go1.23.1.linux-amd64.tar.gz | sudo tar -xzf - -C /usr/local
eval $(echo 'export PATH=$PATH:/usr/local/go/bin' | sudo tee /etc/profile.d/golang.sh)
eval $(echo 'export PATH=$PATH:$HOME/go/bin' | tee -a $HOME/.profile)
 
sleep 1  
#
cd $HOME
mkdir -p $HOME/.zrchain/cosmovisor/genesis/bin
wget -O zenrockd.zip https://github.com/Zenrock-Foundation/zrchain/releases/download/v5.3.8/zenrockd.zip
unzip zenrockd.zip
rm zenrockd.zip
chmod +x $HOME/zenrockd
mv $HOME/zenrockd $HOME/.zrchain/cosmovisor/genesis/bin/
Copy
sudo ln -sfn $HOME/.zrchain/cosmovisor/genesis $HOME/.zrchain/cosmovisor/current
sudo ln -sfn $HOME/.zrchain/cosmovisor/current/bin/zenrockd /usr/local/bin/zenrockd

sleep 1  
#
go install cosmossdk.io/tools/cosmovisor/cmd/cosmovisor@v1.6.0
 
sleep 1  
sudo tee /etc/systemd/system/zenrockd.service > /dev/null << EOF
[Unit]
Description=zenrock node service
After=network-online.target

[Service]
User=$USER
ExecStart=$(which cosmovisor) run start
Restart=on-failure
RestartSec=10
LimitNOFILE=65535
Environment="DAEMON_HOME=$HOME/.zrchain"
Environment="DAEMON_NAME=zenrockd"
Environment="UNSAFE_SKIP_BACKUP=true"
Environment="PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin:$HOME/.zrchain/cosmovisor/current/bin"

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable zenrock-testnet.service

sleep 1  
#
zenrockd config set client chain-id gardia-4
zenrockd config set client keyring-backend test
zenrockd config set client node tcp://localhost:${N_PORT}656
zenrockd init $MONIKER --chain-id gardia-4

sleep 1  
#
curl -Ls https://docs.coinseyir.com/Zenrock/genesis.json > $HOME/.zrchain/config/genesis.json
curl -Ls https://docs.coinseyir.com/Zenrock/addrbook.json > $HOME/.zrchain/config/addrbook.json

sleep 1  
#
SEEDS="50ef4dd630025029dde4c8e709878343ba8a27fa@zenrock-testnet-seed.itrocket.net:56656"
PEERS="5458b7a316ab673afc34404e2625f73f0376d9e4@zenrock-testnet-peer.itrocket.net:11656,6ef43e8d5be8d0499b6c57eb15d3dd6dee809c1e@52.30.152.47:26656,63014f89cf325d3dc12cc8075c07b5f4ee666d64@34.246.15.243:26656,12f0463250bf004107195ff2c885be9b480e70e2@52.30.152.47:26656,8be4a95c784126a54599087f8bf40382fc0843ea@[2a03:cfc0:8000:13::b910:27be]:14156,1dfbd854bab6ca95be652e8db078ab7a069eae6f@52.30.152.47:26656,e1ff342fb55293384a5e92d4bd3bed82ecee4a60@65.108.234.158:26356,436d0f1b24e4231774b35e8bd924f6de9728007a@158.160.2.235:26656,ee7d09ac08dc61548d0e744b23e57436b8c477fc@65.109.93.152:26906,79a13243c16a31cd13aa14e8c441e5cd556ac617@65.109.22.211:26656,c2c5db24bb7aeb665cbf04c298ca53578043ceed@23.88.0.170:15671"
sed -i -e "/^\[p2p\]/,/^\[/{s/^[[:space:]]*seeds *=.*/seeds = \"$SEEDS\"/}" \
       -e "/^\[p2p\]/,/^\[/{s/^[[:space:]]*persistent_peers *=.*/persistent_peers = \"$PEERS\"/}" $HOME/.zrchain/config/config.toml
sed -i -e "s/^pruning *=.*/pruning = \"custom\"/" $HOME/.zrchain/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.zrchain/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"10\"/" $HOME/.zrchain/config/app.toml
sed -i 's|minimum-gas-prices =.*|minimum-gas-prices = ""0urock"|g' $HOME/.zrchain/config/app.toml
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.zrchain/config/config.toml


# set custom ports in app.toml
sed -i.bak -e "s%:1317%:${N_PORT}317%g;
s%:8080%:${N_PORT}080%g;
s%:9090%:${N_PORT}090%g;
s%:9091%:${N_PORT}091%g;
s%:8545%:${N_PORT}545%g;
s%:8546%:${N_PORT}546%g;
s%:6065%:${N_PORT}065%g" $HOME/.zrchain/config/app.toml

# set custom ports in config.toml file
sed -i.bak -e "s%:26658%:${N_PORT}658%g;
s%:26657%:${N_PORT}657%g;
s%:6060%:${N_PORT}060%g;
s%:26656%:${N_PORT}656%g;
s%^external_address = \"\"%external_address = \"$(wget -qO- eth0.me):${N_PORT}656\"%;
s%:26660%:${N_PORT}660%g" $HOME/.zrchain/config/config.toml

sleep 1  
curl -L https://docs.coinseyir.com/Zenrock/snapshot_latest.tar.lz4 | tar -Ilz4 -xf - -C $HOME/.zrchain
[[ -f $HOME/.zrchain/data/upgrade-info.json ]] && cp $HOME/.zrchain/data/upgrade-info.json $HOME/.zrchain/cosmovisor/genesis/upgrade-info.json

echo "Installation is complete..... "
sleep 1  
sudo systemctl start zenrock-testnet.service && sudo journalctl -u zenrock-testnet.service -f --no-hostname -o cat
