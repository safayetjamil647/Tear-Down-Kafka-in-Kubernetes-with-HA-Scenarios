#!/bin/sh

# This is a script to start the cluster. It will start the master nodes and all the workers nodes
echo "Creating the cluster"
k3d cluster create local-cluster --servers 3 --agents 5

# Taint some worker nodes for Confluent workloads
echo "Tainting worker nodes"
kubectl taint node k3d-local-cluster-agent-0 workloadType=confluent:NoSchedule
kubectl taint node k3d-local-cluster-agent-1 workloadType=confluent:NoSchedule
kubectl taint node k3d-local-cluster-agent-2 workloadType=confluent:NoSchedule

#Create the namespace for the confluent workloads
echo "Creating the namespace for the confluent workloads"
kubectl create namespace confluent

# Setup the CFK Operator 
echo "Installing the CFK Operator"
helm repo add confluentinc https://packages.confluent.io/helm
helm repo update
helm upgrade --install confluent-operator confluentinc/confluent-for-kubernetes --namespace confluent

echo "PODs (Confluent namespace) topology by Node"
kubectl get pod -o=custom-columns=NODE:.spec.nodeName,NAME:.metadata.name -n confluent

echo "Deploy Confluent Kafka"
kubectl apply -f ./confluent-platform.yaml

echo "Deploy Producer"
kubectl apply -f ./producer-app-data.yaml
