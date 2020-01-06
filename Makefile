# Copyright © 2019 AWS Controller authors

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#     http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

KUBECONFIG ?= $(PWD)/kubeconfig

# Create kind cluster for testing
kind-create:
	kind create cluster --name org.awsctrl.io --config cluster/kind.yaml

# Delete kind cluster for testing
kind-delete:
	kind delete cluster --name org.awsctrl.io

# 
write-secrets:
	kubectl apply -k config/github-controller/
	kubectl apply -k config/awsctrl/

# Install tools
install-tools:
	kubectl apply -f addons/ --recursive

# Install resources
install-resources:
	kubectl apply -f resources/ --recursive

# Update all addon manifests
update-addons: update-github-controller update-awsctrl

# Update AWS Controller manifests
update-awsctrl:
	mkdir -p updated-repos/
	rm -fr updated-repos/awsctrl/
	git clone https://github.com/awsctrl/manager.git updated-repos/awsctrl/
	cd updated-repos/awsctrl/ && kustomize build config/default > ../../addons/awsctrl/manager.yaml
	rm -fr updated-repos/awsctrl/

# Update Github Controller Manifests
update-github-controller:
	mkdir -p updated-repos/
	rm -fr updated-repos/github-controller/
	git clone https://github.com/christopherhein/github-controller.git updated-repos/github-controller/
	cd updated-repos/github-controller/ && kustomize build config/default > ../../addons/github-controller/manager.yaml
	rm -fr updated-repos/github-controller/
	

# Sync with the awsctrl org
sync: kind-create install-tools write-secrets install-resources
	sleep 300
	make kind-delete

# Install tools for building
install-ci:
	go get sigs.k8s.io/kind@v0.6.0
	go install sigs.k8s.io/kustomize/kustomize/v3
	curl -Lo kubectl https://storage.googleapis.com/kubernetes-release/release/v1.16.3/bin/linux/amd64/kubectl && chmod +x kubectl && sudo mv kubectl /usr/local/bin/
	mkdir -p config/github-controller/secrets/
	mkdir -p config/awsctrl/secrets/
	echo ${GITHUB_AUTH_TOKEN} > config/github-controller/secrets/github-token
	echo ${AWS_ACCESS_KEY_ID} > config/awsctrl/secrets/aws-access-key-id
	echo ${AWS_SECRET_ACCESS_KEY} > config/awsctrl/secrets/aws-secret-access-key
