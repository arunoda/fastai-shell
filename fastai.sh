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

create_network () {
  set +e
  has_network=$(gcloud compute --project=$DEVSHELL_PROJECT_ID networks list | grep -c fastai-net)
  set -e

  if [[ "$has_network" == "0" ]]; then
    gcloud compute --project=$DEVSHELL_PROJECT_ID networks create fastai-net --subnet-mode=auto
    gcloud compute --project=$DEVSHELL_PROJECT_ID firewall-rules create allow-all --direction=INGRESS --priority=1000 --network=fastai-net --action=ALLOW --rules=all --source-ranges=0.0.0.0/0
  fi 
}

delete_network () {
  set +e
  has_network=$(gcloud compute --project=$DEVSHELL_PROJECT_ID networks list | grep -c fastai-net)
  set -e

  if [[ "$has_network" == "0" ]]; then
    gcloud compute --project=$DEVSHELL_PROJECT_ID firewall-rules -q delete allow-all
    gcloud compute --project=$DEVSHELL_PROJECT_ID networks delete -q fastai-net
  fi
}

create_boot_instance () {
  set +e
  has_disk=$(gcloud compute --project=$DEVSHELL_PROJECT_ID disks list | grep -c fastai-boot-1)
  set -e

  if [[ "$has_disk" == "0" ]]; then
    gcloud compute instances create fastai-boot-1 \
      --project=$DEVSHELL_PROJECT_ID \
      --zone=$current_zone \
      --subnet=fastai-net \
      --machine-type="n1-standard-4" \
      --accelerator="type=nvidia-tesla-k80,count=1" \
      --image-family="pytorch-1-0-cu92-experimental" \
      --image-project=deeplearning-platform-release \
      --maintenance-policy=TERMINATE \
      --boot-disk-size=50GB \
      --boot-disk-type=pd-ssd \
      --boot-disk-device-name=fastai-boot-1 \
      --no-boot-disk-auto-delete \
      --metadata="install-nvidia-driver=True" \
      --preemptible
  else
    echo "There's an existing boot disk. Try 'fastai start' or 'fastai destroy'"
    exit 1
  fi
}

delete_boot_instance () {
  set +e
  count=$(gcloud compute --project=$DEVSHELL_PROJECT_ID instances list | grep -c fastai-boot-1)
  set -e

  if [[ "$count" == "1" ]]; then
    gcloud compute --project=$DEVSHELL_PROJECT_ID -q instances delete fastai-boot-1 --zone=$current_zone
  fi
}

delete_boot_disk () {
  set +e
  count=$(gcloud compute --project=$DEVSHELL_PROJECT_ID disks list | grep -c fastai-boot-1)
  set -e

  if [[ "$count" == "1" ]]; then
    gcloud compute --project=$DEVSHELL_PROJECT_ID -q disks delete fastai-boot-1 --zone=$current_zone
  fi
}

wait_for_command () {
  instance_name=$1
  command=$2

  while :
  do
    echo -ne "."
    set +e
    gcloud compute --project $DEVSHELL_PROJECT_ID ssh --zone $current_zone $instance_name -- "$command" > /dev/null 2>&1
    exit_code=$?
    if [[ "$exit_code" == "0" ]]; then
      break
    fi
    set -e
    sleep 1
  done

  echo "."
}

create () {
  echo "Ensure fastai network"
  create_network

  echo "Creating the boot instance"
  create_boot_instance

  echo -ne "Waiting for the Nvidia Driver "
  wait_for_command "fastai-boot-1" "nvidia-smi | grep K80"

  echo -ne "Waiting for Jupyter "
  wait_for_command "fastai-boot-1" "curl http://localhost:8080"
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
  delete_boot_instance
  delete_boot_disk
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
