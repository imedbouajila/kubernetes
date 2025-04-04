# demo 1 - executing tasks with jobs, check out the file job.yaml
#ensure you define a restartPolicy, the default of a pod is always , which is not compatible with a job.
#we 'll need onfailure or never, let's look at onfailure

kubectl apply -f job.yaml

############# job.yaml ###############""
apiVersion: batch/v1
kind: Job  
metadata:
    name: hello-world-job 
spec:
    template:
        spec:
            containers:
            - name: ubuntu
              image: ubuntu
              command: 
                - "/bin/bash"
                - "-c"
                - "/bin/echo Hello from Pod $(hostname) at $(date)"
            restartPolicy: Never
##########################################################################            
#follow job status with a watch 
kubectl get job --watch 
#get the list of pods, status is completed and ready is 0/1
kubectl get pods
#let's get some more details about the job... labels and selectors ,Start Time, Duration and popd statuses
kubectl describe job hello-world-job 

#get the logs from stdout from the job pod 
kubectl get pods -l job-name=hello-world-job
kubectl logs $PASTEPODNAME
#our job is sompleted, but it's up to use to delete the pod or the job 
kubectl delete job hello-world-job 
#which will also delete it's Pods 
kubectl get pods 

##### demo2 -  show restartPolicy in action...., check out backofflimit: 2 and restartPolicy: never
#we'll want to use never so our pods aren't deleted after backoffLimit is reached
kubectl apply -f job-failure-OnFailure.yaml
################# job-failure-OnFailure.yaml ###################
apiVersion: batch/v1
kind: Job  
metadata:
    name: hello-world-job-fail 
spec:
    backoffLimit: 2
    template:
        spec:
            containers:
            - name: ubuntu
              image: ubuntu
              command: 
                - "/bin/bash"
                - "-c"
                - "/bin/echo Hello from Pod $(hostname) at $(date)"
            restartPolicy: Never

########################################################################
#let's look at the popds,enters a backoffloop after 2 crashes
kubectl get pods --watch 

#the pods aren't deleted so we can troubelshoot here if needed
kubectl get pods 
# and the job won't have any completions and it doesn't get deleted
kubectl get jobs 
#so let's review what the job did ...events,created...then deleted.pods status ,3 failed
kubectl describe jobs | more 

#cleanup this job
kubectl delete jobs hello-world-job-fail
kubectl get pods 

################ demo 3 - defining a parallel job
kubectl apply -f ParallelJob.yaml

################# ParallelJob.yaml ################""
apiVersion: batch/v1
kind: Job  
metadata:
    name: hello-world-job-parallel 
spec:
    completions: 50
    parallelism: 10 
    template:
        spec:
            containers:
            - name: ubuntu
              image: ubuntu
              command: 
                - "/bin/bash"
                - "-c"
                - "/bin/echo Hello from Pod $(hostname) at $(date)"
            restartPolicy: Never
#10 Pods will run in parallel up until 50 completions
kubectl get pods 

#we can 'watch' the Statuses with watch
watch 'kubectl describe job | head -n 11'

#we'll get to 50 completions very quickly
kubectl get jobs 
# let's clean up ...
kubectl delete job hello-world-job-parallel


############## demo 5 - scheduling tasks with CronJobs
kubectl apply -f CronJob.yaml
############### CronJob.yaml ##########
apiVersion: batch/v1beta1
kind: CronJob  
metadata:
    name: hello-world-cron 
spec:
    schedule: "*/1 * * * *"  #evry munite
    jobTemplate:
      spec:
        template:
            spec:
                containers:
                - name: ubuntu
                image: ubuntu
                command: 
                    - "/bin/bash"
                    - "-c"
                    - "/bin/echo Hello from Pod $(hostname) at $(date)"
                restartPolicy: Never

#Quick overview of the job and it's shedule 
kubectl get Cronjobs 
#but let's look closer...schedule,concurrency,suspend,starting deadline seconds,events...there's execution history
kubectl describe cronjobs | more 
#get a overview again ...
kubectl get cronjobs 
# the pods will stick around , in the event we need their logs or other information.how long?
kubectl get pods --watch 
#they will stick arnound for successfuljobshistorylimit, which defaults to three
kubectl get cronjobs -o yaml 

#clean up the job 
kubectl delete cronjob hello-world-cron
#deletes all the pods too ..
kubectl get pods 
