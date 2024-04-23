# Define variables for virtual environment and Python version
PYTHON_VERSION ?= 3.11
SHELL := /bin/zsh

install-asdf::
	@echo ">> checking for asdf installation"
	@if ! command -v asdf >/dev/null 2>&1; then \
		echo "asdf is not installed. please install it from https://asdf-vm.github.io/"; \
		exit 1; \
	fi

install-python:: install-asdf
	@echo ">> checking if Python $(PYTHON_VERSION) is installed..."
	@if ! asdf list python | grep -wq $(PYTHON_VERSION); then \
		echo "python $(PYTHON_VERSION) is not installed. adding python plugin and installing..."; \
		asdf plugin add python; \
		asdf install python latest:$(PYTHON_VERSION); \
		asdf local python latest:$(PYTHON_VERSION); \
	else \
		echo "python $(PYTHON_VERSION) is already installed."; \
	fi

install-pipx:: install-python
	@echo ">> checking if pipx is installed"
	@if ! command -v pipx &> /dev/null; then \
		echo "pipx is not installed. Installing pipx..."; \
		$(python3) -m pip install --user pipx; \
		$(python3) -m pipx ensurepath; \
	else \
		echo "pipx is already installed"; \
	fi

install-uv:: install-pipx
	@echo ">> installing uv package manager"
	pipx install uv

venv:: install-uv
	@echo ">> checking for virtual environment"
	@if [ -d ".venv" ]; then \
        echo "virtual environment exists"; \
    else \
        echo "creating virtual environment"; \
		uv venv; \
    fi

activate:: venv
	@if [ -z "$$VIRTUAL_ENV" ]; then \
		echo ">> run 'source .venv/bin/activate' to enter virtual environment shell"; \
		exit 1; \
	fi

sync-dependencies:: venv
	@echo ">> compiling pyproject.toml to requirements.txt"
	uv pip compile pyproject.toml -o requirements.txt

install-dependencies:: venv
	@if [ ! -e requirements.txt ]; then \
		echo ">> Error: requirements.txt is missing. run 'make sync-dependencies' to generate the file"; \
		exit 1; \
	fi
	@echo ">> installing dependencies"
	uv pip install -r requirements.txt

# commands bellow assume the environment has been setup and the dependencies are installed
lint:: activate
	@echo ">> linting code"
	ruff check

format:: activate
	@echo ">> formatting code"
	ruff format

check-code:: activate lint format
	@echo ">> code checked"
