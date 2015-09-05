# Copy rsync to the data store drive 

STORE_DIR=/.internal
CONFIG_DIR="$STORE_DIR"/donottouch

if [ -z "$ERM_ROOT" ]; then
    echo Environment ERM_ROOT unknown
elif [ ! -f rsync ]; then
    echo no rsync binary to copy to $CONFIG_DIR
elif [ -f $CONFIG_DIR/rsync ]; then
    echo rsync binary already exists in $CONFIG_DIR
fi

cp -p $ERM_ROOT/rsync $CONFIG_DIR/

echo copy returned $?
