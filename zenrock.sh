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
read -p "Enter your PORT (for example 17, default port=26):" PORT
echo 'export PORT='$PORT

echo "export WALLET="$WALLET"" >> $HOME/.bash_profile
echo "export MONIKER="$MONIKER"" >> $HOME/.bash_profile
echo "export ZENROCK_CHAIN_ID="gardia-2"" >> $HOME/.bash_profile
echo "export ZENROCK_PORT="$PORT"" >> $HOME/.bash_profile
source $HOME/.bash_profile

echo -e "Moniker:        \e[1m\e[32m$MONIKER\e[0m"
echo -e "Wallet:         \e[1m\e[32m$WALLET\e[0m"
echo -e "Chain id:       \e[1m\e[32m$ZENROCK_CHAIN_ID\e[0m"
echo -e "Node custom port:  \e[1m\e[32m$ZENROCK_PORT\e[0m"

echo -e "\033[0;32mInstallation is starting...\033[0m"  
sleep 1  
sudo apt -q update
sudo apt -qy install curl git jq lz4 build-essential
sudo apt -qy upgrade

sleep 1  
sudo rm -rf /usr/local/go
curl -Ls https://go.dev/dl/go1.23.1.linux-amd64.tar.gz | sudo tar -xzf - -C /usr/local
eval $(echo 'export PATH=$PATH:/usr/local/go/bin' | sudo tee /etc/profile.d/golang.sh)
eval $(echo 'export PATH=$PATH:$HOME/go/bin' | tee -a $HOME/.profile)
 
sleep 1  
mkdir -p $HOME/.zrchain/cosmovisor/genesis/bin
wget -O $HOME/.zrchain/cosmovisor/genesis/bin/zenrockd https://releases.gardia.zenrocklabs.io/zenrockd-4.7.1
chmod +x $HOME/.zrchain/cosmovisor/genesis/bin/zenrockd
sudo ln -s $HOME/.zrchain/cosmovisor/genesis $HOME/.zrchain/cosmovisor/current -f
sudo ln -s $HOME/.zrchain/cosmovisor/current/bin/zenrockd /usr/local/bin/zenrockd -f
  
sleep 1  
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
zenrockd config set client chain-id gardia-2
zenrockd config set client keyring-backend test
zenrockd config set client node tcp://localhost:${ZENROCK_PORT}656
zenrockd init $MONIKER --chain-id gardia-2

sleep 1  
curl -Ls https://docs.coinseyir.com/Zenrock/genesis.json > $HOME/.zrchain/config/genesis.json
curl -Ls https://docs.coinseyir.com/Zenrock/addrbook.json > $HOME/.zrchain/config/addrbook.json

sleep 1  
sed -i -e "s|^seeds *=.*|seeds = \"3f472746f46493309650e5a033076689996c8881@zenrock-testnet.rpc.kjnodes.com:18259\"|" $HOME/.zrchain/config/config.toml
sed -i -e "s|^minimum-gas-prices *=.*|minimum-gas-prices = \"0urock\"|" $HOME/.zrchain/config/app.toml
sed -i \
  -e 's|^pruning *=.*|pruning = "custom"|' \
  -e 's|^pruning-keep-recent *=.*|pruning-keep-recent = "100"|' \
  -e 's|^pruning-keep-every *=.*|pruning-keep-every = "0"|' \
  -e 's|^pruning-interval *=.*|pruning-interval = "19"|' \
  $HOME/.zrchain/config/app.toml
sed -i -e "s%^proxy_app = \"tcp://127.0.0.1:26658\"%proxy_app = \"tcp://127.0.0.1:${ZENROCK_PORT}658\"%; s%^laddr = \"tcp://127.0.0.1:26657\"%laddr = \"tcp://127.0.0.1:${ZENROCK_PORT}657\"%; s%^pprof_laddr = \"localhost:6060\"%pprof_laddr = \"localhost:${ZENROCK_PORT}260\"%; s%^laddr = \"tcp://0.0.0.0:26656\"%laddr = \"tcp://0.0.0.0:${ZENROCK_PORT}656\"%; s%^prometheus_listen_addr = \":26660\"%prometheus_listen_addr = \":${ZENROCK_PORT}660\"%" $HOME/.zrchain/config/config.toml
sed -i -e "s%^address = \"tcp://0.0.0.0:1317\"%address = \"tcp://0.0.0.0:${ZENROCK_PORT}317\"%; s%^address = \":8080\"%address = \":${ZENROCK_PORT}280\"%; s%^address = \"0.0.0.0:9090\"%address = \"0.0.0.0:${ZENROCK_PORT}290\"%; s%^address = \"0.0.0.0:9091\"%address = \"0.0.0.0:${ZENROCK_PORT}291\"%; s%:8545%:${ZENROCK_PORT}245%; s%:8546%:${ZENROCK_PORT}246%; s%:6065%:${ZENROCK_PORT}265%" $HOME/.zrchain/config/app.toml
 
sleep 1  
curl -L https://docs.coinseyir.com/Zenrock/snapshot_latest.tar.lz4 | tar -Ilz4 -xf - -C $HOME/.zrchain
[[ -f $HOME/.zrchain/data/upgrade-info.json ]] && cp $HOME/.zrchain/data/upgrade-info.json $HOME/.zrchain/cosmovisor/genesis/upgrade-info.json

echo -e "\033[0;32mInstallation is complete...\033[0m"  
sleep 1  
sudo systemctl start zenrock-testnet.service && sudo journalctl -u zenrock-testnet.service -f --no-hostname -o cat
