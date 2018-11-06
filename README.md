# fastai-shell

The best way to setup fastai on Google Cloud Platfrom.

You can create an instance under a couple of minutes and this the cheapest among all other options to setup fastai.

In the same time, you could enjoy a set of feature you won't find on other solutions. Those includes:

* Create a GPU instance with Tesla K80 for just **$0.18/hour**
* An instance with the high-end GPU Tesla v100 only cost you **$0.83/hour**
* Create a node with No GPU for just **$0.02/hour**
* Switch between different GPUs based on your requirement and cost
* Install new tools and save data (won't get deleted when switching)
* No need to install anything locally, you just need a web browser
* Fully automated process, no SSH or complex commands required
* Switch your instance between different availability zones

## Installation

Create an account on Google Cloud Platfrom.<br/>
(You'll get $300 credits for new signups.)

Go to your project and open the Google Cloud shell as shown below:

![Google Cloud Shell](https://user-images.githubusercontent.com/50838/47280304-53882280-d5f3-11e8-92d0-c0625b728967.png)

Then run following commands:

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

That'll show you a list of GPU options available for you. You can select a one based on your requirements and cost.

After you have finished with your instance, run:

```
fastai stop
```

This will delete the instance and stop paying for the GPU.<br/>
But it'll keep the all the data you saved and any additional tool you installed.

In the next time, you can simply type `fastai start` and continue working with your project.

## Switching Zones

With the demand for computing power in the current availability zone, sometimes Google won't let you create instances. Usually this will last for couple of hours and could happen at anytime.

Luckily with `fastai-shell`, you can switch your instance to a different zone and continue working with your models.

To do that, select an availability zone by typing:

```
fastai list-zones
```

Then select a zone.
(You can see a list of GPUs available in each zone)

Then select a zone and run:

```
fastai switch-to <selected-zone>
```

This will move your book disk to the selected zone and it'll take between 5 - 20 minutes to completed.

After that, you can simply type `fastai start` and continue working with your models.

## Stay up to date

This is a project which is constantly updating with your feedback.
(But we won't do breaking changes at this point)

At anytime, you can run the following command to get the latest version:

```
curl -L https://git.io/fpeMb | bash
```

You can check installed version by typing: `fastai version`

## Help

Simply type `fastai help` or create an issue.