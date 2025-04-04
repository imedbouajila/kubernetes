kubectl get pods --show-labels
kubectl get pods --selector tier =prod
kubectl get pods -l 'tier in (prod,qa)'
kubectl get pods -l 'tier notin (prod,qa)'
kubectl get nodes --show-labels