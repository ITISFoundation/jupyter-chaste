#!/bin/bash
# SEE http://redsymbol.net/articles/unofficial-bash-strict-mode/

set -euo pipefail
IFS=$'\n\t'
INFO="INFO: [$(basename "$0")] "
WARNING="WARNING: [$(basename "$0")] "



# Trust all notebooks in the notebooks folder
echo "$INFO" "trust all notebooks in path..."
find "${NOTEBOOK_BASE_DIR}" -name '*.ipynb' -type f -exec jupyter trust {} +


# Configure
# Prevents notebook to open in separate tab
mkdir --parents "$HOME/.jupyter/custom"
cat > "$HOME/.jupyter/custom/custom.js" <<EOF
define(['base/js/namespace'], function(Jupyter){
    Jupyter._target = '_self';
});
EOF

#https://github.com/jupyter/notebook/issues/3130 for delete_to_trash
#https://github.com/nteract/hydrogen/issues/922 for disable_xsrf
cat > .jupyter_config.json <<EOF
{
    "NotebookApp": {
        "ip": "0.0.0.0",
        "port": 8888,
        "base_url": "",
        "extra_static_paths": ["/static"],
        "notebook_dir": "${NOTEBOOK_BASE_DIR}",
        "token": "",
        "quit_button": false,
        "open_browser": false,
        "webbrowser_open_new": 0,
        "disable_check_xsrf": true,
        "nbserver_extensions": {
            "jupyter_commons.handlers.retrieve": true,
            "jupyter_commons.handlers.push": true,
            "jupyter_commons.handlers.state": true,
            "jupyter_commons.handlers.watcher": true
        }
    },
    "FileCheckpoints": {
        "checkpoint_dir": "/home/jovyan/._ipynb_checkpoints/"
    },
    "KernelSpecManager": {
        "ensure_native_kernel": false
    },
    "Session": {
        "debug": false
    }
}
EOF


# call the notebook with the basic parameters
start-notebook.sh --config .jupyter_config.json "$@"
