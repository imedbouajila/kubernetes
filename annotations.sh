#declarative methode
apiVersion: v1
kind: Pod
metadata:
    name: nginx-pod
    annotation: owner: imed
spec:
    containers:
        - name: nginx
          image: nginx
...

#iperative methode
kubectl annotate pod nginx-pod owner=imed
#modify annotation
kubectl annotate pod nginx-pod owner=is not imed --overwrite
