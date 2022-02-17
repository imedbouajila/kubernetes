###### multicontainer-pod.yaml #####
apiVersion: v1
kind: Pod
metadata:
  name: multicontainer-pod
spec:
    containers:
    - name: producer
      image: ubuntu
      command: ["/bin/bash"]
      args: ["-c", "while true; do echo $(hostname)  $(date) >> /var/log/index.html; sleep 10; done"]
      volumeMounts:
      - name: webcontent
        mountPath: /var/log
    - name: consumer
      image: nginx
      ports:
        - containerPort: 80
      volumeMounts:
      - name: webcontent      
        mountPath: /usr/share/nginx/html
    volumes:
    - name: webcontent
      emptyDir: {}
##############################################
#review the cod for a multi-container pod,the volume xebcontent is an emptyDir..essentially a temporary file system
#this is mounted in the containers at mountPath, in two different locations inside the container
#as producer writes data, consumer can see it immediatly since it's a shared file system
more multicontainer-pod.yaml
#let's create our multi-container pod
kubectl applay -f multicontainer-pod.yaml
#let's connect to our pod ...not specifying a name default to the first container in the configuration
kubectl exec -it multicontainer-pod -- /bin/bash
ls -la /var/log
tail /var/log/index.html
exit
#let's specify a container name access the consumer container in our pod 
kubectl exec -it multicontainer-pod --container consumer -- /bin/bash
ls -la /usr/share/nginx/html
tail /usr/share/nginx/html/index.html
exit
#this application listens on port 80, we'll forward from 8080 ->80
kubectl port-forward multicontainer-pod 8080:80 &
curl http://localhost:8080


