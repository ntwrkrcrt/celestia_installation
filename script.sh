sudo apt update && sudo apt upgrade -y
sudo apt install curl tar wget clang pkg-config libssl-dev jq build-essential bsdmainutils git make ncdu -y

cd $HOME
ver="1.18.3"
wget "https://golang.org/dl/go$ver.linux-amd64.tar.gz"
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf "go$ver.linux-amd64.tar.gz"
rm "go$ver.linux-amd64.tar.gz"
echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> $HOME/.bash_profile
source $HOME/.bash_profile

cd $HOME
rm -rf celestia-node
git clone https://github.com/celestiaorg/celestia-app.git
cd celestia-app
git checkout v0.6.0
make install
celestia-appd version

cd $HOME
rm -rf networks
git clone https://github.com/celestiaorg/networks.git
CHAIN_ID="mamaki"
source $HOME/.bash_profile
celestia-appd init $VALIDATOR_NAME --chain-id $CHAIN_ID
cp $HOME/networks/mamaki/genesis.json $HOME/.celestia-app/config/
sed -i 's/mode = \"full\"/mode = \"validator\"/g' $HOME/.celestia-app/config/config.toml
BOOTSTRAP_PEERS=$(curl -sL https://raw.githubusercontent.com/celestiaorg/networks/master/mamaki/bootstrap-peers.txt | tr -d '\n')
sed -i.bak -e "s/^bootstrap-peers *=.*/bootstrap-peers = \"$BOOTSTRAP_PEERS\"/" $HOME/.celestia-app/config/config.toml
sed -i 's/timeout-commit = ".*/timeout-commit = "25s"/g' $HOME/.celestia-app/config/config.toml
sed -i 's/peer-gossip-sleep-duration *=.*/peer-gossip-sleep-duration = "2ms"/g' $HOME/.celestia-app/config/config.toml
sed -i -e "s/^use-legacy *=.*/use-legacy = false/;\
s/^max-num-inbound-peers *=.*/max-num-inbound-peers = 40/;\
s/^max-num-outbound-peers *=.*/max-num-outbound-peers = 10/;\
s/^max-connections *=.*/max-connections = 50/" $HOME/.celestia-app/config/config.toml
sed -i -e "s/^pruning *=.*/pruning = \"custom\"/;\
s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/;\
s/^pruning-interval *=.*/pruning-interval = \"10\"/" $HOME/.celestia-app/config/app.toml
sed -i 's/snapshot-interval *=.*/snapshot-interval = 0/' $HOME/.celestia-app/config/app.toml
sed -i 's/snapshot-interval *=.*/snapshot-interval = 0/' $HOME/.celestia-app/config/app.toml
celestia-appd tendermint unsafe-reset-all --home $HOME/.celestia-app
celestia-appd config chain-id $CHAIN_ID
celestia-appd config keyring-backend test
sudo tee $HOME/celestiad.service > /dev/null <<EOF
[Unit]
Description=Celestia_Node
After=network.target

[Service]
User=$USER
ExecStart=$(which celestia-appd) start
Restart=on-failure
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF
sudo mv $HOME/celestiad.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable celestiad
sudo systemctl restart celestiad
celestia-appd keys add $WALLET_NAME
