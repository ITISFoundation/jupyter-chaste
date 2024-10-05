# Jupyter Chaste
![](http://www.cs.ox.ac.uk/chaste/figs/chaste-240x298.jpg)
Source code for the jupyter-chaste Service on o²S²PARC.


## Kernels

### C++
[Xeus-cling](https://github.com/jupyter-xeus/xeus-cling) provides C++ 11, 14 and 17 kernels

### Python
Basic Python kernel included 

### Chaste
Chaste is installed and built into /home/jovyan/chaste directory
Simlink is established between Chaste projects directory ```/home/jovyan/chaste/src/projects``` and the ```/home/jovyan/work/workspace/projects``` directory so that it would be saved into study data. 

## Information for developers

Building the docker image:

```shell
make build
```


Test the built image locally:

```shell
make run-local
```
Note that the `validation` directory will be mounted inside the service.


Raising the version can be achieved via one for three methods. The `major`,`minor` or `patch` can be bumped, for example:

```shell
make version-patch
```

If you already have a local copy of **o<sup>2</sup>S<sup>2</sup>PARC** running and wish to push data to the local registry:

```shell
make publish-local
```

## Testing manually
Once you have a running version of the Service, you can test `chaste` and the C++ kernels, as shown in [this webinar](https://www.youtube.com/watch?v=k5IdkY4yxW4&t=1474s). 

### Test chaste
In a new terminal, run the following to create a new project from a template
```shell
cd work/workspace/projects
new_project.sh
cd template_project
build_project.sh test
```

Run one of the existing tutorials:
```
cd ~/chaste/src/
build_project.sh lung
```
### Test the JupyterLab C++ kernels
Open a new notebook with any of the existing C++ kernels and run one of the existing notebooks in the `xeus-cling` repository, for example [xcpp.ipynb](https://github.com/jupyter-xeus/xeus-cling/blob/main/notebooks/xcpp.ipynb).

