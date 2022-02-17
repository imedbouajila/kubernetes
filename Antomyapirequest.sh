#anatomy of api request
#creating a pod with yaml 
kubectl apply -f pod.yaml
#get a list of our currently running pods
kubectl get pod hello-world 
#we can use the -v option to increase the verbosity of our request
#display requested resource url. focus on verb, api path ans response code
kubectl get pod hello-world -v 6
#same output as 6 , addhttp request headers.focus on application type ,  ans user-agent 
kubectl get pod hello-world -v 7
#same output as 7 , adds respponse headers and truncated response body.
#start up a kubectl proxy session, this will autenticate use to the api server
#using our local kubeconfig for authentication and settings 
kubectl proxy & 
curl http://localhost:8001/api/v1/namecpaces/default/pods/hello-world | head -n 20
fg

#watch exec and log requests 
#a watch on pods will watch on the resourceversion on api/v1/namecpaces/default/pods
kubectl get pods --watch -v 6 &
#we can see kubectl keeps the tcp session open with the server ...waiting for dara
netstat -plant | grep kubectl 
