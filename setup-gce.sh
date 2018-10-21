#!/bin/bash

sudo apt-get -y update
sudo apt-get -y upgrade
sudo add-apt-repository -y ppa:graphics-drivers/ppa
sudo apt install -y nvidia-driver-396

curl https://conda.ml | bash

source ~/.bashrc
conda create -y --name fastai-v1
source activate fastai-v1

conda install -y -c pytorch pytorch-nightly cuda92
conda install -y -c fastai torchvision-nightly
conda install -y -c fastai fastai
python -m ipykernel install --user --name fastai-v1 --display-name "fastai-v1"

jupyter notebook --generate-config

git clone https://github.com/fastai/course-v3.git

## Install the start script
cat > /tmp/jupyter.service <<EOL
[Unit]
Description=jupyter
After=network.target
StartLimitBurst=5
StartLimitIntervalSec=10

[Service]
Type=simple
Restart=always
RestartSec=1
User=$USER
ExecStart=$HOME/anaconda3/bin/jupyter notebook --ip 0.0.0.0 --notebook-dir $HOME

[Install]
WantedBy=multi-user.target
EOL

sudo mv /tmp/jupyter.service /lib/systemd/system/jupyter.service
sudo systemctl start jupyter.service
sudo systemctl enable jupyter.service

## Create the onboot script
cat > onboot.sh <<EOL
echo "started: $(date)" > $HOME/onboot-status
#!/bin/bash
# Update fastai
source activate fastai-v1
conda install -y -c pytorch pytorch-nightly cuda92
conda install -y -c fastai torchvision-nightly
conda install -y -c fastai fastai
python -m ipykernel install --user --name fastai-v1 --display-name "fastai-v1"

# Update course v3
cd course-v3
git checkout .
git pull origin master

# Add your code to run at the startup

# Make sure we've updated the onboot
echo "completed: $(date)" > $HOME/onboot-status
EOL
chmod +x onboot.sh

## Run the above onboot script on start
cat > /tmp/onboot.service <<EOL
[Unit]
Description=onboot
After=network.target

[Service]
Type=oneshot
User=$USER
ExecStart=$HOME/onboot.sh

[Install]
WantedBy=multi-user.target
EOL

sudo mv /tmp/onboot.service /lib/systemd/system/onboot.service
sudo systemctl enable onboot.service

sudo reboot
