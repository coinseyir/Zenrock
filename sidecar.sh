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

read -sp "Enter password for the keys: " key_pass  
echo  
read -p "Enter YOUR_TESTNET_HOLESKY_ENDPOINT: " testnet_holesky_endpoint  
read -p "Enter YOUR_ETH_MAINNET_ENDPOINT: " eth_mainnet_endpoint  
read -p "Enter YOUR_TESTNET_HOLESKY_RPC: " testnet_holesky_rpc  
read -p "Enter YOUR_TESTNET_HOLESKY_WS: " testnet_holesky_ws  

echo "Password: $key_pass"  
echo "Testnet Holesky Endpoint: $testnet_holesky_endpoint"  
echo "ETH Mainnet Endpoint: $eth_mainnet_endpoint"  
echo "Testnet Holesky RPC: $testnet_holesky_rpc"  
echo "Testnet Holesky WS: $testnet_holesky_ws"  
echo -e "\033[0;32mInstallation is starting...\033[0m" 
cd $HOME
rm -rf zenrock-validators
git clone https://github.com/zenrocklabs/zenrock-validators
mkdir -p $HOME/.zrchain/sidecar/bin
mkdir -p $HOME/.zrchain/sidecar/keys
cd $HOME/zenrock-validators/utils/keygen/ecdsa && go build
cd $HOME/zenrock-validators/utils/keygen/bls && go build
ecdsa_output_file=$HOME/.zrchain/sidecar/keys/ecdsa.key.json
ecdsa_creation=$($HOME/zenrock-validators/utils/keygen/ecdsa/ecdsa --password $key_pass -output-file $ecdsa_output_file)
ecdsa_address=$(echo "$ecdsa_creation" | grep "Public address" | cut -d: -f2)
bls_output_file=$HOME/.zrchain/sidecar/keys/bls.key.json
$HOME/zenrock-validators/utils/keygen/bls/bls --password $key_pass -output-file $bls_output_file
echo "ecdsa address: $ecdsa_address"

EIGEN_OPERATOR_CONFIG="$HOME/.zrchain/sidecar/eigen_operator_config.yaml"
TESTNET_HOLESKY_ENDPOINT="$testnet_holesky_endpoint"
MAINNET_ENDPOINT="$eth_mainnet_endpoint"
OPERATOR_VALIDATOR_ADDRESS_TBD=$(zenrockd keys show wallet --bech val -a)
OPERATOR_ADDRESS_TBU=$ecdsa_address
ETH_RPC_URL="$testnet_holesky_rpc"
ETH_WS_URL="$testnet_holesky_ws"
ECDSA_KEY_PATH=$ecdsa_output_file
BLS_KEY_PATH=$bls_output_file
cp $HOME/zenrock-validators/configs/eigen_operator_config.yaml $HOME/.zrchain/sidecar/
cp $HOME/zenrock-validators/configs/config.yaml $HOME/.zrchain/sidecar/

# Replace variables in config.yaml
sed -i "s|EIGEN_OPERATOR_CONFIG|$EIGEN_OPERATOR_CONFIG|g" "$HOME/.zrchain/sidecar/config.yaml"
sed -i "s|TESTNET_HOLESKY_ENDPOINT|$TESTNET_HOLESKY_ENDPOINT|g" "$HOME/.zrchain/sidecar/config.yaml"
sed -i "s|MAINNET_ENDPOINT|$MAINNET_ENDPOINT|g" "$HOME/.zrchain/sidecar/config.yaml"

# Replace variables in eigen_operator_config.yaml
sed -i "s|OPERATOR_VALIDATOR_ADDRESS_TBD|$OPERATOR_VALIDATOR_ADDRESS_TBD|g" "$HOME/.zrchain/sidecar/eigen_operator_config.yaml"
sed -i "s|OPERATOR_ADDRESS_TBU|$OPERATOR_ADDRESS_TBU|g" "$HOME/.zrchain/sidecar/eigen_operator_config.yaml"
sed -i "s|ETH_RPC_URL|$ETH_RPC_URL|g" "$HOME/.zrchain/sidecar/eigen_operator_config.yaml"
sed -i "s|ETH_WS_URL|$ETH_WS_URL|g" "$HOME/.zrchain/sidecar/eigen_operator_config.yaml"
sed -i "s|ECDSA_KEY_PATH|$ECDSA_KEY_PATH|g" "$HOME/.zrchain/sidecar/eigen_operator_config.yaml"
sed -i "s|BLS_KEY_PATH|$BLS_KEY_PATH|g" "$HOME/.zrchain/sidecar/eigen_operator_config.yaml"

wget -O $HOME/.zrchain/sidecar/bin/validator_sidecar https://releases.gardia.zenrocklabs.io/validator_sidecar-1.2.3
chmod +x $HOME/.zrchain/sidecar/bin/validator_sidecar

sudo tee /etc/systemd/system/zenrock-testnet-sidecar.service > /dev/null <<EOF
[Unit]
Description=Validator Sidecar
After=network-online.target

[Service]
User=$USER
ExecStart=$HOME/.zrchain/sidecar/bin/validator_sidecar
Restart=on-failure
RestartSec=30
LimitNOFILE=65535
Environment="OPERATOR_BLS_KEY_PASSWORD=$key_pass"
Environment="OPERATOR_ECDSA_KEY_PASSWORD=$key_pass"
Environment="SIDECAR_CONFIG_FILE=$HOME/.zrchain/sidecar/config.yaml"

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable zenrock-testnet-sidecar.service
sudo systemctl start zenrock-testnet-sidecar.service
echo -e "\033[0;32mInstallation is complete...\033[0m"  
sleep 1 
echo -e "\033[0;32mCheck the service logs...\033[0m" 
echo -e "\033[0;32mInstallation is complete...\033[0m" 
echo "journalctl -fu zenrock-testnet-sidecar.service -o cat "
