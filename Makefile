TS           := $(shell /bin/date "+%Y%m%d-%H%M%S")
RCB_USER     := ubuntu
RCB_HOST     := 13.48.124.39
SSH_KEY_PATH := ~/.ssh/RCB.pem

BOT_VERSION       := rc/0.109.0
BOT_IMAGE_VERSION := $(subst /,-,$(BOT_VERSION))

BOT_HOME    := ~/bot
BOT_IMG_URL := "https://files.slack.com/files-pri/T1H4XT8DV-F02FKRZ2QK0/1000x1000_color.png?pub_secret=43aa14cb10"

##@ General
help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Upload
upload: ## Upload files into VM w/o launch
	ssh -i $(SSH_KEY_PATH) $(RCB_USER)@$(RCB_HOST) 'mkdir -p $(BOT_HOME)/sql/ $(BOT_HOME)/resources/ $(BOT_HOME)/mysql_data/ $(BOT_HOME)/logs/'
	scp -i $(SSH_KEY_PATH) config.yml $(RCB_USER)@$(RCB_HOST):$(BOT_HOME)/resources/config.yml
	git clone --depth 1 --branch $(BOT_VERSION) https://github.com/kvendingoldo/random_coffee_slack.git /tmp/rcb
	rsync -av -e 'ssh -i $(SSH_KEY_PATH)' /tmp/rcb/admin-tools $(RCB_USER)@$(RCB_HOST):$(BOT_HOME)/
	scp -i $(SSH_KEY_PATH) /tmp/rcb/docker-compose.yml $(RCB_USER)@$(RCB_HOST):$(BOT_HOME)/docker-compose.yml
	rm -rf /tmp/rcb

start: ## Start RCB service
	ssh -i $(SSH_KEY_PATH) $(RCB_USER)@$(RCB_HOST) 'cd $(BOT_HOME) && BOT_HOME=$(BOT_HOME) BOT_VERSION=$(BOT_IMAGE_VERSION) BOT_IMG_URL=$(BOT_IMG_URL) docker-compose up -d --force-recreate'

cleanup: ## Cleanup bot resources from VM
	ssh -i $(SSH_KEY_PATH) $(RCB_USER)@$(RCB_HOST) 'rm -f $(BOT_HOME)/sql/* $(BOT_HOME)/resources/config.yml $(BOT_HOME)/docker-compose.yml /tmp/rcb.tar'
	ssh -i $(SSH_KEY_PATH) $(RCB_USER)@$(RCB_HOST) 'docker rm -f bot || echo "Bot container does not exist"'

cleanup_data: ## Clean up MySQL data from VM
	ssh -i $(SSH_KEY_PATH) $(RCB_USER)@$(RCB_HOST) 'rm -f $(BOT_HOME)/mysql_data/*'
