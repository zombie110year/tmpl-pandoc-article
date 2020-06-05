---
title: '使用 Pandoc 进行文档编辑'
author: Zombie110year
date: 2020-06-04 00:00:00
toc: true
toc-depth: 2
number-sections: true
documentclass: ctexart
---

![pandoc caption](asset/pandoc-logo.png)

Pandoc 是一个标记语言转换工具，它支持非常多的语言之间的相互转换，并且，支持一种功能非常强大的 Markdown 解析功能 —— 即 Pandoc Markdown [@doc_pandoc_markdown]。

并且，Pandoc 提出 filter 协议，可以用 JSON 的方式与其他可执行文件交流数据，为标记语言的扩展解析功能提供了接口。
本文介绍利用 Pandoc 进行大型文档写作的方法。

# 利其器

在用 Pandoc 进行文章写作时，通常为用到以下工具：

pandoc
:   pandoc 本体

pandoc-crossref[@doc_pandoc_crossref]
:   为 pandoc markdown 提供交叉引用功能。

pandoc-citeproc
:   一般跟随 pandoc 本体一同分发。提供解析参考文献引用的功能。

vscode
:   说它是目前地球最强的文本编辑器应该没人反对吧？

shd101wyy.markdown-preview-enhanced
:   vscode 与 atom 编辑器上最好用的 Markdown 实时渲染扩展。

其中，由于 pandoc-crossref 与 pandoc-citeproc 使用了相同的标记语法，因此在配置 filter 时，
需要让 crossref 在 citeproc 之前工作，否则会引起冲突。
并且 pandoc-crossref 与 pandoc 本体的版本高度耦合，甚至会出现兼容 2.9.2.1 但不兼容 2.9.2 的情况，
因此在安装时需要提前确认好本地 pandoc 的版本，到 GitHub Release 下载兼容的版本。

# 工作区布置

我们创建一个空的文件夹作为工作区，通常，我们希望工作区包含以下内容（用缩进代表一个文件夹）

```
Makefile                # 利用 Makefile 进行任务控制
pandoc.yaml             # 利用 pandoc 的 --defaults 选项，
                        # 将所有命令行参数写为 yaml 格式

.vscode/
    settings.json       # 针对当前项目进行一些布置

src/                    # 将所有作者创造的内容保存在此文件夹下
    main.md             # 一个入口文档，通常在此文档编辑 YAML 元数据头
    chapter1.md         # 其他的章节内容
    asset/              # 在文章中引用的图片、代码、或其他资源保存在此文件夹中

static/                 # 不在文章中引用的资源文件
    highlight.theme     # 语法高亮样式文件（在 pandoc.yaml 中使用）
    template.*          # 使用的模板（在 pandoc.yaml 中配置）

build/                  # 所有由程序生成的内容保存在此
```

## pandoc.yaml

pandoc 可以将命令行参数写成 yaml 格式，其选项名的长形式和 yaml 中的键名一一对应，对于一些命令行表现和 yaml 键值对表现相异的部分，一般都遵循以下规律：

值的数目超过一的参数、选项在 yaml 中也可以用复数形式的键名 + yaml 列表来进行配置。
:   ```
    pandoc --filter pandoc-crossref --filter pandoc-citeproc

    filters:
    - pandoc-crossref
    - pandoc-citeproc
    ```

起标志（flag）作用的选项，在 yaml 中的值类型应当为 bool。
:   ```
    pandoc --toc

    toc: true
    ```

一个典型的 yaml 文件通常有以下内容：

```yaml
# 路径相对于 pandoc 可执行文件的当前工作目录
# 为了与 Markdown Preview Enhanced 相配合（通过 stdout）不配置输入输出文件
# input-files:
# output:

filters:
- pandoc-crossref
- pandoc-citeproc

html-math-method:
  method: katex
  url: "https://cdn.jsdelivr.net/npm/katex@0.11.1/dist/katex.min.js"

metadata:
  bibliography: src/asset/ref.bib
  csl: chinese-gb7714-2015-numeric.csl
  link-citations: false
  reference-section-title: 参考文献
  # 配置 pandoc-crossref 引用显示前缀
  figPrefix: "图"
  lstPrefix: "代码"
  secPrefix: "章"
  eqnPrefix: "式"
  # 配置 pandoc-crossref 项目标题前缀
  figureTitle: "图"
  tableTitle: "表"
  listingTitle: "代码"
```

在转换文档时，不再传递过长的命令行参数，而使用

```sh
pandoc --defaults=pandoc.yaml --standalone -o <output>
```

