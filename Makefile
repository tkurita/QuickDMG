PRODUCT_NAME := QuickDMG
WORKSPACE := $(PRODUCT_NAME).xcworkspace
CONFIG := Release
DSTROOT := ${HOME}

.PHONY:install clean build trash

default: trash clean install

trash:
	trash "$(DSTROOT)/Applications/$(PRODUCT_NAME).app"

install:
	xcodebuild -workspace $(WORKSPACE) -scheme "$(PRODUCT_NAME)" -configuration $(CONFIG) install DSTROOT=$(DSTROOT)

clean:
	xcodebuild -workspace $(WORKSPACE) -scheme "$(PRODUCT_NAME)" -configuration $(CONFIG) clean

build:
	xcodebuild -workspace $(WORKSPACE) -scheme "$(PRODUCT_NAME)" -configuration $(CONFIG) build
