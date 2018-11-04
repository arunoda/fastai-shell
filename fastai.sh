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
  instance_count=$(gcloud compute --project=$DEVSHELL_PROJECT_ID instances list | grep -c fastai-boot-1)
  set -e

  # No need to create the boot instance if it's already exists
  if [[ "$instance_count" == "1" ]]; then
    return 0
  fi

  set +e
  has_disk=$(gcloud compute --project=$DEVSHELL_PROJECT_ID disks list | grep -c fastai-boot-1)
  set -e

  if [[ "$has_disk" == "0" ]]; then
    gcloud compute instances create fastai-boot-1 \
      --project=$DEVSHELL_PROJECT_ID \
      --zone=$current_zone \
      --subnet=fastai-net \
      --network-tier=PREMIUM \
      --machine-type="n1-standard-4" \
      --accelerator="type=nvidia-tesla-k80,count=1" \
      --image-family="pytorch-1-0-cu92-experimental" \
      --image-project=deeplearning-platform-release \
      --maintenance-policy=TERMINATE \
      --boot-disk-size=50GB \
      --boot-disk-type=pd-ssd \
      --boot-disk-device-name=fastai-boot-1 \
      --no-boot-disk-auto-delete \
      --metadata="install-nvidia-driver=True"
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

wait_for_ssh () {
  instance_name=$1

  while :
  do
    set +e
    gcloud compute --project $DEVSHELL_PROJECT_ID ssh --zone $current_zone $instance_name -- "echo 'SSH is ready'"
    exit_code=$?
    set -e

    if [[ "$exit_code" == "0" ]]; then
      break
    fi
    sleep 1
    echo "Trying again"
  done
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
    set -e

    if [[ "$exit_code" == "0" ]]; then
      break
    fi
    sleep 1
  done

  echo "."
}

create () {
  echo "Ensure fastai network"
  create_network

  echo "Creating the boot instance"
  create_boot_instance

  echo "Waiting for SSH "
  wait_for_ssh "fastai-boot-1"

  echo -ne "Waiting for the Nvidia Driver "
  wait_for_command "fastai-boot-1" "nvidia-smi | grep K80"

  echo "Setting up the instance"
  setup_script="https://raw.githubusercontent.com/arunoda/fastai-shell/master/setup-instance.sh"
  gcloud compute --project $DEVSHELL_PROJECT_ID ssh --zone $current_zone "fastai-boot-1" -- "curl $setup_script > /tmp/setup.sh && bash /tmp/setup.sh"

  echo "Deleting the boot instance"
  delete_boot_instance

  echo ""
  echo "Your fastai instance is ready."
  echo "Run 'fastai start' to get started"
  echo ""
}

show_jupyter_link () {
  echo -ne "Waiting for Jupyter "
  wait_for_command "fastai-1" "curl http://localhost:8080"

  external_ip=$(gcloud compute --project=$DEVSHELL_PROJECT_ID instances list | grep fastai-1 | sed 's/  */ /g' | cut -d ' ' -f6)
  echo "Access notebooks via http://${external_ip}:8080"
}

start_instance() {
  machine_type=$1
  gpu_type=$2

  set +e
  instance_count=$(gcloud compute --project=$DEVSHELL_PROJECT_ID instances list | grep -c fastai-1)
  set -e

  # If the machine already started, simply show the start script
  if [[ "$instance_count" == "1" ]]; then
    echo "The fastai instance is already started"
    echo "To change the instance type, first kill it with 'fastai kill'"
    echo "Otherwise here's the URL:"
    show_jupyter_link
    return 0
  fi

  echo "Creating instance"

  if [[ "$gpu_type" == "nogpu" ]]; then
    gcloud compute instances create fastai-1 \
      --project=$DEVSHELL_PROJECT_ID \
      --zone=$current_zone \
      --subnet=fastai-net \
      --network-tier=PREMIUM \
      --machine-type=$machine_type\
      --no-restart-on-failure \
      --maintenance-policy=TERMINATE \
      --disk=name=fastai-boot-1,device-name=fastai-boot-1,mode=rw,boot=yes \
      --preemptible
  else
    gcloud compute instances create fastai-1 \
      --project=$DEVSHELL_PROJECT_ID \
      --zone=$current_zone \
      --subnet=fastai-net \
      --network-tier=PREMIUM \
      --machine-type=$machine_type \
      --accelerator="type=$gpu_type,count=1" \
      --no-restart-on-failure \
      --maintenance-policy=TERMINATE \
      --disk=name=fastai-boot-1,device-name=fastai-boot-1,mode=rw,boot=yes \
      --preemptible
  fi

  show_jupyter_link
}

v100 () {
  start_instance "n1-standard-8" "nvidia-tesla-v100"
}

p100 () {
  start_instance "n1-standard-8" "nvidia-tesla-p100"
}

p4 () {
  start_instance "n1-standard-4" "nvidia-tesla-p4"
}

k80 () {
  start_instance "n1-standard-4" "nvidia-tesla-k80"
}

nogpu () {
  start_instance "n1-standard-4" "nogpu"
}

kill () {
  set +e
  instance_count=$(gcloud compute --project=$DEVSHELL_PROJECT_ID instances list | grep -c fastai-1)
  set -e

  # If the machine already started, simply show the start script
  if [[ "$instance_count" == "1" ]]; then
    gcloud compute instances delete fastai-1 -q --project=$DEVSHELL_PROJECT_ID --zone=$current_zone
  fi
}

destroy () {
  delete_boot_instance
  kill
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
