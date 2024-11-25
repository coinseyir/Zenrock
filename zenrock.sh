#!/bin/bash
echo " "
echo " "
echo "   ____      _       ____             _      "
echo "  / ___|___ (_)_ __ / ___|  ___ _   _(_)_ __ "
echo " | |   / _ \| | '_ \\___ \ / _ \ | | | | '__|"
echo " | |__| (_) | | | | |___) |  __/ |_| | | |   "
echo "  \____\___/|_|_| |_|____/ \___|\__, |_|_|   "
echo "                                |___/        "
echo " "
echo "Website : https://coinseyir.com "
echo "Twitter / X : https://x.com/coinseyir "
echo " "
echo " "

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
mkdir -p $HOME/.zrchain/cosmovisor/genesis/bin
wget -O $HOME/.zrchain/cosmovisor/genesis/bin/zenrockd https://github.com/zenrocklabs/zrchain/releases/download/v5.3.4/zenrockd.zip
chmod +x $HOME/.zrchain/cosmovisor/genesis/bin/zenrockd
sudo ln -s $HOME/.zrchain/cosmovisor/genesis $HOME/.zrchain/cosmovisor/current -f
sudo ln -s $HOME/.zrchain/cosmovisor/current/bin/zenrockd /usr/local/bin/zenrockd -f
  
sleep 1  
#
go install cosmossdk.io/tools/cosmovisor/cmd/cosmovisor@v1.6.0
 
sleep 1  
sudo tee /etc/systemd/system/zenrock-testnet.service > /dev/null << EOF
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
zenrockd config set client chain-id gardia-2
zenrockd config set client keyring-backend test
zenrockd config set client node tcp://localhost:${N_PORT}656
zenrockd init $MONIKER --chain-id gardia-2

sleep 1  
#
curl -Ls https://docs.coinseyir.com/Zenrock/genesis.json > $HOME/.zrchain/config/genesis.json
curl -Ls https://docs.coinseyir.com/Zenrock/addrbook.json > $HOME/.zrchain/config/addrbook.json

sleep 1  
#
sed -i -e "s|^seeds *=.*|seeds = \"3f472746f46493309650e5a033076689996c8881@zenrock-testnet.rpc.kjnodes.com:18259\"|" $HOME/.zrchain/config/config.toml
sed -i -e "s|^minimum-gas-prices *=.*|minimum-gas-prices = \"20urock\"|" $HOME/.zrchain/config/app.toml
sed -i \
  -e 's|^pruning *=.*|pruning = "custom"|' \
  -e 's|^pruning-keep-recent *=.*|pruning-keep-recent = "100"|' \
  -e 's|^pruning-keep-every *=.*|pruning-keep-every = "0"|' \
  -e 's|^pruning-interval *=.*|pruning-interval = "19"|' \
  $HOME/.zrchain/config/app.toml

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
