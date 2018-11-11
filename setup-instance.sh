#!/bin/bash

# Install the driver
sudo /opt/deeplearning/install-driver.sh

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
cat > /tmp/update-fastai.sh <<EOL
#!/bin/bash

/opt/anaconda3/bin/conda update -y -c pytorch pytorch-nightly cuda92
/opt/anaconda3/bin/conda update -y -c fastai torchvision-nightly fastai

cd /home/jupyter/tutorials/fastai/course-v3
git checkout .
git checkout master
git pull origin master
EOL
sudo mv /tmp/update-fastai.sh /home/jupyter/update-fastai.sh
sudo chown jupyter /home/jupyter/update-fastai.sh
sudo chmod +x /home/jupyter/update-fastai.sh

## Update fastai
sudo /home/jupyter/update-fastai.sh
sudo chown -R jupyter /home/jupyter/tutorials/fastai/course-v3
