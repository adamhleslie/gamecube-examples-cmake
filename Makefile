# Makefile for building example projects
# This Makefile discovers and builds all CMake projects in the repository

# Configuration
BUILD_DIR := build
OUTPUT_DIR := build
CMAKE := cmake
MAKE := make

# CMake arguments
# Usage: make CMAKE_FLAGS="-DCMAKE_BUILD_TYPE=Release" configure
CMAKE_FLAGS ?=

# Toolchain file
# Usage: make TOOLCHAIN_FILE=/path/to/toolchain.cmake configure
ifdef TOOLCHAIN_FILE
	CMAKE_TOOLCHAIN_ARG := -DCMAKE_TOOLCHAIN_FILE=$(TOOLCHAIN_FILE)
else
	current_dir := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
	CMAKE_TOOLCHAIN_ARG := -DCMAKE_TOOLCHAIN_FILE=$(current_dir)cmake/devkitpro/toolchains/gamecube.toolchain.cmake
endif

# Build type (Debug, Release, RelWithDebInfo, MinSizeRel)
# Usage: make BUILD_TYPE=Release configure
ifdef BUILD_TYPE
	CMAKE_BUILD_TYPE_ARG := -DCMAKE_BUILD_TYPE=$(BUILD_TYPE)
else
	CMAKE_BUILD_TYPE_ARG := -DCMAKE_BUILD_TYPE=Debug
endif

# Combined CMake arguments
CMAKE_ARGS := $(CMAKE_TOOLCHAIN_ARG) $(CMAKE_BUILD_TYPE_ARG) $(CMAKE_FLAGS)

# Find all directories containing CMakeLists.txt
PROJECT_DIRS := $(shell find . -name "CMakeLists.txt" -not -path "*/build/*" -not -path "./cmake/*" -exec dirname {} \; | sort -u)

# Default target
.PHONY: all
all: configure build

# Help target
.PHONY: help
help:
	@echo "Available targets:"
	@echo "  all        - Configure and build all projects (default)"
	@echo "  configure  - Configure all CMake projects"
	@echo "  build      - Build all configured projects"
	@echo "  parallel   - Build all projects in parallel"
	@echo "  clean      - Remove all build directories"
	@echo "  distclean  - Remove all build artifacts and output directory"
	@echo "  list       - List all discovered projects"
	@echo "  help       - Show this help message"
	@echo ""
	@echo "Output:"
	@echo "  All .dol files are collected in $(OUTPUT_DIR)/ after building"
	@echo ""
	@echo "CMake configuration variables:"
	@echo "  TOOLCHAIN_FILE  - Path to CMake toolchain file"
	@echo "  BUILD_TYPE      - Build type (Debug, Release, RelWithDebInfo, MinSizeRel)"
	@echo "  CMAKE_FLAGS     - Additional CMake flags"

# List all discovered projects
.PHONY: list
list:
	@echo "Discovered projects:"
	@for dir in $(PROJECT_DIRS); do \
		echo "  $$dir"; \
	done

# Configure all projects
.PHONY: configure
configure:
	@echo "Configuring all projects..."
	@if [ -n "$(CMAKE_ARGS)" ]; then \
		echo "CMake arguments: $(CMAKE_ARGS)"; \
		echo ""; \
	fi
	@for dir in $(PROJECT_DIRS); do \
		echo ""; \
		echo "=== Configuring $$dir ==="; \
		mkdir -p "$$dir/$(BUILD_DIR)"; \
		(cd "$$dir/$(BUILD_DIR)" && $(CMAKE) $(CMAKE_ARGS) ..) || exit 1; \
	done
	@echo ""
	@echo "All projects configured successfully!"

