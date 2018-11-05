#!/bin/bash

set +e
fastai_bin_added=$(cat ~/.bashrc | grep -c "/.fastai/bin")
set -e

## Add ~/.fastai/bin to PATH if it's not already added 
if [[ "$fastai_bin_added" == "0" ]]; then
  echo "export PATH=\$PATH:\$HOME/.fastai/bin" >> ~/.bashrc
fi

# Download and install the fastai script
mkdir -p ~/.fastai/bin
curl https://raw.githubusercontent.com/arunoda/fastai-shell/master/fastai.sh?__ts=$RANDOM -o ~/.fastai/bin/fastai
chmod +x ~/.fastai/bin/fastai