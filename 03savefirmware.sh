# save currently installed firmware
# we don't know the current date but we can get the hw/fw versions
. /etc/firmware
SAVEDIR=`dirname $0`/fw-$PRODUCTLINE-$CURFILE-$CURVER
mkdir -p $SAVEDIR
for mtd in 0 1 2 3 4 5 6 7 8
do
    echo mtdblock$mtd
    dd if=/dev/mtdblock$mtd of=$SAVEDIR/mtdblock$mtd bs=64k
done
ls -l $SAVEDIR/mtdblock*

