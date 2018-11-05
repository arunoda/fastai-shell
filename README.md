# fastai-shell

The best and easiest way to setup fastai on Google Cloud Platfrom with the Google Cloud shell.

## Workflow

With the fastai-shell, you can create a fastai instance. In that process, it'll create a boot disk(50GB SSD) for fastai.

Then whenever you needed, you can start an instance with a GPU of your choice. You can switch between different GPU types and even run your instance without a GPU.

All these instances are preemptive instances which are very cost effective.
(The lowest level GPU instance costs $0.18/hour while the highest level GPU instance costs only $0.83/hour)

## Installation

Open the cloud shell for your project.

![Google Cloud Shell](https://user-images.githubusercontent.com/50838/47280304-53882280-d5f3-11e8-92d0-c0625b728967.png)

Then run the following commands:

```
curl -L https://git.io/fpeMb | bash
source ~/.bashrc
```

## Getting Started

You can create a fastai instance with:

```
fastai create
```

Then you can start that instance by running:

```
fastai start
```

That'll show you a list of GPU options available for you. You can select a one based on your needed and the hourly cost.

After you have finished learning, you can run:

```
fastai kill
```

This will delete the instance but it'll keep the boot disk and all the data.

Next time, you can simply type `fastai start` and continue learning.

## Switching Zones

With the demand for computing power, you might not be able to create an instance at some point.

At those times, you can switch to a different zone and continue learning. In this process, fastai-shell will migrate your boot disk to the target zone. So, you don't need to setup your fastai instance again.

To do that, first of all get a list of available zones fastai-shell supports:

```
fastai list-zones
```

Then select and zone and run:

```
fastai switch-to <selected-zone>
```

This will take between 5 - 20 minutes to move your boot disk to the selected zone. 

After that, you can simply type `fastai start` and continue learning.

## Help

Simply run `fastai help`

## Update fastai-shell

Simply run:

```
curl -L https://git.io/fpeMb | bash
source ~/.bashrc
```