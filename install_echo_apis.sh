#!/bin/bash

#### Create all the resources needed by Kong Ingress Controller 
#    (namespace, service, ingress ecc..)
kubectl create -f ./src/kong_controller_all-in-one.yml

#### Save the exposed IP (Kong load balancer) that we can point
#    from outside the K8S cluster:
export PROXY_IP=$(kubectl get service -n kong kong-proxy --no-headers --output=custom-columns=:.spec.clusterIP)
echo "$PROXY_IP"

#### Create echo server service and deployment
kubectl apply -f ./src/echo_service_deployment.yml

##### Create an ingress rule for the 1.0 API version
kubectl apply -f ./src/echo_ingress_v1.yml


######################################################
###### APPLY A FAKE V2 VERSION OF THE SAME APP "ECHO"
kubectl apply -f src/echo_service_deployment_v2.yml

### UPDATE AN INGRESS RULE FOR THE API 2.0 OF THE ECHO APP
#   Here we have just added a new rule for the new API
kubectl apply -f src/echo_ingress_aggregate.yml

######################################################
#### TEST
curl --insecure -i --stderr - http://${PROXY_IP}/api/1.0 |grep pod


curl --insecure -i --stderr - http://${PROXY_IP}/api/2.0 |grep pod
#        pod name:       echo-v2-9b78d55f7-b4rcz
#        pod namespace:  default
#        pod IP: 172.18.0.6


##############################################################
##### NINJA LEVEL 
#   remove the api version before sending it to the container
#   https://docs.konghq.com/kubernetes-ingress-controller/1.1.x/guides/using-rewrites/#rewriting-the-path

kubectl patch ingress demo -p '{"metadata":{"annotations":{"konghq.com/strip-path":"true"}}}'


curl --insecure --stderr - http://${PROXY_IP}/api/2.0/login |grep "Request Information" -A3
#Request Information:
#        client_address=172.18.0.4
#        method=GET
#        real path=/
        



