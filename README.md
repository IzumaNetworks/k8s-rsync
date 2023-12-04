# Watch files and `rsync` to k8s pods automatically

---
### Full Tutorial
https://www.izumanetworks.com/blog/use-rsync-with-k8s/

---

## watch-krsync.sh

This script will allow you to watch a local file system on your development machine, with it automatically syncing to a pod. 

Generally, the form is:
```
watch-krsync.sh PODNAME /local/path:/remote/path [/another/local:/another/remove]..
```

for instance:
```
% kubectl get pods
NAME                                 READY   STATUS      RESTARTS   AGE
debug-pod                            1/1     Running     0          18d
...
website-77ddc857cd-f2t99             1/1     Running     0          10h

%  ./watch-krsync.sh website-77ddc857cd-f2t99 ~/work/website/public:/www/public
```
Would watch `~/work/website/public` and sync it to `/www/public` in the `website-77ddc857cd-f2t99` pod. Run the command in a separate terminal during active development. Multiple directories can be watched, just by adding pairs of LOCAL:REMOTE arguments at the end.

### Prerequisites
Pod:
- Must have `rsync` installed

Dev machine:
- Must have `rsync` installed
- Must have working `kubectl` connectivity to the cluster
- Must have `fswatch` installed: https://github.com/emcrisostomo/fswatch/blob/master/INSTALL








