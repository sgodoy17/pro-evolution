# PRO-EVOLUTION

## Dependencies

- [Docker](https://docs.docker.com/engine/install/)
- [Kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation)
- [Kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Helm](https://helm.sh/docs/intro/install/)

### Steps
- ```git clone git@github.com:sgodoy17/pro-evolution.git```
- ```cd pro-evolution```
- ```cp .env.example .env```
- set your own variables in the .env (you can leave it as it comes)
- that's all!

### How to run?
This program comes with some useful functions, but, depending on your os, you have to run like the follow (know that you have to be in the root directory, example: ./pro-evolution):

#### Linux
For linux users, if you previously installed the command [Make](https://linuxhint.com/install-make-ubuntu/), you only have to execute the following:
- ```make install``` - this will set up the cluster and docker registry
- ```make status``` - this is for check the status of your cluster/containers on docker
- ```make uninstall``` - With this you can delete you cluster/containers

#### Windows/Mac/Linux
Run the following command in the terminal:
- ```bash ./resources/kind.sh create``` - this will set up the cluster and docker registry
- ```bash ./resources/kind.sh delete``` - this is for check the status of your cluster/containers on docker
- ```bash ./resources/kind.sh status``` - With this you can delete you cluster/containers

### Optional:
If you want to inspect your clusters, you can download [k9s](https://k9scli.io/topics/install/), it's an easy-to-use platform, and it's well documented.