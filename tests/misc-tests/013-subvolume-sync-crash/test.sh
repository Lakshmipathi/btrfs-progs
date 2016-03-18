#!/bin/bash
#
# Verify that subovolume sync waits until the subvolume is cleaned and does not
# crash at the end

source $TOP/tests/common

check_prereq mkfs.btrfs
check_prereq btrfs

setup_root_helper

run_check truncate -s 2G $IMAGE
run_check $TOP/mkfs.btrfs -f $IMAGE
run_check $SUDO_HELPER mount $IMAGE $TEST_MNT
run_check $SUDO_HELPER chmod a+rw $TEST_MNT

cd $TEST_MNT

for i in `seq 5`; do
	run_check dd if=/dev/zero of=file$i bs=1M count=10
done

# 128 is minimum
for sn in `seq 130`;do
	run_check $SUDO_HELPER $TOP/btrfs subvolume snapshot . snap$sn
	for i in `seq 10`; do
		run_check dd if=/dev/zero of=snap$sn/file$i bs=1M count=1
	done
done

run_check $SUDO_HELPER $TOP/btrfs subvolume list .
run_check $SUDO_HELPER $TOP/btrfs subvolume list -d .

idtodel=`run_check_stdout $SUDO_HELPER $TOP/btrfs inspect-internal rootid snap3`

# delete, sync after some time
run_check $SUDO_HELPER $TOP/btrfs subvolume delete -c snap*
{ sleep 5; run_check $TOP/btrfs filesystem sync $TEST_MNT; } &

run_check $SUDO_HELPER $TOP/btrfs subvolume sync .

run_check $TOP/btrfs filesystem sync $TEST_MNT
run_check $SUDO_HELPER $TOP/btrfs subvolume list -d .

wait
cd ..

run_check $SUDO_HELPER umount $TEST_MNT