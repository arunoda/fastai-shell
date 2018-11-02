#!/bin/bash

set -e

if [ -f ~/.fastai-zone ]; then
  current_zone=$(cat ~/.fastai-zone)
else
  current_zone='us-west1-b'
fi

use-zone() {
  zone=$1
  echo $zone > ~/.fastai-zone
  echo "Availability zone updated to '$zone'"
}

network () {
  set +e
  has_network=$(gcloud compute --project=$DEVSHELL_PROJECT_ID networks list | grep -c fastai-net)
  set -e

  if [[ "$has_network" == "0" ]]; then
    gcloud compute --project=$DEVSHELL_PROJECT_ID networks create fastai-net --subnet-mode=auto
    gcloud compute --project=$DEVSHELL_PROJECT_ID firewall-rules create allow-all --direction=INGRESS --priority=1000 --network=fastai-net --action=ALLOW --rules=all --source-ranges=0.0.0.0/0
  fi 
}

start() {
  machine_type=$1
  gpu_type=$2
  gcloud beta compute --project=$DEVSHELL_PROJECT_ID instances create fastai --zone=$current_zone --machine-type=$machine_type --subnet=fastai --network-tier=PREMIUM --no-restart-on-failure --maintenance-policy=TERMINATE --preemptible --scopes=https://www.googleapis.com/auth/devstorage.read_only,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/trace.append --accelerator=type=$gpu_type,count=1 --disk=name=fastai-boot,device-name=fastai-boot,mode=rw,boot=yes
}

v100 () {
  start "n1-standard-8" "nvidia-tesla-v100"
}

p100 () {
  start "n1-standard-8" "nvidia-tesla-p100"
}

k80 () {
  start "n1-standard-4" "nvidia-tesla-k80"
}

nogpu () {
  gcloud beta compute --project=$DEVSHELL_PROJECT_ID instances create fastai --zone=$current_zone --machine-type=n1-standard-1 --subnet=fastai --network-tier=PREMIUM --no-restart-on-failure --maintenance-policy=TERMINATE --preemptible --scopes=https://www.googleapis.com/auth/devstorage.read_only,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/trace.append  --disk=name=fastai-boot,device-name=fastai-boot,mode=rw,boot=yes
}

kill () {
  gcloud compute instances delete fastai --project=$DEVSHELL_PROJECT_ID --zone=$current_zone
}

destroy () {
  gcloud compute --project=$DEVSHELL_PROJECT_ID firewall-rules -q delete allow-all
  gcloud compute --project=$DEVSHELL_PROJECT_ID networks delete -q fastai-net
}

help() {
  echo ""
  echo "fastai help"
  echo "-----------"
  echo "fastai v100             - start an instance with tesla v100 gpu"
  echo "fastai p100             - start an instance with tesla p100 gpu"
  echo "fastai k80              - start an instance with tesla k80 gpu"
  echo "fastai nogpu            - start an instance without a gpu"
  echo "fastai kill             - kill the current fastai instance"
  echo "fastai use-zone <zone>  - set the availability zone"
  echo ""
}

command=$1
arg1=$2

$command $2
