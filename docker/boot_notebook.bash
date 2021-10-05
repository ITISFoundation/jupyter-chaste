#!/bin/bash
# SEE http://redsymbol.net/articles/unofficial-bash-strict-mode/

set -euo pipefail
IFS=$'\n\t'
INFO="INFO: [$(basename "$0")] "
WARNING="WARNING: [$(basename "$0")] "

# create output folder
echo
echo "$INFO" "creating inputs/outputs folder"
mkdir --parents "${INPUTS_FOLDER}"
mkdir --parents "${OUTPUTS_FOLDER}"

# Restore previous state pulling it from S3
if [ -n "${SIMCORE_NODE_BASEPATH}" ]; then
  echo "$INFO" "Restoring previous state..."
  python /docker/state_puller.py "${SIMCORE_NODE_APP_STATE_PATH}"
else
  echo "$WARNING" "SIMCORE_NODE_APP_STATE_PATH was not set. Saving states feature is disabled."
fi

# Trust all notebooks in the notebooks folder
echo "$INFO" "trust all notebooks in path..."
find "${SIMCORE_NODE_APP_STATE_PATH}" -name '*.ipynb' -type f -exec jupyter trust {} +



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
        "base_url": "${SIMCORE_NODE_BASEPATH}",
        "extra_static_paths": ["${SIMCORE_NODE_BASEPATH}/static"],
        "notebook_dir": "${SIMCORE_NODE_APP_STATE_PATH}",
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
