################################################################################
# 変数
################################################################################
IGNORE_OS       := linux,macos,windows
IGNORE_EDITOR   := vim,emacs,intellij+all,visualstudiocode
IGNORE_LANGUAGE := c,c++,rust,python,ruby,rust,go,java,kotlin,node,erlang,elixir,commonlisp,racket,scala
IGNORE_TOOL     := vagrant,ansible,terraform,gradle,maven
IGNORE_LIST     := $(IGNORE_LANGUAGE),$(IGNORE_OS),$(IGNORE_EDITOR),$(IGNORE_TOOL)
GIT_IGNORE_URL  := https://www.toptal.com/developers/gitignore/api/$(IGNORE_LIST)

################################################################################
# タスク
################################################################################
.gitignore:
	curl --output .gitignore $(GIT_IGNORE_URL)

.PHONY: setup-gitignore
setup-gitignore: .gitignore ## .gitignoreをsetup
	@make --no-print-directory add-my-go-env-for-gitignore
	@make --no-print-directory add-rq-for-gitignore

.PHONY: add-my-go-env-for-gitignore
add-my-go-env-for-gitignore:
	grep '^.bash_history$$' .gitignore || echo '.bash_history' >> .gitignore
	grep '^go-bin$$' .gitignore || echo 'go-bin' >> .gitignore
	grep '^go-pkg$$' .gitignore || echo 'go-pkg' >> .gitignore
	grep '^.cache$$' .gitignore || echo '.cache' >> .gitignore
	grep '^.config$$' .gitignore || echo '.config' >> .gitignore
	grep '^__debug_bin$$' .gitignore || echo '__debug_bin' >> .gitignore

.PHONY: add-rq-for-gitignore
add-rq-for-gitignore:
	grep 'rq' .gitignore || echo 'rq' >> .gitignore
