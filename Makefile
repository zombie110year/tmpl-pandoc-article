# Markdown 源文件
SOURCE       := $(wildcard src/*.md)

# 配置 pandoc 可执行文件的路径，默认使用 PATH 里的第一个
PANDOC       := pandoc
DEFAULTS     := pandoc.yaml

ifeq ($(OS), Windows_NT)
CP           := powershell -NoProfile -c cp
else
CP           := cp
endif

# 配置默认目标
out: build/main.tex

# 资源文件
ASSET        := $(wildcard src/asset/*)
ASSET_COPIED := $(subst src/,build/,$(ASSET))
STATICS      := $(wildcard static/*)

build/main.%: $(SOURCE) $(STATICS) copy_asset
	$(PANDOC) --defaults $(DEFAULTS) --standalone -o $@ $(SOURCE)

copy_asset: $(ASSET_COPIED)

build/asset/%: src/asset/%
	$(CP) $< $@

.PHONY: out copy_asset
