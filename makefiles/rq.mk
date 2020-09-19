################################################################################
# 変数
################################################################################
RQ_VERSION   := v1.0.2
RQ_LINUX_URL := https://github.com/dflemstr/rq/releases/download/$(RQ_VERSION)/rq-$(RQ_VERSION)-x86_64-unknown-linux-gnu.tar.gz

################################################################################
# タスク
################################################################################

# curl
# -L: --location
# -S: --show-error
# -f: --fail
# -s: --silent
# -o: --output

# tar
# -z: --gzip
# -x: --extract
# -v: --verbose
# -f: --file
.PHONY: install-rq
install-rq:
	( command -v ./rq ) \
	|| ( curl -LSfso ./rq.tar.gz $(RQ_LINUX_URL) && tar -zxvf ./rq.tar.gz && chmod +x ./rq )
