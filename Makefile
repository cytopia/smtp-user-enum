ifneq (,)
.error This Makefile requires GNU Make.
endif

# -------------------------------------------------------------------------------------------------
# Default configuration
# -------------------------------------------------------------------------------------------------
.PHONY: help lint pycodestyle pydocstyle black dist sdist bdist build checkbuild deploy autoformat clean


VERSION = 2.7
BINPATH =
BINNAME = smtp-user-enum

# -------------------------------------------------------------------------------------------------
# Default Target
# -------------------------------------------------------------------------------------------------
help:
	@echo "lint             Lint source code"
	@echo "build            Build Python package"
	@echo "dist             Create source and binary distribution"
	@echo "sdist            Create source distribution"
	@echo "bdist            Create binary distribution"
	@echo "clean            Build"


# -------------------------------------------------------------------------------------------------
# Lint Targets
# -------------------------------------------------------------------------------------------------

lint: pycodestyle pydocstyle black

pycodestyle:
	docker run --rm -v $(PWD):/data cytopia/pycodestyle --show-source --show-pep8 $(BINNAME)

pydocstyle:
	docker run --rm -v $(PWD):/data cytopia/pydocstyle $(BINNAME)

black:
	docker run --rm -v ${PWD}:/data cytopia/black -l 100 --check --diff $(BINNAME)

.PHONY: mypy
mypy:
	@V="$$( docker run --rm cytopia/mypy --version | head -1 )"; \
	echo "# -------------------------------------------------------------------- #"; \
	echo "# Check Mypy: $${V}"; \
	echo "# -------------------------------------------------------------------- #"
	@#
	docker pull cytopia/mypy
	docker run --rm $$(tty -s && echo "-it" || echo) -v ${PWD}:/data --entrypoint= cytopia/mypy sh -c ' \
		mkdir -p /tmp \
		&& cp $(BINPATH)$(BINNAME) /tmp/$(BINNAME).py \
		&& mypy --config-file setup.cfg /tmp/$(BINNAME).py'

.PHONY: pylint
pylint:
	@V="$$( docker run --rm cytopia/pylint --version | head -1 )"; \
	echo "# -------------------------------------------------------------------- #"; \
	echo "# Check pylint: $${V}"; \
	echo "# -------------------------------------------------------------------- #"
	@#
	docker pull cytopia/pylint
	docker run --rm $$(tty -s && echo "-it" || echo) -v $(PWD):/data --entrypoint= cytopia/pylint sh -c ' \
		mkdir -p /tmp \
		&& cp $(BINPATH)$(BINNAME) /tmp/$(BINNAME).py \
		&& pylint --rcfile=setup.cfg /tmp/$(BINNAME).py'




# -------------------------------------------------------------------------------------------------
# Build Targets
# -------------------------------------------------------------------------------------------------

dist: sdist bdist

sdist:
	docker run \
		--rm \
		$$(tty -s && echo "-it" || echo) \
		-v $(PWD):/data \
		-w /data \
		-u $$(id -u):$$(id -g) \
		python:$(VERSION)-alpine \
		python setup.py sdist

bdist:
	docker run \
		--rm \
		$$(tty -s && echo "-it" || echo) \
		-v $(PWD):/data \
		-w /data \
		-u $$(id -u):$$(id -g) \
		python:$(VERSION)-alpine \
		python setup.py bdist_wheel --universal

build:
	docker run \
		--rm \
		$$(tty -s && echo "-it" || echo) \
		-v $(PWD):/data \
		-w /data \
		-u $$(id -u):$$(id -g) \
		python:$(VERSION)-alpine \
		python setup.py build

checkbuild:
	docker run \
		--rm \
		$$(tty -s && echo "-it" || echo) \
		-v $(PWD):/data \
		-w /data \
		python:$(VERSION)-alpine \
		sh -c "pip install twine \
		&& twine check dist/*"


# -------------------------------------------------------------------------------------------------
# Publish Targets
# -------------------------------------------------------------------------------------------------

deploy:
	docker run \
		--rm \
		$$(tty -s && echo "-it" || echo) \
		-v $(PWD):/data \
		-w /data \
		python:$(VERSION)-alpine \
		sh -c "pip install twine \
		&& twine upload dist/*"


# -------------------------------------------------------------------------------------------------
# Misc Targets
# -------------------------------------------------------------------------------------------------

autoformat:
	docker run \
		--rm \
		$$(tty -s && echo "-it" || echo) \
		-v $(PWD):/data \
		-w /data \
		cytopia/black -l 100 $(BINNAME)
clean:
	-rm -rf $(BINNAME).egg-info/
	-rm -rf dist/
	-rm -rf build/
