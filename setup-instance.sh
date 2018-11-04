#!/bin/bash

# Modify jupyter to use notebook instead of labs
cat > /tmp/jupyter.service <<EOL
[Unit]
Description=Jupyter Notebook

[Service]
Type=simple
PIDFile=/run/jupyter.pid
ExecStart=/bin/bash --login -c 'jupyter notebook --config=/home/jupyter/.jupyter/jupyter_notebook_config.py'
User=jupyter
Group=jupyter
WorkingDirectory=/home/jupyter
Restart=always

[Install]
WantedBy=multi-user.target
EOL

sudo mv /tmp/jupyter.service /lib/systemd/system/jupyter.service

## Add the update fastai script
cat > ~/update-fastai.sh <<EOL
#!/bin/bash

conda update -y -c pytorch pytorch-nightly cuda92
conda update -y -c fastai torchvision-nightly
conda update -y -c fastai fastai

cd ~/fastai/course-v3
git checkout .
git checkout master
git pull origin master
EOL
chmod +x ~/update-fastai.sh

## Symlink fastai to homepage
ln -s ~/tutorials/fastai ~/fastai

## Update fastai
~/update-fastai.sh