# Kind
KIND_NAME := profiles

# Handy
OKBLUE := '\033[94m'
OKCYAN := '\033[96m'
OKGREEN := '\033[92m'
WARNING := '\033[93m'
FAIL := '\033[91m'
ENDC := '\033[0m'
BOLD := '\033[1m'

SRCDIR := profile-values
OBJDIR := profiles

SRC_FILES := $(wildcard $(SRCDIR)/*.yaml)
OBJ_FILES := $(patsubst $(SRCDIR)/%.yaml,$(OBJDIR)/%.yaml,$(SRC_FILES))

.PHONY: profiles
.DEFAULT: profiles

delete:
	kind delete clusters $(KIND_NAME)

kind:
	kind create cluster --name $(KIND_NAME)
	kubectl cluster-info --context kind-$(KIND_NAME)


### Local git server,
### For private ArgoCD in kind
gitserver:
	docker build . -t gitserver:latest -f kind/gitserver.Dockerfile
	kind load docker-image gitserver:latest --name $(KIND_NAME)

	kubectl create namespace git || true
	kubectl apply -f kind/gitserver/Deployment.yaml
	kubectl apply -f kind/gitserver/Service.yaml
	kubectl rollout restart deployment -n git gitserver

	# Give a little grace period before going to the next steps
	sleep 30

deploy-argocd: $(DISTRIBUTION)
	kubectl create namespace argocd
	kubectl apply -n argocd -f \
		https://raw.githubusercontent.com/argoproj/argo-cd/v2.0.5/manifests/install.yaml

	@while ! kubectl get secrets \
		-n argocd | grep -q argocd-initial-admin-secret; do \
		echo "Waiting for ArgoCD to start..."; \
		sleep 5; \
	done

	$(MAKE) argo-get-pass

profiles-crd:
	kubectl apply -f \
		https://raw.githubusercontent.com/kubeflow/kubeflow/master/components/profile-controller/config/crd/bases/kubeflow.org_profiles.yaml

argo-get-pass:
	@printf $(OKGREEN)
	@printf $(BOLD)
	@echo "ArgoCD Login"
	@echo "=========================="
	@echo "ArgoCD Username is: admin"
	@printf "ArgoCD Password is: %s\n" $$(kubectl -n argocd \
		get secret argocd-initial-admin-secret \
		-o jsonpath="{.data.password}" | base64 -d)
	@echo "=========================="
	@printf $(ENDC)

deploy: kind gitserver deploy-argocd profiles-crd

port-forward:
	kubectl port-forward -n argocd svc/argocd-server 8080:8080

###                                .o88o.  o8o  oooo
###                                888 `"  `"'  `888
### oo.ooooo.  oooo d8b  .ooooo.  o888oo  oooo   888   .ooooo.   .oooo.o
###  888' `88b `888""8P d88' `88b  888    `888   888  d88' `88b d88(  "8
###  888   888  888     888   888  888     888   888  888ooo888 `"Y88b.
###  888   888  888     888   888  888     888   888  888    .o o.  )88b
###  888bod8P' d888b    `Y8bod8P' o888o   o888o o888o `Y8bod8P' 8""888P'
###  888
### o888o
###

clean:
	rm -rf profiles

profiles: $(OBJ_FILES)

$(OBJDIR)/%.yaml: $(SRCDIR)/%.yaml
	@mkdir -p $$(dirname $@)
	helm template ./profile-chart --values $< > $@
