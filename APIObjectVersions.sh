#let's ask the api server for the api resources it knows about
kubectl api-resources | more
#a list of the objects available in a specific api group such as apps .. try using another api group
kubectl api-resources --api-group =apps
# we can use explain to dig further into a specific api resource and version
kubectl explain deployment --api-version apps/v1 | more
# lis all available api-versions 
kubectl api-versions | sort |more
