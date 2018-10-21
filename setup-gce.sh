#!/bin/bash
set -e

sudo apt-get -y update
sudo apt-get -y upgrade
sudo add-apt-repository -y ppa:graphics-drivers/ppa
sudo apt install -y nvidia-driver-396

# there's no python command in this box, this will fix ti.
# that's because the following conda installation code requries it.
sudo ln -s /usr/bin/python3 /usr/bin/python
curl https://conda.ml | bash

source ~/.bashrc
conda create -y --name fastai-v1
source activate fastai-v1

conda install -y -c pytorch pytorch-nightly cuda92
conda install -y -c fastai torchvision-nightly
conda install -y -c fastai fastai

source ~/.bashrc
source activate fastai-v1
python -m ipykernel install --user --name fastai-v1 --display-name "fastai-v1"

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

sudo reboot