两个参数代替。如上例所述，为了方便配置 MPE（Markdown Preview Enhanced） 的渲染，没有指定输出文件，而是在转换时才通过 -o 参数来指定，这样，就可以很方便地配置 MPE 使用 pandoc 来代替 markdown-it 了。

另外，在这里可以看到一个 `metadata` 键，这个键对应 `--metadata=KEY:VALUE` 命令行参数。对于 Markdown 来说，它指定的就是一个文档的 YAML 头。

为了在编辑由多个文件组成的项目时，MPE 能够独立预览单个文件，不至于让 pandoc 每次都全量渲染，没有指定 input-files。
当然，可以指定并注释，在最后生成结果时再取消注释并调用 pandoc 渲染。

## main.md

通常，我们把每个文件都可能用到的元数据写在 pandoc.yaml 文件里，把整个项目只使用一次的元数据以 YAML header 的形式写在入口 Markdown 文件的头部:

```yaml
---
title: 文档的标题
author: 作者
date: 1900-01-01 00:00:00
toc: true
toc-depth: 2
number-sections: true
...
```

# Makefile 调用

在根目录的 Makefile 里，配置：

```makefile
# Markdown 源文件
SOURCE       := $(wildcard src/*.md)

# 配置 pandoc 可执行文件的路径，默认使用 PATH 里的第一个
PANDOC       := pandoc
DEFAULTS     := pandoc.yaml

ifeq ($(OS), Windows_NT)
CP           := powershell -noprofile -c cp
MKDIR        := powershell -noprofile -c mkdir
else
CP           := cp
MKDIR        := mkdir
endif

# 配置默认目标
out: build/main.tex

# 资源文件
ASSET        := $(wildcard src/asset/*)
ASSET_COPIED := $(subst src/,build/,$(ASSET))
STATICS      := $(wildcard static/*)

build/main.%: $(SOURCE) $(STATICS) copy_asset
	$(PANDOC) --defaults $(DEFAULTS) --standalone -o $@ $(SOURCE)

copy_asset: build/asset $(ASSET_COPIED)

build/asset: build
	$(MKDIR) $@
build:
	$(MKDIR) $@

build/asset/%: src/asset/%
	$(CP) $< $@

.PHONY: out copy_asset
```

（复制时记得把前缀空格换成制表符！）

当 latex 文档渲染出来后，进入 build 目录用 LaTeX 发行版进行编译。有些编译比较麻烦的，比如要建立目录、索引之类的，
需要多次编译，还需要插入 makeindex 指令等，可以在 build/ 目录下编写一个新的 Makefile，反正也不长。

# Markdown Preview Enhanced

在 vscode 工作区的配置文件中添加：

```json
{
    "markdown-preview-enhanced.usePandocParser": true,
    "markdown-preview-enhanced.pandocArguments": "--defaults=pandoc.yaml"
}
```

# Pandoc 的重要扩展语法

介绍 pandoc 所扩展的最有诱惑力的语法。

## 隐式标题引用

当启用 `implicit_header_references` 扩展时，可以用 `[]` 包括标题原文创建一个指向标题的引用。

    # 标题文本

    [标题文本]

## 定义列表

    术语
    :   定义

## 交叉引用与引文引用

这其实是 pandoc-crossref 和 pandoc-citeproc 提供的语法：

    Blah blah [参阅 @doe99， 33-35 页; 以及 @smith04, 第 1 章].

    Blah blah [@doe99，33-35、38-39 页和 *passim*].

    Blah blah [@smith04; @doe99].

当文档中存在无法指定具体位置的引用时，在 YAML 头中添加：

    nocite: |
        @key

这样，引文仍然会包含在引文目录中。

更多的注意事项参考 pandoc-citeproc [@doc_pandoc_citeproc] 和 pandoc-crossref [@doc_pandoc_crossref] 的文档。

## 属性标注

在任意 Markdown 元素后用 `{attr }` 的格式添加属性，语法类似 HTML：

```
    ![image](foo.jpg){#id .class width=30 height=20px}

    ~~~~ {#mycode .haskell .numberLines startFrom="100"}
    qsort []     = []
    qsort (x:xs) = qsort (filter (< x) xs) ++ [x] ++
                qsort (filter (>= x) xs)
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    ::: {.warning}
    警告段落！
    :::
```

## 通用原始属性

在一个栅栏式代码块中使用属性 `{=format}` 可以指定当输出格式为 format 时将代码块中内容作为原始输出内容：

~~~
    ``{=openxml}
    <w:p>
    <w:r>
        <w:br w:type="page"/>
    </w:r>
    </w:p>
    ``
~~~

# Pandoc Template

- [ ] todo


# data dir 机制

- [ ] todo