# Collect all .dol files into output directory
.PHONY: collect-dol
collect-dol:
	@echo "Collecting .dol files..."
	@mkdir -p $(OUTPUT_DIR)
	@for dir in $(PROJECT_DIRS); do \
		if [ -d "$$dir/$(BUILD_DIR)" ]; then \
			for dol in $$(find "$$dir/$(BUILD_DIR)" -name "*.dol" 2>/dev/null); do \
				project_name=$$(echo $$dir | sed 's/^\.\///g' | sed 's/\//-/g'); \
				dol_name=$$(basename $$dol); \
				cp "$$dol" "$(OUTPUT_DIR)/$${project_name}-$${dol_name}"; \
				echo "  Copied $$dol -> $(OUTPUT_DIR)/$${project_name}-$${dol_name}"; \
			done; \
		fi; \
	done
	@echo ""
	@echo "Build complete! .dol files available in $(OUTPUT_DIR)/"

# Build all projects
.PHONY: build
build:
	@echo "Building all projects..."
	@for dir in $(PROJECT_DIRS); do \
		if [ -d "$$dir/$(BUILD_DIR)" ]; then \
			echo ""; \
			echo "=== Building $$dir ==="; \
			(cd "$$dir/$(BUILD_DIR)" && $(MAKE)) || exit 1; \
		else \
			echo "Warning: $$dir/$(BUILD_DIR) not found. Run 'make configure' first."; \
		fi; \
	done
	@echo ""
	@echo "All projects built successfully!"
	@echo ""
	@$(MAKE) collect-dol

# Clean build directories (keep configuration)
.PHONY: clean
clean:
	@echo "Cleaning all projects..."
	@for dir in $(PROJECT_DIRS); do \
		if [ -d "$$dir/$(BUILD_DIR)" ]; then \
			echo "Cleaning $$dir"; \
			(cd "$$dir/$(BUILD_DIR)" && $(MAKE) clean 2>/dev/null) || true; \
		fi; \
	done
	@echo "Clean complete!"

# Remove all build directories
.PHONY: distclean
distclean:
	@echo "Removing all build directories..."
	@for dir in $(PROJECT_DIRS); do \
		if [ -d "$$dir/$(BUILD_DIR)" ]; then \
			echo "Removing $$dir/$(BUILD_DIR)"; \
			rm -rf "$$dir/$(BUILD_DIR)"; \
		fi; \
	done
	@if [ -d "$(OUTPUT_DIR)" ]; then \
		echo "Removing $(OUTPUT_DIR)"; \
		rm -rf "$(OUTPUT_DIR)"; \
	fi
	@echo "Distclean complete!"

# Internal per-project build targets (used by parallel target)
# Automatically configures if needed before building
.PHONY: $(foreach dir,$(PROJECT_DIRS),build-$(subst /,-,$(subst ./,,$(dir))))
$(foreach dir,$(PROJECT_DIRS),build-$(subst /,-,$(subst ./,,$(dir)))):
	@project_path=$(subst -,/,$(subst build-,,$@)); \
	if [ ! -d "$$project_path/$(BUILD_DIR)" ]; then \
		echo "Configuring $$project_path"; \
		if [ -n "$(CMAKE_ARGS)" ]; then \
			echo "CMake arguments: $(CMAKE_ARGS)"; \
		fi; \
		mkdir -p "$$project_path/$(BUILD_DIR)"; \
		(cd "$$project_path/$(BUILD_DIR)" && $(CMAKE) $(CMAKE_ARGS) ..); \
	fi; \
	echo "Building $$project_path"; \
	(cd "$$project_path/$(BUILD_DIR)" && $(MAKE))

# Parallel build support - builds all projects in parallel
# Each project gets its own target, allowing make's -j flag to parallelize
.PHONY: parallel
parallel:
	@echo "Building all projects in parallel (will stop on first error)..."
	@$(MAKE) -j$(shell nproc 2>/dev/null || echo 4) $(foreach dir,$(PROJECT_DIRS),build-$(subst /,-,$(subst ./,,$(dir))))
	@echo ""
	@echo "All projects built successfully in parallel!"
	@echo ""
	@$(MAKE) collect-dol
